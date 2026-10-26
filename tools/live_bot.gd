## A pretend player for the live server: signs in, queues, aims, replays the
## fight locally and checks its end hash matches the server's. CI runs two of
## them against a server to prove a whole live match works end to end.
##
##   godot --headless --script res://tools/live_bot.gd -- --url=ws://127.0.0.1:8080 --name=a [--critter=vampire] [--tier=3] [--room=F:AAAA:BBBB]
##
## Prints LIVE_BOT_OK <winner> <hash> or LIVE_BOT_FAIL <why>, exit code 0/1.
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const SimVersion := preload("res://sim/sim_version.gd")
const Lineup := preload("res://sim/lineup.gd")
const LiveMatch := preload("res://sim/live_match.gd")

var ws := WebSocketPeer.new()
var opts := {"url": "ws://127.0.0.1:8080", "name": "bot", "critter": "vampire",
	"tier": "3", "timeout": "40", "room": ""}
var started := 0.0
var said_hello := false
var matched := {}
var done := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1]
	started = Time.get_ticks_msec() / 1000.0
	ws.connect_to_url(opts.url)


func _process(_delta: float) -> bool:
	ws.poll()
	if Time.get_ticks_msec() / 1000.0 - started > float(opts.timeout):
		_end(false, "timed out")
	match ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not said_hello:
				said_hello = true
				_send({"t": "hello", "token": opts.name, "sim_version": SimVersion.get_version()})
			while ws.get_available_packet_count() > 0:
				_on(JSON.parse_string(ws.get_packet().get_string_from_utf8()))
		WebSocketPeer.STATE_CLOSED:
			_end(false, "socket closed (%d %s)" % [ws.get_close_code(), ws.get_close_reason()])
	return false


func _on(msg) -> void:
	if not msg is Dictionary:
		_end(false, "bad message")
		return
	match str(msg.t):
		"welcome":
			_send({"t": "queue", "mode": "1v1", "slots": [Lineup.make(opts.critter, int(opts.tier))], "room": opts.room})
		"matched":
			print("LIVE_BOT %s matched as side %d" % [opts.name, int(msg.side)])
			matched = msg
			_send({"t": "aim", "match": msg.match, "angle": -450 if int(msg.side) == 0 else 1350})
		"go":
			# Replay the fight here, as a phone would, and compare with the server.
			var s := MatchSim.new(LiveMatch.config(int(matched.seed), matched.sides, msg.angles)).run_to_end()
			_send({"t": "hash", "match": msg.match, "hash": s.hash})
			if s.hash != str(msg.hash):
				_end(false, "my fight differs from the server's")
			else:
				_end(true, "winner %d %s" % [int(msg.winner), str(msg.hash).substr(0, 12)])
		"ghost":
			_end(false, "no opponent found, offered a ghost")
		"error":
			_end(false, "server error " + str(msg.get("code", "")))


func _send(msg: Dictionary) -> void:
	ws.send_text(JSON.stringify(msg, "", true, true))


func _end(ok: bool, text: String) -> void:
	if done:
		return
	done = true
	print(("LIVE_BOT_OK " if ok else "LIVE_BOT_FAIL ") + opts.name + " " + text)
	ws.close()
	quit(0 if ok else 1)
