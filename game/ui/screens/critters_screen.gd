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
const Painted := preload("res://game/ui/painted.gd")
const Talents := preload("res://sim/talents.gd")

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
	var root := Kit.vbox(18)
	var dex := Kit.card_button(Kit.hbox(8, [Kit.glyph("critters", 26, Kit.ACCENT), Kit.label("Critterpedia", 22, Kit.FG)], BoxContainer.ALIGNMENT_CENTER),
		func(): shell.go("dex"), Kit.ACCENT, Kit.PANEL2, 999, 12)
	dex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("critterpedia", dex)
	# Talents, with a green count of points to spend across every faction.
	var unspent := 0
	for f in Talents.FACTIONS:
		unspent += maxi(0, p.talent_points_free(f))
	var tl := Kit.hbox(8, [Kit.label("Talents", 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)], BoxContainer.ALIGNMENT_CENTER)
	if unspent > 0:
		var count := Kit.panel(Kit.label(str(unspent), 18, Kit.BG, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.GOOD, Color(0, 0, 0, 0), 999, 0, 0))
		var st: StyleBoxFlat = count.get_theme_stylebox("panel")
		st.content_margin_left = 9
		st.content_margin_right = 9
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tl.add_child(count)
	var factions := Kit.card_button(tl, func(): shell.go("factions"), Kit.ACCENT, Kit.PANEL2, 999, 12)
	factions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("factions", factions)
	var meter := _Collection.new()
	meter.fill = _found_by_rarity(p)
	var found := Kit.hbox(12, [Kit.label("%d/%d found" % [p.found_count(), Roster.CRITTERS.size()], 21, Kit.FG), meter, FamilyEdge.info_chip(shell)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(_den(shell.title_row("My critters", {"back": false, "extra": [factions, dex]}), found, shell.size.y >= 1400.0))

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


## The Den: a painted header band (your critters lounging at home) with the
## title row on top and the found meter along the bottom. Shorter on small phones.
static func _den(title: Control, found: Control, tall: bool) -> Control:
	var band := Control.new()
	band.custom_minimum_size = Vector2(0, 250 if tall else 210)
	band.add_child(Painted.make("band_den", {"focus": Vector2(470, 150), "radius": 30.0, "top_dark": 0.6, "bottom_dark": 0.75}))
	band.get_child(0).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0), Color("3a3480"), 30, 3, 0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.add_child(frame)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16 if side != "left" else 22)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := Kit.vbox(0, [title, gap, found])
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	band.add_child(m)
	return band


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
	var t := Kit.card_button(v, func(): shell.go_from("detail", {"id": k.id, "tier": k.tier}, icon), Roster.rarity_border(c.rarity, Kit.LINE), Roster.rarity_bg(c.rarity, Kit.PANEL), 28, 8)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var home := Painted.habitat(k.id)
	if home != "":
		# A window onto the critter's family home, the critter standing on its
		# lit stage, melting into the rarity-tinted card under the name.
		var win := Painted.make(home, {"focus": Vector2(200, 250), "at": Vector2(0.5, 0.49), "px": 1.8,
			"radius": Vector4(25, 25, 0, 0), "bottom_fade": 0.35})
		win.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		win.offset_left = 3
		win.offset_right = -3
		win.offset_top = 3
		win.offset_bottom = 193
		t.add_child(win)
		t.move_child(win, 0)
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
