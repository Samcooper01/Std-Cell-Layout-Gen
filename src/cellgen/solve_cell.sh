#!/usr/bin/env bash
# Per cell recipe solver. Try an escalating matrix of (placer, router, lift)
# recipes for ONE cell and print the FIRST that yields an LVS clean GDS, in a
# form ready to paste into harness/recipes:
#     <cell>   <placer> <router> <mcon> <lift>      # SOLVED (Nit, Ss)
# or  <cell>   UNSOLVED
#
# Usage: harness/solve_cell.sh <cell> [timeout_s]
# Env:   MCON (default 300000)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
cell="${1:?usage: solve_cell.sh <cell> [timeout_s]}"
TO="${2:-60}"
MCON="${MCON:-300000}"
WORK="$ROOT/.work/solve/$cell"; mkdir -p "$WORK/out"
full="sky130_fd_sc_hd__$cell"

# Recipe matrix, cheapest/most-faithful first. Columns: placer router lift layers skipminarea
# The metal escalation ladder: try 2 layers (foundry faithful) first; only climb
# to 3 (met2) then 4 (met3) when a cell won't route in fewer. skipminarea=1 on the
# multi layer rungs (min area DRC fixing is not an LVS requirement and can go UNSAT).
# Columns: placer router lift layers skipminarea group height tight
# Ladder policy: SINGLE height first (most faithful), climb metal layers, add
# tight lift; only then fall back to DOUBLE height (height=2, big routing channel).
recipes=(
  "hierarchical dijkstra 0 2 0 0 1 0"
  "hierarchical dijkstra 1 2 0 0 1 0"
  "meta         dijkstra 1 2 0 0 1 0"
  "meta         dijkstra 1 2 0 0 1 1"
  "meta         dijkstra 1 3 1 0 1 0"
  "meta         dijkstra 1 3 1 0 1 1"
  "hierarchical dijkstra 1 3 1 0 1 1"
  "meta         dijkstra 1 4 1 0 1 1"
  "meta         dijkstra 1 2 0 0 2 1"
  "meta         dijkstra 1 3 1 0 2 1"
  "hierarchical dijkstra 1 3 1 0 2 1"
)
# Allow overriding the matrix (one recipe per line) via env.
if [ -n "${SOLVE_RECIPES:-}" ]; then
  mapfile -t recipes <<<"$SOLVE_RECIPES"
fi
for r in "${recipes[@]}"; do
  read -r pl rt lf nl sma grp hm lt <<<"$r"
  nl="${nl:-2}"; sma="${sma:-0}"; grp="${grp:-0}"; hm="${hm:-1}"; lt="${lt:-0}"
  rm -f "$WORK/out/"* 2>/dev/null
  env RUN_WORK="$WORK" PLACER="$pl" ROUTER="$rt" RECIPE_LIFT_DRAINS="$lf" RECIPE_MCON_WEIGHT="$MCON" \
      RECIPE_NUM_LAYERS="$nl" RECIPE_SKIP_MIN_AREA="$sma" RECIPE_GROUP_FINGERS="$grp" \
      RECIPE_HEIGHT_MULT="$hm" RECIPE_LIFT_TIGHT="$lt" \
      timeout "$TO" "$ROOT/src/cellgen/run_cell.sh" "$cell" >"$WORK/last.log" 2>&1
  if [ -f "$WORK/out/$full.gds" ] && grep -qi 'LVS result: SUCCESS' "$WORK/last.log"; then
    nit=$(grep -oE 'Routing iteration [0-9]+' "$WORK/last.log" | tail -1 | grep -oE '[0-9]+')
    printf '%-28s %-13s %-9s %-8s %s %s %s %s %s   # SOLVED it=%s\n' "$cell" "$pl" "$rt" "$MCON" "$lf" "$nl" "$sma" "$grp" "$hm $lt" "${nit:-?}"
    exit 0
  fi
done
printf '%-28s UNSOLVED\n' "$cell"
exit 1
