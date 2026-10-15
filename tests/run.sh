#!/usr/bin/env bash
# Runs the GDScript test suite and fails on any failed check, script error or
# hang. GDScript has no exceptions, so a runtime error inside a test only shows
# up in the log; this wrapper turns it into a failure.
# The tests are split over one process per CPU core (TEST_WORKERS overrides).
set -uo pipefail
GODOT="${GODOT:-godot}"
n="${TEST_WORKERS:-$(nproc 2>/dev/null || echo 1)}"
dir="$(mktemp -d)"
for k in $(seq 1 "$n"); do
  timeout 1200 "$GODOT" --headless --quit-after 10 --script res://tests/run_tests.gd -- --shard="$k/$n" > "$dir/$k.log" 2>&1 &
  echo $! > "$dir/$k.pid"
done
status=0
for k in $(seq 1 "$n"); do
  wait "$(cat "$dir/$k.pid")" || status=1
  echo "--- tests shard $k of $n"
  cat "$dir/$k.log"
  if grep -q "SCRIPT ERROR" "$dir/$k.log"; then
    echo "::error::Script errors while running tests (shard $k of $n, see log above)"
    status=1
  fi
  if ! grep -q "^All [0-9]* tests passed" "$dir/$k.log"; then
    echo "::error::Test run did not complete (shard $k of $n)"
    status=1
  fi
done
exit "$status"
