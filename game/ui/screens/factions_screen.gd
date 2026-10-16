## Factions: the nine faction talent trees as a 3x3 grid. Each tile shows the
## Faction Rank, points waiting to be spent and progress to the next rank.
## Tap one to open its tree (faction_screen.gd). Rules live in sim/talents.gd
## and meta/profile.gd; this only shows them. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Talents := preload("res://sim/talents.gd")


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(20)
	var head := Kit.vbox(2, [Kit.caption("Talent trees"), Kit.label("Factions", 44)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [shell.back_button("back"), head, shell.info_button("Factions", info_text(), "factions_info")],
		BoxContainer.ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for f in Talents.FACTIONS:
		grid.add_child(_tile(shell, p, f))
	root.add_child(grid)
	return root


static func info_text() -> Array:
	return [
		"Every critter belongs to a faction. Each faction has one talent tree, shared by all its critters in campaign, Gear Vault, Spire and Arena fights.",
		"Points come only from playing, never from the shop or pass: campaign and Gear Vault fights give Faction XP to the critter's faction, and the faction's first critter at each of 2 to 5 stars gives a point. Up to %d per tree." % Talents.MAX_POINTS,
		"A critter uses the rows its stars unlock: 1 star row 1, up to 4 stars row 4, and 5 stars the capstone. Resetting a tree is free, any time.",
		"Each row opens once you've spent enough points in the rows above it: %s." % ", ".join(Talents.ROW_GATE.slice(1).map(func(g): return str(g))),
	]


static func _tile(shell, p, f: String) -> Control:
	var col: Color = Talents.COLORS[f]
	var rank: int = p.faction_rank(f)
	var free: int = p.talent_points_free(f)
	var next: Dictionary = p.faction_xp_rank(f)
	var owned := 0
	for id in Talents.MEMBERS[f]:
		if p.owns(id):
			owned += 1
	var v := Kit.vbox(6, [
		Kit.label(Talents.NAMES[f], 28, col, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("Rank %d" % rank, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.bar(1.0 if rank >= Talents.MAX_POINTS else float(next.xp) / float(next.need), col, 12),
		Kit.label("%d/%d critters" % [owned, Talents.MEMBERS[f].size()], 18, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
	])
	var badge := Kit.label("%d to spend" % free if free > 0 else " ", 18, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(badge)
	var t := Kit.card_button(v, func(): shell.go("faction", {"id": f}), Color(col, .7 if free > 0 else .35), Kit.PANEL, 28, 12)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("faction_" + f, t)
	return t
