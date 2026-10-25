## Fast filled circles for every fight and menu drawing.
##
## Godot 4.3's compatibility renderer turns each draw_circle into a polygon
## and builds, uploads and frees a vertex buffer for it on every redraw; a
## 2v2 fight drew hundreds a frame, which is most of what made phones hot.
## A circle here is one textured quad instead: quads in a row batch into a
## single draw call and need no buffers. The disc textures have a soft one-
## texel rim, so edges look the same or smoother. Render-only.
extends RefCounted

## Texture sizes, picked so a texel is about a screen pixel at 2x for all
## but the biggest circles (soft glows, where a softer rim doesn't show).
const SIZES := [16, 64, 256]

static var _tex: Array[Texture2D] = []


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if not r > 0.0: # Also skips NaN.
		return
	ci.draw_texture_rect(_disc(r), Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), false, col)


static func _disc(r: float) -> Texture2D:
	if _tex.is_empty():
		for n in SIZES:
			_tex.append(_make(n))
	if r < 6.0:
		return _tex[0]
	if r < 24.0:
		return _tex[1]
	return _tex[2]


static func _make(n: int) -> Texture2D:
	var half := n / 2.0
	var rad := half - 1.0
	var px := PackedByteArray()
	px.resize(n * n * 2)
	var i := 0
	for y in n:
		var dy := y + 0.5 - half
		for x in n:
			var dx := x + 0.5 - half
			px[i] = 255
			px[i + 1] = int(clampf(rad - sqrt(dx * dx + dy * dy) + 0.5, 0.0, 1.0) * 255.0)
			i += 2
	return ImageTexture.create_from_image(Image.create_from_data(n, n, false, Image.FORMAT_LA8, px))


## A filled polygon as batched triangles (draw_primitive) instead of one
## polygon command, which would need its own vertex buffer every redraw.
## Same triangulation as draw_colored_polygon; a shape that can't be
## triangulated draws nothing instead of logging an error.
static func poly(ci: CanvasItem, pts, col: Color) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	var cols := PackedColorArray([col, col, col])
	var no_uv := PackedVector2Array()
	if n == 3:
		ci.draw_primitive(pts, cols, no_uv)
		return
	var idx := Geometry2D.triangulate_polygon(pts)
	for i in range(0, idx.size() - 2, 3):
		ci.draw_primitive(PackedVector2Array([pts[idx[i]], pts[idx[i + 1]], pts[idx[i + 2]]]), cols, no_uv)


## draw_arc, with a short arc (a dash, a tick, a spark) drawn as one or two
## straight batched lines instead of a polyline polygon with its own vertex
## buffer. Under a fifth of a radian a chord is within a pixel of the curve
## at any radius we draw. Longer arcs keep the engine's polyline.
const SHORT_ARC := 0.2

static func arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, n: int, col: Color, w := -1.0, aa := false) -> void:
	var span := absf(a1 - a0)
	if w < 0.0 or span > SHORT_ARC * 2.0:
		ci.draw_arc(c, r, a0, a1, n, col, w, aa)
		return
	if not r > 0.0:
		return
	var p0 := c + Vector2(cos(a0), sin(a0)) * r
	var p1 := c + Vector2(cos(a1), sin(a1)) * r
	if span <= SHORT_ARC:
		ci.draw_line(p0, p1, col, w, aa)
		return
	var am := (a0 + a1) / 2.0
	var pm := c + Vector2(cos(am), sin(am)) * r
	ci.draw_multiline(PackedVector2Array([p0, pm, pm, p1]), col, w, aa)


## draw_polyline, with a two-segment stroke (a chevron, a spike's edge)
## drawn as batched lines instead of a polyline polygon with its own vertex
## buffer. Longer strokes keep the engine's polyline for clean joins.
static func pline(ci: CanvasItem, pts, col: Color, w := -1.0, aa := false) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	if w < 0.0 or n > 3:
		ci.draw_polyline(pts, col, w, aa)
	elif n == 2:
		ci.draw_line(pts[0], pts[1], col, w, aa)
	else:
		ci.draw_multiline(PackedVector2Array([pts[0], pts[1], pts[1], pts[2]]), col, w, aa)


## A soft round glow (or with black, a soft shadow) as one textured quad: full
## col inside inner * r, easing smoothly out to nothing at r. Use it instead
## of stacking faint circles, which shows as rings.
static var _glow_tex := {}

static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, inner := 0.0) -> void:
	if not r > 0.0 or col.a <= 0.0:
		return
	var key := clampi(roundi(inner * 10.0), 0, 9)
	if not _glow_tex.has(key):
		_glow_tex[key] = _make_glow(key / 10.0)
	ci.draw_texture_rect(_glow_tex[key], Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), false, col)


static func _make_glow(inner: float) -> Texture2D:
	var n := 128
	var half := n / 2.0
	var px := PackedByteArray()
	px.resize(n * n * 2)
	var i := 0
	for y in n:
		var dy := y + 0.5 - half
		for x in n:
			var dx := x + 0.5 - half
			var u := clampf((sqrt(dx * dx + dy * dy) / half - inner) / (1.0 - inner), 0.0, 1.0)
			px[i] = 255
			px[i + 1] = int(pow(1.0 - u * u * (3.0 - 2.0 * u), 1.4) * 255.0)
			i += 2
	return ImageTexture.create_from_image(Image.create_from_data(n, n, false, Image.FORMAT_LA8, px))
