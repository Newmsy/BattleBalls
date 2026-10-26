#!/usr/bin/env bash
# Plays a live match and a friend-room one end to end: the live server (dev
# sign-in) and two pretend players (tools/live_bot.gd), each replaying the
# fight and checking it matches the server's.
# Usage: GODOT=~/godot/godot tools/ci/live_e2e.sh
set -uo pipefail
GODOT="${GODOT:-godot}"
port=18080
LIVE_DEV=1 PORT=$port timeout 120 "$GODOT" --headless --script res://server/live_server.gd &
server=$!
trap 'kill $server 2>/dev/null' EXIT
for i in $(seq 1 40); do
  (exec 3<>/dev/tcp/127.0.0.1/$port) 2>/dev/null && break
  sleep 0.5
done
status=0
timeout 60 "$GODOT" --headless --script res://tools/live_bot.gd -- --url=ws://127.0.0.1:$port --name=a --critter=bomber &
a=$!
timeout 60 "$GODOT" --headless --script res://tools/live_bot.gd -- --url=ws://127.0.0.1:$port --name=b --critter=laser || status=1
wait $a || status=1
# Two friends in a room meet whatever their power (T1 vs T5 never pairs in the open queue).
timeout 60 "$GODOT" --headless --script res://tools/live_bot.gd -- --url=ws://127.0.0.1:$port --name=a-room --critter=bomber --tier=1 --room=C:E2E1 &
a=$!
timeout 60 "$GODOT" --headless --script res://tools/live_bot.gd -- --url=ws://127.0.0.1:$port --name=b-room --critter=laser --tier=5 --room=C:E2E1 || status=1
wait $a || status=1
if [ $status -ne 0 ]; then echo "::error::A live match didn't play out end to end (see LIVE_BOT lines above)"; fi
exit $status
