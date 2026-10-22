## Deep Space (nebula, asteroid, wells, horizon, orbit, starfall): a
## starfield with nebula clouds inside a riveted hull ring with running
## lights, a ringed planet nearby and cratered asteroids for pillars. Each
## map gets its own nebula colours and planet. Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")

## Per map: two nebula colours, the planet's light and dark, its ring.
const LOOKS := {
	"nebula": ["b14bff", "21c7ff", "ffb46b", "8a3a1a", "ffd59a"],
	"asteroid": ["ff7a3d", "2fd6c8", "9fd8ff", "2a5a9a", "e8f6ff"],
	"wells": ["7a3cff", "ff4fd8", "c9ff8a", "3a7a2a", "efffd0"],
	"horizon": ["ff4fa8", "7a3cff", "ffd166", "b8601f", "ffe9b0"],
	"orbit": ["3c7aff", "8a4bff", "ff8a8a", "8a2a3a", "ffd0d0"],
	"starfall": ["ffb84d", "5a3cff", "b8e0ff", "3a5a9a", "ffffff"],
}


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var look: Array = LOOKS.get(ctx.id, LOOKS.nebula)
	var reach := ctx.canvas.size.x * 0.75
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["10123a", "070822", "03030f"], p.distance_to(ctx.centre) / reach))
	for _i in 140:
		var p := Vector2(ctx.rng.randf_range(ctx.canvas.position.x, ctx.canvas.end.x), ctx.rng.randf_range(ctx.canvas.position.y, ctx.canvas.end.y))
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.6)), Color(1, 1, 1, ctx.rng.randf_range(0.3, 0.9)))

	# The floor: deep space with two nebula clouds and its own stars.
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["181a4a", "0c0d2e", "06071c"], p.distance_to(ctx.centre) / (ctx.full.size.x * 0.6)))
	var c1 := ctx.at(330.0, 340.0)
	var c2 := ctx.at(680.0, 660.0)
	for k in 3:
		_cloud(cv, ctx, c1 + Vector2(ctx.rng.randf_range(-120, 120), ctx.rng.randf_range(-120, 120)) * ctx.s, ctx.u(260.0 - k * 50.0), Color(look[0]), 0.28)
		_cloud(cv, ctx, c2 + Vector2(ctx.rng.randf_range(-120, 120), ctx.rng.randf_range(-120, 120)) * ctx.s, ctx.u(250.0 - k * 50.0), Color(look[1]), 0.24)
	for p in Kit.scatter_in(ctx, 150, ctx.u(8.0)):
		var big := ctx.rng.randf() < 0.07
		Kit.disc(cv, p, ctx.u(4.0 if big else ctx.rng.randf_range(1.0, 2.2)), Color(1, 1, 1, ctx.rng.randf_range(0.35, 0.95)))
		if big: # A sparkle.
			cv.draw_line(p - Vector2(ctx.u(11.0), 0), p + Vector2(ctx.u(11.0), 0), Color(1, 1, 1, 0.6), ctx.u(1.5), true)
			cv.draw_line(p - Vector2(0, ctx.u(11.0)), p + Vector2(0, ctx.u(11.0)), Color(1, 1, 1, 0.6), ctx.u(1.5), true)
	# A planet: out in the corner when there's room, else far off on the floor.
	var corner := ctx.canvas.position + Vector2(ctx.u(70.0), ctx.u(70.0))
	if Kit.room_outside(ctx, corner, ctx.u(40.0)):
		_planet(cv, ctx, corner, ctx.u(62.0), look, 1.0)
	else:
		_planet(cv, ctx, ctx.at(150.0, 140.0), ctx.u(48.0), look, 0.55)
	Kit.inner_shadow(cv, ctx, ctx.u(34.0), 0.5)

	# The hull: riveted plates, an inner light strip and running lights.
	Kit.blocks(ctx, ctx.u(64.0), ctx.wall, func(q, _e, i):
		Kit.lit(cv, q, Color("56608a") if i % 2 else Color("4c5580"), Color("232842"))
		cv.draw_line(q[1], q[2], Color(0.08, 0.09, 0.18, 0.8), ctx.u(2.0), true))
	for p in Kit.along(ctx.outline, ctx.wall * 0.72, ctx.u(15.0)):
		Kit.disc(cv, p, ctx.u(2.2), Color("a9b2d6"))
	var n := 0
	for p in Kit.along(ctx.outline, ctx.wall * 0.32, ctx.u(70.0)):
		var col := Color("7cf9ff") if n % 2 == 0 else Color("ff6bd6")
		Kit.glow(cv, p, ctx.u(16.0), Color(col, 0.6))
		Kit.disc(cv, p, ctx.u(4.0), col)
		n += 1
	var edge := ctx.outline.duplicate()
	edge.append(edge[0])
	cv.draw_polyline(edge, Color(0.49, 0.98, 1.0, 0.25), ctx.u(7.0), true)
	cv.draw_polyline(edge, Color("7cf9ff"), ctx.u(2.5), true)


## A cratered asteroid.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.shadow(cv, c, r, 0.55)
	var rock := Kit.blob(c, r, ctx.rng, 9, 0.16)
	Kit.lit(cv, rock, Color("9a96ae"), Color("34324a"))
	for k in [[Vector2(-0.3, -0.2), 0.24], [Vector2(0.32, 0.25), 0.17], [Vector2(0.15, -0.42), 0.11], [Vector2(-0.25, 0.42), 0.13]]:
		var at: Vector2 = c + k[0] * r
		var cr: float = k[1] * r
		Kit.disc(cv, at, cr, Color("4a4760"))
		cv.draw_arc(at, cr, 0.4, 2.6, 12, Color(1, 1, 1, 0.25), maxf(1.0, cr * 0.18), true)
	var rim := rock.duplicate()
	rim.append(rock[0])
	cv.draw_polyline(rim, Color(0.1, 0.1, 0.18, 0.7), maxf(1.0, r * 0.05), true)


static func _cloud(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float, col: Color, a: float) -> void:
	# Only the part over the floor; the glow is soft, so clip by keeping it
	# a mesh fanned inside the outline.
	var reach := r
	Kit.floor_fill(cv, ctx, func(p): return Color(col, a * clampf(1.0 - p.distance_to(c) / reach, 0.0, 1.0) * clampf(1.0 - p.distance_to(c) / reach, 0.0, 1.0)), 10)


static func _planet(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float, look: Array, a: float) -> void:
	var ring_col := Color(look[4], 0.75 * a)
	var tilt := -0.35
	var back := PackedVector2Array()
	var front := PackedVector2Array()
	for i in 41:
		var t := PI + i * PI / 40.0
		back.append(c + Vector2(cos(t) * r * 1.7, sin(t) * r * 0.32).rotated(tilt))
		front.append(c + Vector2(cos(t - PI) * r * 1.7, sin(t - PI) * r * 0.32).rotated(tilt))
	cv.draw_polyline(back, ring_col, r * 0.12, true)
	Kit.glow(cv, c, r * 1.4, Color(look[2], 0.18 * a))
	Kit.ball(cv, c, r, Color(look[2], a), Color(look[3], a))
	for k in 3:
		var band := PackedVector2Array()
		for i in 21:
			var x := -0.85 + i * 0.085
			band.append(c + Vector2(x, -0.3 + k * 0.28 + 0.05 * sin(i)) * r)
		cv.draw_polyline(band, Color(1, 1, 1, 0.12 * a), r * 0.1, true)
	cv.draw_polyline(front, ring_col, r * 0.12, true)
