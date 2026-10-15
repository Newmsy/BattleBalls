## The game's sound: fight effects from sim events, music, UI clicks and the
## mute toggle. Only reads the sim, never changes it, and uses its own random
## generator so replays stay identical. Sounds are rendered by
## tools/sfx/make_sfx.py; see /design/sound.md for the plan.
extends Node

const AUDIO_DIR := "res://game/audio/"
const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 16
## Sound modes the toggle cycles through.
const MODES := ["all", "sfx", "off"]
const MODE_LABELS := {"all": "Sound: On", "sfx": "Music: Off", "off": "Sound: Off"}
## Per sound: [max playing at once, min seconds between starts, volume dB].
## Lower caps on frequent sounds keep the chaos readable.
const RULES := {
	"hit": [3, 0.05, -2.0],
	"hit_big": [1, 0.25, 0.0],
	"wall": [2, 0.07, -15.0],
	"ouch_vampire": [1, 0.18, -7.0],
	"ouch_laser": [1, 0.18, -9.0],
	"ko": [1, 0.5, 0.0],
	"heal": [1, 0.3, -10.0],
	"slurp": [1, 0.25, -8.0],
	"zap": [2, 0.08, -9.0],
	"sizzle": [2, 0.12, -10.0],
	"overtime": [1, 1.0, -6.0],
	"heartbeat": [1, 0.5, -6.0],
	"win": [1, 0.5, -3.0],
	"lose": [1, 0.5, -3.0],
	"go": [1, 0.3, -5.0],
	"launch": [1, 0.1, -4.0],
	"stretch": [1, 0.07, -14.0],
	"click": [2, 0.04, -8.0],
}
## Applied to every sound and the music so busy moments don't clip.
const MASTER_DB := -7.0
const MUSIC := {"menu": ["music_menu", -12.0], "fight": ["music_fight", -10.0]}
## Contact damage at or above this share of the target's max HP is a "big hit".
const BIG_HIT_SHARE := 0.18
const LOW_HP_SHARE := 0.35
const HEARTBEAT_EVERY := 0.85

var mode := "all"
## Set while a fight is on screen, for the overtime cue and low-HP pulse.
var fight_sim

var _variants := {} ## sound name -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _last_start := {} ## sound name -> seconds
var _ends := {} ## sound name -> end times of the copies started
var _music: AudioStreamPlayer
var _music_track := ""
var _was_overtime := false
var _heartbeat_in := 0.0
var _rng := RandomNumberGenerator.new() ## Render-side only: never the sim's.
var _clock := 0.0
var _toggle: Button
## Raise the mute toggle by this much, e.g. to clear the home screen's tab bar.
var toggle_lift := 0.0:
	set(v):
		toggle_lift = v
		if _toggle:
			_place_toggle()
var _board: Control


func _init() -> void:
	_rng.randomize()
	for name in RULES:
		_variants[name] = _load_variants(name)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_load_settings()


func _ready() -> void:
	_build_toggle()
	get_tree().node_added.connect(_on_node_added)
	if OS.has_feature("web") and "sounds=1" in str(JavaScriptBridge.eval("window.location.search", true)):
		show_board.call_deferred()


func _process(delta: float) -> void:
	_clock += delta
	if fight_sim == null or fight_sim.finished:
		return
	var you = fight_sim.balls[0]
	if you.alive() and you.hp < you.max_hp * LOW_HP_SHARE:
		_heartbeat_in -= delta
		if _heartbeat_in <= 0.0:
			play("heartbeat")
			_heartbeat_in = HEARTBEAT_EVERY
	else:
		_heartbeat_in = 0.0


# --- Public hooks (called by main.gd) ----------------------------------------

func on_menu() -> void:
	fight_sim = null
	play_music("menu")


func on_aim_drag(pull: float) -> void:
	play("stretch", 0.0, 0.8 + clampf(pull, 0.0, 1.0) * 0.8)


func on_fight_start(sim) -> void:
	fight_sim = sim
	_was_overtime = false
	_heartbeat_in = 0.0
	_music.pitch_scale = 1.0
	play("go")
	play_music("fight")


func on_result(winner: int) -> void:
	fight_sim = null
	_music.pitch_scale = 1.0
	var jingle := "win" if winner == 0 else "lose"
	if is_inside_tree():
		get_tree().create_timer(0.45).timeout.connect(func(): play(jingle))
	play_music("menu")


## Turns one sim step's events into sound.
func consume_events(events: Array[Dictionary], sim) -> void:
	for e in events:
		match e.type:
			"collide":
				var a = sim.balls[e.a]
				var b = sim.balls[e.b]
				var avg_radius: float = (a.radius + b.radius) / 2.0
				play("hit", 0.0, clampf(64.0 / avg_radius, 0.7, 1.4))
			"damage":
				var target = sim.balls[e.target]
				if e.kind == "beam":
					play("sizzle")
				elif e.amount >= target.max_hp * BIG_HIT_SHARE:
					play("hit_big")
				if target.alive():
					play("ouch_" + target.def.ability)
			"heal":
				play("slurp")
				play("heal", 0.0, 1.0 + clampf(e.amount / 20.0, 0.0, 0.3))
			"bounce":
				play("wall", 0.0, 0.9 + _rng.randf() * 0.25)
			"beam":
				play("zap")
			"end":
				if e.reason != "time_limit":
					play("ko")
	if not _was_overtime and sim.in_overtime():
		_was_overtime = true
		play("overtime")
		_music.pitch_scale = 1.06


## Plays a sound (any variant) unless its cap or min gap says to skip it.
func play(name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if mode == "off" or not RULES.has(name) or _variants[name].is_empty():
		return
	var rule: Array = RULES[name]
	if _clock - float(_last_start.get(name, -1000.0)) < rule[1]:
		return
	var ends: Array = _ends.get(name, []).filter(func(t): return t > _clock)
	if ends.size() >= rule[0]:
		return
	var options: Array = _variants[name]
	var stream: AudioStream = options[_rng.randi() % options.size()]
	pitch *= _rng.randf_range(0.95, 1.05)
	ends.append(_clock + stream.get_length() / pitch)
	_ends[name] = ends
	_last_start[name] = _clock
	_start(stream, rule[2] + volume_db + _rng.randf_range(-1.5, 1.5), pitch)


## How many copies of a sound are playing now, by our own bookkeeping.
func playing_count(name: String) -> int:
	return _ends.get(name, []).filter(func(t): return t > _clock).size()


func play_music(track: String) -> void:
	if _music_track == track and (_music.playing or mode != "all"):
		return
	_music_track = track
	if mode != "all":
		_music.stop()
		return
	var info: Array = MUSIC[track]
	var stream = load(AUDIO_DIR + info[0] + ".ogg")
	if stream == null:
		return
	stream.loop = true
	_music.stream = stream
	_music.volume_db = info[1] + MASTER_DB
	if is_inside_tree():
		_music.play()


func sound_names() -> Array:
	return RULES.keys()


# --- Internals ----------------------------------------------------------------

func _start(stream: AudioStream, volume_db: float, pitch: float) -> void:
	if not is_inside_tree():
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db + MASTER_DB
	player.pitch_scale = pitch
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	# All busy: steal the one that has played longest.
	var oldest := _players[0]
	for p in _players:
		if p.get_playback_position() > oldest.get_playback_position():
			oldest = p
	oldest.stop()
	return oldest


func _load_variants(name: String) -> Array:
	var out := []
	var single := AUDIO_DIR + name + ".wav"
	if ResourceLoader.exists(single):
		out.append(load(single))
	var i := 0
	while ResourceLoader.exists("%s%s_%d.wav" % [AUDIO_DIR, name, i]):
		out.append(load("%s%s_%d.wav" % [AUDIO_DIR, name, i]))
		i += 1
	return out


func _apply_mode() -> void:
	# Everything plays on the Master bus: Godot 4.3's web build loses the route
	# to the speakers when buses are added at runtime, so the game goes silent.
	# Muting is done by not starting sounds instead.
	if mode == "off":
		for p in _players:
			p.stop()
	if mode == "all" and _music_track != "" and not _music.playing:
		var track := _music_track
		_music_track = ""
		play_music(track)
	elif mode != "all":
		_music.stop()
	if _toggle:
		_toggle.text = MODE_LABELS[mode]


func _cycle_mode() -> void:
	mode = MODES[(MODES.find(mode) + 1) % MODES.size()]
	_apply_mode()
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "mode", mode)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved: String = cfg.get_value("audio", "mode", "all")
		if saved in MODES:
			mode = saved
	_apply_mode()


func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.has_meta("silent"):
		node.pressed.connect(func(): play("click"))


# --- UI: mute toggle and sound board -------------------------------------------

func _build_toggle() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_toggle = Button.new()
	_toggle.set_meta("silent", true)
	_toggle.add_theme_font_size_override("font_size", 20)
	_toggle.text = MODE_LABELS[mode]
	_toggle.pressed.connect(func(): _cycle_mode(); play("click"))
	layer.add_child(_toggle)
	get_viewport().size_changed.connect(_place_toggle)
	_place_toggle()


func _place_toggle() -> void:
	var size := get_viewport().get_visible_rect().size
	_toggle.size = Vector2(170, 56)
	_toggle.position = Vector2(size.x - 182, size.y - 66 - toggle_lift)
	if _board:
		_board.size = size


## A page of every sound with a play button, for judging sounds on a phone.
## Opened with ?sounds=1 on the web build.
func show_board() -> void:
	if _board:
		_board.visible = true
		return
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_board = Panel.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.06, 0.1, 0.97)
	_board.add_theme_stylebox_override("panel", bg)
	layer.add_child(_board)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 20
	scroll.offset_top = 20
	scroll.offset_right = -20
	scroll.offset_bottom = -90
	_board.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var title := Label.new()
	title.text = "Sound board"
	title.add_theme_font_size_override("font_size", 34)
	grid.add_child(title)
	grid.add_child(Control.new())
	for track in MUSIC:
		grid.add_child(_board_button("Music: " + track, func(): _music_track = ""; play_music(track)))
	for name in RULES:
		for i in _variants[name].size():
			var label: String = name if _variants[name].size() == 1 else "%s %d" % [name, i + 1]
			grid.add_child(_board_button(label, _play_exact.bind(name, i)))
	var close := _board_button("Close", func(): _board.visible = false)
	close.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	close.offset_top = -80
	close.offset_bottom = -12
	close.offset_left = 20
	close.offset_right = -200
	_board.add_child(close)
	_place_toggle()


func _board_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.set_meta("silent", true)
	b.text = text
	b.custom_minimum_size = Vector2(0, 72)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(on_press)
	return b


func _play_exact(name: String, index: int) -> void:
	if mode == "off":
		mode = "sfx"
		_apply_mode()
	_start(_variants[name][index], RULES[name][2], 1.0)
