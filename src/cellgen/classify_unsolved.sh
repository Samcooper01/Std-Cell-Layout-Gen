#!/usr/bin/env bash
# Classify WHY each unsolved cell fails, by running the two most informative
# recipes (default, and meta+lift) and bucketing the failure mode. Helps target
# the next round of fixes. Reads .work/solve/unsolved.txt.
#
# Buckets:
#   TIMEOUT        placement/routing did not finish in the timeout
#   SMT UNSAT      routed but DRC legalization infeasible (density)
#   LVS SHORT      built a GDS less layout, LVS mismatch (short/open)
#   NO TERMINAL    a net had no routing terminal
#   OTHER          anything else
# Usage: harness/classify_unsolved.sh [timeout_s]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
TO="${1:-70}"
UNS="$ROOT/.work/solve/unsolved.txt"
OUT="$ROOT/.work/solve/unsolved_classified.txt"; : > "$OUT"
[ -s "$UNS" ] || { echo "no unsolved cells"; exit 0; }

classify_one() {
  local c="$1" pl="$2" lf="$3" w="$ROOT/.work/cls/$c-$pl-$lf"
  mkdir -p "$w/out"; rm -f "$w/out/"* 2>/dev/null
  env RUN_WORK="$w" PLACER="$pl" RECIPE_LIFT_DRAINS="$lf" timeout "$TO" "$ROOT/src/cellgen/run_cell.sh" "$c" >"$w/log" 2>&1
  local rc=$?
  if [ "$rc" -eq 124 ]; then echo TIMEOUT
  elif grep -qi 'SMT result: UNSAT' "$w/log"; then echo SMT-UNSAT
  elif grep -qi 'has no routing terminal' "$w/log"; then echo NO-TERMINAL
  elif grep -qi "Netlists don't match\|LVS result: FAILED" "$w/log"; then echo LVS-SHORT
  else echo OTHER; fi
}

while read -r c; do
  [ -z "$c" ] && continue
  d=$(classify_one "$c" hierarchical 0)
  m=$(classify_one "$c" meta 1)
  printf '%-28s default=%-11s meta+lift=%-11s\n' "$c" "$d" "$m" | tee -a "$OUT"
done < "$UNS"
echo "# summary (meta+lift bucket):"
awk '{for(i=1;i<=NF;i++) if($i ~ /^meta\+lift=/){split($i,a,"=");print a[2]}}' "$OUT" | sort | uniq -c | sort -rn | tee -a "$OUT"
