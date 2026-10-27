## Family edges in menus (design/type-advantage.md section 6): green ▲ / red ▼
## badges for who has the edge, the "Strong vs / Weak vs" line on the critter
## info card and the nine-family chart popup it opens. Reads the chart in
## sim/families.gd; everything here is drawn once and never redraws.
## Render/UI only.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Dot := preload("res://game/dot.gd")
const Families := preload("res://sim/families.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")

const LAYER := 91 ## Over the critter info card it opens from.

## The chart's wheel: Fire in the middle (it has the most matchups), the rest
## round it clockwise from the top, ordered so most arrows join neighbours.
const HUB := "fire"
const RING := ["nature", "frost", "sea", "tech", "cosmic", "spooky", "toybox", "sweet"]

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
	b.custom_minimum_size = Vector2(0, 0) if score == 0 else Vector2(badge_width(b.score, h), h)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return b


## Pins the edge badge of `mine` (critter ids) on `foes` to the top-right of
## `tile`, `top` px down; nothing when the foes aren't known or it's even.
static func attach(tile: Control, mine: Array, foes: Array, top := 40.0, h := 22.0) -> Control:
	var score := team(mine, foes)
	if score != 0:
		var b := badge(score, h)
		b.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		b.offset_left = -b.custom_minimum_size.x - 6
		b.offset_right = -6
		b.offset_top = top
		b.offset_bottom = top + b.custom_minimum_size.y
		tile.add_child(b)
	return tile


## Draws the badge for `score` filling `rect` on any canvas item (for screens
## that draw themselves, like the fighter cards under the arena).
static func draw_badge(ci: CanvasItem, rect: Rect2, score: int) -> void:
	if score == 0:
		return
	var col := Kit.GOOD if score > 0 else Kit.BAD
	var h := rect.size.y
	ci.draw_style_box(Kit.box(Color("0b0a1f", .85), Color(col, .9), 999, 2, 0), rect)
	var n := absi(score)
	var w := h * .62
	var x0 := rect.position.x + (rect.size.x - w * n) / 2.0
	var cy := rect.position.y + h / 2.0
	for k in n:
		var cx := x0 + w * (k + .5)
		var t := h * .27
		var pts := PackedVector2Array([Vector2(cx, cy - t), Vector2(cx + t * 1.05, cy + t * .8), Vector2(cx - t * 1.05, cy + t * .8)]) if score > 0 \
			else PackedVector2Array([Vector2(cx, cy + t), Vector2(cx - t * 1.05, cy - t * .8), Vector2(cx + t * 1.05, cy - t * .8)])
		Dot.poly(ci, pts, col)


## Width of a badge `h` tall for `score`.
static func badge_width(score: int, h: float) -> float:
	return 0.0 if score == 0 else h * (1.0 + .62 * (absi(score) - 1)) + 8.0


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
		row.add_child(_sized(FamilyIcon.make(e[0], 34 if e[1] == 2 else 28)))
	row.add_child(Kit.spacer())
	row.add_child(Kit.caption("Weak vs", Kit.BAD))
	for e in list(fam, true):
		row.add_child(_sized(FamilyIcon.make(e[0], 34 if e[1] == 2 else 28)))
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


## The chart over everything: a wheel of the nine families with an arrow from
## each family to every family it has type advantage over. `focus` (a family
## id) lights its arrows and lists its strong and weak matchups under it.
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
	var ok := Kit.button("Got it", close_chart, "go", 24, 72)
	var why := Kit.label("Arrows point at the weaker family: +%d%% damage that way, -%d%% back. Every other matchup is even." \
		% [roundi(Families.EDGE_BONUS * 100.0), roundi(Families.EDGE_BONUS * 100.0)], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	why.custom_minimum_size.x = width - 44.0 # Wrapped text measures before layout.
	var rows := [Kit.label("Type advantage", 32), why]
	var wheel := _Wheel.new()
	wheel.focus = focus
	wheel.custom_minimum_size = Vector2(width - 44.0, minf(width - 44.0, view.y * .5))
	wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.append(wheel)
	if focus != "" and Families.EDGES.has(focus):
		var row := Kit.hbox(8, [_sized(FamilyIcon.make(focus, 40)), _sized(Kit.label(str(Families.info(focus).name), 22, FamilyIcon.color(focus))), Kit.spacer(),
			_icons(list(focus).map(func(e): return e[0]), 34, 1), _icons(list(focus, true).map(func(e): return e[0]), 34, -1)], BoxContainer.ALIGNMENT_CENTER)
		rows.append(row)
	rows.append(ok)
	var body := Kit.vbox(8, rows)
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
		load("res://game/ui/family_edge.gd").draw_badge(self, Rect2(Vector2.ZERO, size), score)


## A green ▲ (or red ▼ for `dir` -1) and then the families' icons, for a chart tile.
static func _icons(fams: Array, side: float, dir: int) -> Control:
	var mark := _Badge.new()
	mark.score = dir
	mark.custom_minimum_size = Vector2(badge_width(dir, side * .8), side * .8)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := Kit.hbox(4, [_sized(mark)], BoxContainer.ALIGNMENT_CENTER)
	for f in fams:
		row.add_child(_sized(FamilyIcon.make(f, side)))
	return row


## The wheel: Fire in the middle, the other eight round it, and an arrow in
## the attacker's colour from each family to every family it beats.
class _Wheel extends Control:
	var focus := ""

	func _draw() -> void:
		var c := size / 2.0
		var rad := minf(size.x, size.y) * .5 - minf(size.x, size.y) * .09
		var icon := minf(size.x, size.y) * .13
		var at := {HUB: c}
		for i in RING.size():
			var ang := -PI / 2.0 + TAU * i / RING.size()
			at[RING[i]] = c + Vector2(cos(ang), sin(ang)) * rad
		for a in Families.EDGES:
			for t in Families.EDGES[a]:
				var lit: bool = focus == "" or focus == a or focus == t
				_arrow(at[a], at[t], icon, Color(FamilyIcon.color(a), 1.0 if lit else .14))
		for f in at:
			if f == focus:
				Dot.circle(self, at[f], icon * .6, Color("ffd166"))
			FamilyIcon.draw(self, f, at[f], icon * (1.25 if f == HUB else 1.0))

	func _arrow(a: Vector2, b: Vector2, icon: float, col: Color) -> void:
		var d := (b - a).normalized()
		var from := a + d * icon * .62
		var tip := b - d * icon * .66
		Dot.pline(self, PackedVector2Array([from, tip - d * icon * .2]), col, maxf(3.0, icon * .07), true)
		var n := d.orthogonal() * icon * .17
		Dot.poly(self, PackedVector2Array([tip, tip - d * icon * .34 + n, tip - d * icon * .34 - n]), col)
