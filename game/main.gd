## Game flow: pick balls -> aim -> watch the fight -> result.
## URL params on the web build skip straight to a fight, e.g.
## ?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const ArenaView := preload("res://game/arena_view.gd")

enum State { MENU, AIM, FIGHT, RESULT }

const VERSION := "0.1.0"
const ARENA_PIXELS := 680.0
const SPEEDS := [1.0, 2.0, 4.0, 0.5]
const OPPONENT_RANDOM := "random"

var state := State.MENU
var sim: MatchSim
var player_type := "vampire"
var opponent_choice := OPPONENT_RANDOM
var opponent_type := "laser"
var seed_value := 1
var aim := -450 ## Player launch angle, tenths of a degree.
var speed_index := 0
var auto_start := false

var _accumulator := 0.0
var _dragging := false
var _rng := RandomNumberGenerator.new() ## UI-only randomness (new seeds), never used by the sim.

var arena: ArenaView
var ui: Control
var title_label: Label
var hud_label: Label
var info_label: Label
var stamp_label: Label
var menu_box: VBoxContainer
var player_buttons := {}
var opponent_buttons := {}
var seed_label: Label
var fight_box: HBoxContainer
var speed_button: Button
var aim_box: HBoxContainer
var result_box: VBoxContainer
var result_label: Label
var report_label: Label


func _ready() -> void:
	_rng.randomize()
	seed_value = _rng.randi_range(1, 99999)
	_read_url_params()
	arena = ArenaView.new()
	add_child(arena)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	print("BOOT_OK build=", _build_stamp())
	if auto_start:
		_start_fight()
	else:
		_show_menu()


func _process(delta: float) -> void:
	if state == State.FIGHT:
		_accumulator += delta * SPEEDS[speed_index]
		# Cap catch-up so a slow frame can't freeze the page.
		var steps := 0
		while _accumulator >= MatchSim.DT and steps < 32 and not sim.finished:
			sim.step()
			arena.consume_events(sim.events)
			_accumulator -= MatchSim.DT
			steps += 1
		if sim.finished:
			_show_result()
	arena.advance_effects(delta * (SPEEDS[speed_index] if state == State.FIGHT else 1.0))
	_update_hud()


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
	_set_aim_preview()


func _set_aim_preview() -> void:
	sim = MatchSim.new(_config())
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))


# --- Flow -------------------------------------------------------------------

func _config() -> Dictionary:
	return {"seed": seed_value, "p1": player_type, "p2": opponent_type, "angles": [aim, null]}


func _show_menu() -> void:
	state = State.MENU
	sim = null
	arena.sim = null
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_refresh_menu()
	_show_only(menu_box)


func _refresh_menu() -> void:
	for id in player_buttons:
		player_buttons[id].button_pressed = id == player_type
	for id in opponent_buttons:
		opponent_buttons[id].button_pressed = id == opponent_choice
	seed_label.text = "Seed %d" % seed_value
	var def := BallDefs.get_def(player_type)
	info_label.text = "%s: %s" % [def.display_name, def.description]
	arena.preview_types = [player_type, _pick_opponent()]
	arena.queue_redraw()


func _begin_aim() -> void:
	opponent_type = _pick_opponent()
	state = State.AIM
	aim = MatchSim.AIM_AT_CENTRE[0]
	arena.clear_effects()
	_set_aim_preview()
	info_label.text = "Drag on the arena to aim your %s, then let go to launch." % BallDefs.get_def(player_type).display_name
	_show_only(aim_box)


func _pick_opponent() -> String:
	if opponent_choice != OPPONENT_RANDOM:
		return opponent_choice
	# Derived from the seed so a seed always means the same matchup.
	return BallDefs.PLAYABLE[seed_value % BallDefs.PLAYABLE.size()]


func _launch() -> void:
	_start_fight()


## Starts (or replays) the fight described by the current config.
func _start_fight() -> void:
	sim = MatchSim.new(_config())
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	state = State.FIGHT
	info_label.text = "%s vs %s" % [BallDefs.get_def(player_type).display_name, BallDefs.get_def(opponent_type).display_name]
	speed_button.text = "Speed %sx" % _speed_text()
	_show_only(fight_box)
	print("FIGHT_START ", _report_code())


func _show_result() -> void:
	state = State.RESULT
	var you := sim.balls[0]
	var text := "DRAW"
	if sim.winner == 0:
		text = "YOU WIN!"
	elif sim.winner == 1:
		text = "YOU LOSE"
	result_label.text = text
	info_label.text = "%.1fs. You dealt %d damage%s." % [sim.time(), roundi(you.damage_dealt),
		(" and healed %d" % roundi(you.healed)) if you.healed > 0.0 else ""]
	report_label.text = "Report code: " + _report_code()
	print("MATCH_END winner=%d reason=%s ticks=%d hash=%s" % [sim.winner, sim.end_reason, sim.tick, sim.state_hash()])
	_show_only(result_box)


func _report_code() -> String:
	return "BB1.%s.%s.%d.%d.%s" % [player_type, opponent_type, seed_value, aim, _build_stamp().replace(" ", "")]


# --- UI ---------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 30
	ui.theme = theme
	layer.add_child(ui)

	title_label = _label("BATTLE BALLS", 44)
	hud_label = _label("", 30)
	info_label = _label("", 26)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stamp_label = _label(_build_stamp(), 18)
	stamp_label.modulate = Color(1, 1, 1, 0.45)
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 14)
	menu_box.add_child(_label("Your ball", 26))
	menu_box.add_child(_choice_row(BallDefs.PLAYABLE, player_buttons, func(id): player_type = id; _refresh_menu()))
	menu_box.add_child(_label("Opponent", 26))
	menu_box.add_child(_choice_row(BallDefs.PLAYABLE + [OPPONENT_RANDOM], opponent_buttons, func(id): opponent_choice = id; _refresh_menu()))
	var seed_row := HBoxContainer.new()
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seed_row.add_theme_constant_override("separation", 20)
	seed_label = _label("", 26)
	seed_row.add_child(seed_label)
	seed_row.add_child(_button("New seed", func(): seed_value = _rng.randi_range(1, 99999); _refresh_menu()))
	menu_box.add_child(seed_row)
	menu_box.add_child(_button("FIGHT!", _begin_aim, 40))

	aim_box = _row([
		_button("Launch", _launch),
		_button("Back", _show_menu),
	])

	speed_button = _button("Speed 1x", _cycle_speed)
	fight_box = _row([speed_button, _button("Skip to end", _skip_to_end)])

	result_box = VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	result_label = _label("", 56)
	result_box.add_child(result_label)
	report_label = _label("", 20)
	report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(report_label)
	result_box.add_child(_row([
		_button("Replay", func(): _start_fight()),
		_button("Rematch", _rematch),
	]))
	result_box.add_child(_row([
		_button("Copy report", func(): DisplayServer.clipboard_set(_report_code()); report_label.text = "Copied: " + _report_code()),
		_button("Change balls", _show_menu),
	]))

	for c in [title_label, hud_label, info_label, stamp_label, menu_box, aim_box, fight_box, result_box]:
		ui.add_child(c)


func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var side := minf(ARENA_PIXELS, size.x - 40.0)
	var left := (size.x - side) / 2.0
	var top := 190.0
	arena.view_scale = side / MatchSim.ARENA_SIZE
	arena.position = Vector2(left, top)
	_place(title_label, Vector2(0, 30), Vector2(size.x, 60))
	_place(hud_label, Vector2(left, 110), Vector2(side, 50))
	_place(info_label, Vector2(left, top + side + 20), Vector2(side, 90))
	var controls_top := top + side + 120
	for box in [menu_box, aim_box, fight_box, result_box]:
		_place(box, Vector2(left, controls_top), Vector2(side, size.y - controls_top - 50))
	_place(stamp_label, Vector2(12, size.y - 34), Vector2(size.x, 30))
	arena.queue_redraw()


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _show_only(box: Control) -> void:
	for b in [menu_box, aim_box, fight_box, result_box]:
		b.visible = b == box


func _update_hud() -> void:
	if sim == null:
		hud_label.text = ""
		return
	var a := sim.balls[0]
	var b := sim.balls[1]
	var clock := "%.0fs" % sim.time()
	if sim.in_overtime():
		clock = "OVERTIME x%.1f" % sim.damage_multiplier()
	hud_label.text = "You %d   |   %s   |   %d Foe" % [maxi(0, ceili(a.hp)), clock, maxi(0, ceili(b.hp))]


func _cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()
	speed_button.text = "Speed %sx" % _speed_text()


func _speed_text() -> String:
	var v: float = SPEEDS[speed_index]
	return str(int(v)) if v == floorf(v) else str(v)


func _skip_to_end() -> void:
	while not sim.finished:
		sim.step()
	arena.clear_effects()


func _rematch() -> void:
	seed_value = _rng.randi_range(1, 99999)
	_begin_aim()


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable, font_size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(on_press)
	return b


func _row(children: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for c in children:
		row.add_child(c)
	return row


func _choice_row(ids: Array, store: Dictionary, on_pick: Callable) -> HBoxContainer:
	var group := ButtonGroup.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for id in ids:
		var label: String = "Random" if id == OPPONENT_RANDOM else BallDefs.get_def(id).display_name
		var b := _button(label, on_pick.bind(id))
		b.toggle_mode = true
		b.button_group = group
		store[id] = b
		row.add_child(b)
	return row


# --- Build info and URL params ---------------------------------------------

func _build_stamp() -> String:
	var commit := "dev"
	if FileAccess.file_exists("res://build_info.txt"):
		commit = FileAccess.get_file_as_string("res://build_info.txt").strip_edges()
	return "v%s %s" % [VERSION, commit]


func _read_url_params() -> void:
	if not OS.has_feature("web"):
		return
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	var params := {}
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	if params.get("p1", "") in BallDefs.PLAYABLE:
		player_type = params.p1
	if params.get("p2", "") in BallDefs.PLAYABLE:
		opponent_choice = params.p2
		opponent_type = params.p2
	if params.has("seed") and params.seed.is_valid_int():
		seed_value = int(params.seed)
	if params.has("aim") and params.aim.is_valid_int():
		aim = int(params.aim)
	if params.has("speed"):
		var i := SPEEDS.find(float(params.speed))
		speed_index = maxi(0, i)
	auto_start = params.get("auto", "") == "1"
	if auto_start and opponent_choice == OPPONENT_RANDOM:
		opponent_type = _pick_opponent()
