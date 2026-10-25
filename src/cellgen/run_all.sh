#!/usr/bin/env bash
# Run EVERY sky130_fd_sc_hd cell through lclayout and categorize the outcome.
# Writes one line per cell to .work/results.txt as it goes (so progress is visible
# live), then a DONE marker. Uses an isolated work dir so it can run in the
# background without colliding with foreground per cell debugging.
#
# Outcome categories:
#   PASS:clean          GDS written + internal LVS SUCCESS
#   PASS:drc-only       GDS written but LVS not confirmed (rare)
#   FAIL:lvs            layout built, LVS mismatch (functional bug in generated cell)
#   FAIL:routing        "no routing terminal" / nets without terminals / unroutable
#   FAIL:placement      placement/Euler/SMT failure
#   FAIL:assert         internal tool assertion (router/conflict)
#   FAIL:timeout        exceeded per cell timeout
#   FAIL:other          anything else (see .work/all/log/<cell>.log)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export RUN_WORK="$ROOT/.work/all"
LOGD="$RUN_WORK/log"; mkdir -p "$LOGD"
out="$ROOT/.work/results.txt"; : > "$out"
TO="${PER_CELL_TIMEOUT:-180}"

cells=$(grep -E '^\.SUBCKT ' "$ROOT/cells/sky130_hd_all_cells.sp" \
        | sed -E 's/^\.SUBCKT sky130_fd_sc_hd__//; s/ .*//')
total=$(echo "$cells" | wc -l); i=0
for c in $cells; do
  i=$((i+1))
  log="$LOGD/$c.log"
  timeout "$TO" "$ROOT/src/cellgen/run_cell.sh" "$c" >"$log" 2>&1; rc=$?
  full="sky130_fd_sc_hd__$c"
  lvs=$(grep -oE 'LVS .*(SUCCESS|FAILED|match|mismatch)' "$log" | tail -1)
  if [ -f "$RUN_WORK/out/$full.gds" ]; then
    if echo "$lvs" | grep -qiE 'SUCCESS|match'; then r="PASS:clean"; else r="PASS:drc-only"; fi
  elif [ "$rc" -eq 124 ]; then r="FAIL:timeout"
  elif grep -qiE 'no routing terminal|without terminal|could not be routed|unroutable|No path found' "$log"; then r="FAIL:routing"
  elif echo "$lvs" | grep -qiE 'FAILED|mismatch'; then r="FAIL:lvs"
  elif grep -qiE 'placement|euler|cannot place|SMT' "$log"; then r="FAIL:placement"
  elif grep -qiE 'AssertionError|assert ' "$log"; then r="FAIL:assert"
  else r="FAIL:other"; fi
  printf '%-28s %s\n' "$c" "$r" >> "$out"
  rm -f "$RUN_WORK/out/$full".* 2>/dev/null
done
echo "# DONE ($total cells)" >> "$out"
