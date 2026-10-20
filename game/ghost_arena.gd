## Ghost Arena fight: your trio against an opponent's saved trio as a relay
## (sim/relay.gd). Each of your balls is aimed by you when it first comes
## out; the ghost fires its saved shots. The winner of a leg stays in with
## its HP. Opened from the Arena screen with an attack already started in
## ArenaStore; the result goes back to it.
extends Node2D

const Intro := preload("res://game/ui/intro.gd")
const Arenas := preload("res://sim/arenas.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const FightHud := preload("res://game/fight_hud.gd")
const Relay := preload("res://sim/relay.gd")
const Lineup := preload("res://sim/lineup.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Main := preload("res://game/main.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ResultText := preload("res://game/result_text.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Kit := preload("res://game/ui/ui_kit.gd")

enum State { INTRO, AIM, FIGHT, LEG_END, RESULT }

const ARENA_PIXELS := 680.0
const PANEL_HEIGHT := 400.0
const FightSpeed := preload("res://game/fight_speed.gd")
const LEG_PAUSE := 1.4 ## Seconds to show a leg's winner before the next leg.

var state := State.INTRO
var store
var bot: Dictionary
var relay: Relay
var sim: MatchSim
var aimed: Array[bool] = [false, false, false]
var aim := 0 ## Current aim for your ball, tenths of a degree, screen space.
var result_delta := 0
var slots := [[], []] ## Both trios as lineup slots, for the tier and power on show.

var _accumulator := 0.0
var _pause := 0.0
var _dragging := false

var arena: ArenaView
var sfx: Sfx
var title_label: Label
var hud_label: Label
var fight_hud: FightHud ## Both health bars, above the arena.
var lineup_label: Label
var info_label: Label
var panel: VBoxContainer


func _ready() -> void:
	TouchInput.ensure(self)
	TouchInput.set_back(self, func(): return _back_to_arena if state == State.RESULT else Callable())
	store = ArenaStore.open()
	bot = store.pending_bot()
	if bot.is_empty():
		_back_to_arena.call_deferred()
		return
	var ghost_aims: Array = []
	for i in bot.lineup.slots.size():
		ghost_aims.append(ArenaGhosts.slot_angle(bot.lineup, i, 1))
	# Both trios fight at their known tier, level and gear (sim/lineup.gd).
	slots = [store.pending.get("slots", store.slots()), bot.lineup.slots]
	var mine := Lineup.side(slots[0])
	var theirs := Lineup.side(slots[1])
	relay = Relay.new({
		"seed": int(store.pending.seed),
		"arena": store.pending.get("arena", "square"),
		"sides": [mine.sides, theirs.sides],
		"aims": [mine.sides.map(func(_c): return null), ghost_aims],
		"tiers": [mine.tiers, theirs.tiers],
		"powers": [mine.powers, theirs.powers],
		"gear": [mine.gear, theirs.gear],
		"talents": [mine.talents, theirs.talents],
	})
	arena = ArenaView.new()
	arena.team_tags = ["YOU", "GHOST"]
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	print("ARENA_READY bot=%s card=%s seed=%d" % [bot.id, store.pending.card, int(store.pending.seed)])
	_show_intro()


func _process(delta: float) -> void:
	match state:
		State.FIGHT:
			_accumulator += delta * FightSpeed.current()
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
		arena.advance_effects(delta * (FightSpeed.current() if state == State.FIGHT else 1.0))
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
	var card: Dictionary = Ladder.CARDS[store.pending.card]
	info_label.text = "%s, on %s. Win +%d, lose %d." % [
		bot.name, Arenas.get_def(relay.config.get("arena", "square")).display_name, card.win, card.loss]
	var foes := ArenaGhosts.critters(bot.lineup).map(func(c): return BallDefs.get_def(c).display_name)
	foes.sort()
	lineup_label.text = "They bring: " + ", ".join(foes)
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	_set_panel([_button("FIGHT!", _next_leg, 40), _lineups(), _forfeit_link()])


## Your trio in fight order, VS, theirs sorted (their order stays hidden),
## each with its tier and power.
func _lineups() -> Control:
	var row := _row([])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	for s in slots[0]:
		row.add_child(FighterTag.of_slot(s, 64))
	row.add_child(_label("VS", 28))
	var theirs: Array = slots[1].duplicate()
	theirs.sort_custom(func(a, b): return str(a.critter) < str(b.critter))
	for s in theirs:
		row.add_child(FighterTag.of_slot(s, 64))
	return row


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
	var shot = store.shots[slot]
	aim = MatchSim.AIM_AT_CENTRE[0] + (int(shot) if shot != null else 0)
	arena.clear_effects()
	_preview()
	info_label.text = "Ball %d of 3: drag on the arena to aim your %s, then let go to launch." % [slot + 1, BallDefs.get_def(relay.sides[0][slot]).display_name]
	_set_panel([_button("Launch", _launch, 36)])


func _preview() -> void:
	relay.aims[0][relay.slot[0]] = aim
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))


func _launch() -> void:
	aimed[relay.slot[0]] = true
	relay.aims[0][relay.slot[0]] = aim
	sfx.play("launch")
	_start_leg()


func _start_leg() -> void:
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	state = State.FIGHT
	info_label.text = "%s vs %s" % [_fighter_text(0), _fighter_text(1)]
	var speed := FightSpeed.picker()
	_set_panel([_row([speed, _button("Skip", _skip_leg)])])
	sfx.on_fight_start(sim)


## "T2 Optic · 1,250 power" for the ball `side` has out this leg.
func _fighter_text(side: int) -> String:
	var s := Lineup.clean(slots[side][relay.slot[side]])
	return FighterTag.text(BallDefs.get_def(s.critter).display_name, s.tier, FighterTag.rating(s), s.level)


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
	var won := relay.winner == 0
	var used: Array = []
	for i in 3:
		var a = relay.aims[0][i]
		used.append(null if a == null or not aimed[i] else int(a) - MatchSim.AIM_AT_CENTRE[0])
	result_delta = store.finish_attack(won, used)
	Intro.arena_fought = true
	sfx.on_result(relay.winner)
	var headline := _label("YOU WIN!" if won else ("DRAW" if relay.winner == -1 else "YOU LOSE"), 56)
	headline.modulate = ResultText.WIN if won else (ResultText.DRAW if relay.winner == -1 else ResultText.LOSE)
	var change := "%+d trophies." % result_delta if result_delta != 0 else "No trophies lost at your league's floor."
	if result_delta > 0:
		change = "%+d trophies and Arena Points." % result_delta
	var got: int = store.history[0].get("coins", 0) if not store.history.is_empty() else 0
	if got > 0:
		change += " +%d Tokens." % got
	info_label.text = "%s You're on %d, %s." % [change, store.trophies, Ladder.league_label(store.trophies)]
	print("ARENA_RESULT won=%s delta=%d trophies=%d hash=%s" % [won, result_delta, store.trophies, relay.state_hash()])
	_set_panel([headline, _button("Back to Arena", _back_to_arena, 36)])


## A small red "Forfeit" under the lineups; it asks before it costs anything.
func _forfeit_link() -> Control:
	var b := Button.new()
	b.text = "Forfeit"
	b.flat = true
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(200, 64)
	b.add_theme_font_size_override("font_size", 26)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Kit.BAD)
	b.pressed.connect(_confirm_forfeit)
	return b


func _confirm_forfeit() -> void:
	var loss: int = Ladder.CARDS[store.pending.card].loss
	var yes := _button("Forfeit (%d trophies)" % loss, _forfeit, 28)
	yes.add_theme_color_override("font_color", Kit.BAD)
	_set_panel([_label("Forfeit this attack? It counts as a loss.", 28), _row([yes, _button("Keep going", _show_intro, 28)])])


func _forfeit() -> void:
	store.settle_abandoned()
	_back_to_arena()


func _back_to_arena() -> void:
	ArenaStore.reopen = true
	get_tree().change_scene_to_file("res://game/main.tscn")


# --- UI ---------------------------------------------------------------------

func _update_hud() -> void:
	if relay == null:
		return
	# Balls each side still has, the one fighting included.
	var left := [relay.sides[0].size() - relay.slot[0], relay.sides[1].size() - relay.slot[1]]
	var fighting: bool = sim != null and state in [State.FIGHT, State.LEG_END]
	lineup_label.visible = not fighting
	if fighting:
		hud_label.text = ""
		fight_hud.show_fight(sim, "%d v %d" % left)
	else:
		fight_hud.show_fight(null)
		hud_label.text = "%d left  vs  %d left" % left


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Main._neon_theme()
	layer.add_child(ui)
	title_label = _label("GHOST ARENA", 48)
	title_label.add_theme_color_override("font_outline_color", Color(Main.ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	hud_label = _label("", 28)
	fight_hud = FightHud.new()
	fight_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fight_hud.tags = ["YOU", "GHOST"]
	ui.add_child(fight_hud)
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
	_place(fight_hud, Vector2(left, 100), Vector2(side, 84))
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
