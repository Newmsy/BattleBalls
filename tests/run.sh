#!/usr/bin/env bash
# Runs the GDScript test suite and fails on any failed check, script error or
# hang. GDScript has no exceptions, so a runtime error inside a test only shows
# up in the log; this wrapper turns it into a failure.
set -uo pipefail
GODOT="${GODOT:-godot}"
log="$(mktemp)"
timeout 300 "$GODOT" --headless --quit-after 10 --script res://tests/run_tests.gd 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if grep -q "SCRIPT ERROR" "$log"; then
  echo "::error::Script errors while running tests (see log above)"
  exit 1
fi
if ! grep -q "^All [0-9]* tests passed" "$log"; then
  echo "::error::Test run did not complete"
  exit 1
fi
exit "$status"
