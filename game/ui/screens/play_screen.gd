## Play tab (home). Three bands, top to bottom, so it reads at a glance:
## the This Week banner, the two big ways to fight (the campaign and Quick
## fight with your fighter), then every other mode as a small tile in a
## labelled group (Daily and weekly, Versus, Style). New modes add one tile
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
const GearVault := preload("res://meta/gear_vault.gd")

const DAILY := Color("ffd36b")
const VERSUS := Color("ff4fd8")
const STYLE := Color("5ce1ff")


static func build(shell, _params: Dictionary) -> Control:
	var root := Kit.vbox(20)
	root.add_child(WeekScreen.banner(shell))
	root.add_child(_campaign_card(shell))
	root.add_child(_quick_fight_card(shell))

	# Daily and weekly: same puzzle, run or tower for everyone.
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var trick: Dictionary = WeekScreen.trick_status(day)
	var trick_line := "Solved · streak %d" % trick.streak if trick.solved else ("Out of tries" if trick.tries >= WeekScreen.TRICK_TRIES else "New shot today")
	var run_day := BounceRun.day_number(Time.get_unix_time_from_system())
	var climb = SpireClimb.load_file(LiveOps.now())
	root.add_child(group("Daily and weekly", DAILY, [
		mode_tile(shell, "trickshot", "Trick Shot", trick_line, DAILY,
			func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn"), "target"),
		mode_tile(shell, "bouncerun", "Bounce Run", "Run #%d · daily" % run_day, Color("ffc23d"),
			func(): shell.get_tree().change_scene_to_file("res://game/bounce_run.tscn"), "bounce"),
		mode_tile(shell, "spire", "The Spire", "Floor %d/%d · weekly" % [climb.cleared, Spire.FLOORS], Color("ffc23d"),
			func(): shell.go("spire"), "tower"),
		_vault_tile(shell) if GearVault.is_unlocked(shell.profile) else _locked_tile(shell),
	]))

	# Versus: other players' teams.
	var arena_store = ArenaStore.open()
	root.add_child(group("Versus", VERSUS, [
		mode_tile(shell, "arena", "Ghost Arena", "%s · %s" % [Ladder.league_label(arena_store.trophies), Kit.commas(arena_store.trophies)], VERSUS,
			func(): shell.go("arena"), "ghost"),
		_friends_tile(shell),
	]))

	# Style: looks only, never power.
	root.add_child(group("Style", STYLE, [_pass_tile(shell),
		mode_tile(shell, "shop", "Cosmetics", "Looks only", STYLE, func(): shell.go("shop"), "sparkle")]))
	return root


## The campaign: the main way forward, so it gets the first big card.
static func _campaign_card(shell) -> Control:
	var p = shell.profile
	# Campaign card: Glow Garden progress and the way into the stage list.
	var Zones := preload("res://meta/zones.gd")
	var Campaign := preload("res://meta/campaign.gd")
	var stages: Array = Zones.zone(0).stages
	var cleared := 0
	var star_total := 0
	for i in stages.size():
		cleared += 1 if Campaign.is_cleared(p, 0, i) else 0
		star_total += Campaign.stars_of(p, 0, i)
	var next_text := "All %d stages cleared. 3-star them to sweep." % stages.size()
	if cleared < stages.size():
		var st: Dictionary = stages[cleared]
		next_text = "Next: %s %s · Recommended %s" % [Zones.stage_key(0, cleared), st.get("name", Roster.get_critter(st.enemy).name),
			Kit.commas(Campaign.enemy_rating(0, cleared))]
	var open := Kit.button("Open the map", func(): shell.go("world"), "go", 30, 84)
	shell.mark("campaign", open)
	var zone := Kit.vbox(8, [
		Kit.hbox(10, [Glyph.make("map", 24, Color("9be89a")), Kit.caption("Campaign · Zone 1 · The Neon Circuit", Color("9be89a"))], BoxContainer.ALIGNMENT_BEGIN),
		Kit.hbox(10, [Kit.label("Glow Garden", 40), Kit.spacer(), Glyph.make("stars", 26, Kit.FG, 1),
			Kit.label("%d/%d" % [star_total, stages.size() * 3], 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER),
		Kit.label(next_text if cleared == stages.size() else "%d/%d stages cleared. %s" % [cleared, stages.size(), next_text], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		open,
	])
	var zst := Kit.box(Color("17284a"), Color("2f5a55"), 36, 2, 24)
	return Kit.panel(zone, zst)


## Quick fight with your fighter on it: tap the fighter to change it.
static func _quick_fight_card(shell) -> Control:
	var p = shell.profile
	var b: Dictionary = p.best(p.lineup)
	var c := Roster.get_critter(p.lineup)
	var info := Kit.vbox(2, [Kit.hbox(8, [Glyph.make("swords", 22, Kit.MUTED), Kit.caption("Quick fight · your fighter")]), Kit.label(c.name, 30),
		Kit.hbox(10, [Glyph.make("stars", 24, Kit.FG, b.tier), Kit.label("Lv %d" % b.level, 22, Kit.MUTED), Kit.power(p.power_of(p.lineup), 24)])])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(16, [CritterIcon.make(p.lineup, b.tier, 104), info, Kit.chip("Change", Kit.ACCENT)])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var fighter := Kit.card_button(row, func(): shell.go("detail", {"id": p.lineup}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 24, 0)
	shell.mark("fighter", fighter)
	var fight := Kit.button("Quick fight", shell.request_play, "primary", 30, 84)
	shell.mark("quickfight", fight)
	return Kit.panel(Kit.vbox(14, [fighter, fight]), Kit.box(Kit.PANEL, Color("3a3480"), 36, 2, 24))


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
static func mode_tile(shell, mark: String, title: String, status: String, accent: Color, on_press: Callable, icon := "") -> Control:
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
	shell.mark(mark, tile)
	return tile


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


## Critter Hunts, Training Gym and Gear Vault open after zone 1: one tile.
static func _locked_tile(shell) -> Control:
	var t := mode_tile(shell, "locked_dailies", "Hunts · Gym · Vault", "After zone 1", Kit.MUTED,
		shell.info.bind("After zone 1", ["Beat Mega Boulder, the zone 1 boss, to open three daily modes:",
			"Critter Hunts: copies of one critter to fuse.", "Training Gym: XP for levels.", "Gear Vault: Shells and Cores."]), "lock")
	return t


## Gear Vault, once zone 1 is beaten: today's slot and runs left.
static func _vault_tile(shell) -> Control:
	var now := int(Time.get_unix_time_from_system())
	var slot: String = GearVault.today(now).slot
	var left := GearVault.runs_left(shell.profile, now)
	var line := "%s · %d runs left" % ["Any gear" if slot == "" else slot + "s", left] if left > 0 else "Done for today"
	return mode_tile(shell, "vault", "Gear Vault", line, Color("5ce1ff") if left > 0 else Kit.MUTED, func(): shell.go("vault"), "vault")


static func _pass_tile(shell) -> Control:
	var glow = shell.glow
	var season: Dictionary = glow.season()
	if season.is_empty():
		return mode_tile(shell, "glowpass", "Glow Pass", "Between seasons", DAILY, func(): shell.go("pass"), "pass")
	var n: int = glow.claimable_count()
	var line := "Level %d of 50" % glow.pass_level()
	if n > 0:
		line = "%d reward%s to claim!" % [n, "" if n == 1 else "s"]
	return mode_tile(shell, "glowpass", "Glow Pass", line, DAILY if n > 0 else STYLE, func(): shell.go("pass"), "pass")


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
	return mode_tile(shell, "friends", "Friends", line, Kit.GOOD if fr.attention() > 0 else VERSUS, func(): shell.go("friends"), "friends")
