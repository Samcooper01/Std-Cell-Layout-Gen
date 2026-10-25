#!/usr/bin/env bash
# Stage 2, MAX EFFORT convergence on the OPEN set (Stage 1 non CLEAN cells), with
# FULL PER CELL LOGGING. Goal: converge as many remaining cells as the CURRENT
# placer/router can, area be damned, and record how long every step takes.
#
# Per cell, under .work/ceiling/max/<cell>/ :
#   rung00_committed.log, rung01_<tag>.log, ...  -- FULL verbose (-v) lclayout log
#                                                   for EVERY rung tried (never overwritten)
#   timeline.tsv  -- one row per rung: recipe, result, wall_s, lclayout total_s, and
#                    per stage durations (setup, placement, routing(+iters), min area, LVS)
# Run level roll up stays in .work/ceiling/ceiling.tsv (cheapest area closing recipe/cell).
#
# Usage: ceiling.sh [parallelism] [deadline_hours]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
export OMP_NUM_THREADS=1 Z3_NUM_THREADS=1   # keep each solve single-threaded
PAR="${1:-10}"; DEADLINE_H="${2:-10}"
OUT="$ROOT/.work/ceiling"; mkdir -p "$OUT/max"
BASE="$OUT/baseline.tsv"
TSV="$OUT/ceiling.tsv"; PROG="$OUT/ceiling.progress"
: > "$TSV"; : > "$PROG"
printf 'cell\tresult\tclosing_recipe\twidth_um\theight_um\theight_mult\tlayers\tarea_um2\titers\n' >> "$TSV"

START=$(date +%s)
DEADLINE=$(awk -v s="$START" -v h="$DEADLINE_H" 'BEGIN{printf "%d", s + h*3600}')
export START DEADLINE

cells=$(awk -F'\t' 'NR>1 && $2!="CLEAN"{print $1}' "$BASE")
TOTAL=$(echo "$cells" | grep -c .)
echo "# ceiling: $TOTAL open cells, ${PAR}-way, deadline ${DEADLINE_H}h, FULL LOGGING  $(date '+%H:%M:%S')" | tee "$PROG"

# Ladder: cheapest AREA first, timeout GROWS with rung.
# cols: placer router lift layers sma group height tight  timeout_s
LADDER='meta         dijkstra 1 3 1 0 1 1 120
meta         dijkstra 1 4 1 0 1 1 150
hierarchical dijkstra 1 4 1 0 1 1 180
meta         dijkstra 1 3 1 0 2 1 300
meta         dijkstra 1 4 1 0 2 1 360
hierarchical dijkstra 1 4 1 0 2 1 360
meta         dijkstra 1 4 1 1 2 1 360
meta         dijkstra 1 4 1 0 3 1 600
hierarchical dijkstra 1 4 1 0 3 1 600
meta         dijkstra 1 4 1 0 4 1 900
hierarchical dijkstra 1 4 1 0 4 1 900
meta         dijkstra 1 4 1 1 4 1 900'

# --- timing helpers (epoch of first line matching a stage marker; duration between two) ---
_ep(){ local ts; ts=$(grep -m1 -E "$2" "$1" 2>/dev/null | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'); [ -n "$ts" ] && date -d "$ts" +%s 2>/dev/null || echo ""; }
_dur(){ if [ -n "$1" ] && [ -n "$2" ]; then echo $(( $2 - $1 )); else echo NA; fi; }

log_timeline(){  # $1=w  $2=idx  $3=recipe  $4=log  $5=wall_s  $6=ok(1/0)
  local w="$1" idx="$2" recipe="$3" log="$4" wall="$5" ok="$6"
  local result; [ "$ok" = 1 ] && result=CLOSED || result=fail
  local e_start e_place e_route e_rok e_lvs e_lvsr
  e_start=$(_ep "$log" 'Loading tech file|Load netlist')
  e_place=$(_ep "$log" 'Initialize placer|Placement engine')
  e_route=$(_ep "$log" 'Start routing')
  e_rok=$(_ep "$log" 'Routing successful')
  e_lvs=$(_ep "$log" 'Running LVS check')
  e_lvsr=$(_ep "$log" 'LVS result')
  local setup_s place_s route_s minarea_s lvs_s iters total_s td size wd ht
  setup_s=$(_dur "$e_start" "$e_place")
  place_s=$(_dur "$e_place" "$e_route")
  route_s=$(_dur "$e_route" "$e_rok")
  minarea_s=$(_dur "$e_rok" "$e_lvs")
  lvs_s=$(_dur "$e_lvs" "$e_lvsr")
  iters=$(grep -oE 'Routing iteration [0-9]+' "$log" | tail -1 | grep -oE '[0-9]+'); iters="${iters:-NA}"
  td=$(grep -oE 'Total duration: [0-9]+:[0-9]{2}:[0-9]{2}' "$log" | head -1 | grep -oE '[0-9]+:[0-9]{2}:[0-9]{2}')
  if [ -n "$td" ]; then total_s=$(awk -F: '{print $1*3600+$2*60+$3}' <<<"$td"); else total_s=NA; fi
  size=$(grep -iE '^\s*SIZE ' "$w"/out/*.lef 2>/dev/null | head -1)
  wd=$(echo "$size"|awk '{print $2}'); ht=$(echo "$size"|awk '{print $4}')
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$idx" "$recipe" "$result" "$wall" "$total_s" "$setup_s" "$place_s" "$route_s" "$iters" "$minarea_s" "$lvs_s" "${wd:-NA}" "${ht:-NA}" >> "$w/timeline.tsv"
}

record_close(){  # $1=recipe-label ; reads $w/out/*.lef and $LASTLOG
  local lbl="$1" size
  size=$(grep -iE '^\s*SIZE ' "$w"/out/*.lef 2>/dev/null | head -1)
  wd=$(echo "$size" | awk '{print $2}'); ht=$(echo "$size" | awk '{print $4}')
  ar=$(awk -v a="$wd" -v b="$ht" 'BEGIN{printf "%.2f", a*b}')
  it=$(grep -oE 'Routing iteration [0-9]+' "$LASTLOG" 2>/dev/null | tail -1 | grep -oE '[0-9]+')
  res=CLOSED; rec="$lbl"
}

run_attempt(){  # $1=idx $2=tag $3=recipe-label $4=timeout $5=logfile  (env vars pre-set by caller)
  local idx="$1" tag="$2" label="$3" to="$4" log="$5" t0 t1 ok=0
  rm -f "$w/out/"* 2>/dev/null
  t0=$(date +%s)
  # NOTE: no -v, the default log already timestamps every pipeline step (see timeline.tsv).
  # -v added ~400 MB/rung of routing graph noise for zero extra timing info.
  timeout "$to" "$ROOT/src/cellgen/run_cell.sh" "$c" </dev/null > "$log" 2>&1
  t1=$(date +%s)
  [ -f "$w/out/$full.gds" ] && grep -qi 'LVS result: SUCCESS' "$log" && ok=1
  log_timeline "$w" "$idx" "$label" "$log" "$((t1-t0))" "$ok"
  [ "$ok" = 1 ] && { LASTLOG="$log"; return 0; } || return 1
}

worker(){
  ulimit -v 12582912 2>/dev/null   # 12 GB/solve: runaway z3 dies clean (-> UNSOLVED) not OOM
  c="$1"; full="sky130_fd_sc_hd__$c"
  ccat=$(awk -v k="$c" -F'\t' '$1==k{print $2}' "$ROOT/recipes/cell_categories.tsv"); ccat="${ccat:-uncategorized}"
  w="$ROOT/.work/ceiling/max/$ccat/$c"; mkdir -p "$w/out"; export RUN_WORK="$w"
  rm -f "$w"/rung*.log "$w"/timeline.tsv 2>/dev/null
  printf 'rung\trecipe\tresult\twall_s\ttotal_s\tsetup_s\tplace_s\troute_s\troute_iters\tminarea_s\tlvs_s\twidth\theight\n' > "$w/timeline.tsv"
  res=UNSOLVED; rec=none; wd=NA; ht=NA; hm=1; nl=2; ar=NA; it=NA; LASTLOG=""

  # Rung 0, the cell's own committed recipe.
  if run_attempt 0 committed committed 240 "$w/rung00_committed.log"; then
    record_close "committed"
    hm=$(grep -oE 'height=[0-9]+' "$LASTLOG"|head -1|grep -oE '[0-9]+'); hm="${hm:-1}"
    nl=$(grep -oE 'layers=[0-9]+'  "$LASTLOG"|head -1|grep -oE '[0-9]+'); nl="${nl:-2}"
  fi

  local idx=0
  [ "$res" = CLOSED ] || while IFS= read -r r; do
    [ -z "$r" ] && continue
    idx=$((idx+1))
    [ "$(date +%s)" -ge "$DEADLINE" ] && { res=DEADLINE; break; }
    read -r pl rt lf lay sma grp hgt lt to <<<"$r"
    local tag lbl log
    tag="${pl:0:4}_L${lay}h${hgt}t${lt}s${sma}g${grp}"
    lbl="$pl/L$lay/h$hgt/t$lt/s$sma/g$grp"
    log="$w/rung$(printf '%02d' "$idx")_${tag}.log"
    # BUGFIX: `env VAR=... run_attempt` can't work, env cannot invoke a shell function,
    # so export the recipe vars into the environment; run_cell.sh (external) inherits them.
    export PLACER="$pl" ROUTER="$rt" RECIPE_LIFT_DRAINS="$lf" RECIPE_MCON_WEIGHT=300000 \
           RECIPE_NUM_LAYERS="$lay" RECIPE_SKIP_MIN_AREA="$sma" RECIPE_GROUP_FINGERS="$grp" \
           RECIPE_HEIGHT_MULT="$hgt" RECIPE_LIFT_TIGHT="$lt"
    if run_attempt "$idx" "$tag" "$lbl" "$to" "$log"; then
      record_close "$lbl"; hm="$hgt"; nl="$lay"; break
    fi
  done <<< "$LADDER"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$c" "$res" "$rec" "$wd" "$ht" "$hm" "$nl" "$ar" "${it:-NA}" >> "$ROOT/.work/ceiling/ceiling.tsv"
  n=$(( $(wc -l < "$ROOT/.work/ceiling/ceiling.tsv") - 1 ))
  printf '[%s %d/%d] %-28s %-8s %-22s %sx%s\n' "$(date '+%H:%M:%S')" "$n" "$TOTAL" "$c" "$res" "$rec" "$wd" "$ht" >> "$ROOT/.work/ceiling/ceiling.progress"
}
# RUN_WORK (where run_cell.sh writes) is now set INSIDE worker(), which routes each cell
# to .work/ceiling/max/<category>/<cell>/ using harness/cell_categories.tsv.
export -f worker record_close log_timeline run_attempt _ep _dur
export ROOT TOTAL LADDER
echo "$cells" | grep . | xargs -P "$PAR" -I{} bash -c 'worker "$@"' _ {}
echo "# DONE $(date '+%H:%M:%S')" >> "$PROG"
echo "## RESULT BREAKDOWN" >> "$PROG"
awk -F'\t' 'NR>1{c[$2]++} END{for(k in c) printf "%-9s %d\n", k, c[k]}' "$TSV" | sort -rnk2 | tee -a "$PROG"
