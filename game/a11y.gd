## Accessibility settings shared by every screen: reduced motion, larger text
## and on-screen sound cues. Render-only: nothing here reaches the sim, so
## replays stay identical whatever the player picks. Saved next to the sound
## mode in user://settings.cfg (section "a11y").
extends RefCounted

const SETTINGS_PATH := "user://settings.cfg"
## Smallest font size any text is drawn at. The 720 px wide canvas shrinks to
## about 0.54 on an iPhone, so 20 px lands near Apple's 11 pt minimum.
const MIN_FONT := 20
const LARGE_TEXT_SCALE := 1.2
const KEYS := ["reduced_motion", "large_text", "sound_cues"]

## No screen shake, no white hit flashes or glow pulses, no finisher zoom.
static var reduced_motion := false
## Scales every font by LARGE_TEXT_SCALE.
static var large_text := false
## Short text cues for sounds that have no other visual (low HP, overtime).
static var sound_cues := true

static var _loaded := false


## A readable font size for a design size: never below MIN_FONT, and larger
## when Larger text is on.
static func font(size: int) -> int:
	ensure_loaded()
	var s := maxi(size, MIN_FONT)
	return roundi(s * LARGE_TEXT_SCALE) if large_text else s


## 0 when motion should be suppressed, 1 otherwise. Multiply shakes by it.
static func motion() -> float:
	ensure_loaded()
	return 0.0 if reduced_motion else 1.0


static func ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK and cfg.has_section("a11y"):
		reduced_motion = cfg.get_value("a11y", "reduced_motion", reduced_motion)
		large_text = cfg.get_value("a11y", "large_text", large_text)
		sound_cues = cfg.get_value("a11y", "sound_cues", sound_cues)
	elif OS.has_feature("web"):
		# First run on the web: follow the phone's own Reduce Motion setting.
		var js := "window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches"
		# The bridge hands JS booleans back as 0/1.
		reduced_motion = bool(JavaScriptBridge.eval(js, true))


static func get_value(key: String) -> bool:
	ensure_loaded()
	match key:
		"reduced_motion":
			return reduced_motion
		"large_text":
			return large_text
		"sound_cues":
			return sound_cues
	return false


static func set_value(key: String, on: bool) -> void:
	ensure_loaded()
	match key:
		"reduced_motion":
			reduced_motion = on
		"large_text":
			large_text = on
		"sound_cues":
			sound_cues = on
		_:
			return
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	for k in KEYS:
		cfg.set_value("a11y", k, get_value(k))
	cfg.save(SETTINGS_PATH)


## Back to defaults without touching the saved file (tests).
static func reset() -> void:
	_loaded = true
	reduced_motion = false
	large_text = false
	sound_cues = true


## Re-applies font sizes under `root` after Larger text changes. Controls
## built by ui_kit/main remember their design size in the "base_font" meta.
static func apply_fonts(root: Node) -> void:
	if root is Control and root.has_meta("base_font"):
		root.add_theme_font_size_override("font_size", font(root.get_meta("base_font")))
	for c in root.get_children():
		apply_fonts(c)
