## A phone's connection to the live-fight server (server/live_server.gd): opens
## the socket, signs in with `hello`, then passes every server message on.
## The protocol is listed at the top of server/live_server.gd.
extends Node

signal message(msg: Dictionary)
signal closed(reason: String)

const CONNECT_SECONDS := 8.0

var ws := WebSocketPeer.new()
var _hello := {}
var _said_hello := false
var _done := false
var _waited := 0.0


func start(url: String, hello: Dictionary) -> void:
	_hello = hello
	ws.inbound_buffer_size = 1 << 18
	var err := ws.connect_to_url(url)
	if err != OK:
		_finish("can't connect (%s)" % error_string(err))


func send(msg: Dictionary) -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(JSON.stringify(msg, "", true, true)) # Full precision, like the server.


## Leaves quietly: no `closed` signal.
func stop() -> void:
	_done = true
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		send({"t": "leave"})
		ws.close()
	set_process(false)
	queue_free()


func _process(delta: float) -> void:
	if _done:
		return
	ws.poll()
	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			_waited += delta
			if _waited > CONNECT_SECONDS:
				_finish("no answer from the live server")
		WebSocketPeer.STATE_OPEN:
			if not _said_hello:
				_said_hello = true
				send(_hello)
			while ws.get_available_packet_count() > 0 and not _done:
				var msg = JSON.parse_string(ws.get_packet().get_string_from_utf8())
				if msg is Dictionary:
					message.emit(msg)
		WebSocketPeer.STATE_CLOSED:
			_finish(ws.get_close_reason() if ws.get_close_reason() != "" else "the live server hung up")


func _finish(reason: String) -> void:
	if _done:
		return
	_done = true
	set_process(false)
	closed.emit(reason)
	queue_free()
