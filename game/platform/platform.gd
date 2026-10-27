## The one place the game asks "what device am I on?". Screens and fights call
## Platform.get_current() and never test OS.has_feature or reach for a plugin
## themselves, so the web build, Google Play and the App Store each plug in
## their own provider:
## - game/platform/web_platform.gd: the browser build (battleballs.vercel.app)
## - game/platform/android_platform.gd: the Google Play app
## - game/platform/ios_platform.gd: the App Store app
## - this class: desktop runs, the editor and headless tests (does nothing).
##
## Everything here is render-side: haptics, sharing, notifications, safe areas
## and sign-in never reach the sim, so replays are the same on every device.
## Real money goes through the store (game/glow/store.gd), which this picks too.
extends RefCounted

const Store := preload("res://game/glow/store.gd")
const SETTINGS_PATH := "user://settings.cfg"

## Haptic kinds, lightest first. Providers map them onto the device's buzz.
const HAPTICS := {
	"tap": [12, 0.25], ## [milliseconds, strength 0..1]
	"hit": [18, 0.45],
	"big_hit": [30, 0.8],
	"ko": [70, 1.0],
	"win": [45, 0.7],
	"lose": [40, 0.5],
}
const HAPTIC_GAP_MS := 70 ## Buzzes closer together than this merge into one.

static var _current
static var _haptics_loaded := false
static var _haptics_on := true
static var _last_buzz := -100000


## The provider for this build, made once.
static func get_current():
	if _current == null:
		if OS.has_feature("web"):
			_current = load("res://game/platform/web_platform.gd").new()
		elif OS.has_feature("android"):
			_current = load("res://game/platform/android_platform.gd").new()
		elif OS.has_feature("ios"):
			_current = load("res://game/platform/ios_platform.gd").new()
		else:
			_current = new()
	return _current


## Tests swap in their own provider (null goes back to the real one).
static func use(provider) -> void:
	_current = provider


## "web", "android", "ios" or "desktop".
func kind() -> String:
	return "desktop"


## True inside a store app (Google Play / App Store), where real money works.
func is_native_app() -> bool:
	return false


## The store real money goes through on this build (game/glow/store.gd).
func make_store(backend = null):
	return Store.make(backend)


# --- Haptics -------------------------------------------------------------------

static func haptics_enabled() -> bool:
	if not _haptics_loaded:
		_haptics_loaded = true
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			_haptics_on = cfg.get_value("platform", "haptics", true)
	return _haptics_on


static func set_haptics_enabled(on: bool) -> void:
	_haptics_loaded = true
	_haptics_on = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("platform", "haptics", on)
	cfg.save(SETTINGS_PATH)


## False where the device can't buzz at all (Settings hides the switch).
func can_vibrate() -> bool:
	return false


## A short buzz of one of the HAPTICS kinds. Respects the Settings switch and
## merges buzzes that come too close together. Returns true if it buzzed.
func haptic(what: String) -> bool:
	if not HAPTICS.has(what) or not can_vibrate() or not haptics_enabled():
		return false
	var now := Time.get_ticks_msec()
	if now - _last_buzz < HAPTIC_GAP_MS and what != "ko":
		return false
	_last_buzz = now
	_buzz(HAPTICS[what][0], HAPTICS[what][1])
	return true


func _buzz(_ms: int, _strength: float) -> void:
	pass


# --- Sharing -------------------------------------------------------------------

## Opens the device's share sheet with `text` and `url`. Without one, copies
## the link and returns false so the caller can say "Link copied".
func share(text: String, url: String) -> bool:
	DisplayServer.clipboard_set(url if url != "" else text)
	return false


# --- Notifications -------------------------------------------------------------

## False until the build has a local-notification plugin; screens hide
## "Remind me" options when it's false.
func can_notify() -> bool:
	return false


## Schedules a local notification `seconds` from now under `id` (a later call
## with the same id replaces it). Returns false when it can't.
func notify_later(_id: String, _title: String, _body: String, _seconds: int) -> bool:
	return false


func cancel_notification(_id: String) -> void:
	pass


# --- Sign-in -------------------------------------------------------------------

## True when this build can sign in with `provider` ("google" / "apple")
## natively, handing back an id_token (game/online/account.gd exchanges it
## with Supabase). The web build signs in by redirect instead.
func can_sign_in(_provider: String) -> bool:
	return false


## Starts native sign-in. Emits nothing itself: returns the id_token, or ""
## when cancelled or unavailable.
func sign_in(_provider: String) -> String:
	return ""


# --- Screen --------------------------------------------------------------------

## The parts of the screen that the notch, camera hole, rounded corners or home
## bar cover, in canvas pixels (the 720-wide design space): {top, bottom, left,
## right}. Zero where the system keeps the game clear of them.
func safe_insets(_viewport: Viewport) -> Dictionary:
	return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}


## Turns DisplayServer's safe area (screen pixels) into canvas-pixel insets.
static func insets_from(safe: Rect2i, screen: Vector2i, canvas: Vector2) -> Dictionary:
	if screen.x <= 0 or screen.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	var sx := canvas.x / screen.x
	var sy := canvas.y / screen.y
	return {
		"top": maxf(0.0, safe.position.y * sy),
		"bottom": maxf(0.0, (screen.y - safe.end.y) * sy),
		"left": maxf(0.0, safe.position.x * sx),
		"right": maxf(0.0, (screen.x - safe.end.x) * sx),
	}


## True when the system Back (Android's back gesture / button) should be
## handled by the game rather than closing it.
func has_system_back() -> bool:
	return false
