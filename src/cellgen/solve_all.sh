#!/usr/bin/env bash
# Parallel per cell recipe solver. Runs harness/solve_cell.sh over a set of
# cells concurrently (one cell per core slot; each cell tries its recipe matrix
# sequentially and stops at the first LVS clean recipe). Collects winning recipe
# lines. Safe to run in the background; writes live.
#
# Usage: harness/solve_all.sh [cells] [timeout_s] [parallelism]
#   cells: 'all'  -> every cell in sky130_hd_all_cells.sp   (default)
#          'fail' -> non-PASS:clean cells from .work/results.txt
#          <file> -> one cell per line
#   timeout_s   : per recipe attempt timeout (default 50)
#   parallelism : concurrent cells (default 14)
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
SEL="${1:-all}"; TO="${2:-50}"; PAR="${3:-14}"
OUT="$ROOT/.work/solve"; mkdir -p "$OUT"
SOLVED="$OUT/solved_recipes.txt"; UNSOLVED="$OUT/unsolved.txt"; DONELOG="$OUT/done.txt"
: > "$SOLVED"; : > "$UNSOLVED"; : > "$DONELOG"

case "$SEL" in
  all)  cells=$(grep -E '^\.SUBCKT ' "$ROOT/cells/sky130_hd_all_cells.sp" | sed -E 's/^\.SUBCKT sky130_fd_sc_hd__//; s/ .*//');;
  fail) cells=$(awk '$2!="PASS:clean" && $1!~/^#/ {print $1}' "$ROOT/.work/results.txt");;
  *)    cells=$(grep -vE '^\s*#|^\s*$' "$SEL");;
esac
total=$(echo "$cells" | grep -c .)
echo "# solve_all: $total cells, ${TO}s/attempt, ${PAR}-way parallel, sel=$SEL  $(date '+%H:%M:%S')" | tee "$OUT/progress.txt"

worker() {
  c="$1"
  line=$("$ROOT/src/cellgen/solve_cell.sh" "$c" "$TO" 2>/dev/null)
  # NB: match '# SOLVED' (not 'SOLVED') -- 'UNSOLVED' contains the substring 'SOLVED'.
  if echo "$line" | grep -q '# SOLVED'; then echo "$line" >> "$SOLVED"; tag=SOLVED; else echo "$c" >> "$UNSOLVED"; tag=UNSOLVED; fi
  echo "$c" >> "$DONELOG"
  d=$(wc -l < "$DONELOG"); s=$(wc -l < "$SOLVED")
  printf '[%s %d/%d solved=%d] %s\n' "$(date '+%H:%M:%S')" "$d" "$TOTAL" "$s" "$line" >> "$OUT/progress.txt"
}
export -f worker
export ROOT TO SOLVED UNSOLVED DONELOG OUT
export TOTAL="$total"

echo "$cells" | grep . | xargs -P "$PAR" -I{} bash -c 'worker "$@"' _ {}
echo "# DONE: $(wc -l < "$SOLVED")/$total solved  $(date '+%H:%M:%S')" | tee -a "$OUT/progress.txt"
