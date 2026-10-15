## Play tab (home): quick fight into the arena, your fighter, and what's coming
## (the Neon Circuit campaign and the daily modes), and Daily Trick Shot.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const WeekScreen := preload("res://game/ui/screens/week_screen.gd")
const RisingStar := preload("res://meta/rising_star.gd")


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(26)
	root.add_child(WeekScreen.banner(shell))

	# Campaign card: Glow Garden progress and the way into the stage list.
	var Zones := preload("res://meta/zones.gd")
	var Campaign := preload("res://meta/campaign.gd")
	var stages: Array = Zones.zone(0).stages
	var cleared := 0
	var star_total := 0
	for i in stages.size():
		cleared += 1 if Campaign.is_cleared(p, 0, i) else 0
		star_total += Campaign.stars_of(p, 0, i)
	var next_text := "All %d stages cleared. Go for 3 stars to unlock sweeps." % stages.size()
	if cleared < stages.size():
		var st: Dictionary = stages[cleared]
		next_text = "Next: %s %s, Recommended Power %s." % [Zones.stage_key(0, cleared), st.get("name", Roster.get_critter(st.enemy).name),
			Kit.commas(Campaign.enemy_rating(0, cleared))]
	var open := Kit.button("Open the map", func(): shell.go("campaign", {"zone": 0}), "go", 30, 90)
	shell.mark("campaign", open)
	var zone := Kit.vbox(10, [
		Kit.caption("Zone 1 · The Neon Circuit", Color("9be89a")),
		Kit.label("Glow Garden", 48),
		Kit.hbox(12, [Glyph.make("stars", 26, Kit.FG, 1),
			Kit.label("%d/%d stages · %d/%d stars" % [cleared, stages.size(), star_total, stages.size() * 3], 22, Kit.MUTED)]),
		Kit.label(next_text, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		open,
	])
	var zst := Kit.box(Color("17284a"), Color("2f5a55"), 40, 2, 30)
	root.add_child(Kit.panel(zone, zst))

	# Quick fight: the existing arena menu.
	var vs := Kit.hbox(12, [CritterIcon.make("vampire", 1, 150), Kit.label("VS", 30, Kit.MUTED), CritterIcon.make("laser", 1, 150)], BoxContainer.ALIGNMENT_CENTER)
	var fight := Kit.button("Quick fight", shell.request_play, "go", 34, 100)
	shell.mark("quickfight", fight)
	var quick := Kit.vbox(12, [
		Kit.caption("Arena"),
		Kit.label("Quick fight", 40),
		Kit.label("Pick a ball, aim your launch and fight.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		vs, fight,
	])
	root.add_child(Kit.panel(quick, Kit.box(Kit.PANEL, Kit.LINE, 40, 2, 30)))

	# Daily Trick Shot: one called bank shot a day, open to everyone.
	root.add_child(mode_card(shell, "trickshot", "Daily · new puzzle every day", "Trick Shot",
		"Call your walls, line up one launch and bank it in. Keep your streak going.", "Play today's shot", Color("ffd36b"),
		func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn")))

	# Rising Star: catch-up XP for new accounts, shown only while it is on.
	var rising := _rising_star_card(p)
	if rising != null:
		root.add_child(rising)

	# Your fighter.
	var b: Dictionary = p.best(p.lineup)
	var c := Roster.get_critter(p.lineup)
	var info := Kit.vbox(4, [Kit.label(c.name, 30), Glyph.make("stars", 26, Kit.FG, b.tier), Kit.label("Lv %d" % b.level, 22, Kit.MUTED), Kit.power(p.power_of(p.lineup), 26)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(16, [CritterIcon.make(p.lineup, b.tier, 150), info, Kit.chip("Change", Kit.ACCENT)])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var fighter := Kit.card_button(row, func(): shell.go("detail", {"id": p.lineup}), Color("3a3480"), Kit.PANEL2, 32, 18)
	root.add_child(Kit.vbox(12, [Kit.hbox(0, [Kit.caption("Your fighter"), Kit.spacer(), Kit.label("Zone 1 is 1v1", 22, Kit.MUTED)]), fighter]))

	root.add_child(_friends_card(shell))

	# Daily modes, locked until zone 1 is cleared.
	var modes := GridContainer.new()
	modes.columns = 3
	modes.add_theme_constant_override("h_separation", 14)
	for m in [["Critter Hunts", "Copies to fuse", Color("ff6fae")], ["Training Gym", "XP for levels", Kit.GOOD], ["Gear Vault", "Shells and Cores", Color("3d9bff")]]:
		var v := Kit.vbox(6, [Kit.label(m[0], 24, m[2], HORIZONTAL_ALIGNMENT_LEFT, true), Kit.label(m[1], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
			Kit.hbox(6, [Glyph.make("lock", 22, Kit.MUTED), Kit.label("After zone 1", 18, Kit.MUTED)])])
		var card := Kit.card_button(v, shell.toast.bind("%s unlocks after you beat Mega Boulder, the zone 1 boss." % m[0]), Kit.LINE, Kit.PANEL, 28, 16)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		modes.add_child(card)
	root.add_child(Kit.vbox(12, [Kit.caption("Daily modes"), modes]))
	return root


## A full-width mode card: caption, title, one line of text and a button.
## Other modes (Bounce Run, Arena...) add one line each with this. The button
## is registered as `mark` for the smoke test.
static func mode_card(shell, mark: String, caption: String, title: String, text: String, button_text: String, accent: Color, on_press: Callable) -> Control:
	var btn := Kit.button(button_text, on_press, "primary", 30, 90)
	shell.mark(mark, btn)
	var v := Kit.vbox(10, [Kit.caption(caption, accent), Kit.label(title, 40), Kit.label(text, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true), btn])
	return Kit.panel(v, Kit.box(accent.darkened(.82), accent.darkened(.5), 40, 2, 30))


## The Rising Star banner, or null when it is off (caught up, or past 30 days).
static func _rising_star_card(p) -> Control:
	var text := RisingStar.banner_text(p, int(Time.get_unix_time_from_system()))
	if text == "":
		return null
	var gold := Color("ffd36b")
	var star := Glyph.make("stars", 44, gold, 1)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var words := Kit.vbox(4, [Kit.caption("Rising Star", gold), Kit.label(text, 22, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.label("Helps new players catch up. It ends on its own and is never sold.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return Kit.panel(Kit.hbox(16, [star, words]), Kit.box(gold.darkened(.85), gold.darkened(.45), 32, 2, 22))


## Friends: a count and whatever is waiting (requests, energy gifts).
static func _friends_card(shell) -> Control:
	var fr = shell.friends
	var line := "Add friends, gift energy and rematch their teams."
	if fr.status == "ready":
		var bits := ["%d friend%s" % [fr.friends().size(), "" if fr.friends().size() == 1 else "s"]]
		if not fr.incoming().is_empty():
			bits.append("%d request%s" % [fr.incoming().size(), "" if fr.incoming().size() == 1 else "s"])
		if fr.gifts_claimable > 0:
			bits.append("%d gift%s waiting" % [fr.gifts_claimable, "" if fr.gifts_claimable == 1 else "s"])
		line = " · ".join(bits)
	elif not fr.enabled():
		line = "Go online to add friends."
	var text := Kit.vbox(4, [Kit.label("Friends", 32), Kit.label(line, 22, Kit.GOOD if fr.attention() > 0 else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bolt := Glyph.make("energy", 56, Color("5ce1ff"))
	bolt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := Kit.hbox(16, [bolt, text, Kit.chip("Open", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	var card := Kit.card_button(row, func(): shell.go("friends"), Color("5ce1ff") if fr.attention() > 0 else Kit.LINE, Kit.PANEL, 32, 18)
	shell.mark("friends", card)
	return card
