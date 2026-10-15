#!/usr/bin/env bash
# Decides what the PR balance check fights, and on how many machines.
# Usage: tools/ci/balance_plan.sh <base-sha>   (prints GitHub step outputs)
#   only=<ids>     --only value for tools/balance.gd ("" means every pairing)
#   shards=[1,..]  matrix for the Balance job ([] when nothing needs checking)
#
# - Small roster (SMALL or fewer live critters): every pairing, as before.
# - Otherwise only pairings involving the critters whose sim/critters/<id>.gd
#   changed, each against the whole field. A change to the engine (anything
#   else under sim/, or tools/balance.gd) adds "@sample", a fixed spread of
#   live critters, so engine changes are checked across the roster.
# - No change under sim/ or tools/balance.gd: nothing to check.
# The weekly Balance audit workflow fights every pairing.
set -euo pipefail
base="$1"
SMALL=12
PAIRS_PER_SHARD=40 # 650 fights a pairing (100 seeds on the square, 25 on each of 9 arenas/modifiers): ~9 min a shard.
MAX_SHARDS=14 # With the 4 smoke shards, Sim and Database tests: GitHub's 20 jobs at once.

changed=$(git diff --name-only "$base"...HEAD)
live=$(grep -l '"status": "live"' sim/critters/*.gd | xargs -n1 basename | sed 's/\.gd$//' | sort)
n_live=$(echo "$live" | grep -c . || true)

critters=$(echo "$changed" | grep -E '^sim/critters/[a-z0-9_]+\.gd$' | grep -v '/_template\.gd$' | xargs -r -n1 basename | sed 's/\.gd$//' | sort -u | comm -12 - <(echo "$live") || true)
engine=$(echo "$changed" | grep -E '^(sim/|tools/balance\.gd$)' | grep -vE '^sim/critters/' || true)
touched=$(echo "$changed" | grep -E '^(sim/|tools/balance\.gd$)' || true)

if [ -z "$touched" ]; then
  echo "only="
  echo "shards=[]"
  echo "No sim or balance-tool changes: skipping the balance check." >&2
  exit 0
fi

if [ "$n_live" -le "$SMALL" ]; then
  only=""
  pairs=$(( (n_live + 1) * (n_live + 2) / 2 )) # Plain included.
else
  list=$(echo "$critters" | grep . | paste -sd, - || true)
  if [ -n "$engine" ]; then
    list="${list:+$list,}@sample"
  fi
  only="$list"
  k=$(echo "$list" | tr ',' '\n' | grep -c . || true)
  [ "$k" -gt 0 ] && echo "$list" | grep -q '@sample' && k=$(( k + 7 )) # @sample is 8 critters.
  pairs=$(( k * (n_live + 1) ))
fi
if [ -z "$only" ] && [ "$n_live" -gt "$SMALL" ]; then
  echo "only="
  echo "shards=[]"
  echo "Only non-live critter files changed: skipping the balance check." >&2
  exit 0
fi
shards=$(( (pairs + PAIRS_PER_SHARD - 1) / PAIRS_PER_SHARD ))
[ "$shards" -lt 1 ] && shards=1
[ "$shards" -gt "$MAX_SHARDS" ] && shards=$MAX_SHARDS
echo "only=$only"
echo "shards=[$(seq -s, 1 "$shards")]"
echo "$n_live live critters, ~$pairs pairings, $shards shard(s), only='${only:-every pairing}'." >&2
