## Critters tab ("My critters"): only the critters you own, one card per
## critter and tier (three T1 Zips are one card with a x3 badge), strongest
## first. Each card shows tier stars, level and power; a FUSE ribbon marks 3+ at one tier.
## The Critterpedia button opens every critter, found or not (dex_screen.gd).
extends RefCounted

const FamilyEdge := preload("res://game/ui/family_edge.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const LazyTile := preload("res://game/ui/lazy_tile.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")

static var filter := "all"


## Every owned critter and tier as {id, tier, level, power, stack}, strongest
## first; stack.count is how many copies. Gear sits on a critter's best copy,
## so only that stack counts it.
static func cards(p) -> Array:
	var out: Array = []
	for c in Roster.CRITTERS:
		var best: Dictionary = p.best(c.id)
		for s in p.copies(c.id):
			var pw: int = p.power_of(c.id) if s == best else Roster.power(c.id, s.tier, s.level)
			out.append({"id": c.id, "tier": s.tier, "level": s.level, "power": pw, "stack": s})
	out.sort_custom(func(a, b): return a.power > b.power if a.power != b.power else a.id < b.id)
	return out


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(22)
	var dex := Kit.card_button(Kit.hbox(8, [Kit.glyph("critters", 26, Kit.ACCENT), Kit.label("Critterpedia", 22, Kit.FG)], BoxContainer.ALIGNMENT_CENTER),
		func(): shell.go("dex"), Kit.ACCENT, Kit.PANEL2, 999, 12)
	dex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("critterpedia", dex)
	var factions := Kit.card_button(Kit.label("Factions", 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), func(): shell.go("factions"), Kit.ACCENT, Kit.PANEL2, 999, 12)
	factions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("factions", factions)
	root.add_child(shell.title_row("My critters", {"back": false, "extra": [factions, dex]}))

	var chips := Kit.hbox(6)
	for f in ["all"] + Roster.RARITIES:
		var on: bool = f == filter
		var col: Color = Kit.FG if f == "all" else Roster.RARITY_COLORS[f]
		var name: String = "All" if f == "all" else Roster.RARITY_NAMES[f]
		var l := Kit.label(name, 20, Kit.BG if on else col, HORIZONTAL_ALIGNMENT_CENTER)
		var b := Kit.card_button(l, func(): filter = f; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.ACCENT if on else Kit.PANEL, 999, 8)
		chips.add_child(b)
	root.add_child(chips)

	var all := cards(p)
	var shown := all.filter(func(k): return filter == "all" or Roster.get_critter(k.id).rarity == filter)
	var meter := _Collection.new()
	meter.fill = _found_by_rarity(p)
	root.add_child(Kit.hbox(12, [Kit.label("%d/%d found" % [p.found_count(), Roster.CRITTERS.size()], 21, Kit.MUTED), meter, FamilyEdge.info_chip(shell)], BoxContainer.ALIGNMENT_CENTER))
	if shown.is_empty():
		var what: String = "" if filter == "all" else Roster.RARITY_NAMES[filter] + " "
		root.add_child(Kit.label("No %scritters yet." % what, 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
		return root

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var seen := {}
	for i in shown.size():
		var k: Dictionary = shown[i]
		var n: int = seen.get(k.id, 0)
		seen[k.id] = n + 1
		var mark_as: String = "tile_" + k.id + ("" if n == 0 else "_%d" % n)
		grid.add_child(LazyTile.wrap(func(): return _tile(shell, k, mark_as), i, 15))
	root.add_child(grid)
	return root


## [found, total] per rarity, common first.
static func _found_by_rarity(p) -> Array:
	var out := []
	for r in Roster.RARITIES:
		var of: Array = Roster.CRITTERS.filter(func(c): return c.rarity == r)
		out.append([of.filter(func(c): return p.owns(c.id)).size(), of.size()])
	return out


static func _tile(shell, k: Dictionary, mark_as: String) -> Control:
	var c := Roster.get_critter(k.id)
	var info := Kit.hbox(6, [Kit.label("Lv %d" % k.level, 20, Kit.MUTED), Kit.power(k.power, 20, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	var stars := CenterContainer.new()
	stars.add_child(Glyph.make("stars", 22, Kit.FG, k.tier))
	var name := Kit.label(c.name, 23, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var icon_layer := Control.new()
	icon_layer.custom_minimum_size = Vector2(170, 170)
	icon_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := CritterIcon.make(k.id, k.tier, 170)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_layer.add_child(icon)
	if k.stack.count >= 3 and k.tier < Roster.MAX_TIER:
		var rib := Kit.panel(Kit.label("FUSE", 18, Kit.BG), Kit.box(Kit.GOOD, Color(0, 0, 0, 0), 10, 0, 4))
		rib.get_theme_stylebox("panel").content_margin_left = 10
		rib.get_theme_stylebox("panel").content_margin_right = 10
		icon_layer.add_child(rib)
	if k.stack.count > 1:
		var badge := Kit.panel(Kit.label("x%d" % k.stack.count, 20, Kit.FG), Kit.box(Kit.PANEL2, Kit.LINE, 999, 2, 4))
		badge.get_theme_stylebox("panel").content_margin_left = 10
		badge.get_theme_stylebox("panel").content_margin_right = 10
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		icon_layer.add_child(badge)
	var v := Kit.vbox(4, [icon_layer, name, stars, info])
	var t := Kit.card_button(v, func(): shell.go("detail", {"id": k.id, "tier": k.tier}), Roster.rarity_border(c.rarity, Kit.LINE), Roster.rarity_bg(c.rarity, Kit.PANEL), 28, 8)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark(mark_as, t)
	return t


## The collection meter beside "N/90 found": a track cut into one segment per
## rarity (sized by how many critters it has), each lit in its rarity colour
## as far as you have found them. Drawn once.
class _Collection extends Control:
	const Dot := preload("res://game/dot.gd")
	const Roster := preload("res://game/ui/roster.gd")
	const H := 14.0
	const GAP := 4.0
	var fill: Array = []

	func _init() -> void:
		custom_minimum_size = Vector2(0, H + 4)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var total := 0
		for f in fill:
			total += f[1]
		if total == 0:
			return
		var y := (size.y - H) / 2.0
		var room := size.x - GAP * (fill.size() - 1)
		var x := 0.0
		for i in fill.size():
			var w: float = room * fill[i][1] / total
			var col: Color = Roster.RARITY_COLORS[Roster.RARITIES[i]]
			_bar(Rect2(x, y, w, H), Color(col.darkened(.65), .9))
			if fill[i][0] > 0:
				_bar(Rect2(x, y, maxf(H, w * fill[i][0] / fill[i][1]), H), col.darkened(.1))
				draw_line(Vector2(x + H / 2.0, y + 3), Vector2(x + maxf(H, w * fill[i][0] / fill[i][1]) - H / 2.0, y + 3), Color(1, 1, 1, .3), 2.0, true)
			x += w + GAP

	## A pill: a rect with round ends.
	func _bar(r: Rect2, col: Color) -> void:
		var rad := r.size.y / 2.0
		if r.size.x > r.size.y:
			draw_rect(Rect2(r.position.x + rad, r.position.y, r.size.x - r.size.y, r.size.y), col)
		Dot.circle(self, r.position + Vector2(rad, rad), rad, col)
		Dot.circle(self, Vector2(r.end.x - rad, r.position.y + rad), rad, col)
