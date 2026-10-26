## Fast shapes for every fight and menu drawing.
##
## Godot 4.3's compatibility renderer gives every polygon, AA line and polyline
## its own vertex buffer and draw call, and starts a new draw call whenever
## the texture or the kind of command changes. A critter drawn with a mix of
## circles, polygons and lines cost ~25 draw calls; a menu of icons, hundreds.
## Everything here is a textured triangle (draw_primitive with 3 points) from
## one baked atlas (game/dot_atlas.png): circles, rings, glows, the body
## shading, filled polygons, rects and lines all join the same draw call.
## The atlas's soft one-texel rims keep edges as smooth as the engine's.
## Remake the atlas with tools/dot_atlas.gd after changing a generator.
## Render-only.
##
## Rule: in 4.3 a run of 3-point primitives draws with the FIRST one's
## texture, so every 3-point draw_primitive must pass Dot.atlas() (a solid
## colour uses Dot.WHITE's UV). Use Dot.poly / Dot.tri, never a bare
## draw_primitive with 3 points.
extends RefCounted

const ATLAS_PATH := "res://game/dot_atlas.png"
const DISC_SIZES := [16, 64, 256]
## Inner/outer radius of each baked ring. A ring between two buckets snaps to
## the nearer one, keeping its outer edge (width off by a few percent).
const RING_K := [.5, .6, .68, .74, .79, .83, .86, .89, .915, .935, .955, .97]
## Rings bigger than this (outer radius, px) or thinner than the last bucket
## fall back to the engine's arc, where a 256px texture would blur.
const RING_MAX_R := 160.0

static var _atlas: Texture2D
static var _uv := {}
static var _white := PackedVector2Array()


## Every baked image: name -> side in texels, in packing order.
static func kinds() -> Array:
	var out := [["white", 4]]
	for n in DISC_SIZES:
		out.append(["disc%d" % n, n])
	out.append(["shade", 256])
	for i in RING_K.size():
		out.append(["ring%d" % i, 256])
	out.append(["core", 128])
	out.append(["sheen", 128])
	for i in 10:
		out.append(["glow%d" % i, 128])
	return out


## Where each image sits in the atlas: shelves 2048 wide, biggest first, 2
## texels of clear gutter so linear filtering never bleeds between them.
## White sits at the top-left corner, so a primitive drawn with no UVs in a
## run of Dot triangles still comes out in plain colour.
static func layout() -> Dictionary:
	var items := kinds().filter(func(it): return it[0] != "white")
	items.sort_custom(func(a, b): return a[1] > b[1] if a[1] != b[1] else a[0] < b[0])
	var rects := {"white": Rect2i(0, 0, 4, 4)}
	var x := 6
	var y := 0
	var row := 0
	for it in items:
		if x + it[1] > 2048:
			x = 0
			y += row + 2
			row = 0
		rects[it[0]] = Rect2i(x, y, it[1], it[1])
		x += it[1] + 2
		row = maxi(row, it[1])
	rects["_size"] = Vector2i(2048, y + row)
	return rects


static func atlas() -> Texture2D:
	if _atlas == null:
		_atlas = load(ATLAS_PATH)
		var l := layout()
		var s := Vector2(l["_size"])
		for k in l:
			if k != "_size":
				var r: Rect2i = l[k]
				_uv[k] = Rect2(Vector2(r.position) / s, Vector2(r.size) / s)
		var w: Rect2 = _uv["white"]
		var mid := w.get_center()
		_white = PackedVector2Array([mid, mid, mid])
	return _atlas


## One triangle in one colour.
static func tri(ci: CanvasItem, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var tex := atlas()
	ci.draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([col, col, col]), _white, tex)


## A triangle with a colour per corner (a gradient), e.g. a light beam.
static func tri_colors(ci: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray) -> void:
	var tex := atlas()
	ci.draw_primitive(pts, cols, _white, tex)


## `rect` filled with the atlas image `kind`, tinted `col` (two triangles).
static func quad(ci: CanvasItem, kind: String, rect: Rect2, col: Color) -> void:
	var tex := atlas()
	var u: Rect2 = _uv[kind]
	var cols := PackedColorArray([col, col, col])
	var p0 := rect.position
	var p2 := rect.end
	var p1 := Vector2(p2.x, p0.y)
	var p3 := Vector2(p0.x, p2.y)
	var u0 := u.position
	var u2 := u.end
	var u1 := Vector2(u2.x, u0.y)
	var u3 := Vector2(u0.x, u2.y)
	ci.draw_primitive(PackedVector2Array([p0, p1, p2]), cols, PackedVector2Array([u0, u1, u2]), tex)
	ci.draw_primitive(PackedVector2Array([p0, p2, p3]), cols, PackedVector2Array([u0, u2, u3]), tex)


static func circle(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	if not r > 0.0: # Also skips NaN.
		return
	quad(ci, "disc16" if r < 6.0 else "disc64" if r < 24.0 else "disc256", Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), col)


## A filled rect (draw_rect with filled = true) that batches with the rest.
static func rect(ci: CanvasItem, r: Rect2, col: Color) -> void:
	r = r.abs()
	var a := r.position
	var b := Vector2(r.end.x, a.y)
	var c := r.end
	var d := Vector2(a.x, c.y)
	tri(ci, a, b, c, col)
	tri(ci, a, c, d, col)


## A stroke of width `w` centred on radius `r` (a full-circle draw_arc).
static func ring(ci: CanvasItem, c: Vector2, r: float, w: float, col: Color, aa := true) -> void:
	if not r > 0.0 or not w > 0.0:
		return
	# The engine's antialiased arc fades a pixel past each edge: match its look.
	var half := w / 2.0 + (0.5 if aa else 0.0)
	var outer := r + half
	var k := maxf(0.0, r - half) / outer
	if outer > RING_MAX_R or k > RING_K[RING_K.size() - 1] + .012 or k < RING_K[0] - .1:
		ci.draw_arc(c, r, 0.0, TAU, maxi(24, int(r)), col, w, aa)
		return
	var best := 0
	for i in RING_K.size():
		if absf(RING_K[i] - k) < absf(RING_K[best] - k):
			best = i
	quad(ci, "ring%d" % best, Rect2(c.x - outer, c.y - outer, outer * 2.0, outer * 2.0), col)


## A filled polygon as batched triangles: same triangulation as
## draw_colored_polygon; a shape that can't be triangulated draws nothing
## instead of logging an error.
static func poly(ci: CanvasItem, pts, col: Color) -> void:
	var n: int = pts.size()
	if n < 3:
		return
	if n == 3:
		tri(ci, pts[0], pts[1], pts[2], col)
		return
	var idx := Geometry2D.triangulate_polygon(pts)
	var tex := atlas()
	var cols := PackedColorArray([col, col, col])
	for i in range(0, idx.size() - 2, 3):
		ci.draw_primitive(PackedVector2Array([pts[idx[i]], pts[idx[i + 1]], pts[idx[i + 2]]]), cols, _white, tex)


## A polygon filled with the atlas image `kind`: `uv` (0..1 over the image)
## per point, like draw_colored_polygon with a texture.
static func tex_poly(ci: CanvasItem, pts: PackedVector2Array, uv: PackedVector2Array, col: Color, kind: String) -> void:
	if pts.size() < 3:
		return
	var tex := atlas()
	var u: Rect2 = _uv[kind]
	var cols := PackedColorArray([col, col, col])
	var idx := Geometry2D.triangulate_polygon(pts)
	for i in range(0, idx.size() - 2, 3):
		var a: int = idx[i]
		var b: int = idx[i + 1]
		var c: int = idx[i + 2]
		ci.draw_primitive(PackedVector2Array([pts[a], pts[b], pts[c]]), cols,
			PackedVector2Array([u.position + uv[a] * u.size, u.position + uv[b] * u.size, u.position + uv[c] * u.size]), tex)


## draw_line with a width: a quad, and with `aa` a one-pixel fade on each
## side like the engine's antialiased line (which would be its own polygon).
## Hairlines (w < 0) stay the engine's.
static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w := -1.0, aa := false) -> void:
	if w < 0.0:
		ci.draw_line(a, b, col, w, aa)
		return
	var d := b - a
	if d.length_squared() < 1e-8:
		return
	var n := Vector2(-d.y, d.x).normalized() * (w / 2.0)
	if not aa:
		tri(ci, a + n, b + n, b - n, col)
		tri(ci, a + n, b - n, a - n, col)
		return
	atlas()
	var f := n.normalized() * (1.0 if w >= 1.0 else w) # The fade, like the engine's 1px feather.
	var clear := Color(col, 0.0)
	var solid := PackedColorArray([col, col, col])
	tri(ci, a + n, b + n, b - n, col)
	tri(ci, a + n, b - n, a - n, col)
	for s: float in [1.0, -1.0]:
		var e: Vector2 = n * s
		var o: Vector2 = e + f * s
		ci.draw_primitive(PackedVector2Array([a + e, b + e, b + o]), PackedColorArray([col, col, clear]), _white, _atlas)
		ci.draw_primitive(PackedVector2Array([a + e, b + o, a + o]), PackedColorArray([col, clear, clear]), _white, _atlas)


## draw_arc. A full circle with a width is a baked ring; a short arc (a
## dash, a tick, a spark) is one or two batched lines. Under a fifth of a
## radian a chord is within a pixel of the curve at any radius we draw.
## Other arcs keep the engine's polyline.
const SHORT_ARC := 0.2

static func arc(ci: CanvasItem, c: Vector2, r: float, a0: float, a1: float, n: int, col: Color, w := -1.0, aa := false) -> void:
	var span := absf(a1 - a0)
	if w > 0.0 and span >= TAU - .001:
		ring(ci, c, r, w, col, aa)
		return
	if w < 0.0 or span > SHORT_ARC * 2.0:
		ci.draw_arc(c, r, a0, a1, n, col, w, aa)
		return
	if not r > 0.0:
		return
	var p0 := c + Vector2(cos(a0), sin(a0)) * r
	var p1 := c + Vector2(cos(a1), sin(a1)) * r
	if span <= SHORT_ARC:
		line(ci, p0, p1, col, w, aa)
		return
	var am := (a0 + a1) / 2.0
	var pm := c + Vector2(cos(am), sin(am)) * r
	line(ci, p0, pm, col, w, aa)
	line(ci, pm, p1, col, w, aa)


## draw_polyline, with a one- or two-segment stroke (a chevron, a spike's
## edge) drawn as batched lines. Longer strokes keep the engine's polyline
## for clean joins.
static func pline(ci: CanvasItem, pts, col: Color, w := -1.0, aa := false) -> void:
	var n: int = pts.size()
	if n < 2:
		return
	if w < 0.0 or n > 3:
		ci.draw_polyline(pts, col, w, aa)
		return
	line(ci, pts[0], pts[1], col, w, aa)
	if n == 3:
		line(ci, pts[1], pts[2], col, w, aa)


## A soft round glow (or with black, a soft shadow): full col inside
## inner * r, easing smoothly out to nothing at r. Use it instead of stacking
## faint circles, which shows as rings.
static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, inner := 0.0) -> void:
	if not r > 0.0 or col.a <= 0.0:
		return
	quad(ci, "glow%d" % clampi(roundi(inner * 10.0), 0, 9), Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), col)


# --- The baked images (tools/dot_atlas.gd writes them into the atlas) ---

## Alpha bytes (n * n) of one image.
static func bake(kind: String, n: int) -> PackedByteArray:
	var px := PackedByteArray()
	px.resize(n * n)
	var half := n / 2.0
	var i := 0
	if kind == "white":
		px.fill(255)
		return px
	for y in n:
		for x in n:
			var dx := x + 0.5 - half
			var dy := y + 0.5 - half
			var a := 0.0
			if kind.begins_with("disc"):
				a = clampf(half - 1.0 - sqrt(dx * dx + dy * dy) + 0.5, 0.0, 1.0)
			elif kind.begins_with("ring"):
				var d := sqrt(dx * dx + dy * dy)
				var outer := half - 1.0
				var inner: float = outer * RING_K[int(kind.substr(4))]
				a = clampf(outer - d + 0.5, 0.0, 1.0) * clampf(d - inner + 0.5, 0.0, 1.0)
			elif kind.begins_with("glow"):
				var inner_g := int(kind.substr(4)) / 10.0
				var u := clampf((sqrt(dx * dx + dy * dy) / half - inner_g) / (1.0 - inner_g), 0.0, 1.0)
				a = pow(1.0 - u * u * (3.0 - 2.0 * u), 1.4)
			else:
				a = _body_alpha(kind, Vector2(dx, dy) / (half - 1.0), half)
			px[i] = int(a * 255.0)
			i += 1
	return px


## The critter body finish (CritterArt): "shade" = how far towards the light
## a point is (the continuous version of a stack of shrinking circles sliding
## to the top-left highlight: the largest f whose circle holds the point is
## the smaller root of |p - o f|^2 = (1 - .82 f)^2); "core" darkens the rim
## away from the light; "sheen" is a blurred gloss spot.
static func _body_alpha(kind: String, p: Vector2, half: float) -> float:
	var edge := clampf((1.0 - p.length()) * (half - 1.0) + .5, 0.0, 1.0)
	if kind == "shade":
		var o := Vector2(-.315, -.36)
		var qa := o.length_squared() - .6724
		var f := 1.0
		if (p - o).length_squared() > .0324:
			var qb := 1.64 - 2.0 * p.dot(o)
			var qc := p.length_squared() - 1.0
			f = clampf((-qb + sqrt(maxf(0.0, qb * qb - 4.0 * qa * qc))) / (2.0 * qa), 0.0, 1.0)
		return f * f * (3.0 - 2.0 * f) * edge
	if kind == "core":
		var d := (p - Vector2(-.3, -.35)).length() / 1.35
		return smoothstep(.55, 1.0, d) * edge
	var q := (p - Vector2(-.38, -.48)) / Vector2(.3, .2)
	q = q.rotated(.7)
	return exp(-q.length_squared() * 1.6) * edge


## The whole atlas image (white, alpha from bake()).
static func make_atlas() -> Image:
	var l := layout()
	var size: Vector2i = l["_size"]
	var img := Image.create(size.x, size.y, false, Image.FORMAT_LA8)
	img.fill(Color(1, 1, 1, 0))
	for it in kinds():
		var r: Rect2i = l[it[0]]
		var a := bake(it[0], it[1])
		var la := PackedByteArray()
		la.resize(a.size() * 2)
		for j in a.size():
			la[j * 2] = 255
			la[j * 2 + 1] = a[j]
		img.blit_rect(Image.create_from_data(it[1], it[1], false, Image.FORMAT_LA8, la), Rect2i(Vector2i.ZERO, r.size), r.position)
	return img
