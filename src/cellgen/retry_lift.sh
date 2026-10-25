#!/usr/bin/env bash
# For every FAIL:lvs cell in .work/results.txt, retry it with the net aware
# drain lift knob forced ON (RECIPE_LIFT_DRAINS=1). Report which cells recover
# (GDS written) vs still fail vs time out. Recovered cells are the ones to add
# to harness/recipes with lift=1.
#
# Usage: harness/retry_lift.sh [results_file] [per_cell_timeout]
#   writes .work/lift_recovered.txt (one recovered cell per line)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
RES="${1:-$ROOT/.work/results.txt}"
TO="${2:-60}"
WORK="$ROOT/.work/lift"; mkdir -p "$WORK/out"
REC="$ROOT/.work/lift_recovered.txt"; : > "$REC"
LOG="$ROOT/.work/lift_retry.log"; : > "$LOG"

cells=$(awk '$2=="FAIL:lvs"{print $1}' "$RES")
n=$(echo "$cells" | grep -c . 2>/dev/null || echo 0)
echo "# retry_lift: $n FAIL:lvs cells, timeout ${TO}s each" | tee -a "$LOG"
i=0
for c in $cells; do
  i=$((i+1))
  rm -f "$WORK/out/"* 2>/dev/null
  RECIPE_LIFT_DRAINS=1 RUN_WORK="$WORK" timeout "$TO" "$ROOT/src/cellgen/run_cell.sh" "$c" >"$WORK/last.log" 2>&1; rc=$?
  full="sky130_fd_sc_hd__$c"
  if [ -f "$WORK/out/$full.gds" ]; then
    lvs=$(grep -oiE 'LVS result: (SUCCESS|FAILED)' "$WORK/last.log" | tail -1)
    if echo "$lvs" | grep -qi SUCCESS; then r="RECOVERED"; echo "$c" >> "$REC"; else r="gds-no-lvs"; fi
  elif [ "$rc" -eq 124 ]; then r="TIMEOUT"
  else r="still-FAIL"; fi
  printf '%-28s %s\n' "$c" "$r" | tee -a "$LOG"
done
echo "# DONE: $(wc -l < "$REC") recovered -> $REC" | tee -a "$LOG"
