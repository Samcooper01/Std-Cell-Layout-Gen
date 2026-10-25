#!/usr/bin/env bash
# Run ONE sky130_fd_sc_hd cell through lclayout PnR with our sky130 tech file.
#
# Usage:  harness/run_cell.sh <cell_short_name> [extra lclayout args]
#   e.g.  harness/run_cell.sh inv_1
#         harness/run_cell.sh inv_1 --debug routing graph
#
# It extracts the cell's subckt from sky130_hd_all_cells.sp and ties the bulk pins
# to the rails (VPB->VPWR, VNB->VGND; no body bias) so lclayout's lack of native
# 4 terminal handling doesn't mask real tech file issues. Outputs land in .work/out/.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"

# Pin numeric thread pools to a single thread. lclayout is one core of sustained
# work per cell; without this, OpenBLAS / Open Multi Processing (OMP) / Math Kernel
# Library (MKL) each spawn one thread per host core, so running many cells at once
# oversubscribes badly (this drove the load to 264 and destabilized results). One
# thread per worker also makes runs deterministic. A caller may still override.
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-1}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-1}"
export NUMEXPR_NUM_THREADS="${NUMEXPR_NUM_THREADS:-1}"

# Use THIS worktree's own lclayout copy (if present) instead of the shared editable
# install. lclayout is an editable install pinned to the main tree's absolute path;
# prepending our own src to PYTHONPATH makes Python import it first, so each git
# worktree runs its OWN lclayout (isolated placement/router changes per branch).
if [ -d "$ROOT/lclayout/src" ]; then
  export PYTHONPATH="$ROOT/lclayout/src${PYTHONPATH:+:$PYTHONPATH}"
fi

cell="${1:?usage: run_cell.sh <cell_short_name>  (e.g. inv_1)}"; shift || true
full="sky130_fd_sc_hd__$cell"
ALL="$ROOT/cells/sky130_hd_all_cells.sp"
TECH="${RUN_TECH:-$ROOT/tech/sky130_hd_tech.py}"
work="${RUN_WORK:-$ROOT/.work}"; mkdir -p "$work/nl" "$work/out"
nl="$work/nl/$cell.sp"

# extract the subckt (trailing space disambiguates inv_1 from inv_12), then normalize the
# sky130 hd CDL into a form lclayout + its internal LVS accept:
#   - drop the VPB/VNB bulk PORTS from the .SUBCKT header (lclayout's nmos/pmos are 3 terminal;
#     leaving them as ports causes an LVS port count mismatch), but keep the bulk CONNECTIONS
#     tied to the rails on the device lines (VPB->VPWR, VNB->VGND; no body bias).
#   - add explicit micron units to W/L. The hd CDL writes bare microns (w=0.65 l=0.15), but
#     lclayout reads bare numbers as METERS (0.65 m), making transistors ~1e6x too large.
#   - map sky130 device models to lclayout's generic classes (nfet*->nmos, pfet*->pmos) so the
#     reference and extracted netlists use the same device class (LVS compares class names).
#   - fold the device multipliers (m, mult) into W. A device "m=2 w=0.84" is two parallel
#     0.84um devices (effective 1.68um); lclayout generates a single W=1.68 device, but
#     KLayout's reference reader keeps W=0.84 -> width LVS mismatch. We pre fold W*=m*mult and
#     set m=mult=1 so both sides see the effective width.
# MULT handling, two modes, selected by EXPAND env (default: expand):
#   expand (EXPAND=1, default): a device "m=N" becomes N separate parallel devices each m=1.
#     This is the CORRECT model: the foundry cell IS N parallel fingers, lclayout draws N
#     narrow devices (they fit the cell height and route), and both LVS sides see N devices.
#   fold (EXPAND=0): legacy mode, m*mult folded into one wide W. Kept for comparison only;
#     it breaks drive 4 because W can exceed unit_cell_height (device taller than the cell).
# EXPAND is consumed here during normalization, before the full recipe is parsed below,
# so read column 12 of this cell's recipe line directly (default 1). An explicit env wins.
EXPAND="${EXPAND:-$(awk -v c="$cell" '$0!~/^#/ && $1==c{print (NF>=12?$12:1); f=1} END{if(!f)print 1}' "${RUN_RECIPES:-$ROOT/recipes/recipes}" 2>/dev/null || echo 1)}"
awk -v C="$full" '$0 ~ "^.SUBCKT "C" ", $0 ~ "^.ENDS "C' "$ALL" \
  | awk -v expand="$EXPAND" '{ if ($1 ~ /^[Mm]/) {
             m=1; mu=1;
             for (i=1;i<=NF;i++){ if ($i ~ /^m=/){split($i,p,"=");m=p[2]} else if ($i ~ /^mult=/){split($i,p,"=");mu=p[2]} }
             tot=m*mu;
             if (expand=="1" && tot>1) {
               base=$1;
               for (k=0;k<tot;k++){ line="";
                 for (i=1;i<=NF;i++){ v=$i;
                   if (i==1) v=base"_"k; else if (v ~ /^m=/) v="m=1"; else if (v ~ /^mult=/) v="mult=1";
                   line=line (i>1?" ":"") v; }
                 print line; }
               next;
             } else {
               for (i=1;i<=NF;i++){ if ($i ~ /^w=/){split($i,p,"=");$i="w="(p[2]*m*mu)} else if ($i ~ /^m=/){$i="m=1"} else if ($i ~ /^mult=/){$i="mult=1"} }
             }
           } print }' \
  | sed -E '
      /^\.SUBCKT/I { s/ VPB\b//g; s/ VNB\b//g; }
      s/\bVPB\b/VPWR/g; s/\bVNB\b/VGND/g;
      s/( w=)([0-9.]+)/\1\2u/g; s/( l=)([0-9.]+)/\1\2u/g;
      s/\bnfet[a-z0-9_]*/nmos/g; s/\bpfet[a-z0-9_]*/pmos/g;
    ' > "$nl"
[ -s "$nl" ] || { echo "ERROR: cell '$full' not found in $ALL"; exit 2; }

echo "# cell:    $full"
echo "# netlist: $nl"
echo "# tech:    $TECH"
# --- Per cell generator recipe (LAYER 3 knobs: placer / router / mcon weight) ---
# Look up this cell's recipe from harness/recipes, falling back to the 'default'
# row. These are the ONLY knobs allowed to vary per cell; DRC + library
# architecture (height/site/tracks/unit_cell_width) stay shared in the tech file.
# Precedence: explicit env (PLACER/ROUTER/RECIPE_MCON_WEIGHT) and CLI args in
# "$@" override the recipe, which overrides the built in fallbacks.
RECIPES="${RUN_RECIPES:-$ROOT/recipes/recipes}"
recipe=$(awk -v c="$cell" '
  $0 !~ /^#/ && NF>=4 {
    lf=(NF>=5?$5:"0"); nl=(NF>=6?$6:"2"); sm=(NF>=7?$7:"0"); gr=(NF>=8?$8:"0"); hm=(NF>=9?$9:"1"); lt=(NF>=10?$10:"0"); wd=(NF>=11?$11:"1"); ex=(NF>=12?$12:"1")
    if ($1==c)            { pl=$2; rt=$3; mc=$4; lift=lf; lay=nl; sma=sm; grp=gr; hgt=hm; tgt=lt; wid=wd; xpd=ex; found=1 }
    else if ($1=="default"){ dpl=$2; drt=$3; dmc=$4; dlift=lf; dlay=nl; dsma=sm; dgrp=gr; dhgt=hm; dtgt=lt; dwid=wd; dxpd=ex }
  }
  END { if (found) print pl, rt, mc, lift, lay, sma, grp, hgt, tgt, wid, xpd; else print dpl, drt, dmc, dlift, dlay, dsma, dgrp, dhgt, dtgt, dwid, dxpd }' "$RECIPES" 2>/dev/null)
PLACER="${PLACER:-$(echo "$recipe" | awk '{print $1?$1:"hierarchical"}')}"
ROUTER="${ROUTER:-$(echo "$recipe" | awk '{print $2?$2:"dijkstra"}')}"
export RECIPE_MCON_WEIGHT="${RECIPE_MCON_WEIGHT:-$(echo "$recipe" | awk '{print $3?$3:"300000"}')}"
export RECIPE_LIFT_DRAINS="${RECIPE_LIFT_DRAINS:-$(echo "$recipe" | awk '{print $4?$4:"0"}')}"
export RECIPE_NUM_LAYERS="${RECIPE_NUM_LAYERS:-$(echo "$recipe" | awk '{print $5?$5:"2"}')}"
export RECIPE_SKIP_MIN_AREA="${RECIPE_SKIP_MIN_AREA:-$(echo "$recipe" | awk '{print $6?$6:"0"}')}"
export RECIPE_GROUP_FINGERS="${RECIPE_GROUP_FINGERS:-$(echo "$recipe" | awk '{print $7?$7:"0"}')}"
export RECIPE_HEIGHT_MULT="${RECIPE_HEIGHT_MULT:-$(echo "$recipe" | awk '{print $8?$8:"1"}')}"
export RECIPE_LIFT_TIGHT="${RECIPE_LIFT_TIGHT:-$(echo "$recipe" | awk '{print $9?$9:"0"}')}"
export RECIPE_WIDTH_MULT="${RECIPE_WIDTH_MULT:-$(echo "$recipe" | awk '{print $10?$10:"1"}')}"
# EXPAND (recipe column 12) is already resolved above for normalization; nothing else
# consumes it, so no separate export is needed here.

# Don't inject a flag the caller already passed explicitly in "$@".
extra=()
case " $* " in *" --placer "*) : ;;        *) extra+=(--placer "$PLACER") ;; esac
case " $* " in *" --signal-router "*) : ;; *) extra+=(--signal-router "$ROUTER") ;; esac

echo "# recipe:  placer=$PLACER router=$ROUTER mcon=$RECIPE_MCON_WEIGHT lift=$RECIPE_LIFT_DRAINS layers=$RECIPE_NUM_LAYERS skipminarea=$RECIPE_SKIP_MIN_AREA group=$RECIPE_GROUP_FINGERS height=$RECIPE_HEIGHT_MULT tight=$RECIPE_LIFT_TIGHT width=$RECIPE_WIDTH_MULT expand=$EXPAND"
PYTHONHASHSEED=42 lclayout --output-dir "$work/out" --tech "$TECH" --netlist "$nl" \
  --cell "$full" "${extra[@]}" "$@"
