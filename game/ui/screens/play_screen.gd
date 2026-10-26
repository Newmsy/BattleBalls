## Play tab (home): a slim Glow Pass and Shop row under the top bar, then three
## themed doors, Adventure, Daily and Versus. Each door shows its best taps
## (Continue, the dailies, Ghost Arena and Quick fight); its header opens a hub screen with
## everything in it (adventure_screen, week_screen, versus_screen). A new mode
## goes in one hub, and on its door only if it's that door's best tap.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const WeekScreen := preload("res://game/ui/screens/week_screen.gd")
const LiveOps := preload("res://game/liveops.gd")
const TrickShot := preload("res://sim/trick_shot.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const BossesScreen := preload("res://game/ui/screens/bosses_screen.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const Intro := preload("res://game/ui/intro.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const Dev := preload("res://game/dev.gd")

const DAILY := Color("ffd36b")
const VERSUS := Color("ff4fd8")
const STYLE := Color("5ce1ff")
const ADVENTURE := Color("45f5a6")
const BOSS := Color("ff8a3d")
## Kit.MUTED, a step lighter, for words over a painting.
const ON_ART_MUTED := Color("cfcdf0")

## True on a tall phone (more than a 9:16 screen's height): the doors' badges,
## buttons and words grow a step so they fill the room instead of floating.
static var tall := false


static func build(shell, _params: Dictionary) -> Control:
	tall = shell.size.y > 1400.0
	var root := Kit.vbox(14)
	# One column that fills the room: the Glow Pass and Shop row on top, then
	# the doors share the height and spread their rows out, so a tall phone has
	# no dead band in one door. The shell keeps this first child at the top
	# rather than centring it.
	var doors := [_adventure_door(shell), _daily_door(shell), _versus_door(shell)]
	var style := _style_row(shell)
	if not Intro.done(shell.profile):
		# A new player's first fights (game/ui/intro.gd) still see the whole
		# Home: what isn't open yet is dimmed, with what opens it on top.
		style = _lock(shell, style, LATER)
		doors[1] = _lock(shell, doors[1], LATER)
		if not Intro.shows(shell.profile, "arena"):
			doors[2] = _lock(shell, doors[2], "Opens after stage 1-3")
	# Each door's share of the height is roughly in step with its own size (about
	# 410, 300 and 360 high; Adventure a little more), so the spare spreads
	# out instead of pooling in one door.
	for i in doors.size():
		doors[i].size_flags_vertical = Control.SIZE_EXPAND_FILL
		doors[i].size_flags_stretch_ratio = [4.4, 2.8, 3.5][i]
	var col := Kit.vbox(14, [style] + doors)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(col)
	return root


## What a locked part of Home says during a new player's first fights: the
## rest of the game opens with the Trophy Room, after the first Arena fight.
const LATER := "Opens after your first Arena fight"


## `c` dimmed under a cover that says what opens it; a tap on it says the same.
static func _lock(shell, c: Control, line: String) -> Control:
	var words := Kit.label(line, 20, Kit.FG)
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


# --- The three doors ----------------------------------------------------------
# Home is three themed doors (Adventure, Daily, Versus). Each shows its most
# useful actions right on the door; its header opens a hub with everything in
# it. A new mode goes in one hub, and on a door only if it's the door's best tap.

## A door: a header that opens the hub, then the door's own quick actions.
## `paint` puts a painting (game/ui/home_art) on it: {"id", "focus"} heads the
## door with a band of the painting under the title; "hero" fills the whole
## door with it, its words over the darkened top and bottom.
static func door(shell, mark: String, title: String, sub: String, accent: Color, hub: Callable, body: Array, paint := {}) -> Control:
	var head := Kit.vbox(0, [Kit.label(title, 34, accent), Kit.label(sub, 19, Kit.MUTED)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A painted door opens into its hub with a wash of its colour.
	var painting: Array = [null]
	var open_hub := func():
		if is_instance_valid(painting[0]):
			shell.light_from(painting[0], accent)
		hub.call()
	var header := Kit.card_button(Kit.hbox(8, [head, Kit.label("›", 44, accent)], BoxContainer.ALIGNMENT_CENTER), open_hub, Color(0, 0, 0, 0), Color(0, 0, 0, 0), 16, 0)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark, header)
	var bg := accent.darkened(.86)
	var st := Kit.box(bg, accent.darkened(.4), 32, 2, 18)
	if paint.is_empty():
		# Spare height goes into the gaps between the rows, so a tall door spreads
		# out evenly instead of floating its rows in the middle.
		var v := Kit.vbox(0, [header])
		for c in body:
			v.add_child(_gap())
			v.add_child(c)
		return Kit.panel(v, st)
	_on_art(header)
	# The painting sits inside the 2px border, its corners rounded to match.
	st.set_content_margin_all(2)
	if paint.get("hero", false):
		# Its left side is kept calm for the words; the props live on the right.
		var art: Control = HomePainting.make(paint.id, paint.focus, 30.0, Vector4(.24, .6, .3, .92), Kit.BG).calm_left(.62, .72)
		painting[0] = art
		# The painting shows through the spare room between the header and the rows.
		var room := _gap()
		room.custom_minimum_size.y = 40 if tall else 0
		for c in body:
			_on_art(c)
		var v := Kit.vbox(10, [header, room] + body)
		var stack := MarginContainer.new()
		stack.add_child(art)
		stack.add_child(_padded(v, 16, 16))
		return Kit.panel(stack, st)
	# A band of painting with the title on it, then the door's rows.
	var band := MarginContainer.new()
	band.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# On a short phone the band is just the header's height; a tall one grows it.
	band.custom_minimum_size.y = 130 if tall else 0
	painting[0] = HomePainting.make(paint.id, paint.focus, 30.0, Vector4(.3, .45, .55, 1.0), bg).calm_left(.62, .65)
	band.add_child(painting[0])
	band.add_child(_padded(header, 16, 0))
	var rows := Kit.vbox(8, body)
	return Kit.panel(Kit.vbox(0, [band, _padded(rows, 0, 16)]), st)


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


## Adventure: where the campaign stands and Continue, with the Spire and the
## bosses beside it. The header opens the Adventure hub.
static func _adventure_door(shell) -> Control:
	var c := campaign_state(shell.profile)
	var name := Kit.label(c.zone.name, _s(30))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := Kit.hbox(10, [name, _art_pill(Kit.hbox(6, [Glyph.make("crown", 26, Kit.FG, 1), Kit.label("%d/%d" % [c.stars, c.max_stars], 22, Kit.MUTED)]))], BoxContainer.ALIGNMENT_CENTER)
	# The next stage's power sits on a pill too: the right side is the painting's.
	if c.power != null:
		var row: Control = c.next_row
		row.remove_child(c.power)
		row.add_child(_art_pill(c.power))
	# The zone's painting is the door's picture; the next foes' faces sit in
	# the Next line.
	var zone := Kit.vbox(8, [top, c.next_row])
	zone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var go := Kit.button("Continue", func(): shell.go("world"), "go", _s(30), _s(88))
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.size_flags_stretch_ratio = 2.0
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("campaign", go)
	var climb = SpireClimb.load_file(LiveOps.now())
	var spire := door_spot(shell, "spire", token("spire", _s(62)), "Spire", "%d/%d" % [climb.cleared, Spire.FLOORS], DAILY, func(): shell.go("spire"))
	var intro := not Intro.done(shell.profile)
	if intro:
		spire = door_spot(shell, "spire", token("lock", _s(62)), "Spire", "Opens later", Kit.MUTED, func(): shell.toast(LATER))
		spire.modulate = Color(1, 1, 1, .6)
	var bosses: Control
	if BossesScreen.any_open(shell.profile):
		var left := BossesScreen.runs_left_total(shell.profile, int(Time.get_unix_time_from_system()))
		bosses = door_spot(shell, "bosses", token("bosses", _s(62)), "Bosses", "%d left" % left if left > 0 else "Done", BOSS if left > 0 else Kit.MUTED, func(): shell.go("bosses"))
	else:
		bosses = door_spot(shell, "locked_dailies", token("lock", _s(62)), "Bosses", "Opens 1-5", Kit.MUTED, _bosses_locked_info(shell))
		bosses.modulate = Color(1, 1, 1, .6)
	# During the first fights the header goes where Continue does: the hub's
	# other rooms aren't open yet.
	return door(shell, "adventure", "ADVENTURE", "Campaign · Spire · Bosses", ADVENTURE, func(): shell.go("world" if intro else "adventure"),
		[zone, Kit.hbox(10, [go, spire, bosses], BoxContainer.ALIGNMENT_CENTER)],
		{"id": "home_zone_" + c.zone.id, "focus": Vector2(.75, .45), "hero": true})


## Daily: today's puzzle and run, then this week's events. The header opens the
## Daily board (the old This Week screen).
static func _daily_door(shell) -> Control:
	var t := LiveOps.now()
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var trick: Dictionary = WeekScreen.trick_status(day)
	var trick_line := "Solved" if trick.solved else ("Done" if trick.tries >= WeekScreen.TRICK_TRIES else "New")
	var week := func(): shell.go("week")
	var f := LiveOps.fight_of_the_day(t)
	var fotd := Kit.hbox(-12, [CritterIcon.face(f.p1, _s(30)), CritterIcon.face(f.p2, _s(30))], BoxContainer.ALIGNMENT_CENTER)
	var row := Kit.hbox(4, [
		door_spot(shell, "trickshot", token("trick", _s(62)), "Trick Shot", trick_line, DAILY,
			func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn"), not trick.solved and trick.tries == 0),
		door_spot(shell, "bouncerun", token("bounce", _s(62)), "Bounce Run", "New run", DAILY,
			func(): shell.get_tree().change_scene_to_file("res://game/bounce_run.tscn")),
		door_spot(shell, "daily_fotd", token_with("frame_gold", fotd, _s(62)), "Fight of Day", "Call it" if WeekScreen.pick_for(f.date) < 0 else "Called", DAILY, week),
		door_spot(shell, "daily_quests", token("quests", _s(62)), "Quests", _quest_line(shell), DAILY, func(): shell.go("quests"), shell.glow.quests_ready() > 0),
	])
	var season := LiveOps.season(t)
	var sub := "Puzzles, runs and this week's events" if season.is_empty() else "%s · week %d of %d" % [season.name, season.week, season.weeks]
	return door(shell, "thisweek", "DAILY", sub, DAILY, week, [row], {"id": "home_daily", "focus": Vector2(.75, .5)})


## The Quests spot's status: Claim when something is ready, else today's count.
static func _quest_line(shell) -> String:
	if shell.glow.quests_ready() > 0:
		return "Claim"
	var q: Dictionary = shell.glow.quests(LiveOps.now())
	return "New" if (q.daily as Array).is_empty() else "%d/3" % q.chest.done


## Versus: Ghost Arena and Friends, then Quick fight with your fighter (tap
## the face to pick another) while live fights are on. The header opens the
## Versus hub.
static func _versus_door(shell) -> Control:
	var store = ArenaStore.open()
	var league := Kit.vbox(0, [Kit.label("Ghost Arena", _s(26)), Kit.label("%s · %s" % [Ladder.league_label(store.trophies), Kit.commas(store.trophies)], 19, VERSUS)])
	league.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var arena := Kit.card_button(Kit.hbox(12, [token("ghost", _s(64)), league], BoxContainer.ALIGNMENT_CENTER), func(): shell.go("arena"), VERSUS.darkened(.45), VERSUS.darkened(.8), 24, 10)
	arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("arena", arena)
	var fr = shell.friends
	var fg := token("friends", 44)
	fg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var fv := Kit.vbox(2, [fg, Kit.label("Friends", 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)])
	fv.alignment = BoxContainer.ALIGNMENT_CENTER
	fv.custom_minimum_size.x = 100
	var intro := not Intro.done(shell.profile)
	var friends := Kit.card_button(fv, func(): shell.toast(LATER) if intro else shell.go("friends"), VERSUS.darkened(.45), VERSUS.darkened(.8), 24, 10)
	if intro:
		friends.modulate = Color(1, 1, 1, .5)
	friends.size_flags_vertical = Control.SIZE_FILL
	if fr.attention() > 0:
		friends.add_child(red_dot())
	shell.mark("friends", friends)
	var rows: Array = [Kit.hbox(8, [arena, friends], BoxContainer.ALIGNMENT_CENTER)]
	if Dev.quick_fight_shown():
		rows.append(quick_fight_row(shell))
	return door(shell, "versus", "VERSUS", "Ghost Arena · Quick fight · Friends" if Dev.quick_fight_shown() else "Ghost Arena · Friends", VERSUS, func(): shell.go("arena" if intro else "versus"),
		rows,
		{"id": "home_versus", "focus": Vector2(.75, .9)})


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
static func _style_row(shell) -> Control:
	var glow = shell.glow
	var season: Dictionary = glow.season()
	var n: int = 0 if season.is_empty() else glow.claimable_count()
	var line := "Between seasons" if season.is_empty() else ("%d to claim!" % n if n > 0 else "Lv %d/50" % glow.pass_level())
	var words := Kit.hbox(8, [Kit.label("Glow Pass", 22), Kit.spacer(), Kit.label(line, 19, DAILY if n > 0 else Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	var bar := Kit.vbox(6, [words, Kit.bar(0.0 if season.is_empty() else glow.pass_level() / 50.0, STYLE, 10)])
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pass_btn := Kit.card_button(Kit.hbox(12, [Glyph.make("pass", 36, STYLE), bar], BoxContainer.ALIGNMENT_CENTER), func(): shell.go("pass"), STYLE.darkened(.5), STYLE.darkened(.86), 999, 12)
	pass_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if n > 0:
		pass_btn.add_child(red_dot())
	shell.mark("glowpass", pass_btn)
	var shop := Kit.card_button(Kit.hbox(8, [Glyph.make("sparkle", 32, STYLE), Kit.label("Shop", 22)], BoxContainer.ALIGNMENT_CENTER), func(): shell.go("shop"), STYLE.darkened(.5), STYLE.darkened(.86), 999, 12)
	shell.mark("shop", shop)
	return Kit.hbox(10, [pass_btn, shop], BoxContainer.ALIGNMENT_CENTER)


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
	var foe: String = Zones.enemies(stages[next if next >= 0 else stages.size() - 1])[0]
	if next >= 0:
		var st: Dictionary = stages[next]
		var next_l := Kit.label("Next: %s %s" % [Zones.stage_key(z, next), st.get("name", Roster.get_critter(st.enemy).name)], 22, Kit.MUTED)
		next_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		next_l.clip_text = true
		next_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		faces = Kit.hbox(2)
		for id in Zones.enemies(st):
			faces.add_child(CritterIcon.face(id, 40))
		power = Kit.power(Campaign.enemy_rating(z, next), 22, Kit.MUTED)
		next_row = Kit.hbox(12, [faces, next_l, power], BoxContainer.ALIGNMENT_CENTER)
	return {"z": z, "zone": zd, "stars": star_total, "max_stars": stages.size() * 3, "next_row": next_row, "faces": faces, "foe": foe, "power": power}


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
	return Kit.panel(Kit.vbox(0, [band, _padded(card, 8, 14)]), st)


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
