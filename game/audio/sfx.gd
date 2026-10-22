## The game's sound: fight effects from sim events, music, UI clicks and the
## mute toggle. Only reads the sim, never changes it, and uses its own random
## generator so replays stay identical. Sounds are rendered by
## tools/sfx/make_sfx.py; see /design/sound.md for the plan.
extends Node

const AUDIO_DIR := "res://game/audio/"
const Kit := preload("res://game/ui/ui_kit.gd")
const SETTINGS_PATH := "user://settings.cfg"
const VOICES := 16
## Sound modes the toggle cycles through.
const MODES := ["all", "sfx", "off"]
const MODE_LABELS := {"all": "Sound: On", "sfx": "Music: Off", "off": "Sound: Off"}
const FightLayout := preload("res://game/fight_layout.gd")
const TOGGLE_SIZE := FightLayout.PILL
## Per sound: [max playing at once, min seconds between starts, volume dB].
## Lower caps on frequent sounds keep the chaos readable.
## Pitch of the hit_big thud per pulse kind (sim pulse events), so each
## critter's pulse has its own voice.
const PULSE_PITCH := {"drum": 0.7, "wind": 1.6, "ink": 1.3, "stink": 0.9}
const RULES := {
	"hit": [3, 0.05, -2.0],
	"hit_big": [1, 0.25, 0.0],
	"wall": [2, 0.07, -15.0],
	"ouch_vampire": [1, 0.18, -7.0],
	"ouch_laser": [1, 0.18, -9.0],
	"ouch_magnet": [1, 0.18, -9.0],
	"flip": [1, 0.3, -14.0],
	"snap": [1, 0.2, -4.0],
	"crit": [1, 0.15, -5.0],
	"backstab": [1, 0.2, -4.0],
	"ko": [1, 0.5, 0.0],
	"heal": [1, 0.3, -10.0],
	"slurp": [1, 0.25, -8.0],
	"zap": [2, 0.08, -9.0],
	"sizzle": [2, 0.12, -10.0],
	"overtime": [1, 1.0, -6.0],
	"heartbeat": [1, 0.5, -6.0],
	"win": [1, 0.5, -3.0],
	"lose": [1, 0.5, -3.0],
	"draw": [1, 0.5, -3.0],
	"go": [1, 0.3, -5.0],
	"launch": [1, 0.1, -4.0],
	"stretch": [1, 0.07, -14.0],
	"click": [2, 0.04, -8.0],
	"summon_pop": [3, 0.05, -7.0],
	"summon_land": [3, 0.04, -9.0],
	"summon_charge": [1, 0.3, -8.0],
	"summon_legend": [1, 0.5, -3.0],
	"chomp": [1, 0.15, -3.0],
	"thwomp": [1, 0.2, -1.0],
	"pew": [2, 0.06, -6.0],
	"crackle": [2, 0.08, -6.0],
	"rustle": [1, 0.15, -5.0],
	"fizzpop": [1, 0.3, -4.0],
	"drum": [2, 0.08, -4.0],
	"rain": [1, 0.85, -12.0],
	"hum": [1, 0.5, -4.0],
	"ticktock": [1, 0.2, -4.0],
	"splash": [1, 0.3, -2.0],
	"shatter": [1, 0.2, -3.0],
	"clunk": [1, 0.12, -5.0],
	"glug": [1, 0.3, -5.0],
	"whoosh": [1, 0.3, -3.0],
	"buzz": [2, 0.12, -9.0],
	"puff": [1, 0.3, -5.0],
	"roar": [1, 0.5, -2.0],
	"cannon": [1, 0.2, -3.0],
	"splat": [2, 0.1, -6.0],
	"sonar": [1, 0.3, -8.0],
	"twinkle": [1, 0.3, -8.0],
	"zing": [2, 0.08, -7.0],
}
const Families := preload("res://sim/families.gd")
## Pitch of the edge-hit zing per attacking family, so each family's edge
## sounds its own; a very good hit goes a step higher still.
const ZING_PITCH := {"nature": 0.85, "sea": 0.8, "tech": 1.2, "sweet": 1.3, "frost": 1.35, "toybox": 1.1, "spooky": 0.7, "fire": 0.95, "cosmic": 1.05}
## Seconds between rain patters while one of Drizzle's showers is falling.
const RAIN_EVERY := 0.9
## Applied to every sound and the music so busy moments don't clip.
const MASTER_DB := -7.0
## Music per track: [file, volume dB, loops]. All are composed and rendered by
## tools/music/make_music.py at the same loudness, so these set the mix.
## The intro plays once when the game opens and hands over to the menu loop;
## overtime is the fight theme faster and a semitone up; victory loops past
## its 2-bar fanfare (VICTORY_LOOP_FROM) while the win screen is up.
const MUSIC := {
	"intro": ["music_intro", -10.0, false],
	"menu": ["music_menu", -11.0, true],
	"fight": ["music_fight", -11.0, true],
	"overtime": ["music_overtime", -10.0, true],
	"victory": ["music_victory", -9.0, true],
}
const VICTORY_LOOP_FROM := 8 * 60.0 / 124.0 ## 2 bars at 124 BPM.
## Seconds a track change fades over, so music never cuts with a click.
const MUSIC_FADE := 0.3
## After a win, how long the victory tune waits for a results popup to hold
## it (hold_victory) before the menu music takes over.
const VICTORY_GRACE := 1.6
## Contact damage at or above this share of the target's max HP is a "big hit".
const BIG_HIT_SHARE := 0.18
const LOW_HP_SHARE := 0.35
const HEARTBEAT_EVERY := 0.85

var mode := "all"
## Set while a fight is on screen, for the overtime cue and low-HP pulse.
var fight_sim
## The sim side the player is on (live matches put you on side 1 half the time).
var you_side := 0

var _variants := {} ## sound name -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _last_start := {} ## sound name -> seconds
var _ends := {} ## sound name -> end times of the copies started
var _music: AudioStreamPlayer ## The current track.
var _music_out: AudioStreamPlayer ## The previous track while it fades out.
var _music_track := ""
var _fade: Tween
## The intro plays once per app launch, not every time a screen opens.
static var _intro_played := false
## Web: browsers start audio on the first tap, so the intro waits for it.
static var _audio_unlocked := false
var _victory_hold: WeakRef ## The results popup the victory tune plays under.
var _victory_at := 0.0
var _menu_pending := false
var _was_overtime := false
var _heartbeat_in := 0.0
var _rain_in := 0.0
var _drum_beat := 0 ## Alternates Drum's wall taps between two pitches.
var _rng := RandomNumberGenerator.new() ## Render-side only: never the sim's.
var _clock := 0.0
var _toggle: Button
## Hide the corner toggle, e.g. on the home screens, where the settings sheet
## has the same switch and the corner would sit on top of screen buttons.
var toggle_hidden := false:
	set(v):
		toggle_hidden = v
		if _toggle:
			_toggle.visible = not toggle_hidden
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
	_music_out = AudioStreamPlayer.new()
	add_child(_music_out)
	for p in [_music, _music_out]:
		p.finished.connect(_on_music_finished.bind(p))
	if not OS.has_feature("web"):
		_audio_unlocked = true
	_load_settings()


func _ready() -> void:
	_build_toggle()
	get_tree().node_added.connect(_on_node_added)
	if OS.has_feature("web") and "sounds=1" in str(JavaScriptBridge.eval("window.location.search", true)):
		show_board.call_deferred()


## Native apps: no sound while the app is in the background (the web build
## suspends its audio from game/web/shell.html when the page is hidden).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_RESUMED:
		AudioServer.set_bus_mute(0, what == NOTIFICATION_APPLICATION_PAUSED)


func _input(event: InputEvent) -> void:
	if _audio_unlocked or not (event is InputEventMouseButton or event is InputEventScreenTouch) or not event.pressed:
		return
	_audio_unlocked = true
	if _music_track == "intro" and mode == "all" and not _music.playing:
		_start_music("intro")


func _process(delta: float) -> void:
	_clock += delta
	if _music_track == "victory" and (_menu_pending or _victory_hold != null):
		var hold: Control = _victory_hold.get_ref() if _victory_hold else null
		var held := hold != null and _shown(hold)
		if not held and (_victory_hold != null or _clock - _victory_at > VICTORY_GRACE):
			_menu_pending = false
			_victory_hold = null
			play_music("menu")
	if fight_sim == null or fight_sim.finished:
		return
	_rain_in -= delta
	if _rain_in <= 0.0:
		for z in fight_sim.zones:
			if z.kind == "rain" and z.armed():
				play("rain")
				_rain_in = RAIN_EVERY
				break
	var you = fight_sim.balls[you_side]
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
	if _music_track == "victory": # Hand over once the win screen is gone (_process).
		_menu_pending = true
		return
	play_music("menu")


## Whether a popup is still up: attached and not hidden by its parents.
static func _shown(node: Node) -> bool:
	if node.get_parent() == null:
		return false
	while node is CanvasItem:
		if not node.visible:
			return false
		node = node.get_parent()
	return true


## Keeps the victory tune playing while this popup (a win's results) is up;
## the menu music takes over once it closes.
func hold_victory(popup: Control) -> void:
	if _music_track == "victory":
		_victory_hold = weakref(popup)


func on_aim_drag(pull: float) -> void:
	play("stretch", 0.0, 0.8 + clampf(pull, 0.0, 1.0) * 0.8)


func on_fight_start(sim) -> void:
	fight_sim = sim
	_was_overtime = false
	_heartbeat_in = 0.0
	_menu_pending = false
	play("go")
	play_music("fight")


func on_result(winner: int) -> void:
	fight_sim = null
	_menu_pending = false
	_victory_hold = null
	if winner == 0 and mode == "all": # The victory fanfare is the win jingle.
		_victory_at = _clock
		play_music("victory")
		return
	var jingle := "draw" if winner < 0 else ("win" if winner == 0 else "lose")
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
				if e.get("backstab", false):
					play("backstab")
				if e.get("crit", false):
					play("crit", 0.0, 1.0 if e.kind == "contact" else 1.25)
				var src: String = sim.balls[e.source].type_id if e.get("source", -1) >= 0 and e.source < sim.balls.size() else ""
				var edge: int = e.get("edge", 0)
				if edge > 0 and src != "": # The family edge rings over the hit.
					play("zing", 0.0 if edge == 2 else -3.0, ZING_PITCH.get(Families.of(src), 1.0) * (1.26 if edge == 2 else 1.0))
				if e.kind == "beam":
					play("sizzle")
				elif src == "juggernaut" and e.kind in ["contact", "slam"]: # Boulder.
					play("thwomp", 0.0, 1.0 if e.kind == "contact" else 0.85)
				elif e.amount >= target.max_hp * BIG_HIT_SHARE:
					play("hit_big")
				if src in ["vampire", "munch"] and e.kind == "contact": # Count Nibbles and Munch bite.
					play("chomp", 0.0, 1.0 if src == "vampire" else 0.85)
				elif src == "zapper" and e.kind == "zap": # Its coil arc.
					play("crackle", 0.0, 1.0)
				elif src == "swarm" and e.kind != "contact": # A bee sting.
					play("buzz", 0.0, 1.0 + _rng.randf() * 0.2)
				elif src == "mammoth" and e.kind == "contact": # A heavy shove.
					play("thwomp", -3.0, 1.15)
				elif src == "glowbug" and e.kind != "contact": # Its light-bug's sting.
					play("crackle", -4.0, 1.5)
				# Each critter file names its ouch voice and pitch, so new critters
				# reuse the existing chirps.
				if target.alive() and target.def.ouch != "":
					play(target.def.ouch, 0.0, target.def.voice_pitch)
			"heal":
				play("slurp")
				play("heal", 0.0, 1.0 + clampf(e.amount / 20.0, 0.0, 0.3))
			"bounce":
				play("wall", 0.0, 0.9 + _rng.randf() * 0.25)
				if e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "drum": # A little beat off the walls.
					_drum_beat += 1
					play("drum", -6.0, 1.5 if _drum_beat % 2 else 1.2)
			"beam":
				var who: String = sim.balls[e.owner].type_id if e.get("owner", -1) >= 0 and e.owner < sim.balls.size() else ""
				if who == "comet": # A shooting star.
					play("twinkle")
				elif who == "zigzag": # Its path turning to lightning.
					play("crackle", -3.0, 1.2)
				elif who == "drako":
					pass # The breath already roared.
				else:
					play("zap")
			"flip":
				play("flip", 0.0, 1.0 if e.pulling else 0.85)
			"snap":
				play("snap")
			"boom", "pulse":
				var kind: String = e.get("kind", "")
				if kind in ["zap", "bigzap"]:
					play("crackle", 0.0, 1.15 if kind == "zap" else 0.8)
				elif kind == "drum":
					play("drum", 0.0, 0.9)
				elif kind == "dirt": # Mole bursting up.
					play("thwomp", 0.0, 1.2)
				elif kind == "flame": # Flicker relighting.
					play("sizzle", 0.0, 0.8)
				elif kind == "sour":
					play("slurp", 0.0, 1.4)
				elif kind == "tick": # Clockwork's tick ring.
					play("ticktock")
				elif kind == "wave": # Leviathan bursting up.
					play("splash")
				elif kind == "tide": # Ripple's T5 wave.
					play("splash", -2.0, 1.2)
				elif kind == "sunfire": # Phoenix T5 sunfire.
					play("whoosh", 0.0, 0.8)
					play("sizzle", -2.0, 1.2)
				elif kind == "honey": # Honey's T5 sting.
					play("buzz", 0.0, 1.3)
				elif kind == "ping": # Sonar's ping.
					play("sonar")
				elif kind == "paint": # Painter's paint drying.
					play("splat", 0.0, 0.9 + _rng.randf() * 0.2)
				elif kind == "wind": # Gust's huff.
					play("whoosh", 0.0, 1.4)
				elif kind == "stink": # Whiff's cloud blooming.
					play("puff", 0.0, 0.9)
				elif kind == "candy": # Jawbreaker's sugar blast.
					play("crit", -3.0, 1.4)
					play("hit_big", -4.0, 1.2)
				elif kind == "quasar":
					play("hum")
				else:
					play("hit_big", 0.0, 0.8 if e.type == "boom" else PULSE_PITCH.get(kind, 1.1))
			"reflect":
				play("hit", -4.0, 1.5)
			"ricochet": # A Ricochet Core's boosted bump.
				play("snap", -3.0, 1.3)
			"spike": # Spike Yard: a sharp, high snap.
				play("snap", -2.0, 1.7)
			"lava":
				play("sizzle", -6.0, 0.8)
			"portal":
				play("flip", 0.0, 1.6)
			"shot":
				if e.kind == "pea":
					play("pew")
				elif e.kind == "blob" and e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "brewster":
					play("glug", 0.0, 0.95 + _rng.randf() * 0.15)
				elif e.kind == "pearl":
					play("pew", 0.0, 0.7)
				elif e.kind == "shell" and e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "mortar":
					play("cannon", 0.0, 0.95 + _rng.randf() * 0.1)
				elif e.kind == "stinger":
					play("buzz", -2.0, 1.5)
				else:
					play("launch", -6.0, 1.8 if e.kind != "shell" and e.kind != "blob" else 0.9)
			"shut": # Clam clamping shut.
				play("clunk", 0.0, 1.3)
			"salvo", "mega":
				play("snap", 0.0, 0.7)
			"phase":
				play("flip", 0.0, 1.4)
			"ambush", "copy":
				play("snap", 0.0, 1.25)
			"revive":
				play("heal", 0.0, 0.8)
			"honey_lob": # Honey T5 lobbing a glob.
				play("glug", 0.0, 1.3)
			"heard": # Sonar T5 locking on.
				play("sonar", 0.0, 1.3)
			"split": # Splitter tearing in two: a gooey stretch and a pop.
				play("stretch", 0.0, 0.7)
				play("slurp", -3.0, 1.3)
			"grow": # Grow and shrink (Puff, Crumb, Tumble): higher when shrinking.
				if e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "tumble" and e.bigger:
					play("rustle", 0.0, 0.9 + 0.05 * int(sim.balls[e.ball].state.get("twigs", 0)))
				else:
					play("flip", -3.0, 0.75 if e.bigger else 1.6)
			"chomp": # Fin's big bite.
				play("chomp", 0.0, 0.8)
				play("hit_big", -3.0, 0.9)
			"unwind":
				play("snap", 0.0, 0.8)
			"pop":
				if e.ball < sim.balls.size() and sim.balls[e.ball].type_id == "fizz":
					play("fizzpop")
				else:
					play("flip", 0.0, 1.8)
			"stun":
				play("zap", 0.0, 0.6)
			"wrap":
				play("stretch", 0.0, 1.3)
			"spike_burst":
				play("pew", 0.0, 0.8)
				play("pew", -4.0, 1.1)
			"relight":
				play("hit_big", -4.0, 0.7)
			"wrap_pop":
				play("snap", 0.0, 1.4)
			"shatter": # Frostfang breaking the ice.
				play("shatter")
				play("hit_big", -4.0, 0.9)
			"storm": # Thunderbird's storm: a big electric crack.
				play("crackle", 0.0, 0.7)
				play("sizzle", -4.0, 0.8)
			"stack": # Stacks and forms: a rising tick per stack.
				if e.up:
					play("flip", -6.0, 1.1 + 0.08 * e.stacks)
			"burp":
				play("hit_big", 0.0, 0.7)
			"roar":
				play("roar")
				play("hit_big", -4.0, 0.7)
			"breath": # Drako's fire.
				play("whoosh")
			"shout":
				play("snap", 0.0, 0.75)
			"mode":
				play("flip", -2.0, 1.3)
			"bubble", "bubble_pop":
				play("flip", -4.0 if e.type == "bubble" else 0.0, 2.0)
			"launch":
				play("zap", -4.0, 1.6)
			"yoyo", "fling":
				play("stretch", 0.0, 1.3 if e.type == "yoyo" else 1.6)
			"hug":
				play("flip", 0.0, 0.9)
			"dive": # Leviathan plunging under.
				play("splash", -4.0, 1.4)
			"orb_lost":
				play("click", 0.0, 1.4)
			# Movement critters (batch F) reuse the existing sounds at new pitches.
			"teleport":
				play("zap", 0.0, 1.5)
			"charge":
				play("launch", -3.0, 1.2)
			"tether", "yank":
				play("stretch", 0.0, 0.8 if e.type == "tether" else (0.9 if e.get("big", false) else 1.2))
			"tether_end", "bow":
				play("click", 0.0, 0.7)
			"mark":
				play("click", 0.0, 1.6)
			"pounce", "lance", "ping_crit", "gear_slam", "tilt":
				play("snap", 0.0, 1.1)
				if e.type == "gear_slam":
					play("clunk", 0.0, 0.7)
			"ding":
				play("click", 0.0, 1.3 + 0.1 * e.lit)
			"gear": # Gearbox shifting up, a little higher each gear.
				play("clunk", -3.0, 0.8 + 0.15 * e.gear)
			"dig":
				play("flip", 0.0, 0.6)
			"clod":
				play("hit", -6.0, 0.7)
			# Batch H set pieces reuse existing sounds at their own pitch.
			"piece":
				if e.kind == "vine": # Ivy's vine sprouting: grassy.
					play("rustle", -2.0, 1.3)
				elif e.kind == "seed": # Sprout's sapling popping up.
					play("rustle", -3.0, 1.6)
				elif e.kind != "illusion":
					play("wall", -3.0, 0.7)
			"rays":
				if e.kind == "shard": # Glacia's ice shards.
					play("shatter", -3.0, 1.3)
				else:
					play("zap", -2.0, 1.4 if e.kind == "disco" else 1.15)
			"lash": # Ivy's vine: a leafy rustle and a whip.
				play("rustle", 0.0, 1.1)
				play("snap", -6.0, 0.9)
			"root": # Old Oak taking root: creaking wood and a heavy thud.
				play("rustle", 0.0, 0.6)
				play("thwomp", -3.0, 0.8)
			"rewind":
				play("ticktock", 0.0, 1.3)
				play("flip", -4.0, 0.7)
			"illusions", "swap":
				play("flip", 0.0, 1.3)
			"spin":
				play("crit", 0.0, 1.3 if e.prizes.size() > 1 else 1.1)
			"end":
				if e.reason != "time_limit":
					play("ko")
	if not _was_overtime and sim.in_overtime():
		_was_overtime = true
		play("overtime")
		play_music("overtime")


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
	if track == "menu" and _music_track == "intro":
		return # The intro hands over to the menu loop when it ends.
	if track == "menu" and not _intro_played:
		_intro_played = true
		track = "intro"
	if _music_track == track and (_music.playing or mode != "all"):
		return
	_music_track = track
	if mode != "all":
		_stop_music()
		return
	if track == "intro" and not _audio_unlocked:
		return # Starts on the first tap (_input).
	_start_music(track)


func _start_music(track: String) -> void:
	var info: Array = MUSIC[track]
	var stream = load(AUDIO_DIR + info[0] + ".ogg")
	if stream == null or not is_inside_tree():
		return
	stream.loop = info[2]
	stream.loop_offset = VICTORY_LOOP_FROM if track == "victory" else 0.0
	if _fade:
		_fade.kill()
	_music_out.stop()
	if _music.playing: # Fade the old track out on the spare player.
		var old := _music
		_music = _music_out
		_music_out = old
		_fade = create_tween()
		_fade.tween_property(old, "volume_db", old.volume_db - 40.0, MUSIC_FADE)
		_fade.tween_callback(old.stop)
	_music.stream = stream
	_music.volume_db = info[1] + MASTER_DB
	_music.play()


func _stop_music() -> void:
	if _fade:
		_fade.kill()
	_music.stop()
	_music_out.stop()


func _on_music_finished(player: AudioStreamPlayer) -> void:
	if player == _music and _music_track == "intro":
		_music_track = ""
		play_music("menu")


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
		_stop_music()
	if _toggle:
		_toggle.text = MODE_LABELS[mode]


## Next sound mode: all, effects only, off. Saved for next time.
func cycle_mode() -> void:
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
	# A small ghost pill in the kit's style, in the bottom-right corner.
	_toggle = Kit.button(MODE_LABELS[mode], func(): cycle_mode(); play("click"), "ghost", 20, TOGGLE_SIZE.y)
	_toggle.text = MODE_LABELS[mode]
	_toggle.set_meta("silent", true)
	_toggle.clip_text = true
	_toggle.add_theme_font_override("font", Kit.FONT)
	layer.add_child(_toggle)
	get_viewport().size_changed.connect(_place_toggle)
	_place_toggle()


func _place_toggle() -> void:
	var size := get_viewport().get_visible_rect().size
	_toggle.size = TOGGLE_SIZE
	_toggle.position = FightLayout.pill_position(size, 1) # Right of a fight's Speed and Skip pills.
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
		grid.add_child(_board_button("Music: " + track, func(): _music_track = track; _start_music(track)))
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
