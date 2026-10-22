## Frozen Caves (frost, prism): glossy pale-blue ice with a deep fissure
## under the surface, white cracks, frozen bubbles and sheen, snow drifts and
## icicles along the walls, stacked ice-block walls, crystal pillars, a dark
## cave outside. Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var reach := ctx.canvas.size.x * 0.75
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["2c4c78", "18304e", "0b1628"], p.distance_to(ctx.centre) / reach))
	for p in Kit.scatter_out(ctx, 50, ctx.u(4.0)):
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.5, 3.5)), Color(1, 1, 1, 0.8))

	var light := ctx.at(470.0, 420.0)
	var stops := ["eefaff", "c7e8f8", "9fcde9", "6fa8d2"] if ctx.id != "prism" else ["f4f0ff", "d2e2fa", "a9c4ee", "7a90d8"]
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(stops, p.distance_to(light) / (ctx.full.size.x * 0.7)))
	# A deep fissure under the ice.
	var fissure := PackedVector2Array()
	for i in 41:
		var t := i / 40.0
		fissure.append(ctx.at(120.0 + 760.0 * t, 860.0 - 720.0 * t) + Vector2(sin(t * 7.0), cos(t * 5.0)) * ctx.u(40.0))
	Kit.line(cv, fissure, Color(0.16, 0.42, 0.68, 0.22), ctx.u(34.0), ctx.outline)
	Kit.line(cv, fissure, Color(0.08, 0.28, 0.52, 0.35), ctx.u(12.0), ctx.outline)
	Kit.line(cv, fissure, Color(1, 1, 1, 0.5), ctx.u(2.0), ctx.outline)
	# Cracks, frozen bubbles and a couple of glossy sheens.
	for p in Kit.scatter_in(ctx, 10, ctx.u(60.0), [[ctx.centre, ctx.u(90.0)]]):
		var pts := PackedVector2Array([p])
		for _k in 3:
			pts.append(pts[pts.size() - 1] + Vector2.from_angle(ctx.rng.randf() * TAU) * ctx.u(ctx.rng.randf_range(16.0, 34.0)))
		Kit.line(cv, pts, Color(1, 1, 1, 0.85), ctx.u(1.8), ctx.outline)
		Kit.line(cv, PackedVector2Array([pts[1], pts[1] + Vector2.from_angle(ctx.rng.randf() * TAU) * ctx.u(18.0)]), Color(1, 1, 1, 0.7), ctx.u(1.4), ctx.outline)
	for p in Kit.scatter_in(ctx, 26, ctx.u(30.0)):
		var r := ctx.u(ctx.rng.randf_range(3.0, 7.0))
		Kit.disc(cv, p, r, Color(1, 1, 1, 0.22))
		cv.draw_arc(p, r, 0.0, TAU, 16, Color(1, 1, 1, 0.6), ctx.u(1.0), true)
	for k in [[0.0, 0.18], [0.62, 0.12]]:
		var x0: float = ctx.full.position.x + ctx.full.size.x * k[0]
		var w: float = ctx.full.size.x * k[1]
		var band := PackedVector2Array([Vector2(x0, ctx.full.end.y), Vector2(x0 + w, ctx.full.end.y), Vector2(x0 + w + ctx.full.size.x * 0.5, ctx.full.position.y), Vector2(x0 + ctx.full.size.x * 0.5, ctx.full.position.y)])
		var mid := band[0].lerp(band[1], 0.5)
		Kit.clip_grad(cv, PackedVector2Array([band[0], mid, mid + (band[3] - band[0]), band[3]]), ctx.outline, Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.3), band[0], mid)
		Kit.clip_grad(cv, PackedVector2Array([mid, band[1], band[2], mid + (band[3] - band[0])]), ctx.outline, Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0), mid, band[1])
	Kit.inner_shadow(cv, ctx, ctx.u(30.0), 0.4, Color("0d3a66"))
	# Snow drifts, deepest along the top walls, and icicles hanging off them.
	Kit.wavy_rim(cv, ctx, ctx.u(8.0), func(t, p):
		var up := maxf(0.0, -(p - ctx.centre).normalized().y)
		return ctx.u(8.0) + ctx.u(26.0) * up * up + ctx.u(5.0) * sin(t * TAU * 29.0), Color("ffffff"), Color("eef8ff"))
	for e in ctx.outline.size():
		if Kit.edge_normal(ctx.outline, e).y > -0.6:
			continue
		var a := ctx.outline[e]
		var b := ctx.outline[(e + 1) % ctx.outline.size()]
		var n := int(a.distance_to(b) / ctx.u(34.0))
		for i in range(1, n):
			var p := a.lerp(b, float(i) / n) + Vector2(0, ctx.u(20.0))
			var length := ctx.u(ctx.rng.randf_range(10.0, 26.0))
			Kit.grad(cv, PackedVector2Array([p - Vector2(ctx.u(5.0), 0), p + Vector2(ctx.u(5.0), 0), p + Vector2(0, length)]), Color("ffffff"), Color("bfe8ff"), p, p + Vector2(0, length))

	# Stacked ice blocks.
	Kit.blocks(ctx, ctx.u(50.0), ctx.wall, func(q, _e, i):
		Kit.lit(cv, q, Color("e8f8ff") if i % 2 else Color("d6f0ff"), Color("7fbfe0"))
		var loop: PackedVector2Array = q.duplicate()
		loop.append(q[0])
		cv.draw_polyline(loop, Color("6fb4dc"), ctx.u(2.0), true)
		cv.draw_line(q[0].lerp(q[3], 0.3) + (q[1] - q[0]) * 0.1, q[0].lerp(q[3], 0.3) + (q[1] - q[0]) * 0.5, Color(1, 1, 1, 0.8), ctx.u(3.0), true))


## A cluster of ice crystals.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.glow(cv, c, r * 1.4, Color(0.5, 0.88, 1.0, 0.35))
	Kit.shadow(cv, c, r, 0.35)
	for k in [[Vector2(-0.55, 0.2), 0.55, -0.4], [Vector2(0.55, 0.25), 0.5, 0.45], [Vector2(0.0, 0.0), 0.9, 0.0]]:
		var base: Vector2 = c + k[0] * r
		var h: float = k[1] * r * 1.6
		var tilt: float = k[2]
		var gem := PackedVector2Array([base + Vector2(0, -h).rotated(tilt), base + Vector2(r * 0.28, -h * 0.55).rotated(tilt), base + Vector2(r * 0.2, h * 0.35).rotated(tilt), base + Vector2(-r * 0.2, h * 0.35).rotated(tilt), base + Vector2(-r * 0.28, -h * 0.55).rotated(tilt)])
		Kit.lit(cv, gem, Color("e8fbff"), Color("3fa8e0"))
		Kit.poly(cv, PackedVector2Array([gem[0], gem[2].lerp(gem[3], 0.5), gem[3], gem[4]]), Color(1, 1, 1, 0.35))
