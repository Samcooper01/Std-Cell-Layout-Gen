#!/usr/bin/env bash
# Monitor for the router bug fix loop. Regenerates the golden + target cells and
# reports pass counts. Usage: harness/track.sh [tag]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; export PATH="$HOME/eda-env/bin:$PATH"
GOLDEN="inv_1 buf_1 clkinv_1 nand2_1 nand3_1 nand4_1 nor2_1 and2_1 and3_1 or2_1 nand2b_1 nor2b_1 xor2_1 mux2_1 a21oi_1 a21o_1 a22oi_1"
TARGET="nor3_1 nor4_1 or3_1 xnor2_1 o21ai_1 o22ai_1 a211oi_1"
gp=0; gf=""; tp=0; tpass=""
for c in $GOLDEN; do
  timeout 60 env RUN_WORK="$ROOT/.work/track" "$ROOT/src/cellgen/run_cell.sh" "$c" >/dev/null 2>&1
  [ -f "$ROOT/.work/track/out/sky130_fd_sc_hd__$c.gds" ] && gp=$((gp+1)) || gf="$gf $c"
  rm -f "$ROOT/.work/track/out/"* 2>/dev/null
done
for c in $TARGET; do
  timeout 60 env RUN_WORK="$ROOT/.work/track" "$ROOT/src/cellgen/run_cell.sh" "$c" >/dev/null 2>&1
  if [ -f "$ROOT/.work/track/out/sky130_fd_sc_hd__$c.gds" ]; then tp=$((tp+1)); tpass="$tpass $c"; fi
  rm -f "$ROOT/.work/track/out/"* 2>/dev/null
done
echo "golden $gp/17 | target $tp/7 |${tpass:- none} | regressions:${gf:- none}"
[ -n "${1:-}" ] && printf '%s\tgolden=%d/17\ttarget=%d/7\ttpass=%s\n' "$1" "$gp" "$tp" "${tpass:-none}" >> "$ROOT/.work/attempts.log"
