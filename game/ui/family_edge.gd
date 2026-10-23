## Family edges in menus (design/type-advantage.md section 6): green ▲ / red ▼
## badges for who has the edge, the "Strong vs / Weak vs" line on the critter
## info card and the Edge Wheel popup it opens. Reads the chart in
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


## The Edge Wheel over everything: the nine families in a ring, each hitting
## the next three clockwise harder. `focus` (a family id) starts lit; tapping
## a family lights its edges.
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
	var wheel := _Wheel.new()
	wheel.focus = focus
	wheel.custom_minimum_size = Vector2(width - 44.0, width - 44.0 + _Wheel.FOOT)
	var bonus: Array = Families.EDGE_BONUS
	var ok := Kit.button("Got it", close_chart, "go", 24, 72)
	var why := Kit.label("Each family hits the next three clockwise harder: the first +%d%%, the next two +%d%%. Watch out for the three behind you; across the wheel is even. Tap a family to light it up." \
		% [roundi(bonus[2] * 100.0), roundi(bonus[1] * 100.0)], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	why.custom_minimum_size.x = width - 44.0 # Wrapped text measures before layout.
	var body := Kit.vbox(10, [Kit.label("Family edges", 32), why, wheel, ok])
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


class _Wheel extends Control:
	const FOOT := 64.0 ## Room under the ring for the lit family's summary.
	const GOLD := Color("ffd166")
	var focus := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _geo() -> Array:
		var side := minf(size.x, size.y - FOOT)
		return [Vector2(size.x / 2.0, side * .47), side * .36, side * .14]

	func _at(i: int, c: Vector2, r: float) -> Vector2:
		var a := -PI / 2.0 + TAU * i / 9.0
		return c + Vector2(cos(a), sin(a)) * r

	func _gui_input(e: InputEvent) -> void:
		if not (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed):
			return
		var g := _geo()
		var wheel: Array = Families.WHEEL
		var pick := ""
		for i in wheel.size():
			if e.position.distance_to(_at(i, g[0], g[1])) < g[2] * .75:
				pick = wheel[i]
		focus = "" if pick == focus else pick
		accept_event()
		queue_redraw()

	## An arrow from `a` to `b` bowing `bow` px to its left, head at `b`.
	func _arrow(a: Vector2, b: Vector2, bow: float, col: Color, w: float) -> void:
		var mid := (a + b) / 2.0 + (b - a).normalized().orthogonal() * bow
		var pts := PackedVector2Array()
		for k in 13:
			var t := k / 12.0
			pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
		var tip := pts[12]
		var dir := (tip - pts[10]).normalized()
		pts[12] = tip - dir * w * 1.2
		Dot.pline(self, pts, col, w, true)
		var n := dir.orthogonal() * w * 1.5
		Dot.poly(self, PackedVector2Array([tip + dir * w * .6, tip - dir * w * 1.9 + n, tip - dir * w * 1.9 - n]), col)

	func _draw() -> void:
		var g := _geo()
		var c: Vector2 = g[0]
		var r: float = g[1]
		var icon: float = g[2]
		var wheel: Array = Families.WHEEL
		var at := wheel.find(focus)
		Dot.arc(self, c, r, 0.0, TAU, 72, Kit.LINE, icon * .32, true)
		var gap := icon * .62
		for i in wheel.size():
			var a := _at(i, c, r)
			var b := _at((i + 1) % 9, c, r)
			var d := (b - a).normalized()
			_arrow(a + d * gap, b - d * gap, -icon * .18, GOLD if at < 0 else Color(GOLD, .25), 3.0)
		if at >= 0:
			var me := _at(at, c, r)
			for k in [3, 2, 1]:
				var t := _at((at + k) % 9, c, r)
				var d := (t - me).normalized()
				_arrow(me + d * gap, t - d * gap, -icon * (.18 + .25 * (k - 1)), Kit.GOOD, 6.0 if k == 1 else 3.5)
		var font: Font = Kit.FONT
		for i in wheel.size():
			var p := _at(i, c, r)
			var k := (i - at + 9) % 9 if at >= 0 else 0
			var lit := at < 0 or k == 0 or k <= 3
			var behind := at >= 0 and k >= 6
			var col := Color(1, 1, 1, 1.0 if lit or behind else .35)
			var sz := icon * (1.15 if k == 0 and at >= 0 else 1.0)
			if at >= 0 and k == 0:
				Dot.circle(self, p, sz * .62, GOLD)
			elif behind:
				Dot.circle(self, p, sz * (.64 if k == 8 else .58), Kit.BAD)
			FamilyIcon.draw(self, wheel[i], p, sz)
			if col.a < 1.0:
				Dot.circle(self, p, sz * .52, Color(Kit.BG, .6))
			var info := Families.info(wheel[i])
			var fs := roundi(icon * .27)
			var tw := font.get_string_size(info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			# Names sit just inside the ring, clear of the arrows between icons.
			var out := (p - c).normalized()
			var inner := c + out * (r - sz * .5 - fs * .7 - absf(out.x) * tw / 2.0)
			var name_at := inner + Vector2(-tw / 2.0, fs * .35)
			draw_string(font, name_at, info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(Color(info.color), col.a))
		var fs2 := roundi(icon * .22)
		for j in 2:
			var line: String = ["CLOCKWISE", "WINS"][j]
			var tw := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
			draw_string(font, c + Vector2(-tw / 2.0, fs2 * (j - .2)), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(GOLD, .9))
		if at >= 0:
			_summary(wheel, at)

	## Under the ring: the lit family, then ▲▲ / ▲ who it hits and ▼ / ▼▼ who hits it.
	func _summary(wheel: Array, at: int) -> void:
		var h := 38.0
		var y := size.y - FOOT / 2.0
		var groups := [[wheel[at]], [2, [wheel[(at + 1) % 9]]], [1, [wheel[(at + 2) % 9], wheel[(at + 3) % 9]]],
			[-1, [wheel[(at + 6) % 9], wheel[(at + 7) % 9]]], [-2, [wheel[(at + 8) % 9]]]]
		var me = load("res://game/ui/family_edge.gd")
		var w := 0.0
		for gi in groups.size():
			if gi == 0:
				w += h + 12.0
				continue
			w += me.badge_width(groups[gi][0], h * .8) + 4.0 + groups[gi][1].size() * (h + 2.0) + 10.0
		var x := (size.x - w) / 2.0
		for gi in groups.size():
			if gi == 0:
				FamilyIcon.draw(self, groups[0][0], Vector2(x + h / 2.0, y), h * 1.1)
				x += h + 12.0
				continue
			var bw: float = me.badge_width(groups[gi][0], h * .8)
			me.draw_badge(self, Rect2(x, y - h * .4, bw, h * .8), groups[gi][0])
			x += bw + 4.0
			for f in groups[gi][1]:
				FamilyIcon.draw(self, f, Vector2(x + h / 2.0, y), h)
				x += h + 2.0
			x += 10.0
