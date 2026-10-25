#!/usr/bin/env bash
# Autonomous driver for the 8h idle window:
#   1. wait for Stage 1 baseline to finish
#   2. sanity gate the open set (abort if it looks systemically broken)
#   3. run Stage 2 max effort convergence to completion
#   4. write the final report
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="$ROOT/.work/ceiling"
LOG="$OUT/orchestrator.log"; : > "$LOG"
say(){ echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# 1. wait for Stage 1 (poll up to ~45 min)
say "waiting for Stage 1 baseline to finish..."
for i in $(seq 1 180); do
  grep -q '# DONE' "$OUT/baseline.progress" 2>/dev/null && break
  sleep 15
done
grep -q '# DONE' "$OUT/baseline.progress" 2>/dev/null || { say "Stage 1 did not finish in time; ABORT"; exit 1; }

CLEAN=$(awk -F'\t' 'NR>1 && $2=="CLEAN"{n++} END{print n+0}' "$OUT/baseline.tsv")
OPEN=$(awk -F'\t' 'NR>1 && $2!="CLEAN"{n++} END{print n+0}' "$OUT/baseline.tsv")
TOTREC=$(( $(wc -l < "$OUT/baseline.tsv") - 1 ))
say "Stage 1 done: recorded=$TOTREC  CLEAN=$CLEAN  OPEN=$OPEN"

# 2. sanity gate
if [ "$OPEN" -lt 40 ] || [ "$OPEN" -gt 320 ]; then
  say "open set=$OPEN outside sane range [40,320]; NOT launching Stage 2. Review needed."
  exit 2
fi

# 3. Stage 2 (blocks until done; internal 7.0h deadline guard)
say "launching Stage 2 max-effort convergence (10-way, 10h deadline, mem-capped)..."
bash "$ROOT/src/cellgen/ceiling.sh" 10 10 >> "$LOG" 2>&1

# 4. final report
CLOSED=$(awk -F'\t' 'NR>1 && $2=="CLOSED"{n++} END{print n+0}' "$OUT/ceiling.tsv")
STILL=$(awk -F'\t' 'NR>1 && $2!="CLOSED"{n++} END{print n+0}' "$OUT/ceiling.tsv")
FINAL=$(( CLEAN + CLOSED ))
say "===================== FINAL ====================="
say "committed-clean (Stage 1)      : $CLEAN / 437"
say "newly converged (Stage 2)      : $CLOSED (of $OPEN open)"
say "TOTAL converged, current tools : $FINAL / 437"
say "still unconverged              : $STILL"
say "area distribution of newly-converged (height_mult):"
awk -F'\t' 'NR>1 && $2=="CLOSED"{h[$6]++} END{for(k in h) printf "   h=%s : %d cells\n", k, h[k]}' "$OUT/ceiling.tsv" | tee -a "$LOG"
say "================================================="
