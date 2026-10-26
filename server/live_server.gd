## The always-on live-fight server: headless Godot running this repo's sim/,
## speaking JSON over WebSockets. The rules live in server/live_lobby.gd.
##
##   godot --headless --script res://server/live_server.gd
##
## Env: PORT (default 8080). SUPABASE_URL + SUPABASE_ANON_KEY: players sign in
## with their Supabase token, checked against /auth/v1/user. Without them the
## server only runs with LIVE_DEV=1, where the token is taken as the player id
## (local testing and CI only).
##
## Phone -> server: {t:"hello", token, sim_version} {t:"queue", mode, slots}
##   {t:"aim", match, angle} {t:"hash", match, hash} {t:"leave"}
## Server -> phone: {t:"welcome", player} {t:"queued"} {t:"matched", match,
##   side, config, aim_seconds} {t:"go", match, angles, winner, hash}
##   {t:"ghost"} {t:"error", code}
extends SceneTree

const Lobby := preload("res://server/live_lobby.gd")
const SimVersion := preload("res://sim/sim_version.gd")

const MAX_MESSAGE := 16384
const HELLO_SECONDS := 10.0 ## A socket that hasn't signed in by then is dropped.
## One live connection per account: a new sign-in closes the older one. Off
## while playtesters share an account; turn on with real sign-in or rewards.
const ONE_SOCKET_PER_ACCOUNT := false

var lobby: Lobby
var tcp := TCPServer.new()
## peer key -> {ws, player, since, pending_auth}
var peers := {}
var by_player := {}
var version := SimVersion.get_version()
var dev := OS.get_environment("LIVE_DEV") == "1"
var supabase_url := OS.get_environment("SUPABASE_URL").trim_suffix("/").trim_suffix("/rest/v1")
var anon_key := OS.get_environment("SUPABASE_ANON_KEY")
var _next_peer := 1
var _crypto := Crypto.new()
var _stats_at := 0.0


func _initialize() -> void:
	if supabase_url == "" and not dev:
		printerr("Set SUPABASE_URL and SUPABASE_ANON_KEY, or LIVE_DEV=1 for local testing.")
		quit(1)
		return
	lobby = Lobby.new(_fresh_seed)
	# Headless Godot naps between frames; 20 ms (50 ticks a second) is plenty
	# for matchmaking and keeps the always-on container's CPU (and bill) low.
	OS.low_processor_usage_mode_sleep_usec = 20000
	var port := int(OS.get_environment("PORT")) if OS.get_environment("PORT") != "" else 8080
	var err := tcp.listen(port)
	if err != OK:
		printerr("Can't listen on port %d (%s)" % [port, error_string(err)])
		quit(1)
		return
	print("LIVE_SERVER listening on %d, sim %s%s" % [port, version, " (dev sign-in)" if dev else ""])


func _process(_delta: float) -> bool:
	var now := _now()
	while tcp.is_connection_available():
		var ws := WebSocketPeer.new()
		ws.inbound_buffer_size = MAX_MESSAGE
		ws.accept_stream(tcp.take_connection())
		peers[_next_peer] = {"ws": ws, "player": "", "since": now, "pending_auth": false}
		_next_peer += 1
	for key in peers.keys():
		var p: Dictionary = peers[key]
		var ws: WebSocketPeer = p.ws
		ws.poll()
		match ws.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				while ws.get_available_packet_count() > 0:
					_on_message(key, ws.get_packet().get_string_from_utf8(), now)
				if p.player == "" and not p.pending_auth and now - p.since > HELLO_SECONDS:
					ws.close(4001, "sign in first")
			WebSocketPeer.STATE_CLOSED:
				_drop(key)
	_send_all(lobby.tick(now))
	lobby.prune(now)
	if now - _stats_at >= 60.0:
		_stats_at = now
		print("LIVE_STATS peers=%d queued=%d matches=%d finished=%d mismatches=%d" % [
			peers.size(), lobby.queue.size(), lobby.matches.size(), lobby.finished, lobby.mismatches.size()])
	return false


func _on_message(key: int, text: String, now: float) -> void:
	var p: Dictionary = peers[key]
	var msg = JSON.parse_string(text)
	if not msg is Dictionary:
		_send(p.ws, {"t": "error", "code": "bad_message"})
		return
	var t := str(msg.get("t", ""))
	if p.player == "":
		if t == "hello" and not p.pending_auth:
			_hello(key, msg)
		return
	match t:
		"queue":
			var slots = msg.get("slots", [])
			_send_all(lobby.join(p.player, str(msg.get("mode", "")), slots if slots is Array else [], now))
		"aim":
			_send_all(lobby.aim(p.player, int(msg.get("match", 0)), int(msg.get("angle", 0)), now))
		"hash":
			lobby.report(p.player, int(msg.get("match", 0)), str(msg.get("hash", "")))
		"leave":
			lobby.leave(p.player)


func _hello(key: int, msg: Dictionary) -> void:
	var p: Dictionary = peers[key]
	if str(msg.get("sim_version", "")) != version:
		_send(p.ws, {"t": "error", "code": "update", "sim_version": version})
		p.ws.close(4002, "different game version")
		return
	var token := str(msg.get("token", ""))
	if dev:
		_signed_in(key, token if token != "" else "dev-%d" % key)
		return
	p.pending_auth = true
	var req := HTTPRequest.new()
	req.accept_gzip = false
	root.add_child(req)
	req.request_completed.connect(func(result: int, code: int, _h, body: PackedByteArray):
		req.queue_free()
		if not peers.has(key):
			return
		peers[key].pending_auth = false
		var user = JSON.parse_string(body.get_string_from_utf8()) if code == 200 else null
		if result == HTTPRequest.RESULT_SUCCESS and user is Dictionary and str(user.get("id", "")) != "":
			_signed_in(key, str(user.id))
		else:
			_send(peers[key].ws, {"t": "error", "code": "sign_in"})
			peers[key].ws.close(4001, "sign in failed"))
	req.request(supabase_url + "/auth/v1/user", ["apikey: " + anon_key, "Authorization: Bearer " + token])


func _signed_in(key: int, account: String) -> void:
	# While every playtest device shares one test account (game/online/test_user.gd),
	# each connection counts as its own player, so two phones on that account
	# can meet. Live fights give no rewards yet, so playing yourself gains nothing.
	var player := account if ONE_SOCKET_PER_ACCOUNT else "%s#%d" % [account, key]
	var old: int = by_player.get(player, -1)
	if old != -1 and old != key and peers.has(old):
		peers[old].ws.close(4003, "signed in elsewhere")
		peers[old].player = ""
	peers[key].player = player
	by_player[player] = key
	_send(peers[key].ws, {"t": "welcome", "player": player, "sim_version": version})


func _drop(key: int) -> void:
	var p: Dictionary = peers[key]
	if p.player != "" and by_player.get(p.player, -1) == key:
		lobby.leave(p.player)
		by_player.erase(p.player)
	peers.erase(key)


func _send_all(messages: Array) -> void:
	for m in messages:
		var key: int = by_player.get(m[0], -1)
		if key != -1 and peers.has(key):
			_send(peers[key].ws, m[1])


func _send(ws: WebSocketPeer, msg: Dictionary) -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(msg, "", true, true)) # Full precision: gear stats must arrive exact.


func _fresh_seed() -> int:
	return _crypto.generate_random_bytes(4).decode_u32(0) & 0x7FFFFFFF


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
