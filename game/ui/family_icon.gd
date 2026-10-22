## A small badge per critter family, so you can tell a critter's family at a
## glance next to its art: Nature leaf, Sea fish, Tech cog, Sweet wrapped
## candy, Frost snowflake, Toybox die, Spooky ghost, Fire flame, Cosmic
## crescent moon. Each has its own silhouette as well as its family colour
## (sim/families.gd), so it reads without colour too. Drawn once on a control
## that never redraws itself; render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")
const Families := preload("res://sim/families.gd")
const Kit := preload("res://game/ui/ui_kit.gd")

const INK := Color("0b0a1f")


## The family's colour, or the plain text colour outside every family.
static func color(family: String) -> Color:
	var f: Dictionary = Families.info(family)
	return Color(f.color) if not f.is_empty() else Kit.MUTED


## A badge filling a `side` box, drawn once (it costs nothing per frame).
static func make(family: String, side: float, ring := true) -> Control:
	var b := _Badge.new()
	b.family = family
	b.ring = ring
	b.custom_minimum_size = Vector2(side, side)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## The family as a chip ("[leaf] NATURE") for info cards and Critterpedia pages.
static func chip(family: String, font_size := 18) -> PanelContainer:
	var col := color(family)
	var st := Kit.box(Color(0, 0, 0, 0), col, 999, 2, 0)
	st.content_margin_left = 6
	st.content_margin_right = 14
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	var icon := make(family, font_size * 1.35, false)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p := Kit.panel(Kit.hbox(6, [icon, Kit.label(str(Families.info(family).get("name", "")).to_upper(), font_size, col)]), st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p


## The badge centred on `c`, `size` across: a dark disc (ringed in the family
## colour when `ring`) with the family's mark on it.
static func draw(ci: CanvasItem, family: String, c: Vector2, size: float, ring := true) -> void:
	var r := size / 2.0
	var col := color(family)
	if ring:
		Dot.circle(ci, c, r, col)
		Dot.circle(ci, c, r * .87, INK)
	else:
		Dot.circle(ci, c, r, INK)
	var g := r * (.66 if ring else .78)
	match family:
		"nature": _leaf(ci, c, g, col)
		"sea": _fish(ci, c, g, col)
		"tech": _cog(ci, c, g, col)
		"sweet": _candy(ci, c, g, col)
		"frost": _flake(ci, c, g, col)
		"toybox": _die(ci, c, g, col)
		"spooky": _ghost(ci, c, g, col)
		"fire": _flame(ci, c, g, col)
		"cosmic": _moon(ci, c, g, col)
		_: Dot.circle(ci, c, g * .35, col)


## Points given in a unit box (-1..1), placed around `c` at scale `g`.
static func _pts(c: Vector2, g: float, unit: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in unit:
		out.append(c + p * g)
	return out


## A straight stroke as a filled quad (batches with the rest).
static func _bar(ci: CanvasItem, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var n := (b - a).normalized().orthogonal() * w / 2.0
	Dot.poly(ci, PackedVector2Array([a + n, b + n, b - n, a - n]), col)


static func _leaf(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	var axis := Vector2(1, -1).normalized()
	var across := axis.orthogonal()
	var pts := PackedVector2Array()
	for k in 17:
		var u := -1.0 + 2.0 * k / 16.0
		pts.append(c + (axis * u * .9 + across * .5 * (1.0 - u * u)) * g)
	for k in range(15, 0, -1):
		var u := -1.0 + 2.0 * k / 16.0
		pts.append(c + (axis * u * .9 - across * .5 * (1.0 - u * u)) * g)
	Dot.poly(ci, pts, col)
	_bar(ci, c - axis * g * .95, c + axis * g * .55, g * .13, INK)


static func _fish(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	var body := []
	for k in 16:
		var a := TAU * k / 16.0
		body.append(Vector2(-.18 + cos(a) * .62, sin(a) * .44))
	Dot.poly(ci, _pts(c, g, body), col)
	Dot.poly(ci, _pts(c, g, [Vector2(.3, 0), Vector2(.95, -.48), Vector2(.82, 0), Vector2(.95, .48)]), col)
	Dot.circle(ci, c + Vector2(-.45, -.08) * g, g * .11, INK)


static func _cog(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	for k in 8:
		var a := TAU * k / 8.0
		var d := Vector2(cos(a), sin(a))
		_bar(ci, c + d * g * .5, c + d * g * .95, g * .3, col)
	Dot.circle(ci, c, g * .66, col)
	Dot.circle(ci, c, g * .26, INK)


static func _candy(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	Dot.poly(ci, _pts(c, g, [Vector2(-.4, 0), Vector2(-.98, -.46), Vector2(-.86, 0), Vector2(-.98, .46)]), col)
	Dot.poly(ci, _pts(c, g, [Vector2(.4, 0), Vector2(.98, .46), Vector2(.86, 0), Vector2(.98, -.46)]), col)
	Dot.circle(ci, c, g * .52, col)
	_bar(ci, c + Vector2(-.22, .42) * g, c + Vector2(.22, -.42) * g, g * .13, INK)


static func _flake(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	for k in 6:
		var a := TAU * k / 6.0 - PI / 2.0
		var d := Vector2(cos(a), sin(a))
		_bar(ci, c, c + d * g * .95, g * .17, col)
		var m := c + d * g * .55
		_bar(ci, m, m + d.rotated(.8) * g * .32, g * .13, col)
		_bar(ci, m, m + d.rotated(-.8) * g * .32, g * .13, col)
	Dot.circle(ci, c, g * .16, col)


static func _die(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	var turn := -.2
	var pts := []
	var h := .62
	var rr := .2
	for corner in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		var mid: Vector2 = corner * (h - rr)
		var a0: float = corner.angle() - PI / 4.0
		for k in 4:
			var a: float = a0 + PI / 2.0 * k / 3.0
			pts.append((mid + Vector2(cos(a), sin(a)) * rr).rotated(turn))
	Dot.poly(ci, _pts(c, g, pts), col)
	for p in [Vector2(-.33, -.33), Vector2.ZERO, Vector2(.33, .33)]:
		Dot.circle(ci, c + p.rotated(turn) * g, g * .13, INK)


static func _ghost(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	var pts := []
	for k in 11:
		var a := PI + PI * k / 10.0
		pts.append(Vector2(cos(a) * .66, -.2 + sin(a) * .7))
	pts.append_array([Vector2(.66, .82), Vector2(.44, .58), Vector2(.22, .82), Vector2(0, .58),
		Vector2(-.22, .82), Vector2(-.44, .58), Vector2(-.66, .82)])
	Dot.poly(ci, _pts(c, g, pts), col)
	Dot.circle(ci, c + Vector2(-.24, -.18) * g, g * .14, INK)
	Dot.circle(ci, c + Vector2(.24, -.18) * g, g * .14, INK)


const _FLAME := [Vector2(.56, .36), Vector2(.48, .66), Vector2(.24, .86), Vector2(0, .92), Vector2(-.24, .86),
	Vector2(-.48, .66), Vector2(-.56, .36), Vector2(-.5, .02), Vector2(-.32, -.32), Vector2(-.12, -.6),
	Vector2(.06, -.96), Vector2(.24, -.6), Vector2(.3, -.34), Vector2(.42, -.44), Vector2(.56, -.12)]


static func _flame(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	Dot.poly(ci, _pts(c, g, _FLAME), col)
	Dot.poly(ci, _pts(c + Vector2(0, .36) * g, g * .48, _FLAME), col.lerp(Color(1, .92, .55), .7))


static func _moon(ci: CanvasItem, c: Vector2, g: float, col: Color) -> void:
	Dot.circle(ci, c + Vector2(-.12, 0) * g, g * .78, col)
	Dot.circle(ci, c + Vector2(.26, -.26) * g, g * .64, INK)
	var s := c + Vector2(.4, -.34) * g
	var k := g * .28
	Dot.poly(ci, PackedVector2Array([s + Vector2(0, -k), s + Vector2(k * .3, -k * .3), s + Vector2(k, 0), s + Vector2(k * .3, k * .3),
		s + Vector2(0, k), s + Vector2(-k * .3, k * .3), s + Vector2(-k, 0), s + Vector2(-k * .3, -k * .3)]), col)


class _Badge extends Control:
	var family := ""
	var ring := true

	func _draw() -> void:
		var side := minf(size.x, size.y)
		load("res://game/ui/family_icon.gd").draw(self, family, size / 2.0, side, ring)


## A badge for a corner of a critter's art box (CritterIcon.family_badge):
## sits in the bottom-left of the square the critter is drawn in, clear of the
## ball. Its own canvas item, drawn once, so the critter's idle redraws don't
## redraw it.
static func corner(family: String) -> Control:
	var b := _Corner.new()
	b.family = family
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


class _Corner extends Control:
	var family := ""

	func _draw() -> void:
		var side := minf(size.x, size.y)
		var b := clampf(side * .25, 22.0, 44.0)
		var c := Vector2((size.x - side) / 2.0 + b * .6, (size.y + side) / 2.0 - b * .6)
		load("res://game/ui/family_icon.gd").draw(self, family, c, b)
