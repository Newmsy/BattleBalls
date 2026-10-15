## Critters tab: the whole roster. Owned critters are live with tier stars,
## level, power and copy count; a FUSE ribbon marks 3 copies at one tier;
## unfound critters are dark silhouettes.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")

static var filter := "all"


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(22)
	var factions := Kit.card_button(Kit.label("Factions", 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), func(): shell.go("factions"), Kit.ACCENT, Kit.PANEL2, 999, 10)
	factions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("factions", factions)
	root.add_child(Kit.hbox(14, [Kit.label("Critters", 44), Kit.spacer(), Kit.label("%d / %d found" % [p.found_count(), Roster.CRITTERS.size()], 24, Kit.MUTED), factions], BoxContainer.ALIGNMENT_CENTER))

	var chips := Kit.hbox(6)
	for f in ["all"] + Roster.RARITIES:
		var on: bool = f == filter
		var col: Color = Kit.FG if f == "all" else Roster.RARITY_COLORS[f]
		var name: String = "All" if f == "all" else Roster.RARITY_NAMES[f]
		var l := Kit.label(name, 20, Kit.BG if on else col, HORIZONTAL_ALIGNMENT_CENTER)
		var b := Kit.card_button(l, func(): filter = f; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.ACCENT if on else Kit.PANEL, 999, 8)
		chips.add_child(b)
	root.add_child(chips)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for c in Roster.CRITTERS:
		if filter != "all" and c.rarity != filter:
			continue
		grid.add_child(_tile(shell, p, c))
	root.add_child(grid)
	return root


static func _tile(shell, p, c: Dictionary) -> Control:
	var rcol: Color = Roster.RARITY_COLORS[c.rarity]
	var border := Kit.LINE if c.rarity == "common" else Color(rcol, .6)
	if not p.owns(c.id):
		var v := Kit.vbox(2, [CritterIcon.make(c.id, 1, 170, false, true), Kit.label("???", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label(Roster.RARITY_NAMES[c.rarity], 20, Color(rcol, .7), HORIZONTAL_ALIGNMENT_CENTER)])
		var t := Kit.card_button(v, shell.toast.bind("Not found yet. Summon it, or look for it in a later zone."), border, Kit.PANEL, 28, 8)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return t
	var b: Dictionary = p.best(c.id)
	var info := Kit.hbox(6, [Kit.label("Lv %d" % b.level, 20, Kit.MUTED), Kit.power(p.power_of(c.id), 20, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	var stars := CenterContainer.new()
	stars.add_child(Glyph.make("stars", 22, Kit.FG, b.tier))
	var name := Kit.label(c.name, 23, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var icon_layer := Control.new()
	icon_layer.custom_minimum_size = Vector2(170, 170)
	icon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := CritterIcon.make(c.id, b.tier, 170)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_layer.add_child(icon)
	var count := Kit.panel(Kit.label("x%d" % p.total_copies(c.id), 20), Kit.box(Kit.BG, Kit.LINE, 14, 2, 4))
	count.get_theme_stylebox("panel").content_margin_left = 10
	count.get_theme_stylebox("panel").content_margin_right = 10
	count.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	count.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	icon_layer.add_child(count)
	var ready := false
	for s in p.copies(c.id):
		ready = ready or (s.count >= 3 and s.tier < Roster.MAX_TIER)
	if ready:
		var rib := Kit.panel(Kit.label("FUSE", 18, Kit.BG), Kit.box(Kit.GOOD, Color(0, 0, 0, 0), 10, 0, 4))
		rib.get_theme_stylebox("panel").content_margin_left = 10
		rib.get_theme_stylebox("panel").content_margin_right = 10
		icon_layer.add_child(rib)
	var v := Kit.vbox(4, [icon_layer, name, stars, info])
	var t := Kit.card_button(v, func(): shell.go("detail", {"id": c.id}), border, Kit.PANEL, 28, 8)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("tile_" + c.id, t)
	return t
