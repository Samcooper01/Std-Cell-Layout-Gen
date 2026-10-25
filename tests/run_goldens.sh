#!/usr/bin/env bash
# Regression: build every golden cell and assert it is DRC/LVS-clean.
# Exit non zero if any golden fails, this is the gate CI runs on every push.
#   tests/run_goldens.sh
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pass=0; fail=0; failed=""
echo "== golden regression =="
while IFS= read -r c; do
  c="${c%%#*}"; c="$(echo "$c" | tr -d '[:space:]')"; [ -z "$c" ] && continue
  if "$ROOT/tests/build_cell.sh" "$c" >/dev/null 2>&1; then
    pass=$((pass+1)); echo "  ✓ $c"
  else
    fail=$((fail+1)); failed="$failed $c"; echo "  ✗ $c"
  fi
done < "$ROOT/tests/goldens.txt"
echo "-----------------------"
echo "result: $pass passed, $fail failed${failed:+  (failed:$failed)}"
[ "$fail" = 0 ]
