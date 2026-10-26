## The classic maps. The Box is a boxing ring (a canvas mat, ropes and
## corner posts), Neon Rink a hockey rink (lines, face-off circles, boards),
## and Pillar Hall, Spike Yard and Conveyor Factory share a steel factory
## floor (tread plate, hazard-stripe walls, bolted steel pillars).
## Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	match ctx.id:
		"square":
			_ring(cv, ctx)
		"rink":
			_rink(cv, ctx)
		_:
			_steel(cv, ctx)


## A bolted steel pillar with a yellow paint band.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.shadow(cv, c + Vector2(0.15, 0.22) * r, r, 0.55)
	Kit.ball(cv, c, r, Color("c8d0dc"), Color("3a4250"))
	Kit.ring(cv, c, r * 0.86, Color("ffc21f"), r * 0.16)
	Kit.ball(cv, c, r * 0.62, Color("e4eaf2"), Color("5a6474"))
	for i in 6:
		Kit.disc(cv, c + Vector2.from_angle(i * TAU / 6.0) * r * 0.45, maxf(1.0, r * 0.06), Color("2a3040"))


static func _ring(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	# The crowd in the dark, then the apron, then the mat.
	Dot.rect(cv, ctx.canvas, Color("120c1a"))
	for p in Kit.scatter_out(ctx, 60, ctx.u(5.0)):
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.5)), Color(1, 1, 1, ctx.rng.randf_range(0.2, 0.7)))
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall), Color("2a4ab8"), Color("142460"))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["f4f0e6", "e2dccc", "c4bca8"], p.distance_to(ctx.centre) / (ctx.full.size.x * 0.65)))
	Kit.glow(cv, ctx.centre, ctx.u(420.0), Color(1, 1, 0.92, 0.35))
	# A big logo star in the middle and scuffs.
	var star := Kit.star_pts(ctx.centre, ctx.u(150.0), ctx.u(62.0), 5)
	Kit.poly(cv, star, Color(0.85, 0.15, 0.25, 0.22))
	var loop := star.duplicate()
	loop.append(star[0])
	Dot.pline(cv, loop, Color(0.85, 0.15, 0.25, 0.45), ctx.u(4.0), true)
	for p in Kit.scatter_in(ctx, 14, ctx.u(60.0), [[ctx.centre, ctx.u(160.0)]]):
		var a := ctx.rng.randf() * TAU
		Kit.line(cv, PackedVector2Array([p, p + Vector2.from_angle(a) * ctx.u(30.0)]), Color(0.4, 0.35, 0.3, 0.15), ctx.u(6.0), ctx.outline)
	Kit.inner_shadow(cv, ctx, ctx.u(36.0), 0.35)
	# Three ropes and the corner posts with pads.
	for k in 3:
		var rope := Kit.offset(ctx.outline, ctx.wall * (0.25 + 0.27 * k))
		rope.append(rope[0])
		Dot.pline(cv, rope, Color(0, 0, 0, 0.35), ctx.u(7.0), true)
		Dot.pline(cv, rope, [Color("e8283a"), Color("ffffff"), Color("2a5ae8")][k], ctx.u(5.0), true)
	var pads := [Color("e8283a"), Color("2a5ae8")]
	var corners := Kit.offset(ctx.outline, ctx.wall * 0.5)
	for i in corners.size():
		var v := corners[i]
		Kit.shadow(cv, v, ctx.u(18.0), 0.5)
		Kit.ball(cv, v, ctx.u(16.0), Color("e8eef4"), Color("6a7484"))
		Kit.ball(cv, v, ctx.u(10.0), pads[i % 2].lightened(0.3), pads[i % 2].darkened(0.3))


static func _rink(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["2a3448", "141a26"], (p - ctx.canvas.position).y / ctx.canvas.size.y))
	for p in Kit.scatter_out(ctx, 50, ctx.u(5.0)):
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.5)), Color(1, 1, 1, ctx.rng.randf_range(0.2, 0.6)))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["ffffff", "eef6fc", "d2e4f2"], p.distance_to(ctx.at(450, 420)) / (ctx.full.size.x * 0.7)))
	for p in Kit.scatter_in(ctx, 18, ctx.u(40.0)): # Skate scratches.
		var a := ctx.rng.randf_range(-0.6, 0.6) + (PI if ctx.rng.randf() < 0.5 else 0.0)
		Dot.arc(cv, p, ctx.u(ctx.rng.randf_range(60.0, 140.0)), a, a + 0.5, 10, Color(0.6, 0.75, 0.9, 0.3), ctx.u(1.5), true)
	var c := ctx.centre
	var red := Color(0.86, 0.12, 0.2, 0.75)
	var blue := Color(0.15, 0.35, 0.85, 0.7)
	Kit.line(cv, PackedVector2Array([Vector2(ctx.full.position.x, c.y), Vector2(ctx.full.end.x, c.y)]), red, ctx.u(10.0), ctx.outline)
	for y in [330.0, 670.0]:
		Kit.line(cv, PackedVector2Array([Vector2(ctx.full.position.x, ctx.at(0, y).y), Vector2(ctx.full.end.x, ctx.at(0, y).y)]), blue, ctx.u(10.0), ctx.outline)
	for y in [110.0, 890.0]:
		Kit.line(cv, PackedVector2Array([Vector2(ctx.full.position.x, ctx.at(0, y).y), Vector2(ctx.full.end.x, ctx.at(0, y).y)]), red, ctx.u(3.0), ctx.outline)
	Kit.ring(cv, c, ctx.u(110.0), blue, ctx.u(4.0), 64)
	Kit.disc(cv, c, ctx.u(9.0), blue)
	for k in [Vector2(280, 210), Vector2(720, 210), Vector2(280, 790), Vector2(720, 790)]:
		var p := ctx.at(k.x, k.y)
		Kit.ring(cv, p, ctx.u(70.0), red, ctx.u(3.0), 48)
		Kit.disc(cv, p, ctx.u(9.0), red)
	for y in [110.0, 890.0]: # Goal creases.
		var p := ctx.at(500, y)
		var s := 1.0 if y < 500.0 else -1.0
		Dot.arc(cv, p, ctx.u(55.0), 0.0 if s > 0 else PI, PI if s > 0 else TAU, 24, red, ctx.u(3.0), true)
		Kit.poly(cv, PackedVector2Array([p + Vector2(-ctx.u(55.0), 0), p + Vector2(ctx.u(55.0), 0), p + Vector2(ctx.u(38.0), ctx.u(38.0) * s), p + Vector2(-ctx.u(38.0), ctx.u(38.0) * s)]), Color(0.3, 0.6, 1.0, 0.25))
	Kit.inner_shadow(cv, ctx, ctx.u(30.0), 0.25, Color("2a5a8a"))
	# White boards with a yellow kick plate and blue glass caps.
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall * 0.3), Color("ffd23f"), Color("e0a81a"))
	Kit.blocks(ctx, ctx.u(120.0), ctx.wall * 0.7, func(q, _e, i):
		var shift := Kit.offset(q, 0.0)
		Kit.lit(cv, shift, Color("ffffff") if i % 2 else Color("f0f4f8"), Color("a8b4c4")))
	var glass := Kit.offset(ctx.outline, ctx.wall * 0.92)
	glass.append(glass[0])
	Dot.pline(cv, glass, Color(0.5, 0.8, 1.0, 0.7), ctx.u(4.0), true)


static func _steel(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["3a3e48", "1c1e24"], (p - ctx.canvas.position).y / ctx.canvas.size.y))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["a8b0bc", "848c98", "5e6470"], p.distance_to(ctx.at(420, 380)) / (ctx.full.size.x * 0.75)))
	# Tread plate: rows of raised diagonal bumps.
	var step := ctx.u(34.0)
	var j := 0
	var y := ctx.full.position.y + step * 0.5
	var inner := Kit.offset(ctx.outline, -ctx.u(6.0))
	while y < ctx.full.end.y:
		var x := ctx.full.position.x + step * (0.5 if j % 2 else 0.0)
		while x < ctx.full.end.x:
			var p := Vector2(x, y)
			if Geometry2D.is_point_in_polygon(p, inner):
				var d := Vector2.from_angle(PI / 4.0 if (j + int(x / step)) % 2 else -PI / 4.0) * ctx.u(8.0)
				Dot.line(cv, p - d + Vector2(1, 1) * ctx.s, p + d + Vector2(1, 1) * ctx.s, Color(0, 0, 0, 0.25), ctx.u(4.0), true)
				Dot.line(cv, p - d, p + d, Color(1, 1, 1, 0.3), ctx.u(3.5), true)
			x += step
		y += step
		j += 1
	# Panel seams with rivets.
	for k in [333.0, 666.0]:
		for vertical in [true, false]:
			var a := ctx.at(k, 0.0) if vertical else ctx.at(0.0, k)
			var b := ctx.at(k, 1000.0) if vertical else ctx.at(1000.0, k)
			Kit.line(cv, PackedVector2Array([a, b]), Color(0.1, 0.12, 0.16, 0.5), ctx.u(3.0), ctx.outline)
	for p in Kit.scatter_in(ctx, 6, ctx.u(80.0), [[ctx.at(150, 850), ctx.u(140.0)], [ctx.at(850, 150), ctx.u(140.0)]]):
		Kit.poly(cv, Kit.blob(p, ctx.u(ctx.rng.randf_range(28.0, 48.0)), ctx.rng, 9, 0.3), Color(0.12, 0.1, 0.08, 0.22)) # Oil stains.
	Kit.inner_shadow(cv, ctx, ctx.u(38.0), 0.5)
	# Hazard-stripe walls.
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall), Color("ffc21f"), Color("d89a10"))
	Kit.blocks(ctx, ctx.u(26.0), ctx.wall, func(q, _e, i):
		if i % 2:
			Kit.poly(cv, q, Color("1e1e24")), ctx.u(14.0))
	var edge := Kit.offset(ctx.outline, ctx.wall)
	edge.append(edge[0])
	Dot.pline(cv, edge, Color("2a2c34"), ctx.u(4.0), true)
	var rim := ctx.outline.duplicate()
	rim.append(rim[0])
	Dot.pline(cv, rim, Color(1, 1, 1, 0.4), ctx.u(2.0), true)
	for v in Kit.offset(ctx.outline, ctx.wall * 0.5):
		Kit.ball(cv, v, ctx.u(12.0), Color("c8d0dc"), Color("3a4250"))
