## Ball Royale: you and 7 bots in one arena, every ball for itself, last ball
## standing (sim/royale.gd, design/ball-royale.md in the project files). Aim
## your launch, watch the free-for-all with a KO feed, then see where you
## placed. Everyone fights at equal power, so it is an event mode: no trophies.
## URL params: ?mode=royale&seed=42&p1=laser&aim=-450&auto=1&speed=4
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const Royale := preload("res://sim/royale.gd")
const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const A11y := preload("res://game/a11y.gd")
const Main := preload("res://game/main.gd")

enum State { AIM, FIGHT, RESULT }

const SAVE_PATH := "user://royale.cfg"
const ARENA_PIXELS := 680.0
const PANEL_HEIGHT := 400.0
const SPEEDS := [1.0, 2.0, 4.0]
const FEED_LINES := 3
const YOU_COLOR := Color("45f5a6")
const FOE_COLOR := Color("ff5a7a")

## The critter you bring; set by the Play tab card before changing scene.
static var critter := ""
## URL params apply to the first royale only, so Play again gets a new seed.
static var _url_used := false

var state := State.AIM
var seed_value := 1
var lineup: Array = [] ## 8 critter ids, yours first.
var aim := 0 ## Tenths of a degree, screen space.
var sim: Royale
var speed_index := 0
var feed: Array[String] = []
var stats := {"played": 0, "wins": 0, "best": 0, "kos": 0}

var _accumulator := 0.0
var _dragging := false
var _auto := false
var _save := ConfigFile.new()

var arena: ArenaView
var sfx: Sfx
var title_label: Label
var hud_label: Label
var info_label: Label
var panel: VBoxContainer


func _ready() -> void:
	var params := {} if _url_used else _url_params()
	_url_used = true
	var rng := RandomNumberGenerator.new() # UI-only: picks a fresh seed, never used by the sim.
	rng.randomize()
	seed_value = int(params.seed) if params.get("seed", "").is_valid_int() else rng.randi_range(1, 99999)
	var mine := critter
	critter = ""
	if params.get("p1", "") in BallDefs.PLAYABLE:
		mine = params.p1
	if not mine in BallDefs.PLAYABLE:
		mine = BallDefs.PLAYABLE[0]
	lineup = lineup_for(mine, seed_value)
	aim = Royale.aim_at_centre(0)
	if params.get("aim", "").is_valid_int():
		aim = int(params.aim)
	if params.get("speed", "").is_valid_int():
		speed_index = maxi(0, SPEEDS.find(float(params.speed)))
	_auto = params.get("auto", "") == "1"
	stats = load_stats(_save)

	arena = ArenaView.new()
	arena.team_tags = tags()
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	print("ROYALE_READY seed=%d lineup=%s" % [seed_value, ",".join(lineup)])
	_begin_aim()
	if _auto:
		_launch()


## Your critter in seat 0, then 7 bots drawn from the seed. Equal power: every
## playable critter can turn up, duplicates included.
static func lineup_for(mine: String, seed_value: int) -> Array:
	var rng := Rng.new(seed_value ^ 0x5EA7)
	var out := [mine]
	for i in Royale.SIZE - 1:
		out.append(BallDefs.PLAYABLE[rng.range_int(0, BallDefs.PLAYABLE.size() - 1)])
	return out


## Tags under the balls: YOU, then seat numbers so duplicates stay apart.
static func tags() -> Array:
	var t := ["YOU"]
	for i in range(1, Royale.SIZE):
		t.append("#%d" % (i + 1))
	return t


static func ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
	return "%d%s" % [n, suffix]


static func load_stats(file: ConfigFile) -> Dictionary:
	var s := {"played": 0, "wins": 0, "best": 0, "kos": 0}
	if file.load(SAVE_PATH) == OK:
		for k in s:
			s[k] = int(file.get_value("royale", k, 0))
	return s


## One line for the Play tab card, e.g. "Best 2nd · 1 win".
static func stats_line() -> String:
	var s := load_stats(ConfigFile.new())
	if s.played == 0:
		return "Equal power · 8 balls · last one standing"
	return "Best %s · %d win%s · %d KOs" % [ordinal(s.best), s.wins, "" if s.wins == 1 else "s", s.kos]


func _process(delta: float) -> void:
	if state == State.FIGHT:
		_accumulator += delta * SPEEDS[speed_index]
		var steps := 0
		while _accumulator >= MatchSim.DT and steps < 32 and not sim.finished:
			_step()
			_accumulator -= MatchSim.DT
			steps += 1
		if sim.finished:
			_show_result()
	if arena:
		arena.advance_effects(delta * (SPEEDS[speed_index] if state == State.FIGHT else 1.0))
		_update_hud()


func _step() -> void:
	sim.step()
	arena.consume_events(sim.events)
	sfx.consume_events(sim.events, sim)
	for e in sim.events:
		if e.type == "ko":
			_on_ko(e)


func _unhandled_input(event: InputEvent) -> void:
	if state != State.AIM:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_aim_towards(event.position)
		elif _dragging:
			_dragging = false
			_aim_towards(event.position)
			_launch()
	elif event is InputEventMouseMotion and _dragging:
		_aim_towards(event.position)


func _aim_towards(screen_pos: Vector2) -> void:
	var dir := arena.to_world(screen_pos) - sim.balls[0].pos
	if dir.length() < 10.0:
		return
	aim = roundi(rad_to_deg(dir.angle()) * 10.0)
	sfx.on_aim_drag(dir.length() / 600.0)
	_preview()


func _config() -> Dictionary:
	var angles: Array = [aim]
	angles.resize(Royale.SIZE)
	return {"seed": seed_value, "critters": lineup, "angles": angles}


# --- Flow -------------------------------------------------------------------

func _begin_aim() -> void:
	state = State.AIM
	sfx.on_menu()
	_preview()
	info_label.text = "You bring %s. Seven bots, one arena, last ball standing. Drag on the arena to aim, let go to launch." % BallDefs.get_def(lineup[0]).display_name
	_set_panel([_button("Launch", _launch, 36), _button("Back", _home, 26)])


func _preview() -> void:
	sim = Royale.new(_config())
	arena.sim = sim
	arena.clear_effects()
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))


func _launch() -> void:
	sfx.play("launch")
	sim = Royale.new(_config())
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	feed.clear()
	state = State.FIGHT
	info_label.text = "Last ball standing wins!"
	var speed := _button("Speed %dx" % int(SPEEDS[speed_index]), Callable())
	speed.pressed.connect(func():
		speed_index = (speed_index + 1) % SPEEDS.size()
		speed.text = "Speed %dx" % int(SPEEDS[speed_index]))
	_set_panel([_row([speed, _button("Skip", _skip)])])
	sfx.on_fight_start(sim)
	print("ROYALE_START seed=%d aim=%d" % [seed_value, aim])


## Runs to the end without sound or effects; the KO feed still fills in.
func _skip() -> void:
	while not sim.finished:
		sim.step()
		for e in sim.events:
			if e.type == "ko":
				_on_ko(e, false)
	arena.clear_effects()


func _on_ko(e: Dictionary, loud := true) -> void:
	if loud:
		sfx.play("ko")
	var victim := _name(e.ball)
	var line := "%s is out" % victim if e.by < 0 else "%s KO'd %s" % [_name(e.by), victim]
	if e.ball == 0:
		line += " · %s place" % ordinal(e.place)
	feed.append(line)
	while feed.size() > FEED_LINES:
		feed.pop_front()
	info_label.text = "\n".join(feed)


func _name(i: int) -> String:
	return "YOU" if i == 0 else "%s %s" % [BallDefs.get_def(lineup[i]).display_name, tags()[i]]


func _show_result() -> void:
	state = State.RESULT
	var place := sim.place_of(0)
	var won := place == 1
	stats.played += 1
	stats.wins += 1 if won else 0
	stats.best = place if stats.best == 0 else mini(stats.best, place)
	stats.kos += sim.kos[0]
	for k in stats:
		_save.set_value("royale", k, stats[k])
	_save.save(SAVE_PATH)
	sfx.on_result(0 if won else 1)
	title_label.text = "LAST BALL STANDING!" if won else "%s OF 8" % ordinal(place).to_upper()
	title_label.modulate = YOU_COLOR if won else Color.WHITE
	info_label.text = "You placed %s with %d KO%s. Best so far: %s." % [ordinal(place), sim.kos[0], "" if sim.kos[0] == 1 else "s", ordinal(stats.best)]
	var board := GridContainer.new()
	board.columns = 3
	board.add_theme_constant_override("h_separation", 18)
	board.add_theme_constant_override("v_separation", 2)
	for p in sim.placings.size():
		var i: int = sim.placings[p]
		var col := YOU_COLOR if i == 0 else Color("e6e3ff")
		var name_label := _cell(_name(i), col, HORIZONTAL_ALIGNMENT_LEFT)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		board.add_child(_cell(ordinal(p + 1), col, HORIZONTAL_ALIGNMENT_RIGHT))
		board.add_child(name_label)
		board.add_child(_cell("%d KO" % sim.kos[i], col, HORIZONTAL_ALIGNMENT_RIGHT))
	_set_panel([board, _row([_button("Play again", _again, 30), _button("Home", _home, 30)])])
	print("ROYALE_END place=%d winner=%d reason=%s ticks=%d hash=%s" % [place, sim.winner, sim.end_reason, sim.tick, sim.state_hash()])


func _again() -> void:
	critter = lineup[0]
	get_tree().reload_current_scene()


func _home() -> void:
	get_tree().change_scene_to_file("res://game/main.tscn")


# --- UI ---------------------------------------------------------------------

func _update_hud() -> void:
	if sim == null:
		return
	if state == State.AIM:
		hud_label.text = "8 balls · equal power"
		return
	var you := "%d HP" % maxi(0, ceili(sim.balls[0].hp)) if sim.balls[0].alive() else "out in %s" % ordinal(sim.place_of(0))
	hud_label.text = "%d left · You %s · %d KO%s · %d:%02d" % [sim.alive_count(), you, sim.kos[0], "" if sim.kos[0] == 1 else "s", int(sim.time()) / 60, int(sim.time()) % 60]


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Main._neon_theme()
	layer.add_child(ui)
	title_label = _label("BALL ROYALE", 48)
	title_label.add_theme_color_override("font_outline_color", Color(Main.ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	hud_label = _label("", 26)
	info_label = _label("", 24)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	for c in [title_label, hud_label, info_label, panel]:
		ui.add_child(c)


## Same shape as the Ghost Arena: portrait stacks the arena over the panel,
## wide screens put the panel beside it.
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var top := 160.0
	var bottom_margin := 40.0
	var panel_width := 680.0
	var side: float
	var left: float
	var panel_pos: Vector2
	if size.x >= size.y:
		side = minf(size.y - top - bottom_margin, size.x - panel_width - 100.0)
		left = maxf(20.0, (size.x - side - panel_width - 40.0) / 2.0)
		panel_pos = Vector2(left + side + 40.0, top)
	else:
		side = clampf(size.y - top - 100.0 - PANEL_HEIGHT - bottom_margin, 300.0, minf(ARENA_PIXELS, size.x - 40.0))
		left = (size.x - side) / 2.0
		panel_width = maxf(side, minf(ARENA_PIXELS, size.x - 40.0))
		panel_pos = Vector2((size.x - panel_width) / 2.0, top + side + 16.0)
	arena.view_scale = side / MatchSim.ARENA_SIZE
	arena.position = Vector2(left, top)
	_place(title_label, Vector2(0, 30), Vector2(size.x, 60))
	_place(hud_label, Vector2(0, 100), Vector2(size.x, 44))
	_place(info_label, panel_pos, Vector2(panel_width, 100))
	_place(panel, panel_pos + Vector2(0, 108), Vector2(panel_width, PANEL_HEIGHT - 60.0))
	arena.queue_redraw()


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _set_panel(children: Array) -> void:
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()
	for c in children:
		panel.add_child(c)


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", A11y.font(font_size))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _cell(text: String, color: Color, align: HorizontalAlignment) -> Label:
	var l := _label(text, 22)
	l.horizontal_alignment = align
	l.modulate = color
	return l


func _button(text: String, on_press: Callable, font_size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", A11y.font(font_size))
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


func _row(children: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for c in children:
		row.add_child(c)
	return row


func _url_params() -> Dictionary:
	var params := {}
	if not OS.has_feature("web"):
		return params
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	return params
