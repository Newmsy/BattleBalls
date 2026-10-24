## Bounce Run: draft a trio and 3 starting boons, then climb a 20-floor map
## of fights, elites, events, shops, Charge Pads and chests to the Champion.
## The run comes from sim/bounce_run.gd and the UTC day; one ranked run a day
## posts to the shared leaderboard, then practice runs are unranked.
## URL params: ?mode=bouncerun&day=3 (play another day's run, unranked),
## &offline=1 (never touch the leaderboard).
extends Node2D

const FamilyEdge := preload("res://game/ui/family_edge.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const FightAim := preload("res://game/fight_aim.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")
const BoonIcon := preload("res://game/ui/boon_icon.gd")
const BounceBoard := preload("res://game/online/bounce_board.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const A11y := preload("res://game/a11y.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const FinisherCam := preload("res://game/finisher_cam.gd")
const MapView := preload("res://game/bounce_run/map_view.gd")
const LivingArt := preload("res://game/bounce_run/living_art.gd")
const ART := "res://game/bounce_run/art/%s.png"

enum State { DRAFT, START_BOONS, MAP, FLOOR, AIM, FIGHT, RESULT, BOON, EVENT, SHOP, REST, OVER }

const SAVE_PATH := "user://bounce_run.cfg"
const SHARE_URL := "https://battleballs.vercel.app/?mode=bouncerun"
const ARENA_PIXELS := 680.0
const PANEL_HEIGHT := 330.0
const MAP_ROWS_SHOWN := 5.2 ## Floors the map shows at once; it scrolls for the rest.
const FightSpeed := preload("res://game/fight_speed.gd")
const FightLayout := preload("res://game/fight_layout.gd")
const FightHud := preload("res://game/fight_hud.gd")
const FighterStrip := preload("res://game/fighter_strip.gd")
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
var aimer := FightAim.new() ## Tap the arena to aim, let go to launch.
var _result_popup: Control
var _marks := {}
var _board_rows = null ## Leaderboard rows once fetched; null while loading.
var _board_note := ""

var arena: ArenaView
var arena_clip: Control ## Holds the arena; clips it while the finisher cam zooms.
var finisher: FinisherCam
var _hold := -1.0 ## Real seconds on the KO face so far, or -1 before the blow.
var _skipped := false ## Skip also skips the finisher.
var sfx: Sfx
var board: BounceBoard
var ui: Control
var title_label: Label
var sub_label: Label
var hud_label: Label
var fight_hud: FightHud ## Both health bars, above the arena, as on every fight screen.
var fighter_strip: Control ## The two fighters' cards under the arena.
var info_label: Label
var panel: VBoxContainer
var scroll: ScrollContainer
var page: VBoxContainer
var share_button: Button
var rules_button: Button ## The "i" in the corner: how a run works.
var map_view: MapView
var map_scroll: ScrollContainer


func _ready() -> void:
	if arena != null:
		return # Tests may start the scene by hand before the tree does.
	TouchInput.ensure(self) # Its Back, Home and Close buttons take the edge swipe too.
	today = BounceRun.day_number(Time.get_unix_time_from_system())
	day = today
	var params := _url_params()
	if params.get("day", "").is_valid_int():
		day = maxi(1, int(params.day))
	_load()
	# A practice run carries its own seed; the ranked run is the day's tower.
	setup = BounceRun.generate(day, int(run.get("seed", 0)))
	arena_clip = Control.new()
	arena_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena_clip)
	arena = ArenaView.new()
	arena_clip.add_child(arena)
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
	else:
		_show_next()


func _process(delta: float) -> void:
	if state == State.FIGHT:
		if _advance_fight(delta, FightSpeed.current()):
			_unzoom()
			_finish_fight()
		_update_hud()
	else:
		arena.advance_effects(delta)


## Steps the fight in real time at `speed`, slowing into the finisher cam (the
## killing blow in slow motion, zoomed in, then a beat on the KO face), as in
## Quick fight (game/main.gd). Render-only. True once the fight and its
## finisher are over. Reduced motion keeps the KO face without slow-mo or zoom.
func _advance_fight(delta: float, speed: float) -> bool:
	var finishing := finisher.ko_tick >= 0 and not _skipped
	var cinematic := finishing and not A11y.reduced_motion
	var rate := speed
	_accumulator += delta
	var steps := 0
	while not sim.finished and steps < 32:
		rate = finisher.time_scale(sim.tick, speed) if cinematic else speed
		if _accumulator < MatchSim.DT / rate:
			break
		_accumulator -= MatchSim.DT / rate
		arena.snapshot_positions()
		sim.step()
		_consume(sim.events)
		steps += 1
	arena.render_alpha = 1.0 if sim.finished else clampf(_accumulator / (MatchSim.DT / rate), 0.0, 1.0)
	if not finishing:
		arena.advance_effects(delta * speed)
		return sim.finished
	if sim.finished:
		if _hold < 0.0:
			_hold = 0.0
			arena.ko_ball = finisher.loser
		else:
			_hold += delta
		rate = 0.5
	if cinematic and finisher.active(sim.tick):
		var t := sim.tick - 1.0 + arena.render_alpha
		var z := finisher.zoom(t, maxf(0.0, _hold))
		var target := finisher.focus(arena.ball_pos(sim.balls[finisher.loser]), arena.ball_pos(sim.balls[finisher.winner]), z)
		var start := not arena_clip.clip_contents
		arena.set_camera(z, target if start else FinisherCam.follow(arena.cam_focus, target, delta))
		arena.finisher_amount = clampf(finisher.progress(t) / 0.25, 0.0, 1.0)
		arena_clip.clip_contents = true
	arena.advance_effects(delta * rate)
	return _hold >= FinisherCam.HOLD


## Back to the whole arena, keeping the KO face on the critter that fell.
func _unzoom() -> void:
	arena.finisher_amount = 0.0
	arena.set_camera(1.0, Vector2.ONE * MatchSim.ARENA_SIZE / 2.0)
	arena_clip.clip_contents = false


## Puts the arena (and its clip) at `at`, `side` pixels square.
func _fit_arena(at: Vector2, side: float) -> void:
	arena_clip.position = at
	arena_clip.size = Vector2(side, side)
	arena.fit(Vector2.ZERO, side)


func _unhandled_input(event: InputEvent) -> void:
	if state != State.AIM:
		return
	aimer.feed(event, arena, sim.balls[0].pos, func(a: int):
		aim = a
		_preview(), _launch, sfx)


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
		var card := _critter_card(c.critter, func(): _toggle_pick(i), picks.find(i), false, 1, true)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		_mark("br_card_%d" % i, card)
	var next := Kit.button("Next (%d/3)" % picks.size(), _show_start_boons, "go" if picks.size() == BounceRun.PICKS else "ghost", 32)
	next.disabled = picks.size() != BounceRun.PICKS
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mark("br_next", next)
	# Next and Menu share a row so Next stays on screen below the cards.
	_replace_children(page, [grid, Kit.hbox(14, [next, _menu_button()])])
	scroll.scroll_vertical = 0
	_fit_draft.call_deferred(grid)


## Shrinks the stacked draft cards until the page fits without scrolling:
## smaller critter icons first, then smaller ability text, then the rarity
## chips go (the tint and rim still show rarity). Small phones with Larger
## text only. Reports the screen once it has settled.
func _fit_draft(grid: Control) -> void:
	var icons := grid.find_children("*", "", true, false).filter(func(c): return c.has_meta("draft_icon"))
	var texts := grid.find_children("*", "Label", true, false).filter(func(c): return c.has_meta("draft_text"))
	var chips := grid.find_children("*", "", true, false).filter(func(c): return c.has_meta("draft_chip"))
	var font := 19
	for _i in 14:
		await get_tree().process_frame
		if not is_instance_valid(grid) or not grid.is_inside_tree():
			return
		# Leaves room for the corner Sound toggle under the buttons.
		var over := page.get_combined_minimum_size().y - (scroll.size.y - 36.0)
		if over <= 0.0:
			break
		var side: float = icons[0].custom_minimum_size.x if icons else 0.0
		if side > 48.0:
			side = maxf(48.0, side - ceilf(over / 3.0))
			for icon in icons:
				icon.custom_minimum_size = Vector2(side, side)
		elif font > 15:
			font -= 1
			for t in texts:
				t.add_theme_font_size_override("font_size", A11y.font(font))
		elif chips and chips[0].visible:
			for c in chips:
				c.visible = false
		else:
			break
	_report("br_draft")


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
	var trio := Kit.hbox(12, [Kit.caption("Your trio"),
		FighterTag.named_row(picks.map(func(i): return setup.cards[i].critter), 44, 22)], BoxContainer.ALIGNMENT_CENTER)
	_set_page([_art("banner_draft"), trio, grid, Kit.hbox(14, [start, Kit.button("Back", _show_draft, "ghost", 26, 80)])], "br_start_boons")


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
	_show_next()


func _show_floor() -> void:
	state = State.FLOOR
	sfx.on_menu()
	_board_mode()
	var foe := BounceRun.foe(setup, run)
	var row := _row()
	var tier := BounceRun.tier_at(row)
	var big: bool = foe.kind in ["elite", "boss"]
	var rim: Color = MapView.COLORS.get(foe.kind, PINK)
	sub_label.text = "Pick who to send"
	var foe_box := Kit.vbox(8, [
		Kit.hbox(10, [Kit.caption("Floor %d · %s · T%d" % [row + 1, foe.title, tier], rim), Kit.spacer(),
			Kit.caption("Power %d%%" % roundi(100.0 * foe.power))]),
		Kit.hbox(16, [CritterIcon.make(foe.critter, tier, 132 if big else 110), _expand(Kit.vbox(4, [
			Kit.label(_name(foe.critter), 30),
			_ability_label(foe.critter),
		]))]),
	])
	var hurt := _foe_hp_frac()
	if hurt < 1.0:
		# The foe keeps the damage your last critter did (sim/bounce_run.gd).
		foe_box.add_child(Kit.hbox(10, [_expand(Kit.bar(hurt, PINK, 16)), Kit.caption("%d%% HP left" % ceili(100.0 * hurt), PINK)]))
	if big:
		foe_box.add_child(Kit.label("Bigger and tougher than a normal foe." if foe.kind == "elite" else "Beat the Champion to clear the run!", 20, rim, HORIZONTAL_ALIGNMENT_LEFT, true))
	elif foe.kind == "rival":
		foe_box.add_child(Kit.label("Losing knocks nobody out, but costs 20 Buttons.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var trio_cap := "Your trio · T%d" % tier
	var items: Array = [_status_row(), Kit.panel(foe_box, Kit.box(Color("2a1030"), rim, 32, 4 if big else 2, 20)), Kit.caption(trio_cap)]
	for s in BounceRun.PICKS:
		var c := BounceRun.card(setup, run, s)
		var out: bool = run.out[s]
		var card := _critter_card(c.critter, func(): _choose_fighter(s), -1, out, tier + (1 if run.spar == s else 0))
		card.disabled = out
		if not out:
			FamilyEdge.attach(card, [c.critter], [foe.critter], 12, 26)
		items.append(card)
		if not out:
			_mark("br_send_%d" % s, card)
	if run.hatchling != "":
		var hatch := Kit.label("+ your hatchling %s fights beside whoever you send" % _name(run.hatchling), 20, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true)
		items.append(Kit.hbox(10, [CritterIcon.face(run.hatchling, 44, maxi(1, tier - 1)), _expand(hatch)]))
	items.append(Kit.caption("Your boons"))
	items.append(_boon_strip(run.boons, 56))
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
	arena.elites = _elite_balls()
	arena.reset_camera() # Drops the last fight's KO face.
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))
	_update_hud()


func _launch() -> void:
	if state != State.AIM:
		return
	sfx.play("launch")
	# Saved before the fight plays, so closing the app mid-fight can't undo a loss.
	run.launched = {"slot": slot, "aim": aim}
	_save_run()
	var config := BounceRun.fight_config(setup, run, slot, aim)
	sim = MatchSim.new(config)
	arena.sim = sim
	arena.elites = _elite_balls()
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	arena.reset_camera()
	arena_clip.clip_contents = false
	finisher = FinisherCam.plan(config)
	_accumulator = 0.0
	_hold = -1.0
	_skipped = false
	state = State.FIGHT
	sfx.on_fight_start(sim)
	info_label.text = ""
	# Speed, Skip and Sound: the bottom row of pills every fight screen has.
	var skip := FightLayout.skip_pill(_skip)
	_mark("br_skip", skip.button)
	_set_panel([Kit.hbox(14, [FightSpeed.picker(), skip])], "br_fight")
	_layout() # The cards take the room the aim controls had.
	print("BOUNCERUN_FIGHT floor=%d slot=%d aim=%d" % [_row() + 1, slot, aim])


func _skip() -> void:
	_skipped = true
	while not sim.finished:
		sim.step()
	arena.clear_effects()


func _finish_fight() -> void:
	state = State.RESULT
	var won := sim.winner == 0
	var cleared_floor: int = _row() + 1
	var rival: bool = BounceRun.foe(setup, run).kind == "rival"
	run.erase("launched")
	BounceRun.record(setup, run, slot, aim, sim.winner, sim.tick, sim.team_hp(1))
	_save_run()
	sfx.on_result(sim.winner)
	print("BOUNCERUN_RESULT floor=%d won=%s ticks=%d over=%s" % [cleared_floor, won, sim.tick, run.over])
	var info := ""
	if rival:
		info = "Pick an Epic boon next!" if won else "-20 Buttons. Nobody is out."
	elif won:
		info = "Pick a boon next!" if not run.over else "All %d floors in %s." % [BounceRun.FLOORS, _clock(run.ticks)]
	else:
		var left := BounceRun.living(run).size()
		info = "Your trio is out." if run.over else "%d left. The foe has %d%% HP left!" % [left, ceili(100.0 * _foe_hp_frac())]
	info_label.text = ""
	_replace_children(panel, [])
	# The result popup every fight ends on (ResultPopup).
	var next := Kit.button("Continue", _after_result, "go", 26, 84)
	_mark("br_continue", next)
	var caption := "Bounce Run · " + ("Run cleared" if won and run.over else "Floor %d" % cleared_floor)
	var line := Kit.label(info, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	line.custom_minimum_size.x = 560.0 # Wrapped text needs a width before the sheet measures itself.
	var body := [line, _floor_pips(BounceRun.score(run).floors)]
	sfx.toggle_hidden = true # The popup covers the bottom row of pills.
	_result_popup = ResultPopup.show_over(ui, ResultPopup.content(caption, ResultPopup.outcome_of(sim.winner), body, [next]), _report.bind("br_result"))
	sfx.hold_victory(_result_popup)


## One pip per floor: cleared ones lit gold, the rest dim.
func _floor_pips(cleared: int) -> Control:
	var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for i in BounceRun.FLOORS:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(18, 18)
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
	BounceRun.record(setup, run, int(l.slot), int(l.aim), result.winner, result.ticks, result.hp[1])
	_save_run()
	print("BOUNCERUN_SETTLED slot=%d won=%s" % [int(l.slot), result.winner == 0])


func _after_result() -> void:
	if is_instance_valid(_result_popup):
		_result_popup.queue_free()
	sfx.toggle_hidden = false
	if run.over:
		_finish_run()
	else:
		_show_next()


func _show_boon() -> void:
	state = State.BOON
	_board_mode()
	var chest := BounceRun.kind_of(setup, run.at) == "chest"
	sub_label.text = "Glow Chest! Pick a boon" if chest else "Pick a boon"
	var items: Array = [_status_row(), _art("glow_chest" if chest else "banner_boon")]
	for i in run.offer.size():
		var id: String = run.offer[i]
		var b := Boons.get_def(id)
		var col: Color = Roster.RARITY_COLORS[b.rarity]
		var who: Control = null
		if b.has("for"):
			# Faces, not just names: which of your three this boon is for.
			who = FighterTag.named_row(_trio_with(b.for), 34, 20, Kit.MUTED)
			for k in 2:
				var word := Kit.label(["For", "only"][k], 20, Kit.MUTED)
				word.custom_minimum_size.y = 34
				word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				who.add_child(word)
				if k == 0:
					who.move_child(word, 0)
		var head := Kit.hbox(10, [Kit.label(b.name, 32, col), Kit.spacer(), Kit.chip(Roster.RARITY_NAMES[b.rarity], col)])
		var text := Kit.vbox(4, [head, Kit.label(b.text, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
		if who != null:
			text.add_child(who)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var body := Kit.hbox(14, [BoonIcon.make(b.icon, b.rarity, 84), text])
		var card := Kit.card_button(body, func(): _take_boon(id), col, Roster.rarity_bg(b.rarity, Kit.PANEL, 0.3 if b.rarity == "legendary" else 0.18), 28, 20)
		items.append(card)
		_mark("br_boon_%d" % i, card)
	if not run.boons.is_empty():
		items.append(Kit.caption("Your boons"))
		items.append(_boon_strip(run.boons, 52))
	_set_page(items, "br_boon")


## The trio's tier-up moment over the boon page: a gold burst, the trio
## popping in at the new tier one by one and the new star landing. Reduced
## motion shows the same card without the movement.
func _show_tier_up(tier: int) -> void:
	print("BOUNCERUN_TIER_UP T%d" % tier)
	if not is_inside_tree():
		return # Tests drive the run without a screen.
	var gold_bg := Roster.rarity_bg("legendary", Kit.PANEL, 0.06)
	var faces := Kit.hbox(18, [], BoxContainer.ALIGNMENT_CENTER)
	for slot in BounceRun.PICKS:
		var icon := CritterIcon.make(BounceRun.card(setup, run, slot).critter, tier, 120)
		if run.out[slot]:
			icon.modulate = Color(1, 1, 1, 0.35)
		faces.add_child(_pop_wrap(icon))
	var old_stars := Kit.glyph("stars", 44, Kit.MUTED, tier - 1)
	var new_star := Kit.glyph("stars", 44, GOLD, 1)
	var stars := Kit.hbox(6, [old_stars, _pop_wrap(new_star)], BoxContainer.ALIGNMENT_CENTER)
	var head := Kit.label("TIER UP!", 52, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	var lines: Array = [_art("banner_tier_up", 0.6), head, stars, faces,
		Kit.label("Your trio fights at T%d from now on. So do the foes!" % tier, 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)]
	var burst := Panel.new()
	burst.add_theme_stylebox_override("panel", Kit.box(Color(GOLD, 0.55), Color(0, 0, 0, 0), 999, 0, 0))
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := _overlay_card(lines, Kit.box(gold_bg, GOLD, 32, 4, 28), "br_tier_close")
	var layer: Control = card.get_parent().get_parent() # The overlay's root: dim, burst, then the card.
	layer.add_child(burst)
	layer.move_child(burst, 1)
	sfx.play("summon_legend")
	_report.call_deferred("br_tier_up")
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	var centre := card.get_global_rect().get_center() - layer.get_global_rect().position
	burst.size = Vector2(180, 180)
	burst.position = centre - burst.size / 2.0
	burst.pivot_offset = burst.size / 2.0
	if A11y.motion() == 0.0:
		burst.visible = false
		return
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.7, 0.7)
	new_star.scale = Vector2.ZERO
	var pops: Array = faces.get_children().map(func(w): return w.get_child(0))
	for f in pops:
		f.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(burst, "scale", Vector2(6, 6), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(burst, "modulate:a", 0.0, 0.7)
	for f in pops:
		tw.tween_property(f, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(sfx.play.bind("summon_pop"))
	tw.tween_property(new_star, "scale", Vector2(1.6, 1.6), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(sfx.play.bind("twinkle"))
	tw.tween_property(new_star, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "modulate", Color(1.4, 1.3, 1.0), 0.25)
	tw.tween_property(head, "modulate", Color.WHITE, 0.35)


func _take_boon(id: String) -> void:
	BounceRun.take_boon(run, id)
	_save_run()
	sfx.play("heal")
	print("BOUNCERUN_BOON %s" % id)
	_show_next()


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
	var items: Array = [_art("banner_victory" if cleared else "banner_defeat"), head, line, _floor_pips(s.floors), Kit.hbox(14, [share_button, practice])]
	items.append(Kit.label("Best %d · %d/%d cleared" % [stats.best_floors, stats.clears, stats.played], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	items.append(_leaderboard())
	items.append(_menu_button())
	_set_page(items, "br_over")
	if _board_rows == null and _board_note == "":
		_fetch_board()


## An unranked run on a fresh random tower: new draft, boons and foes.
func _practice() -> void:
	ranked = false
	setup = BounceRun.generate(day, randi_range(1, 999999))
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
		if f == BounceRun.FLOORS / 2 - 1:
			ladder += "\n"
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
	fight_hud = FightHud.new()
	fight_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fight_hud.tags = ["YOU", "FOE"]
	ui.add_child(fight_hud)
	fighter_strip = FighterStrip.new()
	fighter_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fighter_strip)
	info_label = Kit.label("", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	panel = Kit.vbox(14)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page = Kit.vbox(18)
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Kit.centre_column(page) # Short pages sit mid-screen, not at the top.
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
	for c in [hud_label, info_label, panel, fight_hud, fighter_strip]:
		c.visible = false
	scroll.visible = true
	sub_label.visible = true
	_layout()


func _arena_mode() -> void:
	arena.visible = true
	for c in [hud_label, info_label, panel, fight_hud, fighter_strip]:
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
	_fit_arena(Vector2(left, top), side)
	_place(title_label, Vector2(0, 30), Vector2(size.x, 60))
	rules_button.position = Vector2(size.x - 92.0, 26.0)
	rules_button.size = Vector2.ZERO
	_place(sub_label, Vector2(20, 96), Vector2(size.x - 40, 40))
	_place(hud_label, Vector2(left, 110), Vector2(side, 50))
	_place(info_label, panel_pos, Vector2(panel_width, 70))
	_place(panel, panel_pos + Vector2(0, 80), Vector2(panel_width, PANEL_HEIGHT - 80.0))
	var fight_view := arena.visible and state in [State.AIM, State.FIGHT, State.RESULT]
	for c in [title_label, rules_button]:
		c.visible = not fight_view
	if fight_view: # The same shape as every fight screen (FightLayout).
		var r := FightLayout.rects(size)
		_fit_arena(r.arena.position, r.arena.size.x)
		FightLayout.place_plates(fight_hud, fighter_strip, r, size)
		var p: Rect2 = r.panel
		var info_h := 0.0 if state == State.FIGHT else 56.0
		_place(info_label, p.position, Vector2(p.size.x, 50))
		_place(panel, p.position + Vector2(0, info_h), Vector2(p.size.x, maxf(0.0, p.size.y - info_h)))
	var page_width := minf(680.0, size.x - 40.0)
	# Pages end above the Sound pill in the bottom corner, so it never covers a button.
	var page_bottom := FightLayout.pill_position(size, 1).y - 12.0
	_place(scroll, Vector2((size.x - page_width) / 2.0, 150), Vector2(page_width, page_bottom - 150))
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
	_fit_art()
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
	for i in 3: # _fit_art resizes after the first.
		await get_tree().process_frame
	print("UI_SCREEN ", screen)
	for k in _marks.keys():
		if not is_instance_valid(_marks[k]):
			_marks.erase(k)
	for k in _marks:
		var c = _marks[k]
		if c is RefCounted:
			if c.mark_shown():
				print("UI_AT %s %d %d" % [k, roundi(c.mark_center().x), roundi(c.mark_center().y)])
			continue
		if is_instance_valid(c) and c.is_visible_in_tree():
			var p: Vector2 = c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])


func _update_hud() -> void:
	hud_label.text = ""
	# Aiming, the controls have the room under the arena: only the foe's plates show.
	var plates := sim != null and state in [State.AIM, State.FIGHT]
	fighter_strip.show_fight(sim if plates else null)
	fighter_strip.foe_only = state == State.AIM
	fight_hud.plates = plates
	fight_hud.foe_only = state == State.AIM
	if sim == null or not arena.visible:
		fight_hud.show_fight(null)
		return
	var clock := "%.0fs" % sim.time()
	if sim.in_overtime():
		clock = "OVERTIME x%.1f" % sim.damage_multiplier()
	fight_hud.show_fight(sim, clock)


## A critter and what its ability does, as a tappable card, tinted and
## rimmed by its rarity with the rarity named on a chip. `stacked` puts the
## icon on top with the text centred under it (the 2-column draft grid);
## otherwise the icon sits left of the text (full-width rows). `pick_no` >= 0
## marks a drafted card: a thick white rim and its pick number by the name.
func _critter_card(critter: String, on_press: Callable, pick_no := -1, out := false, tier := 1, stacked := false) -> Button:
	var rarity: String = Roster.get_critter(critter).rarity
	var col: Color = Roster.RARITY_COLORS[rarity]
	var picked := pick_no >= 0
	var align := HORIZONTAL_ALIGNMENT_CENTER if stacked else HORIZONTAL_ALIGNMENT_LEFT
	var title := ("#%d  " % (pick_no + 1) if picked else "") + _name(critter)
	var chip := Kit.chip(Roster.RARITY_NAMES[rarity], Kit.MUTED if out else col, 16)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if stacked else Control.SIZE_SHRINK_BEGIN
	var text := Kit.vbox(2, [Kit.label(title, 28, Kit.MUTED if out else Kit.FG, align), chip])
	text.add_child(Kit.label("OUT", 22, PINK, align) if out else _ability_label(critter, align))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := CritterIcon.make(critter, tier, 104 if stacked else 80)
	if out:
		icon.modulate = Color(1, 1, 1, 0.35)
	var body: Control
	if stacked:
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.set_meta("draft_icon", true)
		chip.set_meta("draft_chip", true)
		text.get_child(2).set_meta("draft_text", true)
		body = Kit.vbox(6, [icon, text])
	else:
		body = Kit.hbox(12, [icon, text])
	var bg := Kit.PANEL if out else Roster.rarity_bg(rarity, Color("241f55") if picked else Kit.PANEL, 0.2)
	var rim := Kit.LINE if out else (Kit.FG if picked else Roster.rarity_border(rarity, Kit.ACCENT if not stacked else Kit.LINE))
	var card := Kit.card_button(body, on_press, rim, bg, 28, 14)
	if picked:
		var st := Kit.box(bg, rim, 28, 6, 14)
		for k in ["normal", "hover", "focus", "pressed", "hover_pressed"]:
			card.add_theme_stylebox_override(k, st)
	return card


## `c` inside a plain Control of its size, so it can be scaled from its
## centre (a container resets its children's scale whenever it re-sorts).
func _pop_wrap(c: Control) -> Control:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.custom_minimum_size = c.get_combined_minimum_size()
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.size = wrap.custom_minimum_size
	c.pivot_offset = c.size / 2.0
	wrap.add_child(c)
	return wrap


## The share of its HP the current floor's foe has left (1.0 when fresh).
func _foe_hp_frac() -> float:
	if run.get("foe_hp") == null or run.over:
		return 1.0
	var probe := MatchSim.new(BounceRun.fight_config(setup, run, BounceRun.living(run)[0], 0))
	return clampf(probe.balls[1].hp / probe.balls[1].max_hp, 0.0, 1.0)


func _ability_label(critter: String, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var what := Kit.label(_ability_text(critter), 19, ABILITY, align, true)
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
		var tile := Kit.vbox(2, [BoonIcon.make(b.icon, _icon_rarity(b.rarity), side)])
		if names:
			var n := Kit.label(b.name.replace(" ", "\n"), 16, _boon_col(b.rarity), HORIZONTAL_ALIGNMENT_CENTER)
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
	var col := _boon_col(b.rarity)
	var rarity: String = "Glitch (a bad boon)" if b.rarity == "glitch" else Roster.RARITY_NAMES[b.rarity] + " boon"
	var lines: Array = [
		BoonIcon.make(b.icon, _icon_rarity(b.rarity), 140),
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
		"Draft 3 critters and 3 starting boons, then climb a %d-floor map to the Champion. Tap a glowing node to pick your path." % BounceRun.FLOORS,
		"Fights: pick who to send. Lose and that critter is out, but the foe keeps its damage for your next send. Lose all three and the run ends.",
		"Elites are bigger and tougher but pay more. ? nodes hide events with choices. Shops sell boons for Buttons, which you earn in the run. Charge Pads revive, polish or clean.",
		"Glitches are bad boons you only get by choosing a risky option. Shops and Charge Pads clean them.",
		"Your trio and the foes go up a tier every %d floors, up to T5 near the top." % BounceRun.FLOORS_PER_TIER,
		"One ranked run a day, the same map for everyone. Ranked by floors, lives, then time.",
	]:
		lines.append(Kit.label(t, 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	_overlay_card(lines, Kit.box(Kit.PANEL, Kit.ACCENT, 32, 3, 28), "br_rules_close")
	_report.call_deferred("br_rules")


## A card over the page on a dimmed backdrop; tapping outside or Close shuts it.
func _overlay_card(lines: Array, style: StyleBox, close_mark: String) -> PanelContainer:
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
	return card


func _expand(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	return grid


func _menu_button() -> Button:
	var b := Kit.button("Home", _go_menu, "ghost", 26, 80)
	TouchInput.mark_back(b) # The edge swipe leaves too (the run is saved).
	return b


func _trio_with(ability: String) -> Array:
	var out: Array = []
	for s in BounceRun.PICKS:
		var c := BounceRun.card(setup, run, s)
		if BallDefs.get_def(c.critter).ability == ability and not c.critter in out:
			out.append(c.critter)
	return out


static func _name(critter: String) -> String:
	return BallDefs.get_def(critter).display_name


## The critter's ability in a sentence, without the leading "Type." its
## description starts with (the card already shows the name).
static func _ability_text(critter: String) -> String:
	return AbilityText.full(critter)


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


# --- The map, events, shops and Charge Pads ------------------------------------

## Opens whatever the run is waiting on (sim/bounce_run.gd phase()).
func _show_next() -> void:
	match BounceRun.phase(setup, run):
		"over":
			_show_over()
		"boon":
			_show_boon()
		"map":
			_show_map()
		"fight":
			_show_floor()
		"event":
			_show_event()
		"shop":
			_show_shop()
		"rest":
			_show_rest()


## The row of the node you're on (or the next one, on the map).
func _row() -> int:
	return int(BounceRun.node(setup, run.at).get("row", run.floor)) if run.at >= 0 else 0


## Floor, tier, your trio (faded when out, plus a hatchling), Buttons and a
## Boons button: everything about the run in one row.
func _status_row() -> Control:
	var row := Kit.hbox(8)
	var tier := BounceRun.tier_at(mini(run.floor, BounceRun.FLOORS - 1))
	var at: int = (int(run.floor) if run.done else _row()) + 1
	row.add_child(Kit.label("F%d/%d · T%d" % [mini(at, BounceRun.FLOORS), BounceRun.FLOORS, tier], 24, Kit.FG))
	row.add_child(Kit.spacer())
	for s in BounceRun.PICKS:
		var face := CritterIcon.face(BounceRun.card(setup, run, s).critter, 48, tier)
		if run.out[s]:
			face.modulate = Color(1, 1, 1, 0.3)
		row.add_child(face)
	if run.hatchling != "":
		row.add_child(CritterIcon.face(run.hatchling, 34, maxi(1, tier - 1)))
	row.add_child(Kit.spacer())
	row.add_child(Kit.amount("button", run.buttons, 26))
	var boons := Kit.button("%d" % run.boons.size(), _show_held, "ghost", 22, 56)
	boons.custom_minimum_size.x = 70
	_mark("br_boons", boons)
	row.add_child(Kit.hbox(4, [BoonIcon.make("shield", "rare", 30), boons]))
	return row


## Your boons on a card over the page (from the status row).
func _show_held() -> void:
	var lines: Array = [Kit.label("Your boons", 34, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), _boon_strip(run.boons, 60)]
	_overlay_card(lines, Kit.box(Kit.PANEL, Kit.ACCENT, 32, 3, 28), "br_held_close")
	_report.call_deferred("br_held")


func _show_map() -> void:
	state = State.MAP
	sfx.on_menu()
	_board_mode()
	var reach := BounceRun.next_nodes(setup, run)
	sub_label.text = "Tap a glowing node to go there"
	# A fresh view each time: the page's old children are freed.
	map_view = MapView.new()
	map_view.on_select = _go_node
	var view_h := maxf(420.0, scroll.size.y - 190.0)
	map_view.row_h = view_h / MAP_ROWS_SHOWN
	map_view.custom_minimum_size = Vector2(0, MapView.height_for(map_view.row_h))
	map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_scroll = ScrollContainer.new()
	map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	map_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	map_scroll.custom_minimum_size = Vector2(0, view_h)
	map_scroll.add_child(map_view)
	map_view.show_run(setup, run)
	_mark("br_map", map_scroll)
	for k in reach.size():
		_marks["br_node_%d" % k] = _NodeMark.new(map_view, reach[k])
	print("BOUNCERUN_REACH floor=%d kinds=%s" % [run.floor + 1, ",".join(reach.map(func(id): return BounceRun.kind_of(setup, id)))])
	var home := _menu_button()
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_page([_status_row(), map_scroll, home], "br_map")
	_scroll_map.call_deferred()
	var tier := BounceRun.tier_at(mini(run.floor, BounceRun.FLOORS - 1))
	if tier > int(run.get("tier_seen", 1)):
		run.tier_seen = tier
		_save_run()
		_show_tier_up(tier)


## Glides the map up from the floor you just cleared to the one you pick
## next (straight there with Reduced motion).
func _scroll_map() -> void:
	var view := map_view
	var sc := map_scroll
	if not is_instance_valid(view) or not is_instance_valid(sc):
		return
	view.size.y = view.custom_minimum_size.y
	var to := view.scroll_for(sc.size.y)
	var from := minf(to + view.row_h, view.size.y - sc.size.y) if run.floor > 0 else to
	sc.scroll_vertical = roundi(from)
	if from == to or A11y.reduced_motion:
		sc.scroll_vertical = roundi(to)
		return
	var tw := sc.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.15)
	tw.tween_method(func(v: float): sc.scroll_vertical = roundi(v), from, to, 0.55)
	tw.tween_callback(func(): if state == State.MAP: _report("br_map")) # The nodes moved: tell the smoke test.


func _go_node(id: int) -> void:
	if state != State.MAP or not id in BounceRun.next_nodes(setup, run):
		return
	BounceRun.go(setup, run, id)
	_save_run()
	sfx.play("launch")
	print("BOUNCERUN_GO floor=%d kind=%s" % [BounceRun.node(setup, id).row + 1, BounceRun.kind_of(setup, id)])
	_show_next()


## An event's painting, `scale` of the page width (720x440 art).
func _art(id: String, scale := 1.0) -> Control:
	var tex := LivingArt.make(id, ART % id)
	var w := page.custom_minimum_size.x * scale
	tex.custom_minimum_size = Vector2(w, w * 440.0 / 720.0)
	tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if scale == 1.0:
		# A page's painting runs full width and takes the page's spare height
		# (cropping its sides), or gives some up so the buttons stay on screen.
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.set_meta("fill", true)
	return tex


## Sizes a page's full-width painting so the page exactly fits the screen:
## taller when there's room (up to square-ish), shorter (down to a strip)
## when the page would scroll. Measured after a layout pass, when wrapped
## labels know their height.
func _fit_art() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(page):
		return
	var kids := page.get_children().filter(func(c): return c is Control and c.visible)
	if kids.is_empty():
		return
	var used: float = kids[-1].position.y + kids[-1].size.y - kids[0].position.y
	for c in kids:
		if c is TextureRect and c.has_meta("fill"):
			var w: float = c.custom_minimum_size.x
			c.custom_minimum_size.y = clampf(c.size.y + scroll.size.y - 8.0 - used, w * 0.3, w * 1.0)
			return


func _show_event() -> void:
	state = State.EVENT
	sfx.on_menu()
	_board_mode()
	var ev := BounceRun.event(setup, run)
	var id: String = BounceRun.node(setup, run.at).event
	sub_label.text = "Floor %d · Event" % (_row() + 1)
	var items: Array = [_status_row(), _art(id), Kit.label(ev.name, 36, Kit.FG), Kit.label(ev.text, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)]
	for k in ev.choices.size():
		var c: Dictionary = ev.choices[k]
		var ok := BounceRun.can_choose(setup, run, c.id)
		var head := Kit.hbox(10, [Kit.label(c.name, 28, Kit.FG if ok else Kit.MUTED), Kit.spacer()])
		if c.has("buttons"):
			head.add_child(Kit.amount("button", "+%d" % c.buttons, 24, Kit.GOOD))
		if c.has("cost"):
			head.add_child(Kit.amount("button", c.cost, 24, Kit.WARN))
		var body := Kit.vbox(2, [head])
		if c.has("text"):
			body.add_child(Kit.label(c.text, 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		if c.id == "swap" and ok:
			body.add_child(FighterTag.named_row(BounceRun.trade_offer(setup, run), 40, 20, Kit.FG))
		var card := Kit.card_button(body, _event_choice.bind(c), MapView.COLORS.event if ok else Kit.LINE, Kit.PANEL, 24, 14)
		card.disabled = not ok
		if not ok:
			card.modulate = Color(1, 1, 1, 0.5)
		items.append(card)
		_mark("br_choice_%d" % k, card)
	_set_page(items, "br_event")


func _event_choice(c: Dictionary) -> void:
	var args := BounceRun.choice_args(setup, run, c)
	if c.get("arg", "") == "trade":
		_pick_trade()
	elif args.is_empty():
		_apply(func(): BounceRun.choose(setup, run, c.id), c.name)
	elif args.size() == 1 and c.arg in ["out_or_none", "glitch"]:
		_apply(func(): BounceRun.choose(setup, run, c.id, args[0]), c.name)
	else:
		_pick(args, c.arg, func(a): _apply(func(): BounceRun.choose(setup, run, c.id, a), c.name), _show_event)


## The trader: pick one of its two critters, then who of yours goes.
func _pick_trade() -> void:
	var offer := BounceRun.trade_offer(setup, run)
	sub_label.text = "Pick a critter to take"
	var items: Array = [_art("tide_pool_trader")]
	for k in offer.size():
		var card := _critter_card(offer[k], func(): _pick(BounceRun.living(run), "swap_out", func(slot):
			_apply(func(): BounceRun.choose(setup, run, "swap", [slot, k]), "Swap"), _pick_trade), -1, false, BounceRun.tier_at(_row()))
		items.append(card)
		_mark("br_trade_%d" % k, card)
	items.append(Kit.button("Back", _show_event, "ghost", 26, 80))
	_set_page(items, "br_trade")


## A list to pick an action's target from: critter slots or boons. `kind`
## says which and words the header.
func _pick(options: Array, kind: String, on_pick: Callable, back: Callable) -> void:
	sub_label.text = {"living": "Pick a critter", "out_or_none": "Who comes back?", "revive": "Who comes back?", "swap_out": "Who leaves?",
		"boon": "Pick a boon to give up", "polish": "Pick a boon to polish", "glitch": "Pick a Glitch to clean"}.get(kind, "Pick one")
	var items: Array = [_status_row()]
	for k in options.size():
		var o = options[k]
		var card: Button
		if o is int:
			var out: bool = run.out[o]
			card = _critter_card(BounceRun.card(setup, run, o).critter, on_pick.bind(o), -1, false, BounceRun.tier_at(_row()))
			if out:
				card.modulate = Color(1, 1, 1, 0.8)
		else:
			var b := Boons.get_def(o)
			var col := _boon_col(b.rarity)
			var text := Kit.vbox(2, [Kit.label(b.name, 26, col), Kit.label(b.text, 20, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card = Kit.card_button(Kit.hbox(12, [BoonIcon.make(b.icon, _icon_rarity(b.rarity), 56), text]), on_pick.bind(o), col, Kit.PANEL, 24, 12)
		items.append(card)
		_mark("br_pick_%d" % k, card)
	items.append(Kit.button("Back", back, "ghost", 26, 80))
	_set_page(items, "br_pick")


## BoonIcon has no Glitch look; Glitches borrow the Common badge, named in pink.
static func _icon_rarity(rarity: String) -> String:
	return "common" if rarity == "glitch" else rarity


static func _boon_col(rarity: String) -> Color:
	return PINK if rarity == "glitch" else Roster.RARITY_COLORS[rarity]


## Runs a step that changes the run, saves, and shows what changed (boons
## gained or lost, Buttons, a hatchling, revives, trades) before moving on.
func _apply(step: Callable, what: String) -> void:
	var before := run.duplicate(true)
	step.call()
	_save_run()
	sfx.play("heal")
	print("BOUNCERUN_STEP %s" % what)
	var lines := _changes(before)
	if lines.is_empty() or BounceRun.phase(setup, run) == "fight":
		_show_next()
		return
	state = State.EVENT
	sub_label.text = what
	var next := Kit.button("Continue", _show_next, "go", 30)
	_mark("br_continue", next)
	_set_page([_status_row(), Kit.panel(Kit.vbox(12, lines), Kit.box(Kit.PANEL, Kit.ACCENT, 28, 2, 20)), next], "br_outcome")


## Lines saying what changed since `before`.
func _changes(before: Dictionary) -> Array:
	var lines: Array = []
	var gained: Array = run.boons.duplicate()
	var lost: Array = before.boons.duplicate()
	for id in before.boons:
		if id in gained:
			gained.erase(id)
			lost.erase(id)
	for id in gained:
		var b := Boons.get_def(id)
		var bad: bool = b.rarity == "glitch"
		lines.append(Kit.hbox(10, [BoonIcon.make(b.icon, _icon_rarity(b.rarity), 48), _expand(Kit.label(("Glitch: " if bad else "New boon: ") + "%s. %s" % [b.name, b.text], 22, PINK if bad else Roster.RARITY_COLORS[b.rarity], HORIZONTAL_ALIGNMENT_LEFT, true))]))
	for id in lost:
		lines.append(Kit.label("Gone: %s" % Boons.get_def(id).name, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var delta: int = run.buttons - before.buttons
	if delta != 0:
		lines.append(Kit.amount("button", ("+%d" % delta) if delta > 0 else str(delta), 26, Kit.GOOD if delta > 0 else PINK))
	if run.hatchling != before.hatchling:
		lines.append(Kit.hbox(10, [CritterIcon.make(run.hatchling, 1, 80), _expand(Kit.label("%s hatched! It fights beside you in every fight." % _name(run.hatchling), 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))]))
	for s in BounceRun.PICKS:
		if before.out[s] and not run.out[s]:
			lines.append(Kit.label("%s is back in the run!" % _name(run.critters[s]), 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
		if before.critters[s] != run.critters[s]:
			lines.append(Kit.hbox(10, [CritterIcon.make(run.critters[s], BounceRun.tier_at(_row()), 80), _expand(Kit.label("%s joins your trio (for %s)." % [_name(run.critters[s]), _name(before.critters[s])], 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))]))
	if run.spar >= 0 and run.spar != before.spar:
		lines.append(Kit.label("%s fights its next fight one tier higher." % _name(run.critters[run.spar]), 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
	if run.foe_boost > before.foe_boost:
		lines.append(Kit.label("Your next foe is 15% stronger...", 22, PINK, HORIZONTAL_ALIGNMENT_LEFT, true))
	if run.revealed and not before.revealed:
		lines.append(Kit.label("Every ? node on the map now shows what it holds.", 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
	if run.wish and not before.wish:
		lines.append(Kit.label("Boon picks now offer 4. The Champion is 15% stronger.", 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
	if run.dash and not before.dash:
		lines.append(Kit.label("You skip ahead a floor.", 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
	return lines


func _show_shop() -> void:
	state = State.SHOP
	sfx.on_menu()
	_board_mode()
	sub_label.text = "Floor %d · Shop" % (_row() + 1)
	var items: Array = [_status_row(), _art("shop")]
	var shelf := Kit.hbox(10)
	for i in run.shop.stock.size():
		var id: String = run.shop.stock[i]
		var item := "boon:%d" % i
		var b := Boons.get_def(id)
		var col: Color = Roster.RARITY_COLORS[b.rarity]
		var sold: bool = item in run.shop.sold
		var price_row: Control = Kit.label("SOLD", 22, Kit.MUTED) if sold else Kit.amount("button", BounceRun.price(setup, run, item), 24)
		price_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var body := Kit.vbox(4, [BoonIcon.make(b.icon, b.rarity, 64), Kit.label(b.name, 21, col, HORIZONTAL_ALIGNMENT_CENTER, true),
			Kit.label(b.text, 16, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true), price_row])
		body.get_child(0).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var card := Kit.card_button(body, _buy.bind(item), col, Roster.rarity_bg(b.rarity, Kit.PANEL, 0.18), 24, 10)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.disabled = not BounceRun.can_buy(setup, run, item)
		if card.disabled:
			card.modulate = Color(1, 1, 1, 0.5)
		shelf.add_child(card)
		_mark("br_shop_%d" % i, card)
	items.append(shelf)
	var services := Kit.hbox(10)
	for item in ["revive", "clean", "restock"]:
		var b := Kit.cost_button({"revive": "Revive", "clean": "Clean", "restock": "Restock"}[item], BounceRun.price(setup, run, item), "button", _buy.bind(item), "primary", 22, 72)
		b.disabled = not BounceRun.can_buy(setup, run, item)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		services.add_child(b)
		_mark("br_shop_%s" % item, b)
	items.append(services)
	var leave := Kit.button("Back to map", func():
		BounceRun.leave(setup, run)
		_save_run()
		_show_next(), "go", 30)
	_mark("br_leave", leave)
	items.append(leave)
	_set_page(items, "br_shop")


func _buy(item: String) -> void:
	if not BounceRun.can_buy(setup, run, item):
		return
	var dead := BounceRun.dead(run)
	if item == "revive" and dead.size() > 1:
		_pick(dead, "revive", func(s): _bought(item, s), _show_shop)
	else:
		_bought(item, null)


func _bought(item: String, arg) -> void:
	BounceRun.buy(setup, run, item, arg)
	_save_run()
	sfx.play("heal")
	print("BOUNCERUN_BUY %s" % item)
	_show_shop()


func _show_rest() -> void:
	state = State.REST
	sfx.on_menu()
	_board_mode()
	sub_label.text = "Floor %d · Charge Pad" % (_row() + 1)
	var items: Array = [_status_row(), _art("charge_pad"), Kit.label("Pick one before you move on.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)]
	var choices := {"revive": ["Revive", "A knocked-out critter is back in the run."], "polish": ["Polish", "One boon goes a rarity up."],
		"clean": ["Clean", "Every Glitch is gone."]}
	var any := false
	for c in choices:
		var ok := BounceRun.can_rest(run, c)
		any = any or ok
		var body := Kit.vbox(2, [Kit.label(choices[c][0], 28, Kit.FG if ok else Kit.MUTED), Kit.label(choices[c][1], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var card := Kit.card_button(body, _rest.bind(c), MapView.COLORS.rest if ok else Kit.LINE, Kit.PANEL, 24, 14)
		card.disabled = not ok
		if not ok:
			card.modulate = Color(1, 1, 1, 0.5)
		items.append(card)
		_mark("br_rest_%s" % c, card)
	if not any:
		var pass_on := Kit.button("Rest and move on", _rest.bind("pass"), "go", 28)
		_mark("br_rest_pass", pass_on)
		items.append(pass_on)
	_set_page(items, "br_rest")


func _rest(choice: String) -> void:
	var dead := BounceRun.dead(run)
	if choice == "revive" and dead.size() > 1:
		_pick(dead, "revive", func(s): _apply(func(): BounceRun.rest(setup, run, "revive", s), "Charge Pad"), _show_rest)
	elif choice == "polish":
		_pick(BounceRun.polishable(run), "polish", func(id): _apply(func(): BounceRun.rest(setup, run, "polish", id), "Charge Pad"), _show_rest)
	else:
		_apply(func(): BounceRun.rest(setup, run, choice), "Charge Pad")


## Ball indices drawn with the elite look: an Elite or the Champion.
func _elite_balls() -> Array:
	var f := BounceRun.foe(setup, run)
	return [1] if f.get("kind", "") in ["elite", "boss"] else []


## A smoke-test mark for a map node: where the node is on screen.
class _NodeMark extends RefCounted:
	var view: Control
	var id: int

	func _init(view_: Control, id_: int) -> void:
		view = view_
		id = id_

	func mark_center() -> Vector2:
		return view.get_global_rect().position + view.node_pos(id)

	func mark_shown() -> bool:
		return is_instance_valid(view) and view.is_visible_in_tree()
