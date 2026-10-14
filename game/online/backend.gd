## Thin Supabase client: guest accounts, cloud save and Ghost Arena calls.
##
## Offline-first: without res://backend_config.json (local runs, forks, PRs
## built before the secrets exist), or with no network, every call returns
## {"ok": false} and the game carries on. Failures are printed, never
## push_error'd, so a flaky connection can't fail the web smoke test.
##
## Only the public anon/publishable key ever ships in the game. Row-level
## security in supabase/migrations decides what a signed-in player may touch.
extends Node

const CONFIG_PATH := "res://backend_config.json"
const SESSION_PATH := "user://session.json"
const TIMEOUT := 12.0
const REFRESH_MARGIN := 60 ## Refresh the access token this many seconds early.

signal account_changed
signal _session_settled(ok: bool)

var url := ""
var key := ""
## access_token, refresh_token, expires_at (unix seconds), user_id.
var session := {}
var disabled := false ## Set by ?offline=1.
var _settling := false


func _init() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var cfg = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		if cfg is Dictionary:
			url = str(cfg.get("url", "")).trim_suffix("/")
			key = str(cfg.get("anon_key", ""))
	var saved = _read_json(SESSION_PATH)
	if saved is Dictionary and saved.has("refresh_token"):
		session = saved


func enabled() -> bool:
	return not disabled and url != "" and key != ""


func user_id() -> String:
	return str(session.get("user_id", ""))


## Makes sure there is a usable session: reuses the stored one, refreshes it,
## or signs in a brand-new guest. Returns false when offline. Concurrent
## callers share one attempt, so a burst of calls can't create two guests.
func ensure_session() -> bool:
	if not enabled():
		return false
	if _settling:
		return await _session_settled
	_settling = true
	var ok := await _settle_session()
	_settling = false
	_session_settled.emit(ok)
	return ok


func _settle_session() -> bool:
	var now := int(Time.get_unix_time_from_system())
	if session.has("access_token") and int(session.get("expires_at", 0)) - REFRESH_MARGIN > now:
		return true
	if session.has("refresh_token"):
		var refreshed := await _auth("token?grant_type=refresh_token", {"refresh_token": session.refresh_token})
		if refreshed.ok:
			return true
		# 4xx means the refresh token is dead (revoked, project reset). Anything
		# else is the network: keep the guest and try again later.
		if refreshed.code < 400 or refreshed.code >= 500:
			return false
		print("ONLINE guest session expired, starting a new guest")
	var signed_up := await _auth("signup", {"data": {}})
	return signed_up.ok


## Calls a Postgres function exposed by PostgREST (supabase/migrations).
func call_rpc(name: String, args: Dictionary) -> Dictionary:
	return await rest("POST", "/rest/v1/rpc/" + name, args)


## Authenticated REST call. Retries once with a fresh token on a 401.
func rest(method: String, path: String, body = null, headers: PackedStringArray = []) -> Dictionary:
	if not await ensure_session():
		return {"ok": false, "code": 0, "data": null}
	var res := await _send(method, path, body, headers, true)
	if res.code == 401:
		session.erase("access_token")
		if await ensure_session():
			res = await _send(method, path, body, headers, true)
	return res


# --- Internals --------------------------------------------------------------

func _auth(endpoint: String, body: Dictionary) -> Dictionary:
	var res := await _send("POST", "/auth/v1/" + endpoint, body, [], false)
	var data = res.data
	if res.ok and data is Dictionary and data.has("access_token") and data.has("user"):
		var now := int(Time.get_unix_time_from_system())
		var previous := user_id()
		session = {
			"access_token": data.access_token,
			"refresh_token": data.refresh_token,
			"expires_at": int(data.get("expires_at", now + int(data.get("expires_in", 3600)))),
			"user_id": str(data.user.get("id", "")),
		}
		_write_json(SESSION_PATH, session)
		if user_id() != previous:
			account_changed.emit()
	else:
		res.ok = false
		print("ONLINE auth %s failed: %d %s" % [endpoint.get_slice("?", 0), res.code, str(data).left(200)])
	return res


func _send(method: String, path: String, body, headers: PackedStringArray, as_user: bool) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	# Browsers already un-gzip fetch responses; letting Godot try again fails
	# (RESULT_BODY_DECOMPRESS_FAILED) on the web build.
	http.accept_gzip = false
	add_child(http)
	var all := PackedStringArray(["apikey: " + key, "Content-Type: application/json", "Accept: application/json"])
	if as_user:
		all.append("Authorization: Bearer " + str(session.get("access_token", "")))
	all.append_array(headers)
	var methods := {"GET": HTTPClient.METHOD_GET, "POST": HTTPClient.METHOD_POST, "PATCH": HTTPClient.METHOD_PATCH, "DELETE": HTTPClient.METHOD_DELETE}
	var payload := "" if body == null else JSON.stringify(body)
	var err := http.request(url + path, all, methods[method], payload)
	if err != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "data": null}
	var out: Array = await http.request_completed
	http.queue_free()
	var code: int = out[1]
	var text: String = (out[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(text) if text != "" else null
	var ok: bool = out[0] == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300
	if not ok and out[0] != HTTPRequest.RESULT_SUCCESS:
		print("ONLINE %s %s unreachable (result %d)" % [method, path.get_slice("?", 0), out[0]])
	return {"ok": ok, "code": code, "data": data}


static func _read_json(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func _write_json(path: String, value) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(value))
