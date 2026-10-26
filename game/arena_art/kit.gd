## Drawing helpers for the themed arena art (game/arena_art.gd): gradient
## polygons, radial glows and soft shadows as single triangle meshes, strips
## along the arena's outline and deterministic scatter. Everything here is
## painted once into the baked floor texture, never per frame. Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")


## What a painter gets: the arena's shape in pixels plus a seeded RNG.
class Ctx:
	var id: String
	var s: float ## Pixels per arena unit.
	var full: Rect2 ## The arena's square in pixels.
	var canvas: Rect2 ## The square plus the frame margin round it.
	var outline: PackedVector2Array ## The full-size wall outline (convex).
	var centre: Vector2
	var wall: float ## How thick the wall band is, in pixels.
	var rng := RandomNumberGenerator.new()
	var obstacles: Array = [] ## Full-size obstacles: {pos, radius, kind} in pixels.
	var floors: Array = [] ## Full-size floor pads in pixels: {kind, pos, radius} or {kind, rect}.

	func u(v: float) -> float:
		return v * s

	## A point in arena units (0-1000) in pixels.
	func at(x: float, y: float) -> Vector2:
		return full.position + Vector2(x, y) * s

	func is_square() -> bool:
		return outline.size() == 4


## One mesh for any number of triangles: a single canvas command.
static func tris(cv: CanvasItem, pts: PackedVector2Array, cols: PackedColorArray, idx: PackedInt32Array) -> void:
	if idx.size() >= 3 and pts.size() == cols.size():
		RenderingServer.canvas_item_add_triangle_array(cv.get_canvas_item(), idx, pts, cols)


static func poly(cv: CanvasItem, pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(col)
	tris(cv, pts, cols, Geometry2D.triangulate_polygon(pts))


## A polygon shaded from c0 at `a` to c1 at `b` (a straight-line gradient).
static func grad(cv: CanvasItem, pts: PackedVector2Array, c0: Color, c1: Color, a: Vector2, b: Vector2) -> void:
	if pts.size() < 3:
		return
	var d := b - a
	var cols := PackedColorArray()
	for p in pts:
		cols.append(c0.lerp(c1, clampf((p - a).dot(d) / maxf(d.length_squared(), 0.001), 0.0, 1.0)))
	tris(cv, pts, cols, Geometry2D.triangulate_polygon(pts))


## grad() over a polygon light from the top left, dark at the bottom right.
static func lit(cv: CanvasItem, pts: PackedVector2Array, light: Color, dark: Color) -> void:
	var box := bounds(pts)
	grad(cv, pts, light, dark, box.position, box.end)


static func bounds(pts: PackedVector2Array) -> Rect2:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	return box


## Parts of `pts` inside `clip` (the arena outline), each filled.
static func clip_poly(cv: CanvasItem, pts: PackedVector2Array, clip: PackedVector2Array, col: Color) -> void:
	for part in Geometry2D.intersect_polygons(pts, clip):
		poly(cv, part, col)


static func clip_grad(cv: CanvasItem, pts: PackedVector2Array, clip: PackedVector2Array, c0: Color, c1: Color, a: Vector2, b: Vector2) -> void:
	for part in Geometry2D.intersect_polygons(pts, clip):
		grad(cv, part, c0, c1, a, b)


## A polyline, only the bits inside `clip` (empty: no clipping).
static func line(cv: CanvasItem, pts: PackedVector2Array, col: Color, w: float, clip := PackedVector2Array()) -> void:
	if pts.size() < 2:
		return
	if clip.is_empty():
		Dot.pline(cv, pts, col, w, true)
		return
	for part in Geometry2D.intersect_polyline_with_polygon(pts, clip):
		if part.size() >= 2:
			Dot.pline(cv, part, col, w, true)


## A filled ellipse whose colour runs through `stops` from the middle out.
static func radial(cv: CanvasItem, c: Vector2, r: Vector2, stops: Array, n := 40) -> void:
	var pts := PackedVector2Array([c])
	var cols := PackedColorArray([stops[0]])
	var idx := PackedInt32Array()
	var rings := stops.size() - 1
	for k in range(1, rings + 1):
		for i in n:
			var a := i * TAU / n
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * (float(k) / rings))
			cols.append(stops[k])
	for i in n:
		idx.append_array([0, 1 + i, 1 + (i + 1) % n])
	for k in range(1, rings):
		var a0 := 1 + (k - 1) * n
		var a1 := 1 + k * n
		for i in n:
			var j := (i + 1) % n
			idx.append_array([a0 + i, a1 + i, a1 + j, a0 + i, a1 + j, a0 + j])
	tris(cv, pts, cols, idx)


## A soft round light (or with black, a soft shadow) fading out to its rim.
static func glow(cv: CanvasItem, c: Vector2, r: float, col: Color, squash := 1.0) -> void:
	radial(cv, c, Vector2(r, r * squash), [col, Color(col, col.a * 0.45), Color(col, 0.0)], 32)


static func shadow(cv: CanvasItem, c: Vector2, r: float, alpha := 0.4) -> void:
	glow(cv, c + Vector2(0.12, 0.2) * r, r * 1.15, Color(0, 0, 0, alpha), 0.85)


## A disc shaded like a lit ball: light at the top left, dark at the far rim.
static func ball(cv: CanvasItem, c: Vector2, r: float, light: Color, dark: Color, squash := 1.0) -> void:
	var lamp := c + Vector2(-0.35, -0.4) * r
	var n := 32
	var pts := PackedVector2Array([c])
	var idx := PackedInt32Array()
	for k in range(1, 4):
		for i in n:
			var a := i * TAU / n
			pts.append(c + Vector2(cos(a), sin(a) * squash) * r * k / 3.0)
	for i in n:
		idx.append_array([0, 1 + i, 1 + (i + 1) % n])
	for k in range(1, 3):
		var a0 := 1 + (k - 1) * n
		var a1 := 1 + k * n
		for i in n:
			var j := (i + 1) % n
			idx.append_array([a0 + i, a1 + i, a1 + j, a0 + i, a1 + j, a0 + j])
	var cols := PackedColorArray()
	for p in pts:
		cols.append(light.lerp(dark, clampf(p.distance_to(lamp) / (r * 1.55), 0.0, 1.0)))
	tris(cv, pts, cols, idx)


## The outline's points pushed out by d (in by a negative d): each corner
## moves along its bisector so every edge shifts by exactly d.
static func offset(outline: PackedVector2Array, d: float) -> PackedVector2Array:
	var n := outline.size()
	var out := PackedVector2Array()
	var mid := Vector2.ZERO
	for p in outline:
		mid += p
	mid /= n
	for i in n:
		var n1 := _normal(outline[(i - 1 + n) % n], outline[i], mid)
		var n2 := _normal(outline[i], outline[(i + 1) % n], mid)
		var dir := (n1 + n2).normalized()
		out.append(outline[i] + dir * d / maxf(0.25, dir.dot(n1)))
	return out


static func _normal(a: Vector2, b: Vector2, mid: Vector2) -> Vector2:
	var nrm := (b - a).orthogonal().normalized()
	return nrm if nrm.dot((a + b) / 2.0 - mid) > 0.0 else -nrm


## Outward normal of edge i.
static func edge_normal(outline: PackedVector2Array, i: int) -> Vector2:
	var mid := Vector2.ZERO
	for p in outline:
		mid += p
	mid /= outline.size()
	return _normal(outline[i], outline[(i + 1) % outline.size()], mid)


## The band between two loops of the same size, coloured per loop.
static func strip(cv: CanvasItem, a: PackedVector2Array, b: PackedVector2Array, ca: Color, cb: Color) -> void:
	var n := a.size()
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for i in n:
		pts.append(a[i])
		pts.append(b[i])
		cols.append(ca)
		cols.append(cb)
	for i in n:
		var j := (i + 1) % n
		idx.append_array([2 * i, 2 * i + 1, 2 * j + 1, 2 * i, 2 * j + 1, 2 * j])
	tris(cv, pts, cols, idx)


## Shade cast by the walls onto the floor, strongest under the top and left
## walls, as if lit from the bottom right.
static func inner_shadow(cv: CanvasItem, ctx: Ctx, w: float, alpha := 0.45, tint := Color.BLACK) -> void:
	var o := ctx.outline
	var inner := offset(o, -w)
	var n := o.size()
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for i in n:
		var j := (i + 1) % n
		var nrm := edge_normal(o, i)
		var a := alpha * (0.55 + 0.45 * maxf(-nrm.y, -nrm.x * 0.8))
		var base := pts.size()
		pts.append_array([o[i], o[j], inner[j], inner[i]])
		cols.append_array([Color(tint, a), Color(tint, a), Color(tint, 0), Color(tint, 0)])
		idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	tris(cv, pts, cols, idx)


## The wall band split into blocks about `seg` long: calls make(quad, edge,
## index) for each, quad = [inner start, inner end, outer end, outer start].
## skew slides the outer edge along by that many pixels (candy stripes).
static func blocks(ctx: Ctx, seg: float, width: float, make: Callable, skew := 0.0) -> void:
	var a := ctx.outline
	var b := offset(a, width)
	var n := a.size()
	for e in n:
		var f := (e + 1) % n
		var length := a[e].distance_to(a[f])
		var k := maxi(1, roundi(length / seg))
		for i in k:
			var t0 := float(i) / k
			var t1 := float(i + 1) / k
			var sk := skew / maxf(length, 1.0)
			var o0 := 0.0 if i == 0 else clampf(t0 + sk, 0.0, 1.0)
			var o1 := 1.0 if i == k - 1 else clampf(t1 + sk, 0.0, 1.0)
			var q := PackedVector2Array([a[e].lerp(a[f], t0), a[e].lerp(a[f], t1), b[e].lerp(b[f], o1), b[e].lerp(b[f], o0)])
			make.call(q, e, i)


## Fills the floor (inside the outline) with a colour that varies by
## position: shade(p) -> Color, sampled on rings out from the middle. Any
## smooth gradient (radial, linear, lit from a corner) in one mesh.
static func floor_fill(cv: CanvasItem, ctx: Ctx, shade: Callable, rings := 6, step := 0.0) -> void:
	var rim := along(ctx.outline, 0.0, step if step > 0.0 else ctx.full.size.x / 24.0)
	var n := rim.size()
	var c := ctx.centre
	var pts := PackedVector2Array([c])
	var cols := PackedColorArray([shade.call(c)])
	var idx := PackedInt32Array()
	for k in range(1, rings + 1):
		for i in n:
			var p := c.lerp(rim[i], float(k) / rings)
			pts.append(p)
			cols.append(shade.call(p))
	for i in n:
		idx.append_array([0, 1 + i, 1 + (i + 1) % n])
	for k in range(1, rings):
		var a0 := 1 + (k - 1) * n
		var a1 := 1 + k * n
		for i in n:
			var j := (i + 1) % n
			idx.append_array([a0 + i, a1 + i, a1 + j, a0 + i, a1 + j, a0 + j])
	tris(cv, pts, cols, idx)


## Fills a rect (the backdrop) with shade(p) -> Color on an n x n grid.
static func rect_fill(cv: CanvasItem, box: Rect2, shade: Callable, n := 10) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for y in n + 1:
		for x in n + 1:
			var p := box.position + box.size * Vector2(x, y) / n
			pts.append(p)
			cols.append(shade.call(p))
	for y in n:
		for x in n:
			var a := y * (n + 1) + x
			idx.append_array([a, a + 1, a + n + 2, a, a + n + 2, a + n + 1])
	tris(cv, pts, cols, idx)


## A colour from evenly spaced stops at t (0-1).
static func ramp(stops: Array, t: float) -> Color:
	var x := clampf(t, 0.0, 1.0) * (stops.size() - 1)
	var i := mini(int(x), stops.size() - 2)
	return Color(stops[i]).lerp(Color(stops[i + 1]), x - i)


## Points spaced about `step` apart along a loop pushed out by d.
static func along(outline: PackedVector2Array, d: float, step: float) -> Array[Vector2]:
	var loop := offset(outline, d)
	var out: Array[Vector2] = []
	var n := loop.size()
	for e in n:
		var a := loop[e]
		var b := loop[(e + 1) % n]
		var k := maxi(1, roundi(a.distance_to(b) / step))
		for i in k:
			out.append(a.lerp(b, float(i) / k))
	return out


## The outline subdivided every `step` pixels, pushed in by width(t) where
## t runs 0-1 round the loop: a wavy rim (frosting, snow drifts, foam).
static func wavy_rim(cv: CanvasItem, ctx: Ctx, step: float, width: Callable, col: Color, inner_col := Color(0, 0, 0, -1)) -> void:
	var outer := along(ctx.outline, 0.0, step)
	var n := outer.size()
	var c := ctx.centre
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	var ic := col if inner_col.a < 0.0 else inner_col
	for i in n:
		var p := outer[i]
		pts.append(p)
		pts.append(p + (c - p).normalized() * float(width.call(float(i) / n, p)))
		cols.append(col)
		cols.append(ic)
	for i in n:
		var j := (i + 1) % n
		idx.append_array([2 * i, 2 * i + 1, 2 * j + 1, 2 * i, 2 * j + 1, 2 * j])
	tris(cv, pts, cols, idx)


## Seeded points inside the outline (at least `pad` from the walls and
## clear of `avoid` circles: [[centre, radius], ...]).
static func scatter_in(ctx: Ctx, count: int, pad: float, avoid := []) -> Array[Vector2]:
	var inner := offset(ctx.outline, -pad)
	var box := bounds(inner)
	var out: Array[Vector2] = []
	var tries := 0
	while out.size() < count and tries < count * 30:
		tries += 1
		var p := Vector2(ctx.rng.randf_range(box.position.x, box.end.x), ctx.rng.randf_range(box.position.y, box.end.y))
		if not Geometry2D.is_point_in_polygon(p, inner):
			continue
		var ok := true
		for a in avoid:
			if p.distance_to(a[0]) < a[1]:
				ok = false
				break
		if ok:
			out.append(p)
	return out


## Seeded points on the canvas outside the walls (beyond the band).
static func scatter_out(ctx: Ctx, count: int, pad: float) -> Array[Vector2]:
	var outer := offset(ctx.outline, ctx.wall + pad)
	var box := ctx.canvas.grow(-pad * 0.3)
	var out: Array[Vector2] = []
	var tries := 0
	while out.size() < count and tries < count * 40:
		tries += 1
		var p := Vector2(ctx.rng.randf_range(box.position.x, box.end.x), ctx.rng.randf_range(box.position.y, box.end.y))
		if not Geometry2D.is_point_in_polygon(p, outer):
			out.append(p)
	return out


## Does the corner outside the walls have room (a cut or many-sided map)?
static func room_outside(ctx: Ctx, p: Vector2, r: float) -> bool:
	var outer := offset(ctx.outline, ctx.wall + r)
	return ctx.canvas.grow(-r * 0.5).has_point(p) and not Geometry2D.is_point_in_polygon(p, outer)


## A wobbly closed blob (rocks, puddles, moss, clouds).
static func blob(c: Vector2, r: float, rng: RandomNumberGenerator, n := 9, wob := 0.2) -> PackedVector2Array:
	var raw := PackedVector2Array()
	for i in n:
		raw.append(c + Vector2.from_angle(i * TAU / n) * r * (1.0 + rng.randf_range(-wob, wob)))
	return smooth(raw, 2)


## Chaikin corner cutting: rounds a closed polygon.
static func smooth(pts: PackedVector2Array, rounds: int) -> PackedVector2Array:
	var cur := pts
	for _r in rounds:
		var nxt := PackedVector2Array()
		var n := cur.size()
		for i in n:
			var a := cur[i]
			var b := cur[(i + 1) % n]
			nxt.append(a.lerp(b, 0.25))
			nxt.append(a.lerp(b, 0.75))
		cur = nxt
	return cur


static func circle_pts(c: Vector2, r: float, n := 32, squash := 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := i * TAU / n
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * squash))
	return pts


static func star_pts(c: Vector2, r_out: float, r_in: float, points: int, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		pts.append(c + Vector2.from_angle(rot + i * PI / points) * (r_out if i % 2 == 0 else r_in))
	return pts


## A soft-edged disc (batched quad; anti-aliased rim).
static func disc(cv: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	Dot.circle(cv, c, r, col)


static func ring(cv: CanvasItem, c: Vector2, r: float, col: Color, w: float, n := 48) -> void:
	Dot.arc(cv, c, r, 0.0, TAU, n, col, w, true)


## Rect corners as a polygon, rotated by `rot` about its middle.
static func rect_pts(c: Vector2, size: Vector2, rot := 0.0) -> PackedVector2Array:
	var h := size / 2.0
	var pts := PackedVector2Array()
	for v in [Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)]:
		pts.append(c + v.rotated(rot))
	return pts
