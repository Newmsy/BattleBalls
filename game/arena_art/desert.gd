## Desert (dunes, oasis): sun-warmed sand with lit dunes and wind ripples,
## cracked clay in the middle (a turquoise pool for Oasis), red canyon walls
## with layered strata outside, barrel cacti for pillars, a skull, bones and
## pebbles. Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const Kit := preload("res://game/arena_art/kit.gd")

const STRATA := [Color("c4643a"), Color("d27a48"), Color("b55530"), Color("de8c56"), Color("a94b2a"), Color("cf7444")]


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var y := ctx.canvas.position.y
	var k := 0
	while y < ctx.canvas.end.y:
		var h := ctx.u(18.0 + 6.0 * sin(k * 1.7))
		Dot.rect(cv, Rect2(ctx.canvas.position.x, y, ctx.canvas.size.x, h), STRATA[k % STRATA.size()])
		Dot.rect(cv, Rect2(ctx.canvas.position.x, y, ctx.canvas.size.x, ctx.u(2.5)), Color(1, 1, 1, 0.12))
		y += h
		k += 1

	var tl := ctx.full.position
	var br := ctx.full.end
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["fde8b4", "f2c886", "dc9f5c"], (p - tl).dot(Vector2.ONE) / (br - tl).dot(Vector2.ONE)))
	# Two big dunes: a lit crest and a shaded back.
	for spec in [[0.18, 0.1, -1.0], [0.84, 0.08, 1.0]]:
		var base: float = spec[0]
		var amp: float = spec[1]
		var side: float = spec[2]
		var crest := PackedVector2Array()
		for i in 41:
			var t := i / 40.0
			crest.append(ctx.full.position + Vector2(t, base + amp * sin(t * PI * 1.6 + base * 9.0)) * ctx.full.size.x)
		var lit := crest.duplicate()
		var edge_y := ctx.full.position.y if side < 0.0 else ctx.full.end.y
		lit.append(Vector2(ctx.full.end.x, edge_y))
		lit.append(Vector2(ctx.full.position.x, edge_y))
		Kit.clip_grad(cv, lit, ctx.outline, Color("ffeec4"), Color("f6d496"), Vector2(0, crest[20].y), Vector2(0, edge_y))
		var back := crest.duplicate()
		for i in range(40, -1, -1):
			back.append(crest[i] + Vector2(0, -side * ctx.u(26.0)))
		Kit.clip_grad(cv, back, ctx.outline, Color(0.62, 0.36, 0.14, 0.35), Color(0.62, 0.36, 0.14, 0.0), crest[20], crest[20] + Vector2(0, -side * ctx.u(26.0)))
		Kit.line(cv, crest, Color(1.0, 0.97, 0.85, 0.85), ctx.u(3.0), ctx.outline)
	var ry := ctx.full.position.y + ctx.u(250.0)
	while ry < ctx.full.position.y + ctx.u(780.0):
		var wave := PackedVector2Array()
		for i in 41:
			wave.append(Vector2(ctx.full.position.x + ctx.full.size.x * i / 40.0, ry + sin(i * 0.7 + ry * 0.03) * ctx.u(7.0)))
		Kit.line(cv, wave, Color(0.66, 0.4, 0.18, 0.24), ctx.u(2.0), ctx.outline)
		ry += ctx.u(26.0)
	if ctx.id == "oasis":
		_pool(cv, ctx)
	else:
		_clay(cv, ctx)
	var keep := [[ctx.centre, ctx.u(150.0)]]
	for o in ctx.obstacles:
		keep.append([o.pos, o.radius * 1.4])
	for p in Kit.scatter_in(ctx, 24, ctx.u(30.0), keep):
		Kit.shadow(cv, p, ctx.u(5.0), 0.3)
		Kit.ball(cv, p, ctx.u(ctx.rng.randf_range(3.5, 7.0)), Color("e0c09a"), Color("8a6440"))
	var spots := Kit.scatter_in(ctx, 2, ctx.u(70.0), keep + [[ctx.at(150, 850), ctx.u(140.0)], [ctx.at(850, 150), ctx.u(140.0)]])
	if spots.size() == 2:
		_skull(cv, ctx, spots[0])
		_bones(cv, ctx, spots[1])
	Kit.inner_shadow(cv, ctx, ctx.u(44.0), 0.45, Color("5a2008"))

	# Canyon walls: layered red rock with a lit top edge.
	Kit.blocks(ctx, ctx.u(54.0), ctx.wall, func(q, _e, i):
		var tone: Color = STRATA[i % STRATA.size()]
		Kit.lit(cv, q, tone.lightened(0.12), tone.darkened(0.45))
		Dot.line(cv, q[1], q[2], Color(0.25, 0.08, 0.02, 0.6), ctx.u(2.0), true))
	var rim := ctx.outline.duplicate()
	rim.append(rim[0])
	Dot.pline(cv, rim, Color(1.0, 0.75, 0.5, 0.7), ctx.u(2.5), true)


## A ribbed barrel cactus with spines and a flower.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.glow(cv, c + Vector2(0.3, 0.45) * r, r * 1.3, Color(0.42, 0.2, 0.05, 0.5), 0.8)
	Kit.ball(cv, c, r, Color("8ee09a"), Color("1f6a2e"))
	for i in 10:
		var a := i * TAU / 10.0
		Dot.line(cv, c + Vector2.from_angle(a) * r * 0.2, c + Vector2.from_angle(a) * r * 0.95, Color(0.1, 0.3, 0.12, 0.7), r * 0.06, true)
	for i in 20:
		var a := i * TAU / 20.0 + 0.15
		Dot.line(cv, c + Vector2.from_angle(a) * r * 0.95, c + Vector2.from_angle(a) * r * 1.2, Color("fff6d8"), maxf(1.0, r * 0.05), true)
	for k in [[Vector2(-0.18, -0.25), "ff6fa8"], [Vector2(0.12, -0.32), "ffa5cb"], [Vector2(-0.02, -0.1), "ff8fb8"]]:
		Kit.disc(cv, c + k[0] * r, r * 0.16, Color(k[1]))
	Kit.disc(cv, c + Vector2(-0.03, -0.22) * r, r * 0.09, Color("ffd23f"))


static func _clay(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var c := ctx.centre
	var shape := Kit.blob(c, ctx.u(96.0), ctx.rng, 10, 0.12)
	Kit.poly(cv, shape, Color("7d4a26"))
	var step := ctx.u(40.0)
	for i in range(-3, 3):
		for j in range(-3, 3):
			var cell := Kit.rect_pts(c + Vector2(i + 0.5, j + 0.5) * step + Vector2(ctx.rng.randf_range(-6, 6), ctx.rng.randf_range(-6, 6)) * ctx.s, Vector2.ONE * step * 0.86, ctx.rng.randf_range(-0.2, 0.2))
			for part in Geometry2D.intersect_polygons(cell, shape):
				Kit.lit(cv, part, Color("eab478"), Color("b87a44"))
	var rim := shape.duplicate()
	rim.append(shape[0])
	Dot.pline(cv, rim, Color(1.0, 0.85, 0.6, 0.6), ctx.u(4.0), true)


static func _pool(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var c := ctx.centre
	var r := ctx.u(120.0)
	var bank := Kit.blob(c, r * 1.15, ctx.rng, 10, 0.08)
	Kit.lit(cv, bank, Color("c9a06a"), Color("8a6440"))
	var water := Kit.blob(c, r, ctx.rng, 10, 0.08)
	Kit.tris(cv, water, _shade(water, c - Vector2(r, r) * 0.4, r * 2.0, ["7ff0e0", "2fb8c8", "1a7a9a"]), Geometry2D.triangulate_polygon(water))
	for k in 3:
		Dot.arc(cv, c + Vector2(-0.2, -0.15) * r, r * (0.3 + k * 0.18), 3.6, 4.6, 16, Color(1, 1, 1, 0.35), ctx.u(3.0), true)
	for i in 7: # Palm fronds reaching over the water.
		var a := i * TAU / 7.0 + 0.3
		var root := c + Vector2.from_angle(a) * r * 1.25
		var tip := c + Vector2.from_angle(a + 0.25) * r * 0.75
		var side := (tip - root).orthogonal().normalized()
		var frond := PackedVector2Array([root, root.lerp(tip, 0.5) + side * ctx.u(14.0), tip, root.lerp(tip, 0.5) - side * ctx.u(6.0)])
		Kit.grad(cv, frond, Color("2f8a3a"), Color("8ee07a"), root, tip)


static func _skull(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2) -> void:
	var s := ctx.u(15.0)
	Kit.shadow(cv, p, s, 0.35)
	for sgn: float in [-1.0, 1.0]:
		Dot.pline(cv, PackedVector2Array([p + Vector2(sgn * s * 0.9, -s * 0.4), p + Vector2(sgn * s * 1.7, -s * 0.9), p + Vector2(sgn * s * 2.2, -s * 0.4)]), Color("efe4c8"), s * 0.35, true)
	Kit.ball(cv, p, s, Color("fbf5e4"), Color("c9b890"))
	Kit.disc(cv, p + Vector2(-0.38, 0.0) * s, s * 0.28, Color("5a3a22"))
	Kit.disc(cv, p + Vector2(0.38, 0.0) * s, s * 0.28, Color("5a3a22"))


static func _bones(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2) -> void:
	for k in 3:
		var a := p + Vector2(-ctx.u(18.0), ctx.u(-9.0 + k * 9.0))
		var b := p + Vector2(ctx.u(18.0), ctx.u(-9.0 + k * 9.0))
		var mid := a.lerp(b, 0.5) + Vector2(0, -ctx.u(6.0))
		Dot.pline(cv, PackedVector2Array([a, mid, b]), Color(0, 0, 0, 0.2), ctx.u(6.0), true)
		Dot.pline(cv, PackedVector2Array([a, mid, b]), Color("efe4c8"), ctx.u(4.0), true)


static func _shade(pts: PackedVector2Array, lamp: Vector2, reach: float, stops: Array) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(Kit.ramp(stops, p.distance_to(lamp) / reach))
	return cols
