## Daily Trick Shot: aim -> shoot -> see the result, three tries a day, then
## a shareable result grid. The puzzle comes from sim/trick_shot.gd and the
## local date. URL params: ?mode=trickshot&day=12&aim=166&auto=1
## (day picks a puzzle, aim presets the aim in degrees, auto shoots at once).
##
## Critter Shot: a second, separate puzzle each day shot with the Try-a-Critter
## loaner (game/loaner.gd). It has its own tries and never touches the streak.
## Open it by setting `critter_shot` before changing scene, or ?shooter=laser.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const TrickShot := preload("res://sim/trick_shot.gd")
const TrickShotView := preload("res://game/trick_shot_view.gd")
const A11y := preload("res://game/a11y.gd")
const Main := preload("res://game/main.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

enum State { AIM, SHOT, RESULT, DONE }

const SAVE_PATH := "user://trick_shot.cfg"
const SHARE_URL := "https://battleballs.vercel.app/?mode=trickshot"
const ARENA_PIXELS := 680.0
const PANEL_HEIGHT := 400.0
const SHOT_SPEED := 1.5
const LINGER_TICKS := 40 ## Ticks shown after the decisive moment.
const SQUARES := {"solved": "🟩", "wrong_walls": "🟨", "miss": "🟥"}

## Set to a critter id to open that day's Critter Shot instead of the main shot.
static var critter_shot := ""

var state := State.AIM
var today := 1
var day := 1
var puzzle: Dictionary
var shooter := "" ## The Critter Shot's ball, or "" for the main puzzle.
var aim := 0 ## Degrees, screen space (0 = right, 90 = down).
var tries: Array = [] ## [{ aim, result, walls }]
var sim: MatchSim
var shot: Dictionary
var stats := {"streak": 0, "best_streak": 0, "played": 0, "solved": 0, "last_solved_day": 0}

var _accumulator := 0.0
var _linger := 0
var _dragging := false
var _auto_shoot := false
var _save := ConfigFile.new()

var arena: TrickShotView
var title_label: Label
var call_label: Label
var info_label: Label
var panel: VBoxContainer


func _ready() -> void:
	today = maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	day = today
	var params := _url_params()
	if params.get("day", "").is_valid_int():
		day = maxi(1, int(params.day))
	shooter = critter_shot
	critter_shot = ""
	if params.get("shooter", "") in BallDefs.PLAYABLE:
		shooter = params.shooter
	var t := Time.get_ticks_msec()
	puzzle = TrickShot.generate(day, shooter)
	aim = _default_aim()
	if params.get("aim", "").is_valid_int():
		aim = posmod(int(params.aim), 360)
	_auto_shoot = params.get("auto", "") == "1"
	_load()

	arena = TrickShotView.new()
	arena.called_walls = puzzle.walls
	add_child(arena)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	print("TRICKSHOT_READY day=%d shooter=%s walls=%s solutions=%d-%d ms=%d" % [day, puzzle.p1, ",".join(puzzle.walls), puzzle.solutions.front(), puzzle.solutions.back(), Time.get_ticks_msec() - t])
	if _is_over():
		_show_done()
	else:
		_show_aim()
		if _auto_shoot:
			_shoot()


func _process(delta: float) -> void:
	if state == State.SHOT:
		_accumulator += delta * SHOT_SPEED
		var steps := 0
		while _accumulator >= MatchSim.DT and steps < 32 and state == State.SHOT:
			_accumulator -= MatchSim.DT
			steps += 1
			if shot.result == "":
				TrickShot.step_shot(sim, puzzle, shot)
				if sim.tick % 2 == 0 or shot.result != "":
					arena.trail.append(sim.balls[0].pos)
			else:
				sim.step()
				_linger -= 1
				if _linger <= 0 or sim.finished:
					_finish_try()
			arena.consume_events(sim.events)
	arena.advance_effects(delta)


func _unhandled_input(event: InputEvent) -> void:
	if state != State.AIM:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed and _aim_towards(event.position)
	elif event is InputEventMouseMotion and _dragging:
		_aim_towards(event.position)


## Aims from your ball towards a screen point. False if the point is off the arena.
func _aim_towards(screen_pos: Vector2) -> bool:
	var world := arena.to_world(screen_pos)
	if not Rect2(0, 0, MatchSim.ARENA_SIZE, MatchSim.ARENA_SIZE).grow(60.0).has_point(world):
		return false
	var dir := world - sim.balls[0].pos
	if dir.length() >= 10.0:
		_set_aim(roundi(rad_to_deg(dir.angle())))
	return true


func _set_aim(value: int) -> void:
	aim = posmod(value, 360)
	sim = TrickShot.make_sim(puzzle, aim)
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(float(aim)))
	if state == State.AIM and panel.has_node("AimRow/Aim"):
		panel.get_node("AimRow/Aim").text = "%d°" % aim


## Points at the foe, which is never a solution: every puzzle calls a wall.
func _default_aim() -> int:
	var to_foe: Vector2 = puzzle.starts[1] - puzzle.starts[0]
	return posmod(roundi(rad_to_deg(to_foe.angle())), 360)


# --- Flow -------------------------------------------------------------------

func _show_aim() -> void:
	state = State.AIM
	arena.trail.clear()
	arena.ghosts = tries
	arena.solutions = []
	arena.clear_effects()
	_set_aim(aim)
	info_label.text = "Try %d of %d. Drag on the arena to aim, nudge to fine-tune, then shoot." % [tries.size() + 1, TrickShot.TRIES]
	if shooter != "":
		info_label.text = "%s takes this shot. " % BallDefs.get_def(shooter).display_name + info_label.text
	var nudge := func(by: int): _set_aim(aim + by)
	var aim_label := _label("%d°" % aim, 40)
	aim_label.name = "Aim"
	aim_label.custom_minimum_size = Vector2(150, 0)
	var row := _row([_button("-5", nudge.bind(-5)), _button("-1", nudge.bind(-1)), aim_label, _button("+1", nudge.bind(1)), _button("+5", nudge.bind(5))])
	row.name = "AimRow"
	_set_panel([row, _button("SHOOT!", _shoot, 40), _button("Back", _go_menu)])


func _shoot() -> void:
	state = State.SHOT
	sim = TrickShot.make_sim(puzzle, aim)
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.trail = PackedVector2Array([sim.balls[0].pos])
	shot = {"result": "", "walls": []}
	_linger = LINGER_TICKS
	_accumulator = 0.0
	info_label.text = "Bank off %s, then hit the foe." % _walls_text(puzzle.walls)
	_set_panel([_button("Skip", _skip_shot)])
	print("TRICKSHOT_SHOT day=%d aim=%d" % [day, aim])


func _skip_shot() -> void:
	while shot.result == "":
		TrickShot.step_shot(sim, puzzle, shot)
		arena.trail.append(sim.balls[0].pos)
	_finish_try()


func _finish_try() -> void:
	tries.append({"aim": aim, "result": shot.result, "walls": shot.walls})
	print("TRICKSHOT_RESULT day=%d aim=%d result=%s walls=%s" % [day, aim, shot.result, ",".join(shot.walls)])
	if _is_over():
		_record_finish()
	_save_day()
	state = State.RESULT
	arena.ghosts = tries
	var title := "TRICK SHOT!"
	var detail := "Called it."
	match shot.result:
		TrickShot.WRONG_WALLS:
			title = "Too early!"
			detail = "You hit the foe after %d of %d walls." % [shot.walls.size(), puzzle.walls.size()]
		TrickShot.MISS:
			title = "Missed"
			if not _walls_match_so_far(shot.walls):
				detail = "Wrong wall: you banked off %s." % _walls_text(shot.walls)
			elif shot.walls.size() < puzzle.walls.size():
				detail = "Out of time after %d of %d walls." % [shot.walls.size(), puzzle.walls.size()]
			else:
				detail = "Right walls, but it missed the foe."
	var result_label := _label(title, 52)
	result_label.modulate = TrickShotView.RESULT_COLORS[shot.result]
	info_label.text = detail
	var next := _button("See results", _show_done, 36) if _is_over() else _button("Try again (%d left)" % (TrickShot.TRIES - tries.size()), _show_aim, 36)
	_set_panel([result_label, next])


func _walls_match_so_far(walls: Array) -> bool:
	return walls.size() <= puzzle.walls.size() and walls == puzzle.walls.slice(0, walls.size())


func _show_done() -> void:
	state = State.DONE
	# Show the path of a middle solution, ending at the hit, over a fresh setup.
	var best_aim: int = puzzle.solutions[puzzle.solutions.size() / 2]
	var replay := TrickShot.make_sim(puzzle, best_aim)
	var replay_shot := {"result": "", "walls": []}
	arena.trail = PackedVector2Array([replay.balls[0].pos])
	while replay_shot.result == "":
		TrickShot.step_shot(replay, puzzle, replay_shot)
		arena.trail.append(replay.balls[0].pos)
	sim = TrickShot.make_sim(puzzle, best_aim)
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.ghosts = tries
	arena.solutions = puzzle.solutions
	var solved := _solved()
	var headline := _label("Solved in %d!" % tries.size() if solved else "Not today", 48)
	var grid := HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 12)
	for t in tries:
		var sq := ColorRect.new()
		sq.color = TrickShotView.RESULT_COLORS[t.result]
		sq.custom_minimum_size = Vector2(56, 56)
		grid.add_child(sq)
	info_label.text = "Any aim from %d° to %d° works. Streak %d (best %d). New shot tomorrow." % [
		puzzle.solutions.front(), puzzle.solutions.back(), _current_streak(), stats.best_streak]
	if shooter != "":
		info_label.text = "Any aim from %d° to %d° works. A new critter tries out tomorrow." % [puzzle.solutions.front(), puzzle.solutions.back()]
		_set_panel([headline, grid, _button("Menu", _go_menu)])
		return
	var share_button := _button("Share", Callable())
	share_button.pressed.connect(func(): share_button.text = _share())
	_set_panel([headline, grid, _row([share_button, _button("Menu", _go_menu)])])


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://game/main.tscn")


func _is_over() -> bool:
	return _solved() or tries.size() >= TrickShot.TRIES


func _solved() -> bool:
	return tries.any(func(t): return t.result == TrickShot.SOLVED)


# --- Sharing and saving -----------------------------------------------------

func share_text() -> String:
	var squares := ""
	for t in tries:
		squares += SQUARES[t.result]
	var score := str(tries.size()) if _solved() else "X"
	return "Battle Balls Trick Shot #%d %s/%d\n%s\n%s" % [day, score, TrickShot.TRIES, squares, SHARE_URL]


## Opens the share sheet where there is one, else copies. Returns a button label.
func _share() -> String:
	var text := share_text()
	if OS.has_feature("web"):
		var how = JavaScriptBridge.eval("""(function (t) {
			if (navigator.share) { navigator.share({ text: t }).catch(function () { navigator.clipboard && navigator.clipboard.writeText(t); }); return 'share'; }
			if (navigator.clipboard) { navigator.clipboard.writeText(t); return 'copy'; }
			return '';
		})(%s)""" % JSON.stringify(text), true)
		if how == "share":
			return "Shared!"
		if how == "copy":
			return "Copied!"
	DisplayServer.clipboard_set(text)
	return "Copied!"


func _load() -> void:
	if _save.load(SAVE_PATH) != OK:
		return
	for key in stats:
		stats[key] = _save.get_value("stats", key, stats[key])
	tries = _save.get_value(_tries_section(), str(day), [])


## Critter Shot tries live apart from the main puzzle's, so the board and the
## streak only ever read the main one.
func _tries_section() -> String:
	return "days" if shooter == "" else "critter_" + shooter


func _save_day() -> void:
	_save.set_value(_tries_section(), str(day), tries)
	for key in stats:
		_save.set_value("stats", key, stats[key])
	_save.save(SAVE_PATH)


## Counts a finished day. Streaks only follow today's puzzle, not replays of old days.
func _record_finish() -> void:
	if shooter != "":
		return
	stats.played += 1
	if not _solved():
		if day == today:
			stats.streak = 0
		return
	stats.solved += 1
	if day == today:
		stats.streak = stats.streak + 1 if stats.last_solved_day == today - 1 else 1
		stats.last_solved_day = today
		stats.best_streak = maxi(stats.best_streak, stats.streak)


func _current_streak() -> int:
	return stats.streak if stats.last_solved_day >= today - 1 else 0


# --- UI ---------------------------------------------------------------------

func _walls_text(walls: Array) -> String:
	var names := walls.map(func(w): return w.to_upper())
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, -1)) + " and " + names[-1]


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Main._neon_theme()
	layer.add_child(ui)
	title_label = _label(("TRICK SHOT #%d" if shooter == "" else "CRITTER SHOT #%d") % day, 48)
	title_label.add_theme_color_override("font_outline_color", Color(Main.ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	call_label = _label("Bank off %s, then hit the foe" % _walls_text(puzzle.walls), 28)
	call_label.modulate = TrickShotView.CALL_COLOR
	call_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label = _label("", 26)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	for c in [title_label, call_label, info_label, panel]:
		ui.add_child(c)


## Same shape as the main screen: portrait stacks arena over the panel, wide
## screens put the panel beside the arena.
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var top := 190.0
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
		panel_pos = Vector2((size.x - panel_width) / 2.0, top + side + 20.0)
	arena.view_scale = side / MatchSim.ARENA_SIZE
	arena.position = Vector2(left, top)
	_place(title_label, Vector2(0, 30), Vector2(size.x, 60))
	_place(call_label, Vector2(20, 100), Vector2(size.x - 40, 80))
	_place(info_label, panel_pos, Vector2(panel_width, 90))
	_place(panel, panel_pos + Vector2(0, 100), Vector2(panel_width, PANEL_HEIGHT - 100.0))
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
	l.set_meta("base_font", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable, font_size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", A11y.font(font_size))
	b.set_meta("base_font", font_size)
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
