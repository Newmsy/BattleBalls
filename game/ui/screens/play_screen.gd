## Play tab (home): a slim Glow Pass and Shop row under the top bar, then the
## four main modes as painted doors in a 2x2 grid (Campaign, Arena, Bounce Run,
## Critter Plunge), each with its own big button, then a strip of painted
## tokens for everything else you play (Quests, Trick Shot, Fight of the Day,
## Spire, Bosses). A door's › opens its hub (adventure_screen, versus_screen);
## the strip's header opens the Daily board (week_screen). A new mode goes in
## a hub, and on the strip only if it's played most days.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const BounceChest := preload("res://meta/bounce_chest.gd")
const BounceChestOpen := preload("res://game/ui/bounce_chest_open.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const WeekScreen := preload("res://game/ui/screens/week_screen.gd")
const LiveOps := preload("res://game/liveops.gd")
const TrickShot := preload("res://sim/trick_shot.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const BossesScreen := preload("res://game/ui/screens/bosses_screen.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const Intro := preload("res://game/ui/intro.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const Dev := preload("res://game/dev.gd")
const Motion := preload("res://game/ui/motion.gd")

const DAILY := Color("ffd36b")
const VERSUS := Color("ff4fd8")
const STYLE := Color("5ce1ff")
const ADVENTURE := Color("45f5a6")
const BOSS := Color("ff8a3d")
const BOUNCE := Color("ffc23d")
const PLUNGE := Color("27c8ff")
## Kit.MUTED, a step lighter, for words over a painting.
const ON_ART_MUTED := Color("cfcdf0")
const VERSUS_ART := "res://game/ui/versus_art/%s.png"

## True on a tall phone (more than a 9:16 screen's height): the doors' badges,
## buttons and words grow a step so they fill the room instead of floating.
static var tall := false


static func build(shell, _params: Dictionary) -> Control:
	tall = shell.size.y > 1400.0
	var root := Kit.vbox(14)
	var doors := [_campaign_door(shell), _arena_door(shell), _bounce_door(shell), _plunge_door(shell)]
	var style := _style_row(shell)
	var strip := _more_strip(shell)
	if not Intro.done(shell.profile):
		# A new player's first fights (game/ui/intro.gd) still see the whole
		# Home: what isn't open yet is dimmed, with what opens it on top.
		style = _lock(shell, style, LATER, "Opens later")
		strip = _lock(shell, strip, LATER)
		doors[2] = _lock(shell, doors[2], LATER, "Opens later")
		doors[3] = _lock(shell, doors[3], LATER, "Opens later")
		if not Intro.shows(shell.profile, "arena"):
			doors[1] = _lock(shell, doors[1], "Opens after stage 1-3", "After 1-3")
	# Two rows of two; the top row a little taller (Campaign and Arena carry
	# a second line).
	var rows: Array = []
	for i in [0, 2]:
		var row := Kit.hbox(14, [doors[i], doors[i + 1]])
		for d in [doors[i], doors[i + 1]]:
			d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.size_flags_stretch_ratio = 1.12 if i == 0 else 1.0
		rows.append(row)
	var parts: Array = [style] + rows + [strip]
	if Dev.quick_fight_shown():
		parts.append(quick_fight_row(shell))
	var col := Kit.vbox(14, parts)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	return root


## What a locked part of Home says during a new player's first fights: the
## rest of the game opens with the Trophy Room, after the first Arena fight.
const LATER := "Opens after your first Arena fight"


## `c` dimmed under a cover that says what opens it; a tap on it says the same.
## `short` replaces the chip's words on a row too slim for the whole line;
## a tap still toasts all of it.
static func _lock(shell, c: Control, line: String, short := "") -> Control:
	var words := Kit.label(short if short != "" else line, 20, Kit.FG)
	var chip := Kit.panel(Kit.hbox(8, [Glyph.make("lock", 22, Kit.FG), words], BoxContainer.ALIGNMENT_CENTER), Kit.box(Color(Kit.BG, .85), Kit.LINE, 999, 2, 10))
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(chip)
	var cover := Kit.card_button(Control.new(), func(): shell.toast(line), Color(0, 0, 0, 0), Color(Kit.BG, .62), 32, 0)
	cover.add_child(centre)
	# The cover lies over the whole of `c`, in a stack that takes c's place.
	var stack := MarginContainer.new()
	stack.size_flags_horizontal = c.size_flags_horizontal
	stack.size_flags_vertical = c.size_flags_vertical
	stack.add_child(c)
	stack.add_child(cover)
	return stack


## `c` inside a margin: 16px at the sides, `top` and `bottom` above and below.
static func _padded(c: Control, top: int, bottom: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_bottom", bottom)
	m.add_child(c)
	return m


## Words over a painting get a dark rim and a soft shadow so they read on any
## part of it; muted words are lifted a step, since grey on paint vanishes.
static func _on_art(n: Node) -> void:
	if n is Label:
		if n.get_theme_color("font_color") == Kit.MUTED:
			n.add_theme_color_override("font_color", ON_ART_MUTED)
		n.add_theme_color_override("font_outline_color", Color(0, 0, 0, .75))
		n.add_theme_constant_override("outline_size", 6)
		Kit.soft_shadow(n, Color(0, 0, 0, .8), 2, 8)
	for c in n.get_children():
		_on_art(c)


## A small count on a painting (stars, power) on a dark round pill.
static func _art_pill(c: Control) -> Control:
	var st := Kit.box(Color(Kit.BG, .72), Color(1, 1, 1, .1), 999, 1, 0)
	st.content_margin_left = 10
	st.content_margin_right = 12
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	var p := Kit.panel(c, st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## A painted round token (game/ui/home_art/tok_*.png), `side` across.
static func token(id: String, side: int) -> Control:
	var t := TextureRect.new()
	t.texture = load(HomePainting.DIR % ("tok_" + id))
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(side, side)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t


## An empty token frame with today's critter face(s) in it.
static func token_with(frame: String, faces: Control, side: int) -> Control:
	var t := token(frame, side)
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(faces)
	t.add_child(c)
	return t


## An 8px row between a door's rows that soaks up its spare height.
static func _gap() -> Control:
	var g := Control.new()
	g.custom_minimum_size.y = 8
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


## A size on the doors, a step bigger on a tall phone.
static func _s(n: float) -> int:
	return roundi(n * 1.2) if tall else int(n)


## A small round action on a door: a badge (or faces) over a word and a status.
static func door_spot(shell, mark: String, art: Control, title: String, status: String, accent: Color, on_press: Callable, dot := false) -> Control:
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var t := Kit.label(title, 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	var st := Kit.label(status, 16, accent, HORIZONTAL_ALIGNMENT_CENTER)
	for l in [t, st]:
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.clip_text = true
	var b := Kit.card_button(Kit.vbox(4, [art, t, st]), on_press, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 20, 2)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.x = 0
	if dot:
		b.add_child(red_dot())
	shell.mark(mark, b)
	return b


# --- The four doors -----------------------------------------------------------
# Home is four painted doors, one per main mode, each with its own big button.
# Campaign's and Arena's doors open their hubs on a tap anywhere else (the ›);
# Bounce Run's and Plunge's do what their button does.

## A door: a painting filling it, the title and status `lines` on its darkened
## top, and `action` (the mode's big button) along the bottom. A tap anywhere
## else runs `on_tap`; `hub` puts a › by the title, for a door that opens a hub.
static func mode_door(shell, mark: String, title: String, lines: Array, accent: Color, art: Control, action: Control, on_tap: Callable, hub := false) -> Control:
	var words := Kit.vbox(2, [Kit.label(title, _s(30), accent)] + lines)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := Kit.hbox(4, [words])
	if hub:
		var arrow := Kit.label("›", 40, accent)
		arrow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		head.add_child(arrow)
	action.size_flags_vertical = Control.SIZE_SHRINK_END
	var v := Kit.vbox(0, [head, _gap(), action])
	_on_art(head)
	var stack := MarginContainer.new()
	stack.add_child(art)
	var pad := _padded(v, 14, 14)
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 14)
	stack.add_child(pad)
	# The painting sits inside the 3px border, its corners rounded to match.
	var st := Kit.box(accent.darkened(.86), accent.darkened(.2), 30, 3, 0)
	st.set_content_margin_all(3)
	var card := Kit.tap_card(Kit.panel(stack, st), on_tap, 30)
	card.custom_minimum_size.x = 0
	shell.mark(mark, card)
	return card


## A door's painting: cropped round `focus`, darkened under the words at the
## top and a little under the button at the bottom.
static func _door_art(id: String, focus: Vector2, dir := HomePainting.DIR) -> Control:
	return HomePainting.make(id, focus, 27.0, Vector4(.42, .82, .62, .7), Kit.BG, dir)


## A door's big button, in the door's own colour.
static func _door_button(text: String, kind: String, on_press: Callable) -> Button:
	return Kit.button(text, on_press, kind, _s(28), _s(80))


## A muted status line on a door, trimmed rather than widening it.
static func _door_line(text: String, color := Kit.MUTED, size := 19) -> Label:
	var l := Kit.label(text, _s(size), color)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	# In a row beside a glyph or face, a clipped label needs the room given to it.
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## Campaign: the current zone's painting, its next stage and Continue. The
## door opens the Adventure hub (Spire, Bosses, Rift).
static func _campaign_door(shell) -> Control:
	var c := campaign_state(shell.profile)
	var go := _door_button("Continue", "go", func(): shell.go("world"))
	shell.mark("campaign", go)
	var intro := not Intro.done(shell.profile)
	var stars := Kit.hbox(6, [Glyph.make("crown", _s(20), Kit.FG, 1), _door_line("%d/%d" % [c.stars, c.max_stars], Kit.MUTED, 17)])
	var lines: Array = [_door_line(c.zone.name, Kit.FG, 21), _door_line(c.next_line), stars]
	# During the first fights the door goes where Continue does: the hub's
	# other rooms aren't open yet.
	return mode_door(shell, "adventure", "CAMPAIGN", lines, ADVENTURE,
		_door_art("home_zone_" + c.zone.id, Vector2(.64, .7)), go,
		func(): shell.go("world" if intro else "adventure"), true)


## Arena: your league and trophies, and Fight (the Ghost Arena's opponents).
## The door opens the Versus hub (Trophy Room, Bazaar, weekly chest).
static func _arena_door(shell) -> Control:
	var store = ArenaStore.open()
	var fight := _door_button("Fight", "pink", func(): shell.go("arena"))
	shell.mark("arena", fight)
	var lines: Array = [_door_line(Ladder.league_label(store.trophies), Kit.FG, 21),
		Kit.hbox(6, [Glyph.make("trophy", _s(20), DAILY), _door_line(Kit.commas(store.trophies), Kit.MUTED, 17)])]
	var intro := Intro.step(shell.profile) < Intro.TROPHY
	var door := mode_door(shell, "versus", "ARENA", lines, VERSUS,
		_door_art("vs_ghost", Vector2(.47, .75), VERSUS_ART), fight,
		func(): shell.go("arena" if intro else "versus"), true)
	if store.chest_ready():
		door.add_child(red_dot())
	return door


## Bounce Run: today's best floor and a new run, or Open when yesterday's
## best floor left a chest.
static func _bounce_door(shell) -> Control:
	var day := BounceRun.day_number(Time.get_unix_time_from_system())
	var best := BounceChest.best_floors()
	var chest := BounceChest.pending(best, int(shell.profile.bounce_chest), day) if shell.profile != null else {}
	var lines: Array = []
	var action: Button
	var tap: Callable
	if not chest.is_empty():
		tap = func(): BounceChestOpen.show_on(shell, chest)
		action = _door_button("Open", "gold", tap)
		shell.mark("home_bounce_chest", action)
		lines.append(_door_line("%s ready" % BounceChest.TIERS[int(chest.tier)].name, DAILY, 21))
	else:
		tap = func(): shell.get_tree().change_scene_to_file("res://game/bounce_run.tscn")
		action = _door_button("New run", "gold", tap)
		shell.mark("bouncerun", action)
		var today := int(best.get(day, 0))
		lines.append(_door_line("Best today: floor %d" % today if today > 0 else "Climb %d floors" % BounceRun.FLOORS, Kit.FG, 21))
		var t := BounceChest.tier_for(today)
		if t >= 0:
			lines.append(_door_line("%s tomorrow" % BounceChest.TIERS[t].name))
	return mode_door(shell, "home_bounce", "BOUNCE RUN", lines, BOUNCE,
		_door_art("daily_bounce", Vector2(.45, .6)), action, tap)


## Critter Plunge: your racer and Race (the Plunge screen, where you pick the
## field and your racer).
static func _plunge_door(shell) -> Control:
	var open := func(): shell.go("plunge")
	var race := _door_button("Race", "sky", open)
	shell.mark("home_plunge", race)
	var lines: Array = [_door_line("Marble race", Kit.FG, 21)]
	var racer: String = CritterPlunge.racer_for(shell.profile) if shell.profile != null else ""
	if racer != "":
		lines.append(Kit.hbox(6, [CritterIcon.face(racer, _s(26)), _door_line(Roster.get_critter(racer).name, Kit.MUTED, 17)], BoxContainer.ALIGNMENT_CENTER))
	return mode_door(shell, "plunge_door", "PLUNGE", lines, PLUNGE,
		_door_art("vs_plunge", Vector2(.92, .5), VERSUS_ART), race, open)


## Under the doors: a strip of painted tokens for everything else played most
## days. Its header opens the Daily board (Fight of the Day, Bracket, the
## week's events).
static func _more_strip(shell) -> Control:
	var t := LiveOps.now()
	var week := func(): shell.go("week")
	var season := LiveOps.season(t)
	var title := Kit.label("MORE TO PLAY", 20, DAILY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := _door_line("" if season.is_empty() else "%s · week %d of %d" % [season.name, season.week, season.weeks], Kit.MUTED, 17)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var header := Kit.card_button(Kit.hbox(8, [title, right, Kit.label("›", 30, DAILY)], BoxContainer.ALIGNMENT_CENTER), week, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 16, 0)
	shell.mark("thisweek", header)
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var trick: Dictionary = WeekScreen.trick_status(day)
	var trick_line := "Solved" if trick.solved else ("Done" if trick.tries >= WeekScreen.TRICK_TRIES else "New")
	var f := LiveOps.fight_of_the_day(t)
	var side := _s(56)
	var fotd := Kit.hbox(-12, [CritterIcon.face(f.p1, _s(28)), CritterIcon.face(f.p2, _s(28))], BoxContainer.ALIGNMENT_CENTER)
	var climb = SpireClimb.load_file(t)
	var spire := door_spot(shell, "spire", token("spire", side), "Spire", "%d/%d" % [climb.cleared, Spire.FLOORS], DAILY, func(): shell.go("spire"))
	var bosses: Control
	if BossesScreen.any_open(shell.profile):
		var left := BossesScreen.runs_left_total(shell.profile, int(Time.get_unix_time_from_system()))
		bosses = door_spot(shell, "bosses", token("bosses", side), "Bosses", "%d left" % left if left > 0 else "Done", BOSS if left > 0 else Kit.MUTED, func(): shell.go("bosses"))
	else:
		bosses = door_spot(shell, "locked_dailies", token("lock", side), "Bosses", "Opens 1-5", Kit.MUTED, _bosses_locked_info(shell))
		bosses.modulate = Color(1, 1, 1, .6)
	var row := Kit.hbox(2, [
		door_spot(shell, "daily_quests", token("quests", side), "Quests", _quest_line(shell), DAILY, func(): shell.go("quests"), shell.glow.quests_ready() > 0),
		door_spot(shell, "trickshot", token("trick", side), "Trick Shot", trick_line, DAILY,
			func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn"), not trick.solved and trick.tries == 0),
		door_spot(shell, "daily_fotd", token_with("frame_gold", fotd, side), "Fight of Day", "Call it" if WeekScreen.pick_for(f.date) < 0 else "Called", DAILY, week),
		spire, bosses,
	])
	var st := Kit.box(DAILY.darkened(.88), DAILY.darkened(.6), 28, 2, 10)
	st.content_margin_left = 6
	st.content_margin_right = 6
	return Kit.panel(Kit.vbox(4, [_padded(header, 0, 0), row]), st)
## The Quests spot's status: Claim when something is ready, else today's count.
static func _quest_line(shell) -> String:
	if shell.glow.quests_ready() > 0:
		return "Claim"
	var q: Dictionary = shell.glow.quests(LiveOps.now())
	return "New" if (q.daily as Array).is_empty() else "%d/3" % q.chest.done


## Your fighter and the Quick fight button. Tap the fighter to pick another.
static func quick_fight_row(shell) -> Control:
	var p = shell.profile
	var b: Dictionary = p.best(p.lineup)
	var c := Roster.get_critter(p.lineup)
	var name := Kit.label(c.name, 24)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.clip_text = true
	var info := Kit.vbox(0, [name, Kit.hbox(8, [Glyph.make("stars", 20, Kit.FG, b.tier), Kit.label("Lv %d" % b.level, 18, Kit.MUTED), Kit.power(p.power_of(p.lineup), 18)])])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fighter := Kit.card_button(Kit.hbox(10, [CritterIcon.make(p.lineup, b.tier, 64), info], BoxContainer.ALIGNMENT_CENTER), func(): pick_fighter(shell), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 20, 0)
	fighter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("fighter", fighter)
	var fight := Kit.button("Quick fight", shell.request_play, "primary", 26, 80)
	fight.custom_minimum_size.x = 230
	fight.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("quickfight", fight)
	return Kit.hbox(10, [fighter, fight], BoxContainer.ALIGNMENT_CENTER)


## Above the doors: the Glow Pass bar and the Shop, slim because they're looks only.
## Rewards waiting turn the whole bar gold, with a solid "N TO CLAIM" pill in
## place of the level, which swells once as Home opens (no per-frame cost).
static func _style_row(shell) -> Control:
	var glow = shell.glow
	var season: Dictionary = glow.season()
	var n: int = 0 if season.is_empty() else glow.claimable_count()
	var accent := DAILY if n > 0 else STYLE
	var title := Kit.label("Glow Pass", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	var right: Control
	if n > 0:
		right = _claim_pill(n)
	else:
		right = Kit.label("Between seasons" if season.is_empty() else "Lv %d/50" % glow.pass_level(), 19, Kit.MUTED)
	var words := Kit.hbox(8, [title, right], BoxContainer.ALIGNMENT_CENTER)
	var bar := Kit.vbox(6, [words, Kit.bar(0.0 if season.is_empty() else glow.pass_level() / 50.0, accent, 10)])
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	var pass_btn := Kit.card_button(Kit.hbox(12, [Glyph.make("pass", 36, accent), bar], BoxContainer.ALIGNMENT_CENTER), func(): shell.go("pass"),
		accent if n > 0 else STYLE.darkened(.5), Color("2a2410") if n > 0 else STYLE.darkened(.86), 999, 12)
	pass_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("glowpass", pass_btn)
	var shop := Kit.card_button(Kit.hbox(8, [Glyph.make("sparkle", 32, STYLE), Kit.label("Shop", 22)], BoxContainer.ALIGNMENT_CENTER), func(): shell.go("shop"), STYLE.darkened(.5), STYLE.darkened(.86), 999, 12)
	shell.mark("shop", shop)
	return Kit.hbox(10, [pass_btn, shop], BoxContainer.ALIGNMENT_CENTER)


## "3 TO CLAIM" in dark type on a solid gold pill: the Glow Pass's call to
## come and collect. Sized to its words, so it never truncates.
static func _claim_pill(n: int) -> Control:
	var st := Kit.box(DAILY, Color(0, 0, 0, 0), 999, 0, 0)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 1
	st.content_margin_bottom = 1
	var pill := Kit.panel(Kit.label("%d TO CLAIM" % n, 17, Kit.BG), st)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.ready.connect(func():
		if not Motion.calm():
			Motion.bump(pill, 1.2, .5))
	return pill


static func _bosses_locked_info(shell) -> Callable:
	return shell.info.bind("Bosses", ["Opens at stage 1-5.",
		"Piñata Titan: smash it for coins.", "Anvil King: gear and Hammers.", "Brood Queen: Summon Eggs."])


## The furthest open zone: its stars and its next stage as a row of faces.
static func campaign_state(p) -> Dictionary:
	var Zones := preload("res://meta/zones.gd")
	var Campaign := preload("res://meta/campaign.gd")
	var z := 0
	for zi in range(1, Zones.ZONES.size()):
		if Campaign.is_unlocked(p, zi, 0): z = zi
	var zd: Dictionary = Zones.zone(z)
	var stages: Array = zd.stages
	var star_total := 0
	var next := -1
	for i in stages.size():
		if not Campaign.is_cleared(p, z, i) and next < 0: next = i
		star_total += Campaign.stars_of(p, z, i)
	var next_row: Control = Kit.label("All %d stages cleared." % stages.size(), 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	var faces = null
	var power = null
	var next_line := "All %d stages cleared" % stages.size()
	var foe: String = Zones.enemies(stages[next if next >= 0 else stages.size() - 1])[0]
	if next >= 0:
		var st: Dictionary = stages[next]
		next_line = "Next: %s %s" % [Zones.stage_key(z, next), st.get("name", Roster.get_critter(st.enemy).name)]
		var next_l := Kit.label(next_line, 22, Kit.MUTED)
		next_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		next_l.clip_text = true
		next_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		faces = Kit.hbox(2)
		for id in Zones.enemies(st):
			faces.add_child(CritterIcon.face(id, 40))
		power = Kit.power(Campaign.enemy_rating(z, next), 22, Kit.MUTED)
		next_row = Kit.hbox(12, [faces, next_l, power], BoxContainer.ALIGNMENT_CENTER)
	return {"z": z, "zone": zd, "stars": star_total, "max_stars": stages.size() * 3, "next_row": next_row, "next_line": next_line, "faces": faces, "foe": foe, "power": power}


## Quick fight with your fighter on it: tap the fighter to pick another, and
## the card updates in place. Quick fight itself is one tap: your fighter
## against a random foe of its rarity and tier, on a random arena. `band`
## (a painting with its title, on the Versus hub) heads the card.
static func quick_fight_card(shell, band: Control = null) -> Control:
	var p = shell.profile
	var b: Dictionary = p.best(p.lineup)
	var c := Roster.get_critter(p.lineup)
	var name := Kit.label(c.name, 28)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.clip_text = true
	var info := Kit.vbox(2, [Kit.hbox(8, [Glyph.make("swords", 22, Kit.MUTED), Kit.caption("Your fighter")]), name,
		Kit.hbox(10, [Glyph.make("stars", 22, Kit.FG, b.tier), Kit.label("Lv %d" % b.level, 20, Kit.MUTED), Kit.power(p.power_of(p.lineup), 20)])])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [CritterIcon.make(p.lineup, b.tier, 88), info])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	# Tap the fighter to pick another; Quick fight sits beside it, second to the campaign.
	var fighter := Kit.card_button(row, func(): pick_fighter(shell), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 24, 0)
	fighter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("fighter", fighter)
	var fight := Kit.button("Quick fight", shell.request_play, "ghost", 24, 84)
	fight.size_flags_horizontal = Control.SIZE_SHRINK_END
	fight.custom_minimum_size.x = 210
	shell.mark("quickfight", fight)
	var card := Kit.hbox(12, [fighter, fight], BoxContainer.ALIGNMENT_CENTER)
	var st := Kit.box(Kit.PANEL, Color("3a3480"), 36, 2, 18)
	if band == null:
		return Kit.panel(card, st)
	# The Versus hub heads it with a painted band that runs to the border.
	st.set_content_margin_all(2)
	return Kit.tap_card(Kit.panel(Kit.vbox(0, [band, _padded(card, 8, 14)]), st), shell.request_play, 36)


## The fighter picker (also opened by a Quick fight result's Change critter).
static func pick_fighter(shell) -> void:
	var p = shell.profile
	CritterPicker.open(shell, CritterPicker.by_power(p, BallDefs.PLAYABLE), {
		"title": "Your fighter", "current": p.lineup,
		"on_pick": func(id: String) -> void:
			p.set_lineup(id)
			shell.refresh(),
	})


## A labelled group of mode tiles, two to a row, tinted in the group's colour.
static func group(title: String, accent: Color, tiles: Array) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for t in tiles:
		grid.add_child(t)
	return Kit.vbox(10, [Kit.caption(title, accent), grid])


## A small mode tile: an icon badge (a Glyph kind, optional), the title and one
## short status line. The whole tile is the button; `mark` names it for the
## smoke test.
static func mode_tile(shell, mark: String, title: String, status: String, accent: Color, on_press: Callable, icon := "", dot := false) -> Control:
	var name := Kit.label(title, 28)
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.clip_text = true
	var line := Kit.label(status, 20, accent)
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.clip_text = true
	var v := Kit.vbox(2, [name, line])
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var content: Control = v
	if icon != "":
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content = Kit.hbox(12, [icon_badge(icon, accent, 56), v], BoxContainer.ALIGNMENT_BEGIN)
	var tile := Kit.card_button(content, on_press, accent.darkened(.45), accent.darkened(.84), 28, 18)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size.x = 0
	if dot:
		tile.add_child(red_dot())
	shell.mark(mark, tile)
	return tile


## The red "something to do here" dot, for a tile's top-right corner.
static func red_dot() -> Control:
	var d := Panel.new()
	d.add_theme_stylebox_override("panel", Kit.box(Kit.BAD, Kit.BG, 999, 3, 0))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.anchor_left = 1.0
	d.anchor_right = 1.0
	d.offset_left = -30.0
	d.offset_right = -8.0
	d.offset_top = 8.0
	d.offset_bottom = 30.0
	return d


## A mode icon in a round, softly glowing badge of the mode's colour.
static func icon_badge(icon: String, accent: Color, side := 56) -> Control:
	var st := Kit.box(accent.darkened(.72), Color(accent, .55), 999, 2, 0)
	st.shadow_color = Color(accent, .28)
	st.shadow_size = 8
	var g := Glyph.make(icon, side * .64, accent)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var c := CenterContainer.new()
	c.custom_minimum_size = Vector2(side, side)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(g)
	var p := Kit.panel(c, st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## Older full-width card API: now a tile (button_text and text are dropped).
static func mode_card(shell, mark: String, caption: String, title: String, _text: String, _button_text: String, accent: Color, on_press: Callable) -> Control:
	return mode_tile(shell, mark, title, caption, accent, on_press)


## The farming bosses open from Zone 1 stage 5 (the Piñata Titan first).
static func locked_bosses_tile(shell) -> Control:
	var t := mode_tile(shell, "locked_dailies", "Bosses", "After stage 1-5", Kit.MUTED, _bosses_locked_info(shell), "lock")
	t.modulate = Color(1, 1, 1, .55) # Locked reads as locked: dim, with the lock and what opens it.
	return t


## Friends: a count and whatever is waiting (requests, energy gifts).
static func _friends_line(fr) -> String:
	var line := "Add friends"
	if fr.status == "ready":
		line = "%d friend%s" % [fr.friends().size(), "" if fr.friends().size() == 1 else "s"]
		if not fr.incoming().is_empty():
			line = "%d request%s" % [fr.incoming().size(), "" if fr.incoming().size() == 1 else "s"]
		elif fr.gifts_claimable > 0:
			line = "%d gift%s waiting" % [fr.gifts_claimable, "" if fr.gifts_claimable == 1 else "s"]
	elif not fr.enabled():
		line = "Go online"
	return line


static func friends_tile(shell) -> Control:
	var fr = shell.friends
	return mode_tile(shell, "friends", "Friends", _friends_line(fr), Kit.GOOD if fr.attention() > 0 else VERSUS, func(): shell.go("friends"), "friends", fr.attention() > 0)
