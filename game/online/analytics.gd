## Anonymous play analytics: a small queue of game events, sent in batches to
## log_events() (supabase/migrations/*_analytics.sql) as the signed-in guest.
##
## Call the static helper from anywhere: Analytics.track("fight_end", {...}).
## It does nothing until main.gd has called Analytics.start(), and nothing at
## all while the player has opted out. Events never carry names, free text or
## device ids: only the event name, game facts in `props`, and a timestamp.
## The queue lives in user:// so events made offline (or just before the tab
## closes) go out next time. Sending never blocks or fails the game.
##
## Event names and props the stats screen reads:
##   app_open        {first}
##   fight_end       {mode, picked, team: [critter], foe: [critter], result: win|loss|draw, secs}
##   onboarding_step {step, ms}
##   energy          {delta, source} (+ gained, - spent)
##   screen          {name}
##   summon, fuse, share: feature use
extends Node

const STATE_PATH := "user://analytics.json"
const BATCH := 50 ## Events per request (the server takes up to 100).
const MAX_QUEUE := 500 ## Oldest events are dropped past this.
const FLUSH_EVERY := 20.0 ## Seconds between sends while events are waiting.
const FLUSH_AT := 20 ## Send straight away once this many are waiting.
const SAVE_EVERY := 3.0 ## Seconds between writes of the queue to user://.
const RETRY_MAX := 300.0 ## Longest wait (seconds) between failed sends.

static var _instance ## The one running Analytics node, or null before start().
static var _opened := false ## app_open goes out once per launch, not per scene.

var backend ## game/online/backend.gd; main.gd hands over its own on every load.
var opt_out := false
var is_test := false ## Debug builds and automated browsers: kept off the dashboard.
var session_id := ""
var app_version := ""
var queue: Array = []
var forget_pending := false ## Opted out, but the server hasn't deleted their events yet.
var _seq := 0 ## Last event number: a sent batch is removed by number, not position.
var _sending := false
var _retry_wait := 0.0 ## Seconds to wait before sending again after a failure.
var _send_started := 0 ## Ticks (ms) when the current send began.
var _since_flush := 0.0
var _since_save := 0.0
var _dirty := false
var _state_path := STATE_PATH


## Creates the analytics node on first call (it outlives scene changes) and
## points it at this scene's backend. Returns the node.
static func start(tree: SceneTree, backend_, version: String, params := {}):
	var first := false
	if _instance == null:
		_instance = new()
		first = not FileAccess.file_exists(_instance._state_path)
		_instance.app_version = version
		_instance.load_state()
		_instance.apply_privacy_signals(params)
		tree.root.add_child.call_deferred(_instance)
	_instance.backend = backend_
	if not _opened:
		_opened = true
		track("app_open", {"first": first})
	return _instance


static func track(event: String, props := {}) -> void:
	if _instance != null:
		_instance.add(event, props)


static func instance():
	return _instance


static func set_opt_out(value: bool) -> void:
	if _instance != null:
		_instance.set_opted_out(value)


static func opted_out() -> bool:
	return _instance != null and _instance.opt_out


func _init(state_path := STATE_PATH) -> void:
	_state_path = state_path
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	session_id = "%08x%04x" % [rng.randi(), rng.randi() & 0xffff]
	is_test = OS.is_debug_build()


func _process(delta: float) -> void:
	_since_save += delta
	if _dirty and _since_save >= SAVE_EVERY:
		save_state()
	# A send whose backend was freed by a scene change never answers.
	if _sending and Time.get_ticks_msec() - _send_started > 30000:
		_sending = false
	_since_flush += delta
	if _since_flush >= maxf(FLUSH_EVERY, _retry_wait) or (queue.size() >= FLUSH_AT and _retry_wait == 0.0):
		_since_flush = 0.0
		if forget_pending:
			_forget()
		else:
			flush()


func _notification(what: int) -> void:
	# Leaving the app (or tab): try to send now; the saved queue covers a send
	# that doesn't finish.
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		if _dirty:
			save_state()
		flush()


func add(event: String, props := {}) -> void:
	if opt_out:
		return
	_seq += 1
	queue.append({"name": event, "props": props, "t": int(Time.get_unix_time_from_system() * 1000.0), "i": _seq})
	if queue.size() > MAX_QUEUE:
		queue = queue.slice(queue.size() - MAX_QUEUE)
	# Written a few seconds later (or on leaving the app), not per event: a
	# write on the web is an IndexedDB sync.
	_dirty = true
	if not is_inside_tree():
		save_state()


## Sends the oldest waiting events. Only once the game has a guest session,
## so analytics never signs anyone up on its own.
func flush() -> void:
	if _sending or opt_out or queue.is_empty() or not _can_send():
		return
	_sending = true
	_send_started = Time.get_ticks_msec()
	var batch := queue.slice(0, BATCH)
	var res: Dictionary = await backend.call_rpc("log_events", {
		"p_events": batch, "p_session": session_id, "p_app_version": app_version,
		"p_platform": OS.get_name(), "p_test": is_test,
	})
	_sending = false
	# A 400 is the server refusing the batch itself (a bug, not the network):
	# drop it so it can't block everything behind it.
	if res.ok or res.code == 400:
		drop_sent(int(batch.back().get("i", 0)))
		_retry_wait = 0.0
		if res.ok:
			print("ANALYTICS_OK sent=%d" % batch.size())
	else:
		_retry_wait = minf(RETRY_MAX, maxf(FLUSH_EVERY, _retry_wait * 2.0))
	if opt_out and forget_pending:
		# Opted out while this batch was on its way: delete it too.
		_forget()


## Removes the events up to number `last` (events added during a send, or
## the queue being trimmed meanwhile, leave the right ones behind).
func drop_sent(last: int) -> void:
	queue = queue.filter(func(e): return int(e.get("i", 0)) > last)
	save_state()


func set_opted_out(value: bool) -> void:
	if value == opt_out:
		return
	opt_out = value
	forget_pending = opt_out
	if opt_out:
		queue.clear()
	save_state()
	if opt_out:
		_forget()


## Asks the server to delete this player's events; retried until it works
## (no session yet, offline, or a batch still being sent).
func _forget() -> void:
	if not forget_pending or _sending or not _can_send():
		return
	_sending = true
	_send_started = Time.get_ticks_msec()
	var res: Dictionary = await backend.call_rpc("forget_my_analytics", {})
	_sending = false
	if res.ok and opt_out:
		forget_pending = false
		save_state()


## Browser privacy settings (Global Privacy Control, Do Not Track) opt a new
## player out by default, and ?analytics=off|on sets it outright. Automated
## browsers (the smoke test) are marked as test traffic.
func apply_privacy_signals(params: Dictionary) -> void:
	if OS.has_feature("web"):
		if JavaScriptBridge.eval("navigator.webdriver === true", true) == true:
			is_test = true
		if not FileAccess.file_exists(_state_path) and \
				JavaScriptBridge.eval("navigator.globalPrivacyControl === true || navigator.doNotTrack === '1'", true) == true:
			opt_out = true
			save_state()
	match str(params.get("analytics", "")):
		"off":
			set_opted_out(true)
		"on":
			set_opted_out(false)


func load_state() -> void:
	if not FileAccess.file_exists(_state_path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(_state_path))
	if data is Dictionary:
		opt_out = data.get("opt_out", false) == true
		forget_pending = data.get("forget_pending", false) == true
		queue = data.get("queue", []) if data.get("queue") is Array else []
		for e in queue:
			_seq = maxi(_seq, int(e.get("i", 0)) if e is Dictionary else 0)


func save_state() -> void:
	_dirty = false
	_since_save = 0.0
	var f := FileAccess.open(_state_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"opt_out": opt_out, "forget_pending": forget_pending, "queue": queue}))


func _can_send() -> bool:
	return backend != null and is_instance_valid(backend) and backend.enabled() and backend.user_id() != ""


# --- Event helpers ---------------------------------------------------------------

## "win", "loss" or "draw" for the player's side (0) from a sim winner.
static func result_of(winner: int) -> String:
	return "win" if winner == 0 else ("loss" if winner == 1 else "draw")
