## One critter: power, stats, level against the tier cap, the T1-T5 ability
## ladder, gear slots and the copies owned per tier.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")


static func header(shell, title: String, extra: Control = null) -> Control:
	var back := Kit.card_button(Glyph.make("back", 34, Kit.FG), shell.back, Kit.LINE, Kit.PANEL, 999, 14)
	shell.mark("back", back)
	var row := Kit.hbox(18, [back, Kit.label(title, 40)])
	row.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if extra:
		row.add_child(extra)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var c := Roster.get_critter(params.id)
	var b: Dictionary = p.best(c.id)
	var rcol: Color = Roster.RARITY_COLORS[c.rarity]
	var root := Kit.vbox(24)
	root.add_child(header(shell, c.name, Kit.chip(Roster.RARITY_NAMES[c.rarity], rcol)))

	var hero_icon := CritterIcon.make(c.id, b.tier, 320, true)
	var stars := CenterContainer.new()
	stars.add_child(Glyph.make("stars", 34, Kit.FG, b.tier, Roster.MAX_TIER))
	var pw := CenterContainer.new()
	pw.add_child(Kit.power(p.power_of(c.id), 40))
	var hero := Kit.vbox(8, [_centered(hero_icon), stars, Kit.label("%s · %s" % [c.type, c.role], 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), pw,
		Kit.label(c.vibe, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)])
	root.add_child(hero)

	var gear: Array = p.gear_on(c.id)
	var hp := roundi(120.0 * (1.0 + .03 * (b.level - 1)))
	var dmg := roundi(10.0 * (1.0 + .03 * (b.level - 1)))
	var stats := GridContainer.new()
	stats.columns = 3
	stats.add_theme_constant_override("h_separation", 12)
	for s in [["HP", str(hp)], ["Damage", str(dmg)], ["Speed", {"juggernaut": "Slow", "speedster": "Fast", "ghost": "Fast", "splitter": "Fast"}.get(c.id, "Normal")]]:
		var cell := Kit.panel(Kit.vbox(2, [Kit.label(s[0].to_upper(), 19, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(s[1], 34, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)]), Kit.box(Kit.PANEL2, Color(0, 0, 0, 0), 24, 0, 14))
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(cell)
	root.add_child(stats)

	var cap := Roster.level_cap(b.tier)
	var note := "Max level. Fuse to raise the cap to %d." % Roster.level_cap(b.tier + 1) if b.level >= cap else "Tier %d caps at level %d. Fuse to raise it." % [b.tier, cap]
	root.add_child(Kit.panel(Kit.vbox(10, [Kit.hbox(0, [Kit.caption("Level"), Kit.spacer(), Kit.label("%d / %d" % [b.level, cap], 24)]),
		Kit.bar(float(b.level) / cap, Kit.GOOD), Kit.label(note, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])))

	var ladder := Kit.vbox(8, [Kit.caption("Ability by tier")])
	for i in Roster.MAX_TIER:
		var have: bool = i < b.tier
		var tag := Kit.panel(Kit.label("T%d" % (i + 1), 22, Kit.BG if have else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.ACCENT if have else Color("221e4f"), Color(0, 0, 0, 0), 14, 0, 4))
		tag.custom_minimum_size = Vector2(62, 0)
		var l := Kit.label(c.ladder[i], 23, Kit.FG if have else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(14, [tag, l])
		if i == 4:
			row.add_child(Kit.chip("Special", Glyph.GOLD, 16))
		var st := Kit.box(Color(Kit.ACCENT, .14) if i == b.tier - 1 else Color(0, 0, 0, 0), Color(Kit.ACCENT, .5) if i == b.tier - 1 else Color(0, 0, 0, 0), 18, 2, 10)
		ladder.add_child(Kit.panel(row, st))
	root.add_child(Kit.panel(ladder))

	var slots := Kit.hbox(12)
	for slot in ["Shell", "Core"]:
		var g: Dictionary = {}
		for x in gear:
			if x.slot == slot:
				g = x
		var col: Color = Roster.RARITY_COLORS[g.rarity] if not g.is_empty() else Kit.MUTED
		var v := Kit.vbox(2, [Kit.label(g.get("name", "Empty " + slot), 24, col, HORIZONTAL_ALIGNMENT_LEFT, true),
			Kit.label(g.get("text", "Tap to equip"), 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var card := Kit.card_button(v, shell.toast.bind("Gear swapping arrives with the Bag screen."), Kit.LINE, Kit.PANEL2, 24, 14)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(card)
	root.add_child(Kit.vbox(12, [Kit.caption("Gear"), slots]))

	var chips := Kit.hbox(10)
	for s in p.copies(c.id):
		chips.add_child(Kit.panel(Kit.label("T%d  x%d" % [s.tier, s.count], 22), Kit.box(Kit.PANEL2, Kit.LINE, 16, 2, 10)))
	root.add_child(Kit.panel(Kit.vbox(10, [Kit.caption("Copies you own"), chips,
		Kit.label("3 of the same tier fuse into 1 of the next tier.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])))

	var ready: Dictionary = {}
	for s in p.copies(c.id):
		if ready.is_empty() and s.count >= 3 and s.tier < Roster.MAX_TIER:
			ready = s
	var lineup := Kit.button("In lineup" if p.lineup == c.id else "Use in lineup", func(): p.set_lineup(c.id); shell.toast("%s is now your fighter." % c.name); shell.refresh(), "ghost", 26, 90)
	var fuse := Kit.button("Fuse T%d" % ready.get("tier", b.tier), func(): shell.open_tab("fuse", {"id": c.id, "tier": ready.tier}), "go", 26, 90)
	fuse.disabled = ready.is_empty()
	shell.mark("fuse_this", fuse)
	root.add_child(Kit.hbox(16, [lineup, fuse]))
	return root


static func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc
