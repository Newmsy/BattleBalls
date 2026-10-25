## Accounts: every player starts as a guest (anonymous Supabase user). A guest
## can save their progress to an account without losing anything, because
## linking keeps the same user id: by email code, or by Apple / Google once
## those are switched on in Supabase. On another device they sign in to the
## same account and their cloud save comes down (see save_game.gd).
##
## Email: Supabase sends a 6-digit code (and a link). The code works anywhere;
## the link opens the web build, which picks the session up from the address
## (backend.take_session_from_page). Apple and Google are web redirects for
## now; the native iOS / Android sign-in plugins come with the store builds.
extends RefCounted

signal changed

const PROVIDERS := ["apple", "google"]
const SITE := "https://battleballs.vercel.app"

var backend ## game/online/backend.gd
## offline (no backend), loading, guest, linked, error (couldn't reach it)
var status := "loading"
var email := ""
var linked_providers: Array = [] ## e.g. ["email", "apple"]
var providers_on := {} ## Server switches: {"apple": true, "google": false, "email": true}
## An email code in flight: {email, mode}, mode "save" (link this guest) or
## "signin" (switch this device to an existing account).
var pending := {}
var message := "" ## Last result to show the player ("" for none).
var busy := false
var _refreshing := false


func _init(backend_ = null) -> void:
	backend = backend_
	if not enabled():
		status = "offline"


func enabled() -> bool:
	return backend != null and backend.enabled()


func is_guest() -> bool:
	return status == "guest"


## Where emailed links and Apple/Google redirects come back to: this page on
## the web (previews included), the live site otherwise.
func return_url() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("window.location.origin + window.location.pathname", true))
	return SITE


func refresh() -> void:
	if not enabled() or _refreshing:
		return
	_refreshing = true
	await _refresh()
	_refreshing = false
	changed.emit()


func _refresh() -> void:
	if not await backend.ensure_session():
		status = "error"
		return
	var res: Dictionary = await backend.auth_call("GET", "user", null, true)
	if res.ok and res.data is Dictionary:
		var u: Dictionary = res.data
		email = str(u.get("email", "")) if u.get("email") != null else ""
		linked_providers = []
		var identities = u.get("identities", [])
		for i in (identities if identities is Array else []):
			linked_providers.append(str(i.get("provider", "")))
		status = "guest" if bool(u.get("is_anonymous", false)) else "linked"
	else:
		status = "error"
	var settings: Dictionary = await backend.auth_call("GET", "settings")
	if settings.ok and settings.data is Dictionary and settings.data.get("external") is Dictionary:
		providers_on = settings.data.external


func provider_ready(provider: String) -> bool:
	return bool(providers_on.get(provider, false))


static func valid_email(text: String) -> bool:
	var e := text.strip_edges()
	var at := e.find("@")
	return at > 0 and e.rfind(".") > at + 1 and not e.ends_with(".") and not " " in e


## Step 1: email a code. mode "save" links it to this guest; "signin" moves
## this device to an existing account.
func send_code(address: String, mode: String) -> bool:
	address = address.strip_edges().to_lower()
	if not valid_email(address):
		return _done(false, "That email doesn't look right.")
	busy = true
	changed.emit()
	var back := "?redirect_to=" + return_url().uri_encode()
	var res: Dictionary
	if mode == "save":
		res = await backend.auth_call("PUT", "user" + back, {"email": address}, true)
	else:
		res = await backend.auth_call("POST", "otp" + back, {"email": address, "create_user": false})
	if res.ok:
		pending = {"email": address, "mode": mode}
		return _done(true, "Code sent to %s. Check spam too." % address)
	return _done(false, _explain(res, mode))


## Step 2: the 6-digit code from the email.
func verify_code(code: String) -> bool:
	code = code.strip_edges().replace(" ", "")
	if pending.is_empty():
		return _done(false, "Ask for a code first.")
	if code.length() < 6 or not code.is_valid_int():
		return _done(false, "Enter the 6-digit code.")
	busy = true
	changed.emit()
	var type := "email_change" if pending.mode == "save" else "email"
	var res: Dictionary = await backend.auth_call("POST", "verify", {"type": type, "email": pending.email, "token": code})
	if not res.ok:
		return _done(false, _explain(res, "verify"))
	if not backend.take_session(res.data):
		# Some verify replies carry no new session: the old one now has the
		# email, so a refresh is enough.
		backend.session.erase("access_token")
	var was_signin: bool = pending.mode == "signin"
	pending = {}
	await refresh()
	return _done(true, "Signed in!" if was_signin else "Saved! Sign in with %s on any device to carry on." % email)


func cancel_code() -> void:
	pending = {}
	message = ""
	changed.emit()


## Apple / Google: leaves the page and comes back signed in (web). For a guest
## the provider is linked to this account; otherwise it is a plain sign-in.
func use_provider(provider: String, mode: String) -> void:
	if not OS.has_feature("web"):
		_done(false, "Coming with the app store version.")
		return
	var back := return_url().uri_encode()
	if mode == "save":
		var res: Dictionary = await backend.auth_call("GET",
			"user/identities/authorize?provider=%s&redirect_to=%s&skip_http_redirect=true" % [provider, back], null, true)
		if not (res.ok and res.data is Dictionary and res.data.has("url")):
			_done(false, _explain(res, "provider"))
			return
		JavaScriptBridge.eval("window.location.href = %s" % JSON.stringify(str(res.data.url)), true)
	else:
		var to := "%s/auth/v1/authorize?provider=%s&redirect_to=%s" % [backend.url, provider, back]
		JavaScriptBridge.eval("window.location.href = %s" % JSON.stringify(to), true)


func sign_out() -> void:
	busy = true
	changed.emit()
	await backend.sign_out()
	email = ""
	linked_providers = []
	pending = {}
	busy = false
	message = "Signed out. You're playing as a new guest on this device."
	status = "loading"
	await refresh()


## Deletes this account (or guest) and its progress for good, on the server
## and this device. The device carries on as a new guest.
func delete_account() -> bool:
	busy = true
	message = ""
	changed.emit()
	var res: Dictionary = await backend.delete_account()
	if not res.is_empty():
		return _done(false, "Can't reach the server. Check your connection." if int(res.get("code", 0)) == 0 else "Couldn't delete your account. Try again.")
	email = ""
	linked_providers = []
	pending = {}
	busy = false
	message = "Account deleted. You're playing as a new guest."
	status = "loading"
	await refresh()
	return true


func _done(ok: bool, text: String) -> bool:
	busy = false
	message = text
	changed.emit()
	return ok


static func _explain(res: Dictionary, step: String) -> String:
	var d = res.get("data")
	var code := ""
	var text := ""
	if d is Dictionary:
		code = str(d.get("error_code", d.get("code", "")))
		text = str(d.get("msg", d.get("message", d.get("error_description", ""))))
	if int(res.get("code", 0)) == 0:
		return "Can't reach the server. Check your connection."
	if int(res.code) == 429 or "rate" in code:
		return "Too many emails just now. Try again in a few minutes."
	if code == "email_exists" or "already been registered" in text:
		return "That email already has an account. Use Sign in instead."
	if code == "otp_expired" or "expired" in text or "invalid" in text.to_lower():
		return "That code didn't work or has expired. Ask for a new one."
	if step == "signin" and (code == "otp_disabled" or "Signups not allowed" in text):
		return "No account for that email. Save your progress to it instead."
	if code == "manual_linking_disabled" or code == "provider_disabled":
		return "That sign-in isn't switched on yet."
	return "Something went wrong (%s). Try again." % (code if code != "" else str(res.code))
