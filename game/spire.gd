## The Spire fight: your picks against the floor's enemy lineup as a relay
## (sim/relay.gd, design/spire.md). You aim each ball when it first comes
## out; enemy aims come from the floor seed. The result is settled into the
## climb file (meta/spire_climb.gd), then it's back to the Spire screen.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const Relay := preload("res://sim/relay.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const SpireScreen := preload("res://game/ui/screens/spire_screen.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Main := preload("res://game/main.gd")
const LiveOps := preload("res://game/liveops.gd")

enum State { INTRO, AIM, FIGHT, LEG_END, RESULT }

const ARENA_PIXELS := 680.0
const PANEL_HEIGHT := 400.0
const SPEEDS := [1.0, 2.0, 4.0]
const LEG_PAUSE := 1.4 ## Seconds to show a leg's winner before the next leg.

var state := State.INTRO
var climb
var spec: Dictionary
var relay: Relay
var sim: MatchSim
var aimed: Array[bool] = []
var aim := 0 ## Current aim for your ball, tenths of a degree, screen space.
var speed_index := 0

var _accumulator := 0.0
var _pause := 0.0
var _dragging := false

var arena: ArenaView
var sfx: Sfx
var title_label: Label
var hud_label: Label
var lineup_label: Label
var info_label: Label
var panel: VBoxContainer


func _ready() -> void:
	climb = SpireClimb.load_file(LiveOps.now())
	if climb.pending.is_empty() or int(climb.pending.floor) != climb.next_floor():
		climb.pending = {}
		_back.call_deferred()
		return
	spec = climb.floor_spec()
	var picks: Array = climb.pending.picks
	relay = Relay.new(Spire.relay_config(spec, picks))
	for i in picks.size():
		aimed.append(false)
	arena = ArenaView.new()
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	print("SPIRE_READY week=%d floor=%d seed=%d" % [climb.week, spec.floor, spec.seed])
	_show_intro()


func _process(delta: float) -> void:
	match state:
		State.FIGHT:
			_accumulator += delta * SPEEDS[speed_index]
			var steps := 0
			while _accumulator >= MatchSim.DT and steps < 32 and not sim.finished:
				sim.step()
				arena.consume_events(sim.events)
				sfx.consume_events(sim.events, sim)
				_accumulator -= MatchSim.DT
				steps += 1
			if sim.finished:
				_end_leg()
		State.LEG_END:
			_pause -= delta
			if _pause <= 0.0:
				_next_leg()
	if arena:
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
	sfx.on_aim_drag(dir.length() / 600.0)
	_preview()


# --- Flow -------------------------------------------------------------------

func _show_intro() -> void:
	state = State.INTRO
	sfx.on_menu()
	var foes: Array = spec.enemies.map(func(e): return BallDefs.get_def(e.id).display_name)
	lineup_label.text = "They bring: " + ", ".join(foes)
	info_label.text = "Floor %d%s. Every critter that comes out spends 1 Stamina, win or lose." % [spec.floor, " (boss)" if spec.boss else ""]
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	var fight := _button("FIGHT!", _next_leg, 40)
	fight.name = "SpireFight"
	_set_panel([fight, _button("Back", _back, 24)])


func _next_leg() -> void:
	if relay.finished:
		_show_result()
		return
	var slot: int = relay.slot[0]
	if not aimed[slot]:
		_begin_aim(slot)
	else:
		_start_leg()


func _begin_aim(slot: int) -> void:
	state = State.AIM
	aim = MatchSim.AIM_AT_CENTRE[0]
	arena.clear_effects()
	_preview()
	info_label.text = "Ball %d of %d: drag on the arena to aim your %s, then let go to launch." % [slot + 1, relay.sides[0].size(), BallDefs.get_def(relay.sides[0][slot]).display_name]
	var launch := _button("Launch", _launch, 36)
	launch.name = "SpireLaunch"
	_set_panel([launch, _button("Give up (counts as a loss)", _give_up, 24)])


func _preview() -> void:
	relay.aims[0][relay.slot[0]] = aim
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))


func _launch() -> void:
	aimed[relay.slot[0]] = true
	relay.aims[0][relay.slot[0]] = aim
	# Saved at every launch, so closing the app mid-floor still costs Stamina.
	climb.pending.launched = aimed.count(true)
	climb.save_file()
	sfx.play("launch")
	_start_leg()


func _start_leg() -> void:
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	state = State.FIGHT
	info_label.text = "%s vs %s" % [BallDefs.get_def(sim.balls[0].type_id).display_name, BallDefs.get_def(sim.balls[1].type_id).display_name]
	var speed := _button("Speed %dx" % int(SPEEDS[speed_index]), Callable())
	speed.pressed.connect(func():
		speed_index = (speed_index + 1) % SPEEDS.size()
		speed.text = "Speed %dx" % int(SPEEDS[speed_index]))
	var skip := _button("Skip", _skip_leg)
	skip.name = "SpireSkip"
	_set_panel([_row([speed, skip])])
	sfx.on_fight_start(sim)


func _skip_leg() -> void:
	while not sim.finished:
		sim.step()
	arena.clear_effects()


func _end_leg() -> void:
	relay.record_leg(sim)
	var w := sim.winner
	if w == -1:
		info_label.text = "Both balls are out!"
	else:
		info_label.text = "%s %s stays in with %d HP." % ["Your" if w == 0 else "Their", BallDefs.get_def(sim.balls[w].type_id).display_name, ceili(sim.balls[w].hp)]
	state = State.LEG_END
	_pause = LEG_PAUSE
	_set_panel([])


func _show_result() -> void:
	state = State.RESULT
	var r: Dictionary = climb.settle(relay)
	climb.save_file()
	sfx.on_result(0 if r.won else 1)
	var headline := _label("FLOOR %d CLEARED!" % r.floor if r.won else "NOT THIS TIME", 52)
	headline.modulate = Color("45f5a6") if r.won else Color("ff5a7a")
	var names: Array = r.spent.map(func(id): return BallDefs.get_def(id).display_name)
	info_label.text = "%s Stamina spent: %s." % ["Rewards are waiting on the Spire screen." if r.won else "Try again with fresh critters.", ", ".join(names)]
	print("SPIRE_RESULT floor=%d won=%s hash=%s" % [r.floor, r.won, relay.state_hash()])
	var back := _button("Back to the Spire", _back, 36)
	back.name = "SpireBack"
	_set_panel([headline, back])


func _give_up() -> void:
	climb.settle(relay, aimed.count(true))
	climb.save_file()
	_back()


func _back() -> void:
	if climb and not climb.pending.is_empty() and state == State.INTRO:
		climb.pending = {}
		climb.save_file()
	SpireScreen.reopen = true
	get_tree().change_scene_to_file("res://game/main.tscn")


# --- UI ---------------------------------------------------------------------

func _update_hud() -> void:
	if relay == null:
		return
	var left := [relay.sides[0].size() - relay.slot[0], relay.sides[1].size() - relay.slot[1]]
	var marks := "%d left  vs  %d left" % left
	if sim and state in [State.FIGHT, State.LEG_END]:
		hud_label.text = "You %d  %s  %d Foe" % [maxi(0, ceili(sim.balls[0].hp)), marks, maxi(0, ceili(sim.balls[1].hp))]
	else:
		hud_label.text = marks


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Main._neon_theme()
	layer.add_child(ui)
	title_label = _label("THE SPIRE · FLOOR %d" % spec.floor, 44)
	title_label.add_theme_color_override("font_outline_color", Color(Color("ffc23d"), 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	hud_label = _label("", 28)
	lineup_label = _label("", 24)
	lineup_label.modulate = Color("a29fc9")
	info_label = _label("", 26)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	for c in [title_label, hud_label, lineup_label, info_label, panel]:
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
	_place(hud_label, Vector2(0, 100), Vector2(size.x, 44))
	_place(lineup_label, Vector2(0, 144), Vector2(size.x, 36))
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
	_announce.call_deferred()


## Logs where the named buttons are, for the smoke test ("UI_AT name x y").
func _announce() -> void:
	await get_tree().process_frame
	for b in panel.find_children("Spire*", "Button", true, false):
		var p: Vector2 = b.get_global_rect().get_center()
		print("UI_AT %s %d %d" % [b.name, roundi(p.x), roundi(p.y)])


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
	b.add_theme_font_size_override("font_size", font_size)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


func _row(children: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for c in children:
		row.add_child(c)
	return row
