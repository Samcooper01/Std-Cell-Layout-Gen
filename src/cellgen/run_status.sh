#!/usr/bin/env bash
# Populate the status/ folder: run every cell through the current flow (its committed
# recipe), record whether it closes and how long it takes, and save per cell a verbose
# run log, a layout render, and the output files. Then regenerate status/STATUS.md.
#
#   PAR=6 TIMEOUT=900 src/cellgen/run_status.sh            # all 437 cells
#   src/cellgen/run_status.sh inv_1 nand2_1               # just these cells
#
# Env: PAR = parallel workers (default 6), TIMEOUT = per cell seconds cap (default 900).
# Each worker is capped at 12G virtual memory. Results land in status/results.tsv
# (cell<TAB>closed|open<TAB>seconds); logs in status/logs/, renders in status/renders/,
# GDS+LEF in status/outputs/<cell>/.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
export ROOT
MAP="$ROOT/recipes/cell_categories.tsv"
SDIR="$ROOT/status"
export LOGD="$SDIR/logs" OUTD="$SDIR/outputs" RND="$SDIR/renders" WORK="$ROOT/.work/status"
RES="$SDIR/results.tsv"; export RESPART="$RES.part"
export TIMEOUT="${TIMEOUT:-300}"
PAR="${PAR:-6}"
mkdir -p "$LOGD" "$OUTD" "$RND" "$WORK"
# Resume by default: keep prior results, and on a full (no-arg) run skip cells already
# recorded as closed, rerunning only the not-yet-closed ones. FRESH=1 wipes and redoes all.
[ "${FRESH:-0}" = 1 ] && : > "$RESPART"
touch "$RESPART"

worker(){
  cell="$1"
  full="sky130_fd_sc_hd__$cell"
  w="$WORK/$cell"; rm -rf "$w"; mkdir -p "$w"
  ( ulimit -v 12582912 2>/dev/null
    start=$(cut -d' ' -f1 /proc/uptime)
    env RUN_WORK="$w" timeout "$TIMEOUT" "$ROOT/src/cellgen/run_cell.sh" "$cell" > "$w/build.log" 2>&1 || true
    end=$(cut -d' ' -f1 /proc/uptime)
    awk -v a="$start" -v b="$end" 'BEGIN{printf "%.0f\n", b-a}' > "$w/secs"
  )
  secs=$(cat "$w/secs" 2>/dev/null || echo "")
  cp "$w/build.log" "$LOGD/$cell.log" 2>/dev/null || true
  gds="$w/out/$full.gds"
  if [ -f "$gds" ] && grep -qi 'LVS result: SUCCESS' "$w/build.log"; then
    st=closed
    mkdir -p "$OUTD/$cell"
    cp "$gds" "$OUTD/$cell/" 2>/dev/null || true
    cp "$w/out/$full.lef" "$OUTD/$cell/" 2>/dev/null || true
    "$ROOT/src/cellgen/render.py" "$cell" --work "$w" --out "$RND/$cell.png" >/dev/null 2>&1 || true
  else
    st=open
  fi
  printf '%s\t%s\t%s\n' "$cell" "$st" "$secs" >> "$RESPART"
  echo "[$st ${secs}s] $cell"
}
export -f worker

if [ "$#" -gt 0 ]; then
  # explicit cells: always run exactly those (a targeted retry)
  todo=$(printf '%s\n' "$@" | sort -u)
else
  # full run: skip cells already closed, (re)run everything else (opens + not-yet-run)
  closed="$WORK/.closed"; grep -P '\tclosed\t' "$RESPART" 2>/dev/null | cut -f1 | sort -u > "$closed"
  todo=$(comm -23 <(cut -f1 "$MAP" | sort -u) "$closed")
  echo "resume: $(wc -l < "$closed") already closed (kept), $(printf '%s\n' "$todo" | grep -c .) to run"
fi
echo "PAR=$PAR TIMEOUT=${TIMEOUT}s"
printf '%s\n' "$todo" | grep . | xargs -P "$PAR" -I{} bash -c 'worker "$@"' _ {}

# last write per cell wins (a rerun appends after the old line), then sort for the table
awk -F'\t' 'NF{last[$1]=$0} END{for(c in last) print last[c]}' "$RESPART" | sort > "$RES"
bash "$ROOT/src/cellgen/gen_status.sh"
echo "done: $(awk -F'\t' '$2=="closed"{n++}END{print n+0}' "$RES") closed, $(awk -F'\t' '$2=="open"{n++}END{print n+0}' "$RES") open."
