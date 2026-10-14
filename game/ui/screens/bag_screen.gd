## Bag tab: gear (Shells and Cores, with who wears each) and items. Tap gear to
## move it to another critter; swapping is always free.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")

static var section := "gear"


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var count := 0
	for i in p.items:
		count += i.count
	var root := Kit.vbox(22)
	root.add_child(Kit.hbox(0, [Kit.label("Bag", 44), Kit.spacer(), Kit.label("%d gear · %d items" % [p.gear.size(), count], 24, Kit.MUTED)]))

	var seg := Kit.hbox(8)
	for s in [["gear", "Gear"], ["items", "Items"]]:
		var on: bool = section == s[0]
		var b := Kit.card_button(Kit.label(s[1].to_upper(), 24, Kit.FG if on else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			func(): section = s[0]; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.PANEL2 if on else Kit.PANEL, 22, 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("bag_" + s[0], b)
		seg.add_child(b)
	root.add_child(seg)

	if section == "gear":
		for slot in ["Shell", "Core"]:
			var grid := _grid()
			for g in p.gear:
				if g.slot == slot:
					grid.add_child(_gear_tile(shell, g))
			root.add_child(Kit.vbox(12, [Kit.caption(slot + "s"), grid]))
	else:
		var grid := _grid()
		for it in p.items:
			var v := Kit.vbox(6, [_center(_item_icon(it)), Kit.label(it.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true), Kit.label("x%d" % it.count, 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
			var card := Kit.card_button(v, func(): _item_sheet(shell, it), Kit.LINE, Kit.PANEL, 28, 14)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shell.mark("item_" + it.name.replace(" ", "_"), card)
			grid.add_child(card)
		root.add_child(grid)
		root.add_child(Kit.label("Spare critter copies stay in your collection, not the Bag.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	return root


static func _gear_tile(shell, g: Dictionary) -> Control:
	var col: Color = Roster.RARITY_COLORS[g.rarity]
	var wearer: String = "Free" if g.on == "" else "On " + Roster.get_critter(g.on).name
	var v := Kit.vbox(4, [_center(Glyph.make(g.slot.to_lower(), 90, col)), Kit.label(g.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true),
		Kit.label(Roster.RARITY_NAMES[g.rarity], 19, col, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(wearer, 19, Kit.GOOD if g.on != "" else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)])
	var card := Kit.card_button(v, func(): _gear_sheet(shell, g), Color(col, .55), Kit.PANEL, 28, 12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("gear_%d" % g.uid, card)
	return card


static func _gear_sheet(shell, g: Dictionary) -> void:
	var p = shell.profile
	var col: Color = Roster.RARITY_COLORS[g.rarity]
	var info := Kit.vbox(6, [Kit.label(g.name, 36), Kit.chip("%s %s" % [Roster.RARITY_NAMES[g.rarity], g.slot], col)])
	info.get_child(1).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var wearer: String = "Not equipped" if g.on == "" else "Worn by " + Roster.get_critter(g.on).name
	var v := Kit.vbox(18, [Kit.hbox(18, [Glyph.make(g.slot.to_lower(), 110, col), info]), Kit.label(g.text, 28, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.label(wearer, 22, Kit.MUTED), Kit.caption("Equip to")])
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var row := Kit.hbox(12)
	for c in Roster.CRITTERS:
		if not p.owns(c.id):
			continue
		var on: bool = g.on == c.id
		var card := Kit.card_button(Kit.vbox(0, [CritterIcon.make(c.id, p.best(c.id).tier, 120), Kit.label(c.name, 19, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)]),
			func(): p.equip(g.uid, c.id); shell.close_overlay(); shell.toast("%s equipped to %s." % [g.name, c.name]); shell.refresh(),
			Kit.GOOD if on else Kit.LINE, Kit.PANEL2, 24, 6)
		card.custom_minimum_size.x = 150
		shell.mark("equip_" + c.id, card)
		row.add_child(card)
	scroll.add_child(row)
	scroll.custom_minimum_size.y = row.get_combined_minimum_size().y
	v.add_child(scroll)
	if g.on != "":
		v.add_child(Kit.button("Unequip", func(): p.unequip(g.uid); shell.close_overlay(); shell.refresh(), "ghost", 26, 84))
	shell.sheet(v)


static func _item_sheet(shell, it: Dictionary) -> void:
	var p = shell.profile
	var v := Kit.vbox(18, [Kit.hbox(18, [_item_icon(it), Kit.label("%s  x%d" % [it.name, it.count], 34)]), Kit.label(it.text, 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	var act: Button
	match it.name:
		"Energy Pack":
			act = Kit.button("Use 1", func(): shell.close_overlay(); if p.use_energy_pack(): shell.toast("+30 energy"); shell.refresh(), "primary", 28, 90)
			act.disabled = it.count <= 0
		"Summon Orb":
			act = Kit.button("Go to Summon", func(): shell.show_tab("summon"), "primary", 28, 90)
		_:
			act = Kit.button("Use on a critter", func(): shell.close_overlay(); shell.toast("Levelling with XP Chips arrives with the save update."), "primary", 28, 90)
	shell.mark("item_use", act)
	v.add_child(act)
	shell.sheet(v)


static func _item_icon(it: Dictionary) -> Control:
	var kind: String = {"Energy Pack": "energy", "Summon Orb": "orb"}.get(it.name, "bolt")
	var g := Glyph.make(kind, 80, it.color)
	var box := Kit.panel(g, Kit.box(Color(it.color, .15), Color(it.color, .5), 24, 2, 12))
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return box


static func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	return grid


static func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc
