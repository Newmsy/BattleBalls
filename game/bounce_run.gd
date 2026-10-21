## Bounce Run: draft a trio and 3 starting boons, climb 10 floors, pick a
## boon after every win.
## The run comes from sim/bounce_run.gd and the UTC day; one ranked run a day
## posts to the shared leaderboard, then practice runs are unranked.
## URL params: ?mode=bouncerun&day=3 (play another day's run, unranked),
## &offline=1 (never touch the leaderboard).
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const BoonIcon := preload("res://game/ui/boon_icon.gd")
const BounceBoard := preload("res://game/online/bounce_board.gd")
const Glyph := preload("res://game/ui/glyph.gd")

enum State { DRAFT, START_BOONS, FLOOR, AIM, FIGHT, RESULT, BOON, OVER }

const SAVE_PATH := "user://bounce_run.cfg"
const SHARE_URL := "https://battleballs.vercel.app/?mode=bouncerun"
const ARENA_PIXELS := 680.0
const PANEL_HEIGHT := 330.0
const FightSpeed := preload("res://game/fight_speed.gd")
const GOLD := Color("ffc23d")
const PINK := Color("ff5a7a")
const ABILITY := Color("8fd8ff") ## The critter's own ability, apart from boon gold.

var state := State.DRAFT
var today := 1
var day := 1
var ranked := true ## False for practice runs and other days.
var setup: Dictionary
var run: Dictionary ## Empty until the draft is done.
var picks: Array = [] ## Draft selection in progress.
var start_picks: Array = [] ## Starting boons picked, in progress.
var slot := 0 ## Pick slot fighting this floor.
var aim := MatchSim.AIM_AT_CENTRE[0]
var sim: MatchSim
var stats := {"played": 0, "best_floors": 0, "clears": 0}
var save_path := SAVE_PATH ## Tests point this elsewhere.

var _save := ConfigFile.new()
var _accumulator := 0.0
var _dragging := false
var _marks := {}
var _board_rows = null ## Leaderboard rows once fetched; null while loading.
var _board_note := ""

var arena: ArenaView
var sfx: Sfx
var board: BounceBoard
var ui: Control
var title_label: Label
var sub_label: Label
var hud_label: Label
var info_label: Label
var panel: VBoxContainer
var scroll: ScrollContainer
var page: VBoxContainer
var share_button: Button
var rules_button: Button ## The "i" in the corner: how a run works.


func _ready() -> void:
	if arena != null:
		return # Tests may start the scene by hand before the tree does.
	today = BounceRun.day_number(Time.get_unix_time_from_system())
	day = today
	var params := _url_params()
	if params.get("day", "").is_valid_int():
		day = maxi(1, int(params.day))
	setup = BounceRun.generate(day)
	_load()
	arena = ArenaView.new()
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	board = BounceBoard.new()
	add_child(board)
	if params.get("offline", "") == "1" and board.backend != null:
		board.backend.disabled = true
	_build_ui()
	if get_viewport():
		get_viewport().size_changed.connect(_layout)
	print("BOUNCERUN_READY day=%d ranked=%s cards=%s boons=%s" % [day, ranked, ",".join(setup.cards.map(func(c): return c.critter)), ",".join(setup.start_offer)])
	_retry_pending_post()
	if run.has("launched"):
		_settle_launched_fight()
		if run.over:
			_finish_run()
			return
	if run.is_empty():
		_show_draft()
	elif run.over:
		_show_over()
	elif not run.offer.is_empty():
		_show_boon()
	else:
		_show_floor()


func _process(delta: float) -> void:
	if state == State.FIGHT:
		_accumulator += delta * FightSpeed.current()
		var steps := 0
		while _accumulator >= MatchSim.DT and steps < 32 and not sim.finished:
			sim.step()
			_consume(sim.events)
			_accumulator -= MatchSim.DT
			steps += 1
		if sim.finished:
			_finish_fight()
		_update_hud()
	arena.advance_effects(delta * (FightSpeed.current() if state == State.FIGHT else 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if state != State.AIM:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = _aim_towards(event.position)
		elif _dragging:
			_dragging = false
			_aim_towards(event.position)
			_launch()
	elif event is InputEventMouseMotion and _dragging:
		_aim_towards(event.position)


func _aim_towards(screen_pos: Vector2) -> bool:
	var world := arena.to_world(screen_pos)
	if not Rect2(0, 0, MatchSim.ARENA_SIZE, MatchSim.ARENA_SIZE).grow(60.0).has_point(world):
		return false
	var dir := world - sim.balls[0].pos
	if dir.length() >= 10.0:
		aim = roundi(rad_to_deg(dir.angle()) * 10.0)
		sfx.on_aim_drag(dir.length() / 600.0)
		_preview()
	return true


## Boon heals on every wall bounce would bury the fight in popups and wisps.
func _consume(events: Array[Dictionary]) -> void:
	var shown: Array[Dictionary] = []
	for e in events:
		if e.type == "heal" and e.get("boon", false):
			continue
		if e.type == "shield":
			var b := sim.balls[e.target]
			arena._add_popup(b.pos + Vector2(0, -b.radius - 50), "BUBBLE +%d" % roundi(e.amount), Color("7cc4ff"))
			sfx.play("heal")
			continue
		if e.type == "shield_hit":
			var t := sim.balls[e.target]
			arena._add_popup(t.pos + Vector2(28, -t.radius - 10), "-%d" % ceili(e.amount), Color("7cc4ff"))
			continue
		shown.append(e)
	arena.consume_events(shown)
	sfx.consume_events(shown, sim)


# --- Flow ---------------------------------------------------------------------

func _show_draft() -> void:
	state = State.DRAFT
	sfx.on_menu()
	_board_mode()
	sub_label.text = "Draft 3 critters"
	var grid := _grid()
	for i in setup.cards.size():
		var c: Dictionary = setup.cards[i]
		var picked: bool = i in picks
		var card := _critter_card(c.critter, func(): _toggle_pick(i), GOLD if picked else Kit.LINE, picked)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		_mark("br_card_%d" % i, card)
	var next := Kit.button("Next (%d/3)" % picks.size(), _show_start_boons, "go" if picks.size() == BounceRun.PICKS else "ghost", 32)
	next.disabled = picks.size() != BounceRun.PICKS
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mark("br_next", next)
	# Next and Menu share a row so Next stays on screen below the cards.
	_set_page([grid, Kit.hbox(14, [next, _menu_button()])], "br_draft")


func _toggle_pick(i: int) -> void:
	if i in picks:
		picks.erase(i)
	elif picks.size() < BounceRun.PICKS:
		picks.append(i)
	sfx.play("wall")
	_show_draft()


func _show_start_boons() -> void:
	state = State.START_BOONS
	sfx.on_menu()
	_board_mode()
	sub_label.text = "Pick 3 boons"
	var grid := _grid()
	for i in setup.start_offer.size():
		var id: String = setup.start_offer[i]
		var b := Boons.get_def(id)
		var picked: bool = id in start_picks
		var body := Kit.vbox(4, [Kit.hbox(8, [BoonIcon.make(b.icon, b.rarity, 40), Kit.label(b.name, 26, GOLD)]),
			Kit.label(b.text, 20, Kit.FG if picked else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var card := Kit.card_button(body, func(): _toggle_start_boon(i), GOLD if picked else Kit.LINE, Color("241f55") if picked else Kit.PANEL, 28, 16)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		_mark("br_sboon_%d" % i, card)
	var start := Kit.button("Start run (%d/3)" % start_picks.size(), _start_run, "go" if start_picks.size() == BounceRun.START_BOONS else "ghost", 32)
	start.disabled = start_picks.size() != BounceRun.START_BOONS
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mark("br_start", start)
	var trio := Kit.label("Your trio: %s" % ", ".join(picks.map(func(i): return _name(setup.cards[i].critter))),
		22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	_set_page([trio, grid, Kit.hbox(14, [start, Kit.button("Back", _show_draft, "ghost", 26, 80)])], "br_start_boons")


func _toggle_start_boon(i: int) -> void:
	var id: String = setup.start_offer[i]
	if id in start_picks:
		start_picks.erase(id)
	elif start_picks.size() < BounceRun.START_BOONS:
		start_picks.append(id)
	sfx.play("wall")
	_show_start_boons()


func _start_run() -> void:
	run = BounceRun.new_run(setup, picks, start_picks)
	_save_run()
	print("BOUNCERUN_START day=%d picks=%s boons=%s" % [day, picks, ",".join(start_picks)])
	_show_floor()


func _show_floor() -> void:
	state = State.FLOOR
	sfx.on_menu()
	_board_mode()
	var foe: Dictionary = setup.floors[run.floor]
	sub_label.text = "Pick who to send" # The ladder and the foe card say which floor.
	var foe_box := Kit.vbox(8, [
		Kit.hbox(10, [Kit.caption("Floor %d · %s" % [run.floor + 1, foe.title], PINK), Kit.spacer(),
			Kit.caption("Power %d%%" % roundi(100.0 * BounceRun.FOE_POWER[run.floor]))]),
		Kit.hbox(16, [CritterIcon.make(foe.critter, 1, 110), _expand(Kit.vbox(4, [
			Kit.label(_name(foe.critter), 30),
			_ability_label(foe.critter),
			_boon_strip(foe.boons, 44, false),
		]))]),
	])
	var tier := BounceRun.tier_at(run.floor)
	var trio_cap := "Your trio · T%d" % tier
	var items: Array = [_ladder(), Kit.panel(foe_box, Kit.box(Color("2a1030"), PINK, 32, 2, 20)), Kit.caption(trio_cap)]
	for s in BounceRun.PICKS:
		var c := BounceRun.card(setup, run, s)
		var out: bool = run.out[s]
		var card := _critter_card(c.critter, func(): _choose_fighter(s), Kit.LINE if out else Kit.ACCENT, false, out, BounceRun.tier_at(run.floor))
		card.disabled = out
		items.append(card)
		if not out:
			_mark("br_send_%d" % s, card)
	items.append(Kit.caption("Your boons"))
	items.append(_boon_strip(run.boons, 64))
	items.append(_menu_button())
	_set_page(items, "br_floor")


func _choose_fighter(s: int) -> void:
	slot = s
	state = State.AIM
	_arena_mode()
	aim = MatchSim.AIM_AT_CENTRE[0]
	arena.clear_effects()
	_preview()
	info_label.text = FightSpeed.aim_hint() # The matchup is on the arena and the HUD.
	var launch := Kit.button("Launch", _launch, "go", 34)
	_mark("br_launch", launch)
	_set_panel([Kit.hbox(14, [launch, Kit.button("Back", _show_floor, "ghost", 30)])], "br_aim")


func _preview() -> void:
	sim = MatchSim.new(BounceRun.fight_config(setup, run, slot, aim))
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))
	_update_hud()


func _launch() -> void:
	if state != State.AIM:
		return
	sfx.play("launch")
	# Saved before the fight plays, so closing the app mid-fight can't undo a loss.
	run.launched = {"slot": slot, "aim": aim}
	_save_run()
	sim = MatchSim.new(BounceRun.fight_config(setup, run, slot, aim))
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	state = State.FIGHT
	sfx.on_fight_start(sim)
	info_label.text = ""
	var speed := FightSpeed.picker(28)
	var skip := Kit.button("Skip", _skip, "ghost", 28)
	_mark("br_skip", skip)
	_set_panel([Kit.hbox(14, [speed, skip])], "br_fight")
	print("BOUNCERUN_FIGHT floor=%d slot=%d aim=%d" % [run.floor + 1, slot, aim])


func _skip() -> void:
	while not sim.finished:
		sim.step()
	arena.clear_effects()


func _finish_fight() -> void:
	state = State.RESULT
	var won := sim.winner == 0
	var cleared_floor: int = run.floor + 1
	run.erase("launched")
	BounceRun.record(setup, run, slot, aim, sim.winner, sim.tick)
	_save_run()
	sfx.on_result(sim.winner)
	print("BOUNCERUN_RESULT floor=%d won=%s ticks=%d over=%s" % [cleared_floor, won, sim.tick, run.over])
	var title := "FLOOR %d CLEARED!" % cleared_floor if won else "%s IS OUT!" % _name(BounceRun.card(setup, run, slot).critter).to_upper()
	if won and run.over:
		title = "RUN CLEARED!"
	var head := Kit.label(title, 40, Kit.GOOD if won else PINK, HORIZONTAL_ALIGNMENT_CENTER)
	# The result as a card: your critter's face by the headline, then the run's floor pips.
	var face := CritterIcon.make(BounceRun.card(setup, run, slot).critter, 1, 64)
	face.still = true
	var top := Kit.hbox(10, [face, head], BoxContainer.ALIGNMENT_CENTER)
	if won:
		info_label.text = "Pick a boon next!" if not run.over else "All %d floors in %s." % [BounceRun.FLOORS, _clock(run.ticks)]
	else:
		var left := BounceRun.living(run).size()
		info_label.text = "Your trio is out." if run.over else "%d left. Send another!" % left
	var next := Kit.button("Continue", _after_result, "go", 34)
	_mark("br_continue", next)
	_set_panel([top, _floor_pips(BounceRun.score(run).floors), next], "br_result")


## One pip per floor: cleared ones lit gold, the rest dim.
func _floor_pips(cleared: int) -> Control:
	var row := Kit.hbox(8, [], BoxContainer.ALIGNMENT_CENTER)
	for i in BounceRun.FLOORS:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(22, 22)
		pip.add_theme_stylebox_override("panel", Kit.box(GOLD if i < cleared else Kit.PANEL2, Color(GOLD, .5) if i < cleared else Kit.LINE, 999, 2, 0))
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pip)
	return row


## A fight launched before the app closed: the sim is deterministic, so play
## it out now and count it.
func _settle_launched_fight() -> void:
	var l: Dictionary = run.launched
	run.erase("launched")
	var result := MatchSim.new(BounceRun.fight_config(setup, run, int(l.slot), int(l.aim))).run_to_end()
	BounceRun.record(setup, run, int(l.slot), int(l.aim), result.winner, result.ticks)
	_save_run()
	print("BOUNCERUN_SETTLED slot=%d won=%s" % [int(l.slot), result.winner == 0])


func _after_result() -> void:
	if run.over:
		_finish_run()
	elif not run.offer.is_empty():
		_show_boon()
	else:
		_show_floor()


func _show_boon() -> void:
	state = State.BOON
	_board_mode()
	var up := BounceRun.tier_at(run.floor) > BounceRun.tier_at(run.floor - 1)
	sub_label.text = ("Trio is now T%d! Pick a boon." % BounceRun.tier_at(run.floor)) if up else "Pick a boon"
	var items: Array = [_ladder()]
	for i in run.offer.size():
		var id: String = run.offer[i]
		var b := Boons.get_def(id)
		var col: Color = Roster.RARITY_COLORS[b.rarity]
		var who := ""
		if b.has("for"):
			who = "For %s only" % ", ".join(_trio_with(b.for))
		var head := Kit.hbox(10, [Kit.label(b.name, 32, col), Kit.spacer(), Kit.chip(Roster.RARITY_NAMES[b.rarity], col)])
		var text := Kit.vbox(4, [head, Kit.label(b.text, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
		if who != "":
			text.add_child(Kit.label(who, 20, Kit.MUTED))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var body := Kit.hbox(14, [BoonIcon.make(b.icon, b.rarity, 84), text])
		var card := Kit.card_button(body, func(): _take_boon(id), col, Roster.rarity_bg(b.rarity, Kit.PANEL, 0.3 if b.rarity == "legendary" else 0.18), 28, 20)
		items.append(card)
		_mark("br_boon_%d" % i, card)
	if not run.boons.is_empty():
		items.append(Kit.caption("Your boons"))
		items.append(_boon_strip(run.boons, 52))
	items.append(Kit.label("Next: %s %s" % [setup.floors[run.floor].title, _name(setup.floors[run.floor].critter)], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	_set_page(items, "br_boon")


func _take_boon(id: String) -> void:
	BounceRun.take_boon(run, id)
	_save_run()
	sfx.play("heal")
	print("BOUNCERUN_BOON %s" % id)
	_show_floor()


func _finish_run() -> void:
	if ranked:
		stats.played += 1
		stats.best_floors = maxi(stats.best_floors, run.floor)
		if run.floor >= BounceRun.FLOORS:
			stats.clears += 1
		_save.set_value("pending", str(day), run)
		_save_run()
		_post(run)
	_show_over()


func _show_over() -> void:
	state = State.OVER
	sfx.on_menu()
	_board_mode()
	var s := BounceRun.score(run)
	var cleared: bool = s.floors >= BounceRun.FLOORS
	sub_label.text = ("Ranked" if ranked else "Practice") + " · resets 00:00 UTC"
	var head := Kit.label("RUN CLEARED!" if cleared else "Run over", 52, GOLD if cleared else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	var line := Kit.label("%d/%d floors · %d lives · %s" % [s.floors, BounceRun.FLOORS, s.lives, _clock(s.ticks)], 30, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	share_button = Kit.button("Share", func(): share_button.text = _share(), "go", 30)
	var practice := Kit.button("Practice run", _practice, "ghost", 28)
	_mark("br_practice", practice)
	var items: Array = [head, line, _ladder(), Kit.hbox(14, [share_button, practice])]
	items.append(Kit.label("Best %d · %d/%d cleared" % [stats.best_floors, stats.clears, stats.played], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	items.append(_leaderboard())
	items.append(_menu_button())
	_set_page(items, "br_over")
	if _board_rows == null and _board_note == "":
		_fetch_board()


## Same day's run again, unranked, from a fresh draft.
func _practice() -> void:
	ranked = false
	run = {}
	picks = []
	start_picks = []
	_board_rows = null
	_board_note = ""
	_show_draft()


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://game/main.tscn")


# --- Leaderboard ----------------------------------------------------------------

func _post(finished: Dictionary) -> void:
	var ok := await board.submit(finished)
	if ok:
		_save.erase_section_key("pending", str(finished.day))
		_save.save(save_path)
	_fetch_board()


func _retry_pending_post() -> void:
	if not _save.has_section("pending"):
		return
	for key in _save.get_section_keys("pending"):
		var pending: Dictionary = _save.get_value("pending", key)
		var ok := await board.submit(pending)
		if ok:
			_save.erase_section_key("pending", key)
			_save.save(save_path)


func _fetch_board() -> void:
	_board_note = "Loading the board..."
	var res := await board.fetch(day)
	if res.ok:
		_board_rows = res.rows
		_board_note = ""
	else:
		_board_rows = null
		_board_note = "Offline. Score posts later." if ranked else "Offline."
	if state == State.OVER:
		_show_over()


func _leaderboard() -> Control:
	var rows := Kit.vbox(6, [Kit.caption("Leaderboard")])
	if _board_rows == null:
		rows.add_child(Kit.label(_board_note, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	elif _board_rows.is_empty():
		rows.add_child(Kit.label("No scores yet today. Be the first!", 22, Kit.MUTED))
	else:
		for r in _board_rows:
			var col: Color = GOLD if r.get("is_me", false) else Kit.FG
			rows.add_child(Kit.hbox(10, [
				Kit.label("#%d" % int(r.rank), 22, col), Kit.label(str(r.display_name), 22, col), Kit.spacer(),
				Kit.label("F%d · %d" % [int(r.floors), int(r.lives)], 22, col), Kit.glyph("heart", 20, PINK),
				Kit.label("· %s" % _clock(int(r.ticks)), 22, col)]))
	return Kit.panel(rows, Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 20))


# --- Sharing and saving ---------------------------------------------------------

func share_text() -> String:
	var s := BounceRun.score(run)
	var ladder := ""
	for f in BounceRun.FLOORS:
		ladder += "🟩" if f < s.floors else ("🟥" if f == s.floors else "⬛")
	return "Battle Balls Bounce Run #%d: floor %d/%d, %d left\n%s\n%s" % [day, s.floors, BounceRun.FLOORS, s.lives, ladder, SHARE_URL]


func _share() -> String:
	var text := share_text()
	if OS.has_feature("web"):
		var how = JavaScriptBridge.eval("""(function (t) {
			if (navigator.share) { navigator.share({ text: t }).catch(function () { navigator.clipboard && navigator.clipboard.writeText(t); }); return 'share'; }
			if (navigator.clipboard) { navigator.clipboard.writeText(t); return 'copy'; }
			return '';
		})(%s)""" % JSON.stringify(text), true)
		if how == "share":
			return "SHARED!"
	DisplayServer.clipboard_set(text)
	return "COPIED!"


func _load() -> void:
	if _save.load(save_path) != OK:
		return
	for key in stats:
		stats[key] = _save.get_value("stats", key, stats[key])
	var ranked_run: Dictionary = _save.get_value("runs", str(day), {})
	var practice: Dictionary = _save.get_value("practice", str(day), {})
	# A run saved under older rules can't continue under these.
	if ranked_run.get("rules", 1) != BounceRun.RULES_VERSION:
		ranked_run = {}
	if practice.get("rules", 1) != BounceRun.RULES_VERSION:
		practice = {}
	# The ranked run until it's over and a practice run has begun. Other days
	# without a ranked run are practice only.
	ranked = (not ranked_run.is_empty() and (not ranked_run.over or practice.is_empty())) or (day == today and ranked_run.is_empty())
	run = ranked_run if ranked else practice


func _save_run() -> void:
	_save.set_value("runs" if ranked else "practice", str(day), run)
	for key in stats:
		_save.set_value("stats", key, stats[key])
	_save.save(save_path)


# --- UI -------------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Kit.theme()
	layer.add_child(ui)
	title_label = Kit.label("BOUNCE RUN #%d" % day, 48, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_outline_color", Color(Kit.ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	sub_label = Kit.label("", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	hud_label = Kit.label("", 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	info_label = Kit.label("", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	panel = Kit.vbox(14)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page = Kit.vbox(18)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	rules_button = Kit.card_button(Glyph.make("info", 34, Kit.FG), _show_rules, Kit.LINE, Kit.PANEL, 999, 12)
	rules_button.focus_mode = Control.FOCUS_NONE
	_mark("br_rules", rules_button)
	for c in [title_label, sub_label, hud_label, info_label, panel, scroll, rules_button]:
		ui.add_child(c)
	for c in [title_label, sub_label, hud_label, info_label]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _board_mode() -> void:
	arena.visible = false
	arena.sim = null
	for c in [hud_label, info_label, panel]:
		c.visible = false
	scroll.visible = true
	sub_label.visible = true
	_layout()


func _arena_mode() -> void:
	arena.visible = true
	for c in [hud_label, info_label, panel]:
		c.visible = true
	scroll.visible = false
	sub_label.visible = false # The HUD takes its place above the arena.
	_layout()


## Portrait stacks arena over the panel; wide screens put the panel beside it.
func _layout() -> void:
	if get_viewport() == null:
		return
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
		side = clampf(size.y - top - PANEL_HEIGHT - bottom_margin, 300.0, minf(ARENA_PIXELS, size.x - 40.0))
		left = (size.x - side) / 2.0
		panel_width = maxf(side, minf(ARENA_PIXELS, size.x - 40.0))
		panel_pos = Vector2((size.x - panel_width) / 2.0, top + side + 20.0)
	arena.view_scale = side / MatchSim.ARENA_SIZE
	arena.position = Vector2(left, top)
	_place(title_label, Vector2(0, 30), Vector2(size.x, 60))
	rules_button.position = Vector2(size.x - 92.0, 26.0)
	rules_button.size = Vector2.ZERO
	_place(sub_label, Vector2(20, 96), Vector2(size.x - 40, 40))
	_place(hud_label, Vector2(left, 110), Vector2(side, 50))
	_place(info_label, panel_pos, Vector2(panel_width, 70))
	_place(panel, panel_pos + Vector2(0, 80), Vector2(panel_width, PANEL_HEIGHT - 80.0))
	var page_width := minf(680.0, size.x - 40.0)
	_place(scroll, Vector2((size.x - page_width) / 2.0, 150), Vector2(page_width, size.y - 150 - bottom_margin))
	page.custom_minimum_size.x = page_width
	arena.queue_redraw()


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _set_panel(children: Array, screen: String) -> void:
	_replace_children(panel, children)
	_report.call_deferred(screen)


func _set_page(children: Array, screen: String) -> void:
	_replace_children(page, children)
	scroll.scroll_vertical = 0
	_report.call_deferred(screen)


func _replace_children(box: Control, children: Array) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	for c in children:
		box.add_child(c)


## Logs where marked controls are, for the smoke test ("UI_AT name x y").
func _mark(name: String, c: Control) -> void:
	_marks[name] = c


func _report(screen: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	print("UI_SCREEN ", screen)
	for k in _marks.keys():
		if not is_instance_valid(_marks[k]):
			_marks.erase(k)
	for k in _marks:
		var c = _marks[k]
		if is_instance_valid(c) and c.is_visible_in_tree():
			var p: Vector2 = c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])


func _update_hud() -> void:
	if sim == null:
		hud_label.text = ""
		return
	var parts: Array = []
	for b in sim.balls:
		var hp := str(maxi(0, ceili(b.hp)))
		if b.shield > 0.0:
			hp += "+%d" % ceili(b.shield)
		parts.append(hp)
	var clock := "%.0fs" % sim.time()
	if sim.in_overtime():
		clock = "OVERTIME x%.1f" % sim.damage_multiplier()
	hud_label.text = "You %s   |   %s   |   %s Foe" % [parts[0], clock, parts[1]]


## A critter and what its ability does, as a tappable card.
func _critter_card(critter: String, on_press: Callable, border: Color, picked := false, out := false, tier := 1) -> Button:
	var text := Kit.vbox(2, [Kit.label(_name(critter), 28, Kit.MUTED if out else (GOLD if picked else Kit.FG))])
	text.add_child(Kit.label("OUT", 22, PINK) if out else _ability_label(critter))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := CritterIcon.make(critter, tier, 80)
	if out:
		icon.modulate = Color(1, 1, 1, 0.35)
	var row := Kit.hbox(12, [icon, text])
	return Kit.card_button(row, on_press, border, Color("241f55") if picked else Kit.PANEL, 28, 14)


func _ability_label(critter: String) -> Label:
	var what := Kit.label(_ability_text(critter), 19, ABILITY, HORIZONTAL_ALIGNMENT_LEFT, true)
	what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return what


## Boons as a wrapping row of badges, each with its name under it (names
## off for a foe's long list). Tap one for its card (_show_boon_info).
func _boon_strip(ids: Array, side: float, names := true) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 8)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for k in ids.size():
		var id: String = ids[k]
		var b := Boons.get_def(id)
		var tile := Kit.vbox(2, [BoonIcon.make(b.icon, b.rarity, side)])
		if names:
			var n := Kit.label(b.name.replace(" ", "\n"), 16, Roster.RARITY_COLORS[b.rarity], HORIZONTAL_ALIGNMENT_CENTER)
			n.custom_minimum_size.x = side + 24.0
			tile.add_child(n)
		var btn := Kit.card_button(tile, _show_boon_info.bind(id), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 16, 2)
		btn.focus_mode = Control.FOCUS_NONE
		flow.add_child(btn)
		_mark("br_held_%d" % k if names else "br_foe_boon_%d" % k, btn)
	return flow


## A boon's card over the page: badge, name, rarity (shape and word, not just
## colour) and what it does. Tap anywhere to close.
func _show_boon_info(id: String) -> void:
	var b := Boons.get_def(id)
	var col: Color = Roster.RARITY_COLORS[b.rarity]
	var rarity: String = Roster.RARITY_NAMES[b.rarity] + " boon"
	var lines: Array = [
		BoonIcon.make(b.icon, b.rarity, 140),
		Kit.label(b.name, 40, col, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.chip(rarity, col, 20),
		Kit.label(b.text, 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true),
	]
	if b.has("for"):
		lines.append(Kit.label("Only for critters with the %s ability." % b.for.capitalize(), 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	_overlay_card(lines, Kit.box(Roster.rarity_bg(b.rarity, Kit.PANEL, 0.18), col, 32, 3, 28), "br_boon_close")
	print("BOUNCERUN_BOON_INFO %s" % id)
	_report.call_deferred("br_boon_info")


## How a run works, behind the "i": the screens only show what you are deciding.
func _show_rules() -> void:
	var lines: Array = [Kit.label("How Bounce Run works", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)]
	for t in [
		"Draft 3 critters and 3 starting boons, then climb %d floors. Foes start easy and get tougher." % BounceRun.FLOORS,
		"Pick who to send each floor. Lose and that critter is out; lose all three and the run ends.",
		"Your trio starts at T1 and goes up a tier every %d floors, up to T5 on the last floors. Foes stay T1." % BounceRun.FLOORS_PER_TIER,
		"Win a floor to pick another boon. Boons power your whole trio. Rarer boons are stronger; tap a held boon to see it.",
		"A foe's Power is next to your trio's: 100% is even.",
		"One ranked run a day. Ranked by floors, lives, then time.",
	]:
		lines.append(Kit.label(t, 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	_overlay_card(lines, Kit.box(Kit.PANEL, Kit.ACCENT, 32, 3, 28), "br_rules_close")
	_report.call_deferred("br_rules")


## A card over the page on a dimmed backdrop; tapping outside or Close shuts it.
func _overlay_card(lines: Array, style: StyleBox, close_mark: String) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := Button.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_style := Kit.box(Color(.02, .015, .06, .7), Color(0, 0, 0, 0), 0, 0, 0)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		dim.add_theme_stylebox_override(st, dim_style)
	dim.pressed.connect(root.queue_free)
	root.add_child(dim)
	var close := Kit.button("Close", root.queue_free, "ghost", 26, 70)
	_mark(close_mark, close)
	var w := minf(600.0, get_viewport().get_visible_rect().size.x - 40.0)
	for l in lines:
		if l is Label and l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			l.custom_minimum_size.x = w - 56.0
	var card := Kit.panel(Kit.vbox(14, lines + [close]), style)
	card.custom_minimum_size.x = w
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(card)
	root.add_child(centre)
	ui.add_child(root)


func _expand(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	return grid


## One pip per floor: cleared floors green, the current one outlined.
func _ladder() -> Control:
	var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for f in BounceRun.FLOORS:
		var done: bool = not run.is_empty() and f < run.floor
		var current: bool = not run.is_empty() and f == run.floor and not run.over
		var lost: bool = not run.is_empty() and run.over and f == run.floor
		var col := Kit.GOOD if done else (PINK if lost else (Kit.ACCENT if current else Kit.LINE))
		var pip := Kit.panel(Kit.label(str(f + 1), 22, Kit.BG if done else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.box(col if done else Kit.PANEL, col, 14, 3, 6))
		pip.custom_minimum_size = Vector2(56, 52)
		row.add_child(pip)
	return row


func _menu_button() -> Button:
	return Kit.button("Menu", _go_menu, "ghost", 26, 80)


func _trio_with(ability: String) -> Array:
	var out: Array = []
	for s in BounceRun.PICKS:
		var c := BounceRun.card(setup, run, s)
		if BallDefs.get_def(c.critter).ability == ability and not _name(c.critter) in out:
			out.append(_name(c.critter))
	return out


static func _name(critter: String) -> String:
	return BallDefs.get_def(critter).display_name


## The critter's ability in a sentence, without the leading "Type." its
## description starts with (the card already shows the name).
static func _ability_text(critter: String) -> String:
	var d: String = BallDefs.get_def(critter).description
	var cut := d.find(". ")
	return d.substr(cut + 2) if cut >= 0 and cut < 24 else d


static func _clock(ticks: int) -> String:
	var seconds := roundi(float(ticks) / MatchSim.TICK_RATE)
	return "%d:%02d" % [seconds / 60, seconds % 60]


func _url_params() -> Dictionary:
	var params := {}
	if not OS.has_feature("web"):
		return params
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	return params
