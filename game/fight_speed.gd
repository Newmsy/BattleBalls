## Fight playback speed, shared by every fight screen (campaign, Quick fight,
## Ghost Arena, Spire, Bounce Run, Bracket, replays). Render-only: it changes
## how many sim steps play per real second, never the sim itself, so fights
## stay identical replayed from seed at any speed.
##
## Speeds unlock by account level (UNLOCK_LEVELS). The player's last pick is
## a device setting in user://settings.cfg (section "fight"), like sound and
## accessibility. main.gd keeps `account_level` up to date; the other fight
## scenes read it from here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")

const SETTINGS_PATH := "user://settings.cfg"
const SPEEDS := [1.0, 2.0, 4.0]
const UNLOCK_LEVELS := [1, 5, 10]

static var account_level := 1
## Testing switch (Settings > Testing): every speed open whatever the level.
static var unlock_all := false
## ?speed= in the URL (smoke tests, clips): played as given, locks ignored.
static var url_speed := 0.0

static var _pick := 0
static var _loaded := false


## The speed fights play at now: the last pick, capped to what's unlocked.
static func current() -> float:
	if url_speed > 0.0:
		return url_speed
	return SPEEDS[index()]


static func index() -> int:
	_ensure_loaded()
	var i := clampi(_pick, 0, SPEEDS.size() - 1)
	while i > 0 and not unlocked(i):
		i -= 1
	return i


static func unlocked(i: int) -> bool:
	_ensure_loaded()
	return unlock_all or account_level >= UNLOCK_LEVELS[i]


## Picks speed `i` and remembers it. Locked speeds are ignored.
static func select(i: int) -> void:
	if i < 0 or i >= SPEEDS.size() or not unlocked(i):
		return
	url_speed = 0.0
	_pick = i
	_save()


static func all_unlocked() -> bool:
	_ensure_loaded()
	return unlock_all


static func set_unlock_all(on: bool) -> void:
	_ensure_loaded()
	unlock_all = on
	_save()


static func label(i: int) -> String:
	return "%dx" % int(SPEEDS[i]) if unlocked(i) else "%dx Lv%d" % [int(SPEEDS[i]), UNLOCK_LEVELS[i]]


## A row of speed buttons for a fight's panel: the pick lit, locked ones
## dimmed with the level that opens them.
static func picker(font_size := 26, height := 84) -> Picker:
	return Picker.new(font_size, height)


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_pick = int(cfg.get_value("fight", "speed", 0))
		unlock_all = bool(cfg.get_value("fight", "unlock_all", false))


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("fight", "speed", _pick)
	cfg.set_value("fight", "unlock_all", unlock_all)
	cfg.save(SETTINGS_PATH)


class Picker extends HBoxContainer:
	signal picked(speed: float)

	var _font := 26
	var _height := 84

	func _init(font_size: int, height: int) -> void:
		_font = font_size
		_height = height
		add_theme_constant_override("separation", 8)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_stretch_ratio = 2.0
		refresh()

	## Redraws for the current pick and unlocks.
	func refresh() -> void:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		var live := FightSpeedRef.current()
		for i in FightSpeedRef.SPEEDS.size():
			var on: bool = is_equal_approx(live, FightSpeedRef.SPEEDS[i])
			var b := Kit.button(FightSpeedRef.label(i), _pick.bind(i), "primary" if on else "ghost", _font, _height)
			b.name = "Speed%dx" % int(FightSpeedRef.SPEEDS[i])
			b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			b.clip_text = true
			b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			b.disabled = not FightSpeedRef.unlocked(i)
			b.tooltip_text = "Unlocks at account level %d" % FightSpeedRef.UNLOCK_LEVELS[i] if b.disabled else ""
			add_child(b)

	func _pick(i: int) -> void:
		FightSpeedRef.select(i)
		refresh()
		picked.emit(FightSpeedRef.current())


const FightSpeedRef := preload("res://game/fight_speed.gd")
