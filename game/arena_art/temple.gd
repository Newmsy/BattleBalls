## Lost Temple (temple, ruins, thorn): worn sandstone tiles with cracks and
## moss, a carved gold sun in the middle, carved stone walls with gold trim
## and torches, fluted stone columns, jungle all round. Thorn is overgrown.
## Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const Kit := preload("res://game/arena_art/kit.gd")

const TILES := [Color("dcbd84"), Color("d3b073"), Color("e2c690"), Color("cca66a")]
const GOLD := Color("ffd970")
const GOLD_DARK := Color("b8801f")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var thorn := ctx.id == "thorn"
	var reach := ctx.canvas.size.x * 0.72
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["44722f", "2c4d20", "16260f"], p.distance_to(ctx.centre) / reach))
	for p in Kit.scatter_out(ctx, 60, ctx.u(10.0)):
		_leaf(cv, ctx, p, ctx.u(ctx.rng.randf_range(12.0, 20.0)), ctx.rng.randf() * TAU)

	# Sandstone tiles on dark mortar.
	Kit.floor_fill(cv, ctx, func(_p): return Color("9a7646"))
	var size := ctx.u(84.0)
	var gap := ctx.u(2.0)
	var start := ctx.centre - Vector2.ONE * size * 6.5
	for i in 13:
		for j in 13:
			var tl := start + Vector2(i, j) * size
			var tile := PackedVector2Array([tl + Vector2(gap, gap), tl + Vector2(size - gap, gap), tl + Vector2(size - gap, size - gap), tl + Vector2(gap, size - gap)])
			var tone: Color = TILES[(i * 7 + j * 3) % TILES.size()]
			for part in Geometry2D.intersect_polygons(tile, ctx.outline):
				Kit.grad(cv, part, tone.lightened(0.12), tone.darkened(0.14), tl, tl + Vector2(size, size))
	for _i in 9: # Cracks.
		var p := Kit.scatter_in(ctx, 1, ctx.u(60.0))
		if p.is_empty():
			continue
		var crack := PackedVector2Array([p[0]])
		for _k in 4:
			crack.append(crack[crack.size() - 1] + Vector2(ctx.rng.randf_range(-1.0, 1.0), ctx.rng.randf_range(-0.2, 1.0)).normalized() * ctx.u(ctx.rng.randf_range(14.0, 26.0)))
		Kit.line(cv, crack, Color(0.35, 0.22, 0.08, 0.7), ctx.u(2.5), ctx.outline)
	_sun(cv, ctx)
	# Moss (or thorny vines) creeping in from the walls.
	var r_in := ctx.full.size.x * 0.33
	for p in Kit.scatter_in(ctx, 90 if thorn else 60, ctx.u(6.0)):
		if p.distance_to(ctx.centre) < r_in:
			continue
		var col := Color("4f7a2e") if ctx.rng.randf() < 0.5 else Color("6a9a3a")
		Kit.poly(cv, Kit.blob(p, ctx.u(ctx.rng.randf_range(8.0, 18.0)), ctx.rng, 7, 0.3), Color(col, 0.75))
	if thorn:
		for e in ctx.outline.size():
			_vine(cv, ctx, Kit.offset(ctx.outline, -ctx.u(14.0)), e, Color("3d6a24"), true)
	for v in ctx.outline: # Warm torchlight on the floor by each corner.
		Kit.glow(cv, v.lerp(ctx.centre, 0.08), ctx.u(170.0), Color(1.0, 0.7, 0.3, 0.3))
	Kit.inner_shadow(cv, ctx, ctx.u(44.0), 0.5)

	# Carved stone blocks, gold trim, torches and creeping vines.
	Kit.blocks(ctx, ctx.u(46.0), ctx.wall, func(q, _e, i):
		var tone := Color("c49a5e") if i % 3 else Color("b88e54")
		Kit.lit(cv, q, tone.lightened(0.1), tone.darkened(0.3))
		var loop: PackedVector2Array = q.duplicate()
		loop.append(q[0])
		Dot.pline(cv, loop, Color("5a4020"), ctx.u(2.0), true))
	var trim := Kit.offset(ctx.outline, ctx.u(2.0))
	trim.append(trim[0])
	Dot.pline(cv, trim, GOLD, ctx.u(3.5), true)
	var band := Kit.offset(ctx.outline, ctx.wall * 0.5)
	for e in ctx.outline.size():
		if e % 2 == 1:
			_vine(cv, ctx, band, e, Color("3f7a2a"), false)
	for v in Kit.offset(ctx.outline, ctx.wall * 0.5):
		_torch(cv, ctx, v)


## A fluted sandstone column, a little ivy round its foot.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.shadow(cv, c, r * 1.1, 0.5)
	Kit.ball(cv, c, r * 1.12, Color("a8844f"), Color("5a3d1e"))
	Kit.ball(cv, c, r * 0.95, Color("f6e2b4"), Color("c09858"))
	for i in 12:
		var a := i * TAU / 12.0
		Dot.line(cv, c + Vector2.from_angle(a) * r * 0.6, c + Vector2.from_angle(a) * r * 0.92, Color("a88246"), r * 0.08, true)
	Kit.ball(cv, c, r * 0.42, Color("fff3d6"), Color("dcc08a"))
	var ivy := PackedVector2Array()
	for i in 16:
		ivy.append(c + Vector2.from_angle(1.6 + i * 0.12) * r * (1.02 + 0.05 * sin(i * 1.7)))
	Dot.pline(cv, ivy, Color("3f7a2a"), r * 0.1, true)
	for i in range(0, 16, 3):
		_leaf(cv, ctx, ivy[i], r * 0.16, 1.6 + i * 0.12)


## The gold sun carved into the middle, with its shadow.
static func _sun(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var c := ctx.centre
	for pass_no in 2:
		var o := Vector2(ctx.u(3.0), ctx.u(4.0)) if pass_no == 0 else Vector2.ZERO
		var dark := pass_no == 0
		var col := Color(0.3, 0.18, 0.05, 0.5) if dark else GOLD
		for i in 16:
			var a := i * TAU / 16.0
			var tri := PackedVector2Array([c + o + Vector2.from_angle(a) * ctx.u(104.0), c + o + Vector2.from_angle(a + 0.13) * ctx.u(80.0), c + o + Vector2.from_angle(a - 0.13) * ctx.u(80.0)])
			if dark:
				Kit.poly(cv, tri, col)
			else:
				Kit.lit(cv, tri, GOLD, GOLD_DARK)
		Dot.arc(cv, c + o, ctx.u(68.0), 0.0, TAU, 64, col if dark else GOLD_DARK, ctx.u(9.0), true)
		if not dark:
			Dot.arc(cv, c, ctx.u(68.0), PI, PI * 1.6, 24, Color(1, 1, 1, 0.45), ctx.u(3.0), true)
	Kit.glow(cv, c, ctx.u(60.0), Color(1.0, 0.8, 0.35, 0.35))
	Kit.ball(cv, c, ctx.u(24.0), GOLD, GOLD_DARK)


static func _torch(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2) -> void:
	var s := ctx.wall / ctx.u(30.0)
	Kit.glow(cv, p, ctx.u(60.0) * s, Color(1.0, 0.65, 0.2, 0.45))
	Kit.disc(cv, p, ctx.u(10.0) * s, Color("5a3d1e"))
	Kit.disc(cv, p, ctx.u(7.0) * s, Color("c9952f"))
	var flame := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		var rr := ctx.u(9.0) * s * (1.0 + 0.9 * maxf(0.0, -sin(a)))
		flame.append(p + Vector2(cos(a) * ctx.u(8.0) * s, sin(a) * rr) - Vector2(0, ctx.u(6.0) * s))
	Kit.grad(cv, flame, Color("ffe066"), Color("ff7a1f"), p, p - Vector2(0, ctx.u(22.0) * s))
	Kit.disc(cv, p - Vector2(0, ctx.u(5.0) * s), ctx.u(4.0) * s, Color("fff6c8"))


## A vine along edge e of `loop`, with leaves.
static func _vine(cv: CanvasItem, ctx: Kit.Ctx, loop: PackedVector2Array, e: int, col: Color, thorns: bool) -> void:
	var a := loop[e]
	var b := loop[(e + 1) % loop.size()]
	var nrm := (b - a).orthogonal().normalized()
	var pts := PackedVector2Array()
	var k := 24
	for i in k + 1:
		var t := 0.15 + 0.7 * i / float(k)
		pts.append(a.lerp(b, t) + nrm * sin(t * 22.0 + e) * ctx.u(7.0))
	Dot.pline(cv, pts, col, ctx.u(3.5), true)
	for i in range(1, k, 3):
		var dir := (pts[i + 1] - pts[i]).angle() + (0.9 if i % 2 else -0.9)
		if thorns:
			var tip := pts[i] + Vector2.from_angle(dir) * ctx.u(9.0)
			Kit.poly(cv, PackedVector2Array([pts[i] + Vector2.from_angle(dir + 1.6) * ctx.u(2.5), tip, pts[i] + Vector2.from_angle(dir - 1.6) * ctx.u(2.5)]), Color("8a2a3a"))
		_leaf(cv, ctx, pts[i] + Vector2.from_angle(dir) * ctx.u(6.0), ctx.u(7.0), dir)


static func _leaf(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2, size: float, rot: float) -> void:
	var leaf := Kit.circle_pts(Vector2.ZERO, size, 12, 0.42)
	for i in leaf.size():
		leaf[i] = p + leaf[i].rotated(rot)
	var tone: Color = [Color("5aa83a"), Color("3f8a2c"), Color("74bf48")][ctx.rng.randi() % 3]
	Kit.lit(cv, leaf, tone.lightened(0.2), tone.darkened(0.3))
	Dot.line(cv, p - Vector2.from_angle(rot) * size * 0.8, p + Vector2.from_angle(rot) * size * 0.8, Color(0.1, 0.25, 0.08, 0.6), maxf(1.0, size * 0.08), true)
