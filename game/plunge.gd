## Critter Plunge race screen: your fighter and a CPU field drop down a
## marble run (sim/plunge.gd) and fight on the way; you watch. Opened from
## the Plunge screen in Versus (game/ui/screens/plunge_screen.gd), which has
## already spent the energy and left the race in CritterPlunge.pending. The result pops
## up on the shared ResultPopup with coins, XP, league points and the
## Faction XP ring, paid into the game save here (meta/critter_plunge.gd); a
## new league's crest drops in big beside the medal that reached it.
## Each race opens on the course banner and a 3, 2, 1, GO! countdown
## (game/plunge_intro.gd; just GO! on "Race again"); the race only starts
## stepping on GO. The camera rides with your racer (game/plunge_view.gd),
## callouts cheer what it does (game/plunge_story.gd), a close finish near
## the line slows the view onto it, and once it is over (finished or knocked
## out) the rest of the race runs at skip speed. All of that is the view:
## the sim steps the same race whatever happens on screen.
## URL params: ?mode=plunge&seed=5&n=8 (a practice race: no rewards, nothing
## spent), &course=lava (one of PlungeCourse.COURSES), &speed=2, &you=1 (practice as racer 0).
extends Node2D

const Plunge := preload("res://sim/plunge.gd")
const PlungeView := preload("res://game/plunge_view.gd")
const PlungeStrip := preload("res://game/plunge_strip.gd")
const PlungeIntro := preload("res://game/plunge_intro.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const Main := preload("res://game/main.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const FactionRing := preload("res://game/ui/faction_ring.gd")
const FightSpeed := preload("res://game/fight_speed.gd")
const FightLayout := preload("res://game/fight_layout.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const Profile := preload("res://meta/profile.gd")
const PlungeSfx := preload("res://game/plunge_sfx.gd")
const PlungeStory := preload("res://game/plunge_story.gd")
const PlungeChips := preload("res://game/plunge_chips.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const Analytics := preload("res://game/online/analytics.gd")
const PlungeLeague := preload("res://meta/plunge_league.gd")
const PlungeScreen := preload("res://game/ui/screens/plunge_screen.gd")
const Ladder := preload("res://game/pvp/ladder.gd")

const SKIP_TICKS := 360 ## Ticks a frame while skipping: fast, never a frozen frame.
const TITLE_H := 64.0
const AFTER_YOU := 1.5 ## Seconds watched after your racer is done, then skip to the result.
const SLOW_RATE := 0.3 ## The photo finish's speed...
const SLOW_SECS := 0.8 ## ...for at most this long (real seconds).
const PHOTO_ZONE := 120.0 ## World px before the line where a photo finish can start...
const PHOTO_GAP := 40.0 ## ...with a rival this close to your racer.
const MEDAL_COLORS := {"gold": Color("ffd36b"), "silver": Color("d9e2ec"), "bronze": Color("e0a46a")}

## Set by "Race again": the next race's countdown is just GO!.
static var again := false

var sim: Plunge
var fighter := ""
var practice := false
var you := 0 ## Your racer (-1 in a practice race you only watch).
var speed := -1.0 ## A ?speed= override, else the Speed pill's pick.
var game_save_path := SaveGame.PATH ## Tests point this elsewhere.
var result := {} ## What finish() paid, once the race is over.
var story: PlungeStory
var skipped := false ## The player pressed Skip (the race wasn't watched to the end).

var _accumulator := 0.0
var _racing := false ## False through the countdown (game/plunge_intro.gd).
var _intro: PlungeIntro
var _skipping := false
var _done := false
var view: PlungeView
var strip: PlungeStrip
var frame: Control
var sfx: Sfx
var ui_root: Control
var title: Label
var _skip: Control
var _speed: Control
var chips: PlungeChips
var _tier := 1
var _after_you := -1.0 ## Seconds since your racer finished or was knocked out.
var _slow := 0.0 ## Real seconds of photo-finish slow-mo left.
var _slow_used := false
var _covered := false ## The result popup is up: the course stops redrawing.


func _ready() -> void:
	if view != null:
		return # Tests may start the scene by hand before the tree does.
	TouchInput.ensure(self)
	TouchInput.set_back(self, func(): return _back if _done else Callable())
	var params := _url_params()
	var cfg: Dictionary = CritterPlunge.pending.get("cfg", {})
	fighter = str(CritterPlunge.pending.get("fighter", ""))
	CritterPlunge.pending = {}
	if cfg.is_empty():
		practice = true
		you = 0 if params.has("you") else -1 # &you=1: race as racer 0, still for nothing.
		var n := int(params.get("n", "6")) if str(params.get("n", "")).is_valid_int() else 6
		n = n if Plunge.FIELD_SIZES.has(n) else 6
		var seed_value := int(params.seed) if str(params.get("seed", "")).is_valid_int() else randi_range(1, 0x7FFFFFFF)
		cfg = {"seed": seed_value, "racers": Plunge.draw_field(seed_value, n)}
		if params.has("course"):
			cfg.course = str(params.course)
		fighter = str(cfg.racers[0])
	if str(params.get("speed", "")).is_valid_float():
		speed = clampf(float(params.speed), 0.25, 8.0)
	sim = Plunge.new(cfg)
	var tiers: Array = cfg.get("tiers", [])
	_tier = int(tiers[0]) if not tiers.is_empty() else 1
	story = PlungeStory.new(you)
	sfx = PlungeSfx.new()
	sfx.you = you
	add_child(sfx)
	frame = Control.new()
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	view = PlungeView.new()
	frame.add_child(view)
	view.set_race(sim, you)
	strip = PlungeStrip.new()
	strip.sim = sim
	strip.you = you
	strip.mouse_filter = Control.MOUSE_FILTER_STOP
	strip.picked.connect(_follow)
	chips = PlungeChips.new()
	chips.view = view
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(chips)
	frame.add_child(strip)
	_build_ui()
	if is_inside_tree():
		get_viewport().size_changed.connect(_layout)
	_layout()
	sfx.play_music("fight")
	_intro = PlungeIntro.new()
	_intro.sfx = sfx
	_intro.you_at = _your_spot
	_intro.gate_at = _gate_y
	if you >= 0:
		_intro.you_color = Roster.RARITY_COLORS.get(str(Roster.get_critter(fighter).get("rarity", "common")), Roster.RARITY_COLORS.common)
	ui_root.add_child(_intro)
	ui_root.move_child(_intro, 1) # Over the course and title, under the pills, so Skip still works.
	_intro.start(sim.course, sim.starters, again)
	again = false
	_intro.go.connect(func(): _racing = true)
	if not practice:
		Analytics.track("plunge_start", {"n": sim.starters, "course": sim.course.info.id})
	print("PLUNGE_READY seed=%d n=%d practice=%s racers=%s" % [int(cfg.seed), sim.starters, practice, ",".join(cfg.racers)])


## The back-swipe table outlives the scene, so it must not keep a freed key.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		TouchInput.clear_back(self)


## Your racer on screen, for the countdown's ring (none when only watching).
func _your_spot():
	if you < 0:
		return null
	return view.get_global_transform() * (sim.balls[0].pos * view.view_scale)


## The gate's height on screen, for the countdown.
func _gate_y():
	return (view.get_global_transform() * (Vector2(0.0, PlungeCourse.START_Y) * view.view_scale)).y


## A tap on a face in the standings follows that racer; a tap on it again,
## or on your own, goes back to yours.
func _follow(i: int) -> void:
	view.follow = -1 if i == view.follow or i == view.you else i
	strip.follow = view.follow


func _process(delta: float) -> void:
	if not _done and _racing:
		var rate := speed if speed > 0.0 else FightSpeed.current()
		if _slow > 0.0:
			rate *= SLOW_RATE
			_slow -= delta
			if _slow <= 0.0:
				view.lock_you = false
		if _skipping:
			for k in SKIP_TICKS:
				if sim.finished:
					break
				sim.step()
				view.consume_events(sim.events)
				story.watch(sim)
		else:
			_accumulator += delta * rate
			var steps := 0
			while _accumulator >= Plunge.DT and steps < 64 and not sim.finished:
				_accumulator -= Plunge.DT
				steps += 1
				sim.step()
				view.consume_events(sim.events)
				sfx.consume_events(sim.events, sim)
				_sounds(sim.events)
				for c in story.watch(sim):
					view.callout(c.text, c.big)
				_photo_finish()
		_after_your_race(delta)
		if sim.finished:
			_finish()
	if not _covered:
		view.advance(delta)


## Once your racer has finished or is out, a moment to see it, then the rest
## of the race runs at skip speed (the same race, just not shown).
func _after_your_race(delta: float) -> void:
	if you < 0 or _skipping:
		return
	if _after_you < 0.0:
		if not sim.racing(0):
			_after_you = 0.0
		return
	_after_you += delta
	if _after_you >= AFTER_YOU:
		_skipping = true


## A close finish: your racer near the line with a rival right by it slows
## the view onto your racer for a moment (once a race; not when only watching).
func _photo_finish() -> void:
	if you < 0 or _slow_used or not sim.racing(0):
		return
	var y: float = sim.balls[0].pos.y
	if sim.finish_y - y > PHOTO_ZONE:
		return
	for j in range(1, sim.starters):
		var close: bool = sim.racing(j) and absf(sim.balls[j].pos.y - y) <= PHOTO_GAP
		if close or (sim.finish_ticks[j] >= 0 and sim.tick - sim.finish_ticks[j] <= 6):
			_slow_used = true
			_slow = SLOW_SECS
			view.lock_you = true
			return


## The race's own sounds; the abilities' come from sfx.consume_events, as in a fight.
func _sounds(events: Array) -> void:
	for e in events:
		match e.type:
			"course_hit":
				if e.bumper:
					sfx.play("pinball_ding", -8.0, 1.2)
			"race_ko":
				sfx.play("ko")
			"finish":
				if e.place == 1:
					sfx.play("tada")
				if _slow > 0.0:
					view.flash_line()
					if e.racer == 0:
						_slow = minf(_slow, 0.3) # A beat to see it, then on.


func _skip_race() -> void:
	if not _skipping and (_after_you < 0.0 or you < 0):
		skipped = true # Skipped before your racer was done: not watched.
	_skipping = true
	_racing = true
	if is_instance_valid(_intro):
		_intro.skip()


func _finish() -> void:
	_done = true
	var place: int = sim.places[0]
	var n := sim.starters
	var knocked: bool = sim.ko_ticks[0] >= 0
	var gains: Array = []
	if not practice:
		gains = _pay(place, knocked)
		_count_quests(place, knocked)
		Analytics.track("plunge_end", {"n": n, "course": sim.course.info.id, "place": place, "ko": knocked, "skipped": skipped})
	print("PLUNGE_RESULT place=%d of %d ko=%s coins=%d" % [place, n, knocked, int(result.get("coins", 0))])
	sfx.on_result(0 if place == 1 else (-1 if place <= n / 2.0 else 1))
	_skip.visible = false
	_speed.visible = false
	sfx.toggle_hidden = true # The popup covers the bottom row of pills.
	sfx.hold_victory(ResultPopup.show_over(ui_root, _result_card(place, knocked, gains), func(): _covered = true))


## The race counts for quests and the Glow Pass like a fight (a win for 1st),
## plus the Plunge quests: podium, wins and courses raced.
func _count_quests(place: int, knocked: bool) -> void:
	var save := SaveGame.new(game_save_path)
	save.load_local()
	var glow = GlowState.new(save)
	glow.record_fight(0 if place == 1 else 1, sim.balls[0].damage_dealt, -1, {"critter": fighter, "tier": _tier})
	glow.record_plunge(place, knocked, sim.course.info.id)


## Pays the race into the game save; returns the Faction XP gains for the ring.
func _pay(place: int, knocked: bool) -> Array:
	var save := SaveGame.new(game_save_path)
	save.load_local()
	var d = save.data.get("profile", {})
	if not (d is Dictionary) or d.is_empty():
		return []
	var p = Profile.from_dict(d, int(Time.get_unix_time_from_system()))
	result = CritterPlunge.finish(p, fighter, place, sim.starters, knocked, not skipped, sim.course.info.id)
	var gains: Array = p.take_faction_gains()
	save.data.profile = p.to_dict()
	save.commit()
	return gains


func _result_card(place: int, knocked: bool, gains: Array) -> Control:
	var n := sim.starters
	var outcome := ResultPopup.Outcome.WIN if place == 1 else (ResultPopup.Outcome.DRAW if place <= n / 2.0 and not knocked else ResultPopup.Outcome.LOSE)
	var words := "Knocked out" if knocked else ("1st!" if place == 1 else "%s of %d" % [_ordinal(place), n])
	var body: Array = [_podium()]
	var line := story.line(sim)
	if line != "":
		body.append(Kit.label(line, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	if not result.is_empty():
		var start := ResultPopup.SLIDE_SECS + .4
		var medal := str(result.get("medal", ""))
		if medal != "": # The medal is the moment: it drops in big, before the rest.
			var col: Color = MEDAL_COLORS.get(medal, Color.WHITE)
			var hero := _hero(Kit.glyph("medal_" + medal, 96, Color.WHITE), "%s medal!" % medal.capitalize(), col)
			hero.name = "PlungeMedal"
			var heroes: Array = [[hero, col]]
			if result.get("promoted", false): # A new league: its crest drops in beside it.
				var lg: Dictionary = PlungeLeague.LEAGUES[int(result.league)]
				var lc: Color = Ladder.LEAGUES[int(result.league)].color
				var up := _hero(PlungeScreen.crest(int(result.league), 96), "%s league!" % lg.name, lc)
				up.name = "PlungeLeagueUp"
				heroes.append([up, lc])
			var row := Kit.hbox(40, heroes.map(func(h): return h[0]), BoxContainer.ALIGNMENT_CENTER)
			body.append(row)
			ResultPopup.drop_in(heroes, sfx, start)
			start += .5 + .3 * (heroes.size() - 1)
		var items: Array = [Kit.amount("coin", "+%d" % result.coins, 30)]
		items.append(Kit.label("+%d XP" % result.xp, 26, Kit.MUTED))
		if int(result.get("points", 0)) > 0: # League points: your crest and what the medal added.
			var pts := Kit.hbox(4, [PlungeScreen.crest(int(result.league), 30), Kit.label("+%d" % result.points, 26, Ladder.LEAGUES[int(result.league)].color)])
			pts.name = "PlungePoints"
			items.append(pts)
		var rewards := Kit.hbox(28, items, BoxContainer.ALIGNMENT_CENTER)
		body.append(rewards)
		ResultPopup.drop_in(rewards.get_children().map(func(c): return [c, null]), sfx, start)
	if not gains.is_empty():
		body.append(FactionRing.rows(gains, sfx))
	var back := Kit.button("Back", _back, "ghost", 26, 84)
	var again_btn := Kit.button("Race again", _again, "go", 26, 84)
	back.name = "PlungeBack"
	again_btn.name = "PlungeAgain"
	again_btn.size_flags_stretch_ratio = 1.5
	_mark("plunge_back", back, 1.0)
	_mark("plunge_again", again_btn, 1.0)
	return ResultPopup.content("%s · %d racers" % [sim.course.info.name, n], outcome, body, [back, again_btn], CritterIcon.make(fighter, _tier, 72), words)


## A big thing over its words, both centred: the medal, a new league's crest.
static func _hero(big: Control, words: String, col: Color) -> Control:
	var hero := Kit.vbox(2, [big, Kit.label(words, 24, col, HORIZONTAL_ALIGNMENT_CENTER)])
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	for c in hero.get_children():
		c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return hero


## The top three, faces and names, so you see who beat you.
func _podium() -> Control:
	var row := Kit.hbox(18, [], BoxContainer.ALIGNMENT_CENTER)
	for k in mini(3, sim.order.size()):
		var i: int = sim.order[k]
		if sim.ko_ticks[i] >= 0:
			break
		var id: String = sim.balls[i].type_id
		var col := Kit.vbox(2, [CritterIcon.make(id, _tier, 64), Kit.label(_ordinal(k + 1), 20, Color("ffd36b") if k == 0 else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label("You" if i == you else Roster.get_critter(id).name, 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		for c in col.get_children():
			c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_child(col)
	return row


static func _ordinal(k: int) -> String:
	return str(k) + (["th", "st", "nd", "rd"][k % 10] if k % 10 <= 3 and (k % 100) / 10 != 1 else "th")


## Another race with the same fighter and field size: spends the energy from
## the save, then reloads the scene with the new race.
func _again() -> void:
	again = true
	if practice:
		get_tree().reload_current_scene()
		return
	var save := SaveGame.new(game_save_path)
	save.load_local()
	var d = save.data.get("profile", {})
	if not (d is Dictionary) or d.is_empty():
		_back()
		return
	var now := int(Time.get_unix_time_from_system())
	var p = Profile.from_dict(d, now)
	var cfg: Dictionary = CritterPlunge.start(p, fighter, sim.starters, now)
	if cfg.has("error"):
		again = false
		_back() # Out of energy: the Plunge screen says so and offers more.
		return
	save.data.profile = p.to_dict()
	save.commit()
	CritterPlunge.pending = {"cfg": cfg, "fighter": fighter}
	get_tree().reload_current_scene()


func _back() -> void:
	CritterPlunge.reopen = true
	get_tree().change_scene_to_file("res://game/main.tscn")


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = Main._neon_theme()
	layer.add_child(ui_root)
	title = Kit.label("%s · %d RACERS" % [sim.course.info.name.to_upper(), sim.starters], 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(title)
	# Speed, Skip and Sound: the bottom row of pills every fight screen has.
	_speed = FightSpeed.picker()
	ui_root.add_child(_speed)
	var skip := FightLayout.skip_pill(_skip_race, "PlungeSkip")
	_skip = skip
	ui_root.add_child(skip)
	_mark("plunge_skip", skip.button)


## The title, then the course down to just above the bottom pills, the full
## width (capped so a wide screen keeps a phone-shaped column).
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(720, 1280)
	var width := minf(size.x, 760.0)
	var x := (size.x - width) / 2.0
	title.position = Vector2(x, 10)
	title.size = Vector2(width, TITLE_H - 10)
	var bottom := size.y - FightLayout.PILL.y - FightLayout.PILL_MARGIN.y - 10.0
	frame.position = Vector2(x, TITLE_H)
	frame.size = Vector2(width, maxf(200.0, bottom - TITLE_H))
	view.view_size = frame.size
	view.view_scale = width / Plunge.WIDTH
	view.top_pad = PlungeStrip.HEIGHT
	strip.position = Vector2.ZERO
	strip.size = Vector2(width, PlungeStrip.HEIGHT)
	chips.position = Vector2.ZERO
	chips.size = frame.size
	chips.top_pad = PlungeStrip.HEIGHT
	view.queue_redraw()


## Logs where a control is once it's laid out, for the smoke test ("UI_AT name x y").
func _mark(name: String, c: Control, wait := 0.0) -> void:
	if is_inside_tree():
		_mark_later.call_deferred(name, c, wait)


func _mark_later(name: String, c: Control, wait: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if wait > 0.0:
		await get_tree().create_timer(wait).timeout
	if is_instance_valid(c) and c.is_visible_in_tree():
		var at := c.get_global_rect().get_center()
		print("UI_AT %s %d %d" % [name, roundi(at.x), roundi(at.y)])


func _url_params() -> Dictionary:
	var params := {}
	if not OS.has_feature("web"):
		return params
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	return params
