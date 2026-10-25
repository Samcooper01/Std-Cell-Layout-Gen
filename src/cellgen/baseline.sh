#!/usr/bin/env bash
# Stage 1, authoritative baseline: build every cell at its COMMITTED recipe,
# record pass/fail + area (width x height, height_mult). Establishes the exact
# open set and the current library's area, before any max area assault.
# Usage: baseline.sh [timeout_s] [parallelism]
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/eda-env/bin:$PATH"
TO="${1:-150}"; PAR="${2:-30}"
OUT="$ROOT/.work/ceiling"; mkdir -p "$OUT/base"
TSV="$OUT/baseline.tsv"; PROG="$OUT/baseline.progress"
: > "$TSV"; : > "$PROG"
printf 'cell\tstatus\twidth_um\theight_um\theight_mult\titers\n' >> "$TSV"

cells=$(grep -E '^\.SUBCKT ' "$ROOT/cells/sky130_hd_all_cells.sp" | sed -E 's/^\.SUBCKT sky130_fd_sc_hd__//; s/ .*//')
TOTAL=$(echo "$cells" | grep -c .)
echo "# baseline: $TOTAL cells @ committed recipe, ${TO}s, ${PAR}-way" | tee "$PROG"

worker() {
  c="$1"; full="sky130_fd_sc_hd__$c"
  w="$ROOT/.work/ceiling/base/$c"; mkdir -p "$w/out"; rm -f "$w/out/"* 2>/dev/null
  env RUN_WORK="$w" timeout "$TO" "$ROOT/src/cellgen/run_cell.sh" "$c" >"$w/log" 2>&1
  rc=$?
  gds="$w/out/$full.gds"; lef="$w/out/$full.lef"
  size=$(grep -iE '^\s*SIZE ' "$lef" 2>/dev/null | head -1)
  wd=$(echo "$size" | awk '{print $2}'); ht=$(echo "$size" | awk '{print $4}')
  hm=$(grep -oE 'height=[0-9]+' "$w/log" 2>/dev/null | head -1 | grep -oE '[0-9]+')
  it=$(grep -oE 'Routing iteration [0-9]+' "$w/log" 2>/dev/null | tail -1 | grep -oE '[0-9]+')
  if [ -f "$gds" ] && grep -qi 'LVS result: SUCCESS' "$w/log"; then st=CLEAN
  elif [ -f "$gds" ] && grep -qi 'LVS result' "$w/log"; then st=LVSFAIL
  elif [ "$rc" = 124 ]; then st=TIMEOUT
  else st=NOGDS; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$c" "$st" "${wd:-NA}" "${ht:-NA}" "${hm:-1}" "${it:-NA}" >> "$ROOT/.work/ceiling/baseline.tsv"
  n=$(( $(wc -l < "$ROOT/.work/ceiling/baseline.tsv") - 1 ))
  printf '[%s %d/%d] %-28s %s  %sx%s\n' "$(date '+%H:%M:%S')" "$n" "$TOTAL" "$c" "$st" "${wd:-NA}" "${ht:-NA}" >> "$ROOT/.work/ceiling/baseline.progress"
}
export -f worker; export ROOT TO TOTAL
echo "$cells" | grep . | xargs -P "$PAR" -I{} bash -c 'worker "$@"' _ {}
echo "# DONE $(date '+%H:%M:%S')" >> "$PROG"
# summary
awk -F'\t' 'NR>1{c[$2]++} END{for(k in c) printf "%-9s %d\n", k, c[k]}' "$TSV" | sort -rnk2 | tee -a "$PROG"
