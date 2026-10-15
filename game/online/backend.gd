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

## The signed-in user changed: a new guest, a sign-in to another account, or
## a sign-out. Not emitted when a guest links an email or provider (same id).
signal account_changed
## sign_out() ran; emitted just before account_changed so the save can reset first.
signal signed_out
signal _session_settled(ok: bool)

var url := ""
var key := ""
## access_token, refresh_token, expires_at (unix seconds), user_id, and
## anonymous (true for a guest that hasn't linked an email or provider yet).
var session := {}
var disabled := false ## Set by ?offline=1.
## Test mode (game/online/test_user.gd): sign in as shared test account N
## instead of a guest. 0 = off.
var test_user := 0
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
	if test_user > 0 and int(session.get("test_user", 0)) != test_user:
		if await _sign_in_test_user():
			return true
		# No test account on the server yet (before the deploy that makes it):
		# carry on as this device's guest. The save moves over once it works.
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
		if int(session.get("test_user", 0)) > 0:
			return await _sign_in_test_user()
		print("ONLINE guest session expired, starting a new guest")
	var signed_up := await _auth("signup", {"data": {}})
	return signed_up.ok


## Calls a Postgres function exposed by PostgREST (supabase/migrations).
func call_rpc(name: String, args: Dictionary) -> Dictionary:
	return await rest("POST", "/rest/v1/rpc/" + name, args)


## Calls a Postgres function with the public key only: no guest session is
## made or used (the stats screen, which is keyed by its own secret).
func call_rpc_public(name: String, args: Dictionary) -> Dictionary:
	if not enabled():
		return {"ok": false, "code": 0, "data": null}
	return await _send("POST", "/rest/v1/rpc/" + name, args, [], false)


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


# --- Accounts (game/online/account.gd drives these) ---------------------------

## A call to Supabase Auth (/auth/v1/...). `as_user` sends the session token
## (needed to change or link the signed-in user).
func auth_call(method: String, path: String, body = null, as_user := false) -> Dictionary:
	if not enabled():
		return {"ok": false, "code": 0, "data": null}
	if as_user and not await ensure_session():
		return {"ok": false, "code": 0, "data": null}
	return await _send(method, "/auth/v1/" + path, body, [], as_user)


## Takes the session from a sign-in or verify response. Returns false if the
## response had none.
func take_session(data) -> bool:
	if not (data is Dictionary and data.has("access_token") and data.has("refresh_token")):
		return false
	var now := int(Time.get_unix_time_from_system())
	var user = data.get("user")
	var claims := jwt_claims(str(data.access_token))
	var previous := user_id()
	var was_test_user := int(session.get("test_user", 0))
	session = {
		"access_token": data.access_token,
		"refresh_token": data.refresh_token,
		"expires_at": int(data.get("expires_at", now + int(data.get("expires_in", 3600)))),
		"user_id": str(user.get("id", "")) if user is Dictionary else str(claims.get("sub", "")),
		"anonymous": bool(user.get("is_anonymous", false)) if user is Dictionary else bool(claims.get("is_anonymous", false)),
	}
	if was_test_user > 0 and user_id() == previous:
		session.test_user = was_test_user # A refresh keeps the test account.
	_write_json(SESSION_PATH, session)
	if user_id() != previous:
		account_changed.emit()
	return true


## Forgets this device's session. The next online call starts a new guest.
func sign_out() -> void:
	if session.has("access_token"):
		await _send("POST", "/auth/v1/logout", {}, [], true)
	session = {}
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
	signed_out.emit()
	account_changed.emit()


## After an Apple/Google redirect or an emailed sign-in link, the web page
## opens with the session in its #fragment. Takes it, cleans the address bar,
## and returns "" (nothing there), "ok", or the error the page carried.
func take_session_from_page() -> String:
	if not OS.has_feature("web"):
		return ""
	var hash := str(JavaScriptBridge.eval("window.location.hash", true)).trim_prefix("#")
	if hash == "" or not ("access_token=" in hash or "error" in hash):
		return ""
	JavaScriptBridge.eval("history.replaceState(null, '', window.location.pathname + window.location.search)", true)
	var params := parse_fragment(hash)
	if params.has("error") or params.has("error_description"):
		return str(params.get("error_description", params.get("error", "sign-in failed"))).replace("+", " ")
	return "ok" if take_session(params) else "sign-in failed"


static func parse_fragment(hash: String) -> Dictionary:
	var out := {}
	for pair in hash.split("&", false):
		var kv := pair.split("=")
		out[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	return out


## The claims inside a Supabase access token (not verified: only used to read
## our own user id after a redirect; the server checks every token it gets).
static func jwt_claims(token: String) -> Dictionary:
	var parts := token.split(".")
	if parts.size() != 3:
		return {}
	var b64 := parts[1].replace("-", "+").replace("_", "/")
	while b64.length() % 4 != 0:
		b64 += "="
	var parsed = JSON.parse_string(Marshalls.base64_to_utf8(b64))
	return parsed if parsed is Dictionary else {}


# --- Internals --------------------------------------------------------------

## Signs in to the shared test account. Its password is made fresh on every
## deploy (tools/supabase_auth_config.mjs) and handed out by test_login, so
## it never sits in the repo.
func _sign_in_test_user() -> bool:
	var login: Dictionary = await call_rpc_public("test_login", {"p_slot": test_user})
	if not (login.ok and login.data is Dictionary and login.data.has("email")):
		return false
	var res := await _auth("token?grant_type=password", {"email": login.data.email, "password": login.data.password})
	if not res.ok:
		return false
	session.test_user = test_user
	_write_json(SESSION_PATH, session)
	print("ONLINE signed in as test user ", test_user)
	return true


func _auth(endpoint: String, body: Dictionary) -> Dictionary:
	var res := await _send("POST", "/auth/v1/" + endpoint, body, [], false)
	if not (res.ok and take_session(res.data)):
		res.ok = false
		print("ONLINE auth %s failed: %d %s" % [endpoint.get_slice("?", 0), res.code, str(res.data).left(200)])
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
	var methods := {"GET": HTTPClient.METHOD_GET, "POST": HTTPClient.METHOD_POST, "PUT": HTTPClient.METHOD_PUT, "PATCH": HTTPClient.METHOD_PATCH, "DELETE": HTTPClient.METHOD_DELETE}
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
