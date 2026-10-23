## The fight screen every relay mode shares (The Spire, Ghost Arena, the
## campaign's pairs and trios stages): your lineup against theirs as a relay
## (sim/relay.gd), a leg's winner staying in with the HP it has left. It
## opens straight on the arena aiming your first ball (tap to aim, let go to
## launch, game/fight_aim.gd), fights on the shared fight layout
## (game/fight_layout.gd) and ends on the shared result popup
## (game/ui/result_popup.gd). Each mode extends it: it hands over the relay
## in its _ready (start()), says what goes under the first aim, and builds
## its result in _show_result().
extends Node2D

const TouchInput := preload("res://game/ui/touch_input.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const FightHud := preload("res://game/fight_hud.gd")
const FighterStrip := preload("res://game/fighter_strip.gd")
const FightSpeed := preload("res://game/fight_speed.gd")
const FightLayout := preload("res://game/fight_layout.gd")
const FightAim := preload("res://game/fight_aim.gd")
const Relay := preload("res://sim/relay.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Main := preload("res://game/main.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")

enum State { AIM, FIGHT, LEG_END, RESULT }

const LEG_PAUSE := 1.4 ## Seconds to show a leg's winner before the next leg.

var state := State.AIM
var relay: Relay
var sim: MatchSim
var aimed: Array[bool] = []
var aim := 0 ## Current aim for your ball, tenths of a degree, screen space.
var aimer := FightAim.new()
## The names the smoke test taps these by ("UI_AT name x y").
var marks := {"launch": "SpireLaunch", "out": "SpireOut", "skip": "SpireSkip"}
var hold_aim := false ## A question is up over the aim: no aiming behind it.

var _accumulator := 0.0
var _pause := 0.0

var arena: ArenaView
var sfx: Sfx
var fight_hud: FightHud ## Both health bars, above the arena.
var fighter_strip: Control ## The two fighters' cards under the arena while the balls are out.
var info_label: Label
var panel: VBoxContainer
var ui_root: Control ## The full-screen UI; the result popup goes on it.


## Builds the screen for `r` and goes straight to aiming the first ball.
## `tags`: the health bars' side tags.
func start(r: Relay, tags := ["YOU", "FOE"]) -> void:
	TouchInput.ensure(self)
	TouchInput.set_back(self, func(): return _back if state == State.RESULT or unlaunched() else Callable())
	relay = r
	aimed.clear()
	for i in relay.sides[0].size():
		aimed.append(false)
	arena = ArenaView.new()
	arena.team_tags = tags
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui(tags)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_next_leg()


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
	if state != State.AIM or hold_aim:
		return
	aimer.feed(event, arena, sim.balls[0].pos, func(a: int):
		aim = a
		_preview(), _launch, sfx)


# --- Hooks for each mode ------------------------------------------------------

## The line over the aim controls.
func _aim_text(slot: int) -> String:
	return FightSpeed.with_aim_hint("%s (%d/%d)" % [BallDefs.get_def(relay.sides[0][slot]).display_name, slot + 1, relay.sides[0].size()])


## Where the aim starts: at the centre.
func _first_aim(_slot: int) -> int:
	return MatchSim.AIM_AT_CENTRE[0]


## The way out under Launch: a free Back before anything is launched.
func _aim_extras() -> Array:
	var out := _button("Back", _back, 24) if unlaunched() else _button("Give up", _give_up, 24)
	_mark(marks.out, out)
	return [out]


## The tier, level and power under each health bar, if the mode shows them.
func _stats_text(_side: int) -> String:
	return ""


func _on_launched() -> void:
	pass


func _show_result() -> void:
	pass


func _give_up() -> void:
	_back()


func _back() -> void:
	pass


# --- Flow -------------------------------------------------------------------

## True until your first ball is launched: leaving then costs nothing.
func unlaunched() -> bool:
	return state == State.AIM and aimed.count(true) == 0


func _next_leg() -> void:
	if relay.finished:
		state = State.RESULT
		info_label.text = ""
		_set_panel([])
		_show_result()
		return
	var slot: int = relay.slot[0]
	if not aimed[slot]:
		_begin_aim(slot)
	else:
		_start_leg()


func _begin_aim(slot: int) -> void:
	state = State.AIM
	hold_aim = false
	sfx.on_menu()
	aim = _first_aim(slot)
	arena.clear_effects()
	_preview()
	fighter_strip.stats = [_stats_text(0), _stats_text(1)]
	info_label.text = _aim_text(slot)
	var launch := _button("Launch", _launch, 36)
	_mark(marks.launch, launch)
	_set_panel([launch] + _aim_extras())


func _preview() -> void:
	relay.aims[0][relay.slot[0]] = aim
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))


func _launch() -> void:
	if state != State.AIM:
		return
	aimed[relay.slot[0]] = true
	relay.aims[0][relay.slot[0]] = aim
	_on_launched()
	sfx.play("launch")
	_start_leg()


func _start_leg() -> void:
	sim = MatchSim.new(relay.leg_config())
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	state = State.FIGHT
	fighter_strip.stats = [_stats_text(0), _stats_text(1)] # The pair now out.
	info_label.text = "" # The names are on the health bars.
	# Speed, Skip and Sound: the bottom row of pills every fight screen has.
	var skip := FightLayout.skip_pill(_skip_leg, marks.skip)
	_mark(marks.skip, skip.button)
	_set_panel([_row([FightSpeed.picker(), skip])])
	sfx.on_fight_start(sim)


func _skip_leg() -> void:
	while not sim.finished:
		sim.step()
	arena.clear_effects()


func _end_leg() -> void:
	relay.record_leg(sim)
	var w := sim.winner
	if w == -1:
		info_label.text = "Both out!"
	else:
		info_label.text = "%s %s stays in with %d HP." % ["Your" if w == 0 else "Their", BallDefs.get_def(sim.balls[w].type_id).display_name, ceili(sim.balls[w].hp)]
	state = State.LEG_END
	_pause = LEG_PAUSE
	_set_panel([])


## The result popup every fight ends on, over this screen.
func _popup(caption: String, body: Array, buttons: Array) -> void:
	sfx.toggle_hidden = true # The popup covers the bottom row of pills.
	sfx.hold_victory(ResultPopup.show_over(ui_root, ResultPopup.content(caption, ResultPopup.outcome_of(relay.winner), body, buttons)))


# --- UI ---------------------------------------------------------------------

func _update_hud() -> void:
	if relay == null or sim == null:
		return
	# Balls each side still has, the one fighting included.
	var left := [relay.sides[0].size() - relay.slot[0], relay.sides[1].size() - relay.slot[1]]
	# Aiming and between legs the controls have the room under the arena:
	# only the foe's plate shows.
	var plates := state in [State.AIM, State.FIGHT, State.LEG_END]
	fighter_strip.show_fight(sim if plates else null)
	fighter_strip.foe_only = state != State.FIGHT
	fighter_strip.bench = [_bench(0), _bench(1)]
	fight_hud.plates = plates
	fight_hud.foe_only = state != State.FIGHT
	fight_hud.show_fight(sim, "%d v %d" % left)


## Side `s`'s teammates on the bench: the ones already out, then the ones to come.
func _bench(s: int) -> Array:
	var out := []
	for j in relay.sides[s].size():
		if j != relay.slot[s]:
			out.append({"id": str(relay.sides[s][j]), "out": j < relay.slot[s]})
	return out


func _build_ui(tags: Array) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = Main._neon_theme()
	layer.add_child(ui_root)
	fight_hud = FightHud.new()
	fight_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fight_hud.tags = tags
	ui_root.add_child(fight_hud)
	fighter_strip = FighterStrip.new()
	fighter_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fighter_strip)
	info_label = _label("", 26)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	ui_root.add_child(info_label)
	ui_root.add_child(panel)


## The same shape as every fight screen (FightLayout): the bars on top, the
## arena, then the info line and controls, the fighters' cards while the
## balls are out.
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var r := FightLayout.rects(size)
	arena.fit(r.arena.position, r.arena.size.x)
	FightLayout.place_plates(fight_hud, fighter_strip, r, size)
	var p: Rect2 = r.panel
	var info_h := 0.0 if state == State.FIGHT else 56.0 # The aim hint, or who stays in.
	_place(info_label, p.position, Vector2(p.size.x, 50))
	_place(panel, p.position + Vector2(0, info_h), Vector2(p.size.x, maxf(0.0, p.size.y - info_h)))
	arena.queue_redraw()


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _set_panel(children: Array) -> void:
	_layout() # Fighting gives the info line's room to the cards.
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()
	for c in children:
		panel.add_child(c)


## Logs where a control is once it's laid out, for the smoke test ("UI_AT name x y").
func _mark(name: String, c: Control, wait := 0.0) -> void:
	_mark_later.call_deferred(name, c, wait)


func _mark_later(name: String, c: Control, wait: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	if is_instance_valid(c) and c.is_visible_in_tree():
		var at := c.get_global_rect().get_center()
		print("UI_AT %s %d %d" % [name, roundi(at.x), roundi(at.y)])


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable, font_size := 30) -> Button:
	var b := Button.new()
	b.text = text.to_upper()
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
