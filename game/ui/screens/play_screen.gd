## Play tab (home): quick fight into the arena, your fighter, and what's coming
## (the Neon Circuit campaign and the daily modes).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const WeekScreen := preload("res://game/ui/screens/week_screen.gd")


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(26)
	root.add_child(WeekScreen.banner(shell))

	# Campaign card (the PvE thread is building zone 1).
	var zone := Kit.vbox(10, [
		Kit.caption("Zone 1 · The Neon Circuit", Color("9be89a")),
		Kit.label("Glow Garden", 48),
		Kit.label("10 stages and the Mega Boulder boss. The campaign map is on its way.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.hbox(8, [Glyph.make("lock", 30, Kit.MUTED), Kit.label("Coming soon", 24, Kit.MUTED)]),
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

	# Your fighter.
	var b: Dictionary = p.best(p.lineup)
	var c := Roster.get_critter(p.lineup)
	var info := Kit.vbox(4, [Kit.label(c.name, 30), Glyph.make("stars", 26, Kit.FG, b.tier), Kit.label("Lv %d" % b.level, 22, Kit.MUTED), Kit.power(p.power_of(p.lineup), 26)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(16, [CritterIcon.make(p.lineup, b.tier, 150), info, Kit.chip("Change", Kit.ACCENT)])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var fighter := Kit.card_button(row, func(): shell.go("detail", {"id": p.lineup}), Color("3a3480"), Kit.PANEL2, 32, 18)
	root.add_child(Kit.vbox(12, [Kit.hbox(0, [Kit.caption("Your fighter"), Kit.spacer(), Kit.label("Zone 1 is 1v1", 22, Kit.MUTED)]), fighter]))

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
