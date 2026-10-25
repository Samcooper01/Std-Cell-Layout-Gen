#!/usr/bin/env bash
# Build ONE cell end to end and verify it is DRC/LVS-clean. Optionally render it.
#
#   tests/build_cell.sh <cell>            # build + verify
#   tests/build_cell.sh <cell> --render   # build + verify + write a PNG of the layout
#
# Exit 0 = clean, non zero = failed. Output lands in .work/test/<cell>/.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"

cell="${1:?usage: build_cell.sh <cell> [--render]}"
full="sky130_fd_sc_hd__$cell"
work="$ROOT/.work/test/$cell"; mkdir -p "$work"

echo "▶ building $cell ..."
env RUN_WORK="$work" "$ROOT/src/cellgen/run_cell.sh" "$cell" > "$work/build.log" 2>&1 || true

gds="$work/out/$full.gds"
if [ -f "$gds" ] && grep -qi 'LVS result: SUCCESS' "$work/build.log"; then
  size=$(grep -iE '^\s*SIZE ' "$work/out/$full.lef" | head -1 | awk '{printf "%.2f x %.2f um", $2, $4}')
  echo "✓ PASS  $cell  ·  DRC + LVS clean,  $size"
  echo "        GDS: $gds"
  if [ "${2:-}" = "--render" ]; then
    png="$ROOT/results/renders/$cell.png"
    "$ROOT/src/cellgen/render.py" "$cell" --work "$work" --out "$png" >/dev/null
    echo "        PNG: $png"
  fi
else
  echo "✗ FAIL  $cell  ·  not clean.  See $work/build.log"
  tail -6 "$work/build.log" | sed 's/^/          /'
  exit 1
fi
