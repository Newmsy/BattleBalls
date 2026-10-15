#!/usr/bin/env bash
# Says which of the slow PR checks this PR's diff can affect.
# Usage: tools/ci/changes.sh <base-sha>   (prints GitHub step outputs)
#   sim=true|false  anything under sim/ or the boon tool changed (Bounce Run boons)
#   web=true|false  anything the web build or the smoke test reads changed
# Docs, notes and the headless balance tools can't change what the browser
# smoke test sees; everything else counts, workflow files included.
set -euo pipefail
changed=$(git diff --name-only "$1"...HEAD)
if echo "$changed" | grep -qE '^(sim/|tools/boon_balance\.gd$)'; then echo "sim=true"; else echo "sim=false"; fi
if echo "$changed" | grep -vE '(\.md$|^balance/|^\.claude/|^tests/|^tools/(balance|boon_balance)\.gd$|^tools/ci/balance_plan\.sh$)' | grep -q .; then
  echo "web=true"
else
  echo "web=false"
fi
