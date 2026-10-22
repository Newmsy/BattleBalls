## Family edges in menus (design/type-advantage.md section 6): green ▲ / red ▼
## badges for who has the edge, the "Strong vs / Weak vs" line on the critter
## info card and the full 9x9 chart popup it opens. Reads the chart in
## sim/families.gd; everything here is drawn once and never redraws.
## Render/UI only.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Dot := preload("res://game/dot.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")

const LAYER := 91 ## Over the critter info card it opens from.

static var _chart: CanvasLayer


## How much family `a` has the edge on family `t`: 2 very good .. -2 very bad.
static func of_families(a: String, t: String) -> int:
	if a == "" or t == "" or not Families.EDGES.has(a) or not Families.EDGES.has(t):
		return 0
	var e: int = Families.EDGES[a].get(t, 0)
	return e if e != 0 else -int(Families.EDGES[t].get(a, 0))


## The edge `mine` (critter ids) have on `foes` (critter ids), summed over each
## of yours against each of theirs and averaged over your side, -2..2.
static func team(mine: Array, foes: Array) -> int:
	if mine.is_empty() or foes.is_empty():
		return 0
	var sum := 0
	for m in mine:
		for f in foes:
			sum += Families.edge(str(m), str(f))
	return clampi(roundi(float(sum) / mine.size()), -2, 2)


## [[family, level]] that `family` hits harder (level 2 first), or that hit it
## harder (`weak`, level 2 first).
static func list(family: String, weak := false) -> Array:
	var out := []
	for f in Families.ids():
		var e := of_families(family, f)
		if (e > 0 and not weak) or (e < 0 and weak):
			out.append([f, absi(e)])
	out.sort_custom(func(x, y): return x[1] > y[1])
	return out


## Families with the biggest edge on any of `foes` (critter ids): who to bring.
static func counters(foes: Array) -> Array:
	var out := []
	for id in foes:
		var fam := Families.of(str(id))
		for f in Families.ids():
			if of_families(f, fam) == 2 and not f in out:
				out.append(f)
	return out


## A small ▲▲ / ▲ / ▼ / ▼▼ badge for an edge score (green up, red down), or an
## empty box for 0. `h` is the badge height.
static func badge(score: int, h := 22.0) -> Control:
	var b := _Badge.new()
	b.score = clampi(score, -2, 2)
	b.custom_minimum_size = Vector2(0, 0) if score == 0 else Vector2(h * (1.0 + .62 * (absi(b.score) - 1)) + 8.0, h)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return b


## Short words for an edge score, for hint lines.
static func words(score: int) -> String:
	return ["They hit you hard", "They have the edge", "Even", "You have the edge", "You hit them hard"][clampi(score, -2, 2) + 2]


## "Strong vs [icons]  Weak vs [icons]" for a critter, very good/bad ones drawn
## bigger. Tapping it opens the full chart. Empty for a critter outside every family.
static func matchup_line(critter: String) -> Control:
	var fam := Families.of(critter)
	if fam == "":
		return Control.new()
	var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	row.add_child(Kit.caption("Strong vs", Kit.GOOD))
	for e in list(fam):
		row.add_child(_sized(FamilyIcon.make(e[0], 38 if e[1] == 2 else 28)))
	row.add_child(Kit.spacer())
	row.add_child(Kit.caption("Weak vs", Kit.BAD))
	for e in list(fam, true):
		row.add_child(_sized(FamilyIcon.make(e[0], 38 if e[1] == 2 else 28)))
	row.add_child(Kit.glyph("info", 26, Kit.MUTED))
	var b := Kit.card_button(row, func(): open_chart(row, fam), Kit.LINE, Kit.PANEL, 22, 10)
	b.set_meta("mark", "edge_line")
	return b


## A small "Families (i)" chip that opens the chart, for screens that list critters.
static func info_chip(shell) -> Control:
	var b := Kit.card_button(Kit.hbox(6, [Kit.label("Families", 20, Kit.FG), Kit.glyph("info", 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER),
		func(): open_chart(shell), Kit.ACCENT, Kit.PANEL2, 999, 8)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	shell.mark("families_info", b)
	return b


static func _sized(c: Control) -> Control:
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c


## The 9x9 chart over everything: each row is an attacker, each column the
## family it hits; `focus` (a family id) is lit.
static func open_chart(from: Node, focus := "") -> void:
	if from == null or not from.is_inside_tree():
		return
	close_chart()
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	layer.name = "FamilyChart"
	from.get_tree().root.add_child(layer)
	_chart = layer
	var view := layer.get_viewport().get_visible_rect().size
	var width := minf(660.0, view.x - 40.0)
	var root := Control.new()
	root.theme = Kit.theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var dim := Button.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_style := Kit.box(Color(.02, .015, .06, .7), Color(0, 0, 0, 0), 0, 0, 0)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		dim.add_theme_stylebox_override(st, dim_style)
	dim.pressed.connect(close_chart)
	root.add_child(dim)
	var grid := _Grid.new()
	grid.focus = focus
	grid.custom_minimum_size = Vector2(width - 44.0, width - 44.0)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bonus: Array = Families.EDGE_BONUS
	var key := Kit.hbox(8, [badge(2, 20), Kit.label("+%d%%" % roundi(bonus[2] * 100.0), 20, Kit.GOOD), Kit.spacer(),
		badge(1, 20), Kit.label("+%d%%" % roundi(bonus[1] * 100.0), 20, Kit.GOOD), Kit.spacer(),
		badge(-1, 20), badge(-2, 20), Kit.label("they hit you", 20, Kit.BAD)], BoxContainer.ALIGNMENT_CENTER)
	var ok := Kit.button("Got it", close_chart, "go", 24, 72)
	var names := HFlowContainer.new()
	names.add_theme_constant_override("h_separation", 14)
	names.add_theme_constant_override("v_separation", 4)
	for f in Families.FAMILIES:
		names.add_child(Kit.hbox(4, [FamilyIcon.make(f.id, 24), Kit.label(f.name, 18, Color(f.color))], BoxContainer.ALIGNMENT_CENTER))
	var why := Kit.label("Every critter is from one of nine families. Some families hit others harder: read a row across to see who it beats.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	why.custom_minimum_size.x = width - 44.0 # Wrapped text measures before layout.
	var body := Kit.vbox(10, [Kit.label("Family edges", 32), why, names, grid, key, ok])
	var card := Kit.panel(body, Kit.box(Color("16133a"), Kit.ACCENT, 36, 3, 22))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.custom_minimum_size.x = width
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(card)
	root.add_child(centre)
	TouchInput.set_back(layer, func(): return Callable(close_chart) if is_instance_valid(_chart) else Callable())
	print("UI_POPUP family_chart")
	_report.call_deferred(layer, card, ok)


static func _report(layer: CanvasLayer, card: Control, ok: Control) -> void:
	if not is_instance_valid(layer) or not layer.is_inside_tree():
		return
	await layer.get_tree().process_frame
	if not is_instance_valid(card):
		return
	var at := ok.get_global_rect().get_center()
	print("UI_AT chart_close %d %d" % [roundi(at.x), roundi(at.y)])
	var view := layer.get_viewport().get_visible_rect().size
	var cr := card.get_global_rect()
	if cr.position.y < 0.0 or cr.end.y > view.y + 1.0:
		print("UI_OVERFLOW family_chart %d" % roundi(cr.size.y))


static func chart_open() -> bool:
	return is_instance_valid(_chart)


static func close_chart() -> void:
	if is_instance_valid(_chart):
		TouchInput.clear_back(_chart)
		_chart.queue_free()
	_chart = null


class _Badge extends Control:
	var score := 0

	func _draw() -> void:
		if score == 0:
			return
		var col := Kit.GOOD if score > 0 else Kit.BAD
		var h := size.y
		draw_style_box(Kit.box(Color("0b0a1f", .85), Color(col, .9), 999, 2, 0), Rect2(Vector2.ZERO, size))
		var n := absi(score)
		var w := h * .62
		var x0 := (size.x - w * n) / 2.0
		for k in n:
			var cx := x0 + w * (k + .5)
			var t := h * .27
			var pts := PackedVector2Array([Vector2(cx, h / 2.0 - t), Vector2(cx + t * 1.05, h / 2.0 + t * .8), Vector2(cx - t * 1.05, h / 2.0 + t * .8)]) if score > 0 \
				else PackedVector2Array([Vector2(cx, h / 2.0 + t), Vector2(cx - t * 1.05, h / 2.0 - t * .8), Vector2(cx + t * 1.05, h / 2.0 - t * .8)])
			Dot.poly(self, pts, col)


class _Grid extends Control:
	var focus := ""

	func _draw() -> void:
		var ids: Array = Families.ids()
		var n := ids.size() + 1
		var cell := minf(size.x, size.y) / n
		var lit := Color(Kit.ACCENT, .18)
		for i in ids.size():
			var head := Vector2(cell * (i + 1.5), cell * .5)
			var side := Vector2(cell * .5, cell * (i + 1.5))
			if ids[i] == focus:
				draw_rect(Rect2(cell * (i + 1), 0, cell, size.y), lit)
				draw_rect(Rect2(0, cell * (i + 1), size.x, cell), lit)
			FamilyIcon.draw(self, ids[i], head, cell * .8)
			FamilyIcon.draw(self, ids[i], side, cell * .8)
		for r in ids.size():
			for c in ids.size():
				var rect := Rect2(cell * (c + 1) + 2, cell * (r + 1) + 2, cell - 4, cell - 4)
				var e: int = load("res://game/ui/family_edge.gd").of_families(ids[r], ids[c])
				var bg := Color("1b1842")
				if r == c:
					bg = Color("0b0a1f")
				elif e == 2:
					bg = Color(Kit.GOOD, .55)
				elif e == 1:
					bg = Color(Kit.GOOD, .22)
				elif e == -1:
					bg = Color(Kit.BAD, .18)
				elif e == -2:
					bg = Color(Kit.BAD, .42)
				draw_rect(rect, bg)
				if e != 0:
					_arrows(rect, e)

	func _arrows(rect: Rect2, e: int) -> void:
		var col := Color.WHITE if absi(e) == 2 else (Kit.GOOD if e > 0 else Kit.BAD)
		var n := absi(e)
		var t := rect.size.y * .14
		var gap := t * 2.4
		var x0 := rect.get_center().x - gap * (n - 1) / 2.0
		var cy := rect.get_center().y
		for k in n:
			var cx := x0 + gap * k
			var pts := PackedVector2Array([Vector2(cx, cy - t), Vector2(cx + t * 1.05, cy + t * .8), Vector2(cx - t * 1.05, cy + t * .8)]) if e > 0 \
				else PackedVector2Array([Vector2(cx, cy + t), Vector2(cx - t * 1.05, cy - t * .8), Vector2(cx + t * 1.05, cy - t * .8)])
			Dot.poly(self, pts, col)
