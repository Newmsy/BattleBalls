## Fight playback speed, shared by every fight screen (campaign, Quick fight,
## Ghost Arena, Spire, Bounce Run, Bracket, replays). Render-only: it changes
## how many sim steps play per real second, never the sim itself, so fights
## stay identical replayed from seed at any speed.
##
## Speeds unlock by account level (UNLOCK_LEVELS). The player's last pick is
## kept in user://settings.cfg (section "fight") and, through on_pick and
## restore(), in the cloud save so every device plays at the same speed.
## main.gd keeps `account_level` up to date; the other fight scenes read it
## from here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const FightLayout := preload("res://game/fight_layout.gd")

const SETTINGS_PATH := "user://settings.cfg"
const SPEEDS := [1.0, 2.0, 4.0]
const UNLOCK_LEVELS := [1, 5, 10]
## The aim tip shows on every aim screen until the account reaches this level
## (a new player's first few fights), then the screens show nothing there.
const AIM_HINT_BELOW_LEVEL := 3
const AIM_HINT := "Drag to aim, let go to launch"

static var account_level := 1
## Testing switch (Settings > Testing): every speed open whatever the level.
static var unlock_all := false
## ?speed= in the URL (smoke tests, clips): played as given, locks ignored.
static var url_speed := 0.0
## Called with the new pick after select() (main.gd puts it in the save).
static var on_pick := Callable()

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
	if on_pick.is_valid():
		on_pick.call(i)


## The remembered pick, whether or not it's unlocked yet.
static func pick() -> int:
	_ensure_loaded()
	return _pick


## Takes the pick another device made (from the cloud save) without calling
## on_pick back.
static func restore(i: int) -> void:
	_ensure_loaded()
	if i < 0 or i >= SPEEDS.size() or i == _pick:
		return
	_pick = i
	_save()


static func all_unlocked() -> bool:
	_ensure_loaded()
	return unlock_all


static func set_unlock_all(on: bool) -> void:
	_ensure_loaded()
	unlock_all = on
	_save()


## "Drag to aim, let go to launch" for a new player's first few fights, else "".
static func aim_hint() -> String:
	return AIM_HINT if account_level < AIM_HINT_BELOW_LEVEL else ""


## `text` and the aim tip on one line ("Stage 1-3 · Drag to aim, let go to launch").
static func with_aim_hint(text: String) -> String:
	var hint := aim_hint()
	return text if hint == "" else (hint if text == "" else text + " · " + hint)


static func label(i: int) -> String:
	return "%dx" % int(SPEEDS[i]) if unlocked(i) else "%dx Lv%d" % [int(SPEEDS[i]), UNLOCK_LEVELS[i]]


## The speed after the one playing now, among the unlocked ones (wrapping
## to 1x); the same speed when nothing else is unlocked.
static func next_index() -> int:
	var i := index()
	for k in range(1, SPEEDS.size() + 1):
		var n := (i + k) % SPEEDS.size()
		if unlocked(n):
			return n
	return i


## The fight's speed pill: tap to cycle 1x, 2x, 4x. It sits at the left of the
## bottom row (Skip in the middle, Sound on the right), whichever row it is
## added to (top_level keeps it out of the row's layout); it shows and hides
## with that row.
static func picker(_font_size := 26, _height := 84) -> Picker:
	return Picker.new()


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


class Picker extends Control:
	signal picked(speed: float)

	var _button: Button
	var _lock: Control

	func _init() -> void:
		top_level = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_button = Kit.button("", _cycle, "ghost", 20, int(FightLayout.PILL.y))
		_button.name = "SpeedPill"
		_button.clip_text = true
		_button.add_theme_font_override("font", Kit.FONT)
		_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_button)
		refresh()

	func _ready() -> void:
		get_viewport().size_changed.connect(_place)
		_place()

	func _place() -> void:
		size = FightLayout.PILL
		global_position = FightLayout.pill_position(get_viewport().get_visible_rect().size, -1)

	## Redraws for the current pick and unlocks.
	func refresh() -> void:
		var i := FightSpeedRef.index()
		_button.text = "Speed: %dx" % int(FightSpeedRef.current())
		if _lock:
			_lock.queue_free()
			_lock = null
		# Nothing to cycle to yet: a padlock and the level that opens 2x.
		var locked := FightSpeedRef.next_index() == i and FightSpeedRef.url_speed <= 0.0
		_button.modulate = Color(1, 1, 1, 0.6 if locked else 1.0)
		if locked:
			_button.text = "1x"
			_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_lock = Kit.hbox(4, [Kit.glyph("lock", 16, Kit.MUTED), Kit.chip("Lv%d" % FightSpeedRef.UNLOCK_LEVELS[1], Kit.MUTED, 16)], BoxContainer.ALIGNMENT_END)
			_lock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_lock.offset_right = -14
			_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for c in _lock.get_children():
				c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_button.add_child(_lock)
		else:
			_button.alignment = HORIZONTAL_ALIGNMENT_CENTER

	func _cycle() -> void:
		var n := FightSpeedRef.next_index()
		if n == FightSpeedRef.index() and FightSpeedRef.url_speed <= 0.0:
			return
		FightSpeedRef.select(n)
		refresh()
		picked.emit(FightSpeedRef.current())


const FightSpeedRef := preload("res://game/fight_speed.gd")
