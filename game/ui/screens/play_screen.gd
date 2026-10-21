## Play tab (home). Three bands, top to bottom, so it reads at a glance:
## the This Week banner, the two big ways to fight (the campaign and Quick
## fight with your fighter), then every other mode as a small tile in a
## labelled group (Daily, Versus, Style). New modes add one tile
## to a group with mode_tile(); the groups grow, the big cards never move.
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

const DAILY := Color("ffd36b")
const VERSUS := Color("ff4fd8")
const STYLE := Color("5ce1ff")


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(20)
	if not Intro.done(shell.profile):
		# A new player's first fights: the campaign, then the Arena once 1-3 opens it.
		root.add_child(_campaign_card(shell))
		if Intro.shows(shell.profile, "arena"):
			var store = ArenaStore.open()
			root.add_child(group("Versus", VERSUS, [mode_tile(shell, "arena", "Ghost Arena", "%s · %s" % [Ladder.league_label(store.trophies), Kit.commas(store.trophies)],
				VERSUS, func(): shell.go("arena"), "ghost")]))
		return root
	root.add_child(WeekScreen.banner(shell))
	root.add_child(_campaign_card(shell))
	root.add_child(_quick_fight_card(shell))

	# Daily: same puzzle, run or tower for everyone.
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var trick: Dictionary = WeekScreen.trick_status(day)
	var trick_line := "Solved · streak %d" % trick.streak if trick.solved else ("Out of tries" if trick.tries >= WeekScreen.TRICK_TRIES else "New shot today")
	var climb = SpireClimb.load_file(LiveOps.now())
	root.add_child(group("Daily", DAILY, [
		mode_tile(shell, "trickshot", "Trick Shot", trick_line, DAILY,
			func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn"), "target", not trick.solved and trick.tries == 0),
		mode_tile(shell, "bouncerun", "Bounce Run", "New run today", Color("ffc23d"),
			func(): shell.get_tree().change_scene_to_file("res://game/bounce_run.tscn"), "bounce"),
		mode_tile(shell, "spire", "The Spire", "Floor %d/%d" % [climb.cleared, Spire.FLOORS], Color("ffc23d"),
			func(): shell.go("spire"), "tower"),
		BossesScreen.tile(shell) if BossesScreen.any_open(shell.profile) else _locked_tile(shell),
	]))

	# Versus: other players' teams.
	var arena_store = ArenaStore.open()
	root.add_child(group("Versus", VERSUS, [
		mode_tile(shell, "arena", "Ghost Arena", "%s · %s" % [Ladder.league_label(arena_store.trophies), Kit.commas(arena_store.trophies)], VERSUS,
			func(): shell.go("arena"), "ghost"),
		_friends_tile(shell),
		# Quick fight is one tap; picking a pair for a four-ball brawl lives here.
		mode_tile(shell, "duo", "2v2", "Pick a pair", VERSUS, func(): shell.request_play("", true), "critters"),
	]))

	# Style: looks only, never power.
	root.add_child(group("Style", STYLE, [_pass_tile(shell),
		mode_tile(shell, "shop", "Cosmetics", "Looks only", STYLE, func(): shell.go("shop"), "sparkle")]))
	return root


## The campaign: the main way forward, so it gets the first big card.
static func _campaign_card(shell) -> Control:
	var p = shell.profile
	# Campaign card: progress in the furthest zone you've opened, and its next stage.
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
	if next >= 0:
		var st: Dictionary = stages[next]
		var next_l := Kit.label("Next: %s %s" % [Zones.stage_key(z, next), st.get("name", Roster.get_critter(st.enemy).name)], 22, Kit.MUTED)
		next_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		next_l.clip_text = true
		next_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		next_row = Kit.hbox(12, [next_l, Kit.power(Campaign.enemy_rating(z, next), 22, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	var open := Kit.button("Continue", func(): shell.go("world"), "go", 32, 96)
	shell.mark("campaign", open)
	var zone := Kit.vbox(8, [
		Kit.hbox(10, [Glyph.make("map", 24, Color("9be89a")), Kit.caption("Campaign · Zone %d" % (z + 1), Color("9be89a"))], BoxContainer.ALIGNMENT_BEGIN),
		Kit.hbox(10, [Kit.label(zd.name, 40), Kit.spacer(), Glyph.make("crown", 28, Kit.FG, 1),
			Kit.label("%d/%d" % [star_total, stages.size() * 3], 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER),
		next_row,
		open,
	])
	var zst := Kit.box(Color("17284a"), Color("2f5a55"), 36, 2, 24)
	return Kit.panel(zone, zst)


## Quick fight with your fighter on it: tap the fighter to pick another, and
## the card updates in place. Quick fight itself is one tap: your fighter
## against a random foe of its rarity and tier, on a random arena.
static func _quick_fight_card(shell) -> Control:
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
	return Kit.panel(Kit.hbox(12, [fighter, fight], BoxContainer.ALIGNMENT_CENTER), Kit.box(Kit.PANEL, Color("3a3480"), 36, 2, 18))


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
static func _locked_tile(shell) -> Control:
	var t := mode_tile(shell, "locked_dailies", "Bosses", "After stage 1-5", Kit.MUTED,
		shell.info.bind("Bosses", ["Opens at stage 1-5.",
			"Piñata Titan: smash it for coins.", "Anvil King: gear and Hammers.", "Brood Queen: Summon Eggs."]), "lock")
	t.modulate = Color(1, 1, 1, .55) # Locked reads as locked: dim, with the lock and what opens it.
	return t


static func _pass_tile(shell) -> Control:
	var glow = shell.glow
	var season: Dictionary = glow.season()
	if season.is_empty():
		return mode_tile(shell, "glowpass", "Glow Pass", "Between seasons", DAILY, func(): shell.go("pass"), "pass")
	var n: int = glow.claimable_count()
	var line := "Lv %d/50" % glow.pass_level()
	if n > 0:
		line = "%d to claim!" % n
	return mode_tile(shell, "glowpass", "Glow Pass", line, DAILY if n > 0 else STYLE, func(): shell.go("pass"), "pass", n > 0)


## Friends: a count and whatever is waiting (requests, energy gifts).
static func _friends_tile(shell) -> Control:
	var fr = shell.friends
	var line := "Add friends"
	if fr.status == "ready":
		line = "%d friend%s" % [fr.friends().size(), "" if fr.friends().size() == 1 else "s"]
		if not fr.incoming().is_empty():
			line = "%d request%s" % [fr.incoming().size(), "" if fr.incoming().size() == 1 else "s"]
		elif fr.gifts_claimable > 0:
			line = "%d gift%s waiting" % [fr.gifts_claimable, "" if fr.gifts_claimable == 1 else "s"]
	elif not fr.enabled():
		line = "Go online to add"
	return mode_tile(shell, "friends", "Friends", line, Kit.GOOD if fr.attention() > 0 else VERSUS, func(): shell.go("friends"), "friends", fr.attention() > 0)
