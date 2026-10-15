#!/usr/bin/env bash
# The Bounce Run boon check (tools/boon_balance.gd), one boon per process,
# as many at once as there are cores. Every fight is seeded, so the table is
# the same as one process checking every boon. Fails if any boon fails.
# Usage: GODOT=<godot binary> tools/ci/boons.sh [boon_balance.gd args...]
set -uo pipefail
GODOT="${GODOT:-godot}"
out=$(mktemp -d)
ids=$(sed -n '/^const ALL := \[/,/\]/p' sim/boons.gd | grep -oE '"[a-z0-9_]+"' | tr -d '"')
[ -n "$ids" ] || { echo "::error::No boon ids found in sim/boons.gd"; exit 1; }
export GODOT out
printf '%s\n' $ids | xargs -P "$(nproc)" -I{} bash -c \
  '"$GODOT" --headless --script res://tools/boon_balance.gd -- --only={} "$@" > "$out/{}.md" 2>&1; echo $? > "$out/{}.status"' _ "$@"
status=0
first=$(echo "$ids" | head -1)
grep -E '^(###|$|\| Boon|\|---)' "$out/$first.md" | head -5
for id in $ids; do
  grep -E '^\| ' "$out/$id.md" | grep -vE '^\| (Boon|---)' || true
  if [ "$(cat "$out/$id.status" 2>/dev/null)" != "0" ]; then
    status=1
    echo "::error::Boon check failed for $id:"
    grep -vE '^(Godot Engine|\| )' "$out/$id.md" | tail -20
  fi
done
exit "$status"
