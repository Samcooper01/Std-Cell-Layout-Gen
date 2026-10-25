#!/usr/bin/env bash
# Run a list of cells through run_cell.sh and tabulate pass/fail + failure stage.
#
# Usage:  harness/run_ladder.sh [cell ...]
#   no args -> a default simplest first ladder.
#   harness/run_ladder.sh inv_1 nand2_1 dfxtp_1
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cells=("$@")
if [ ${#cells[@]} -eq 0 ]; then
  cells=(inv_1 clkinv_1 buf_1 nand2_1 nor2_1 and2_1 or2_1 o21ai_1 a21oi_1 nand3_1 mux2_1 xor2_1 dfxtp_1)
fi

printf "%-14s %-9s %s\n" CELL RESULT "STAGE / FAILURE"
printf '%.0s-' {1..66}; echo
pass=0; total=0
for c in "${cells[@]}"; do
  total=$((total+1))
  out=$(timeout 150 "$ROOT/src/cellgen/run_cell.sh" "$c" 2>&1); rc=$?
  full="sky130_fd_sc_hd__$c"
  lvs=$(echo "$out" | grep -oE "LVS result: [A-Z]+" | tail -1 | awk '{print $3}')
  if [ -f "$ROOT/.work/out/$full.gds" ] && [ "$lvs" = SUCCESS ]; then
    r=PASS; s="DRC+LVS clean, GDS written"; pass=$((pass+1))
  elif [ $rc -eq 124 ]; then r=TIMEOUT; s="killed @150s"
  elif echo "$out" | grep -q "no routing terminal\|Nets without terminals"; then r=FAIL; s="ROUTING: no routing terminal"
  elif [ "$lvs" = FAILED ]; then r=FAIL; s="LVS mismatch"
  else r=FAIL; s=$(echo "$out" | grep -iE "error|assert|exception" | grep -ivE "INFO|Fixed shapes" | head -1 | cut -c1-42); fi
  printf "%-14s %-9s %s\n" "$c" "$r" "$s"
  rm -f "$ROOT/.work/out/$full.gds"
done
echo "----"
echo "PASS: $pass / $total"
