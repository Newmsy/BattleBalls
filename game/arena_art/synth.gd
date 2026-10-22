## Synthwave City (sunset, alley, glitch): a striped retro sun over purple
## mountains and a pink perspective grid inside a neon tube; palms and stars
## outside. Alley is wet asphalt with puddle reflections and neon signs on
## brick; Glitch is the sunset in green and magenta with broken scanlines.
## Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["1c0838", "0d0420", "06020f"], p.distance_to(ctx.centre) / (ctx.canvas.size.x * 0.75)))
	for p in Kit.scatter_out(ctx, 40, ctx.u(4.0)):
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.2)), Color(1, 1, 1, ctx.rng.randf_range(0.3, 0.8)))
	if ctx.id == "alley":
		_alley(cv, ctx)
	else:
		_sunset(cv, ctx, ctx.id == "glitch")
		for k in [[Vector2(0.06, 0.94), 1.0], [Vector2(0.94, 0.94), -1.0], [Vector2(0.05, 0.16), 1.0], [Vector2(0.95, 0.16), -1.0]]:
			var p: Vector2 = ctx.canvas.position + ctx.canvas.size * k[0]
			if Kit.room_outside(ctx, p, ctx.u(30.0)):
				_palm(cv, ctx, p, k[1])
	Kit.inner_shadow(cv, ctx, ctx.u(34.0), 0.5)

	# The rim: a neon tube (magenta for glitch; brick and signs for alley).
	if ctx.id == "alley":
		Kit.blocks(ctx, ctx.u(30.0), ctx.wall, func(q, _e, i):
			Kit.lit(cv, q, Color("7a3040") if i % 2 else Color("6a2838"), Color("2a0e18"))
			cv.draw_line(q[1], q[2], Color(0.1, 0.03, 0.06, 0.8), ctx.u(2.0), true))
		var mid := Kit.offset(ctx.outline, ctx.wall * 0.5)
		for e in mid.size():
			var a := mid[e].lerp(mid[(e + 1) % mid.size()], 0.3)
			var b := mid[e].lerp(mid[(e + 1) % mid.size()], 0.55)
			var col := Color("ff4fd8") if e % 2 == 0 else Color("2df5ff")
			cv.draw_line(a, b, Color(col, 0.3), ctx.u(14.0), true)
			cv.draw_line(a, b, col, ctx.u(4.0), true)
		return
	var tube := Color("2df5ff") if ctx.id != "glitch" else Color("ff4fd8")
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall), Color("1a0a36"), Color("0a0418"))
	var loop := Kit.offset(ctx.outline, ctx.wall * 0.45)
	loop.append(loop[0])
	cv.draw_polyline(loop, Color(tube, 0.18), ctx.u(22.0), true)
	cv.draw_polyline(loop, Color(tube, 0.45), ctx.u(10.0), true)
	cv.draw_polyline(loop, tube.lerp(Color.WHITE, 0.6), ctx.u(4.0), true)


## A chrome post with a neon cap.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	var neon := Color("2df5ff") if ctx.id != "glitch" else Color("ff4fd8")
	Kit.shadow(cv, c, r, 0.55)
	Kit.glow(cv, c, r * 1.45, Color(neon, 0.35))
	Kit.ball(cv, c, r, Color("c8cce0"), Color("23233a"))
	Kit.ring(cv, c, r * 0.72, Color(neon, 0.45), r * 0.24)
	Kit.ring(cv, c, r * 0.72, neon.lerp(Color.WHITE, 0.5), r * 0.08)
	Kit.disc(cv, c + Vector2(-0.35, -0.4) * r, r * 0.2, Color(1, 1, 1, 0.7))


static func _sunset(cv: CanvasItem, ctx: Kit.Ctx, glitch: bool) -> void:
	var top := ctx.full.position.y
	var hy := top + ctx.full.size.y * 0.44
	var bottom := ctx.full.end.y
	var sky := ["140733", "4a1466", "c0347a"] if not glitch else ["03140c", "0a3a2a", "1fa86a"]
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(sky, (p.y - top) / (hy - top)), 8)
	for p in Kit.scatter_in(ctx, 40, ctx.u(10.0)):
		if p.y < hy - ctx.u(150.0):
			Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.0)), Color(1, 1, 1, ctx.rng.randf_range(0.4, 0.9)))
	# The striped sun, sitting on the horizon.
	var sc := Vector2(ctx.centre.x, hy - ctx.u(20.0))
	var sr := ctx.u(150.0)
	var above := PackedVector2Array([Vector2(ctx.canvas.position.x, top - ctx.u(200.0)), Vector2(ctx.canvas.end.x, top - ctx.u(200.0)), Vector2(ctx.canvas.end.x, hy), Vector2(ctx.canvas.position.x, hy)])
	var sky_clip := Geometry2D.intersect_polygons(above, ctx.outline)
	Kit.glow(cv, sc, sr * 1.6, Color(Color("ff5fa8") if not glitch else Color("4fffb0"), 0.4))
	for clip in sky_clip:
		Kit.clip_grad(cv, Kit.circle_pts(sc, sr, 48), clip, Color("fff07a") if not glitch else Color("d0ffe0"), Color("ff3d8b") if not glitch else Color("19c88a"), sc - Vector2(0, sr), sc + Vector2(0, sr))
		for k in 5:
			var y := sc.y + sr * (0.1 + k * 0.17)
			var gap := ctx.u(3.0 + k * 2.2)
			Kit.clip_poly(cv, PackedVector2Array([Vector2(sc.x - sr, y), Vector2(sc.x + sr, y), Vector2(sc.x + sr, y + gap), Vector2(sc.x - sr, y + gap)]), clip, Kit.ramp(sky, (y - top) / (hy - top)))
	# Mountains along the horizon.
	var ridge := PackedVector2Array([Vector2(ctx.full.position.x, hy)])
	var xs := [0.0, 0.08, 0.16, 0.26, 0.36, 0.45, 0.55, 0.64, 0.74, 0.84, 0.92, 1.0]
	var hs := [0.0, 50.0, 25.0, 95.0, 40.0, 110.0, 30.0, 85.0, 45.0, 100.0, 35.0, 10.0]
	for i in xs.size():
		ridge.append(Vector2(ctx.full.position.x + ctx.full.size.x * xs[i], hy - ctx.u(hs[i])))
	ridge.append(Vector2(ctx.full.end.x, hy))
	Kit.clip_grad(cv, ridge, ctx.outline, Color("5a1f7a") if not glitch else Color("0f4a3a"), Color("1a0833") if not glitch else Color("041a12"), Vector2(0, hy - ctx.u(110.0)), Vector2(0, hy))
	var crest := ridge.slice(1, ridge.size() - 1)
	Kit.line(cv, crest, Color("ff8fd0") if not glitch else Color("7cff9b"), ctx.u(2.5), ctx.outline)
	# The ground: a perspective grid running to the sun.
	var ground := PackedVector2Array([Vector2(ctx.canvas.position.x, hy), Vector2(ctx.canvas.end.x, hy), Vector2(ctx.canvas.end.x, bottom + ctx.u(50.0)), Vector2(ctx.canvas.position.x, bottom + ctx.u(50.0))])
	Kit.clip_grad(cv, ground, ctx.outline, Color("2a0a4a") if not glitch else Color("06281a"), Color("0d0420") if not glitch else Color("020a06"), Vector2(0, hy), Vector2(0, bottom))
	var glow_col := Color("ff9fd0") if not glitch else Color("7cffb0")
	Kit.clip_grad(cv, PackedVector2Array([Vector2(sc.x - sr * 0.8, hy), Vector2(sc.x + sr * 0.8, hy), Vector2(sc.x + sr * 0.5, hy + ctx.u(220.0)), Vector2(sc.x - sr * 0.5, hy + ctx.u(220.0))]), ctx.outline, Color(glow_col, 0.45), Color(glow_col, 0.0), Vector2(0, hy), Vector2(0, hy + ctx.u(220.0)))
	var grid := Color("ff4fd8") if not glitch else Color("39ff8a")
	var x := ctx.full.position.x - ctx.full.size.x
	while x <= ctx.full.end.x + ctx.full.size.x:
		var seg := PackedVector2Array([Vector2(ctx.centre.x + (x - ctx.centre.x) * 0.2, hy), Vector2(x, bottom + ctx.u(40.0))])
		Kit.line(cv, seg, Color(grid, 0.25), ctx.u(7.0), ctx.outline)
		Kit.line(cv, seg, grid, ctx.u(2.2), ctx.outline)
		x += ctx.u(70.0)
	for k in range(1, 9):
		var y := hy + (bottom - hy) * pow(k / 8.0, 1.8)
		var seg := PackedVector2Array([Vector2(ctx.canvas.position.x, y), Vector2(ctx.canvas.end.x, y)])
		Kit.line(cv, seg, Color(grid, 0.25), ctx.u(7.0), ctx.outline)
		Kit.line(cv, seg, grid, ctx.u(2.2), ctx.outline)
	Kit.line(cv, PackedVector2Array([Vector2(ctx.canvas.position.x, hy), Vector2(ctx.canvas.end.x, hy)]), Color(1.0, 0.85, 0.95, 0.9), ctx.u(3.0), ctx.outline)
	if glitch: # Scanlines and a few broken bars.
		var y := top
		while y < bottom:
			Kit.clip_poly(cv, PackedVector2Array([Vector2(ctx.full.position.x, y), Vector2(ctx.full.end.x, y), Vector2(ctx.full.end.x, y + ctx.u(2.0)), Vector2(ctx.full.position.x, y + ctx.u(2.0))]), ctx.outline, Color(0, 0, 0, 0.18))
			y += ctx.u(9.0)
		for _i in 7:
			var by := ctx.rng.randf_range(top, bottom)
			var bx := ctx.rng.randf_range(ctx.full.position.x, ctx.full.end.x - ctx.u(200.0))
			var bar := Kit.rect_pts(Vector2(bx + ctx.u(100.0), by), Vector2(ctx.u(ctx.rng.randf_range(80.0, 220.0)), ctx.u(ctx.rng.randf_range(5.0, 14.0))))
			Kit.clip_poly(cv, bar, ctx.outline, Color(Color("ff4fd8") if ctx.rng.randf() < 0.5 else Color("39ff8a"), 0.3))


static func _alley(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var light := ctx.at(500.0, 380.0)
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["3a3150", "26203a", "15101f"], p.distance_to(light) / (ctx.full.size.x * 0.7)))
	for p in Kit.scatter_in(ctx, 260, ctx.u(4.0)): # Grit.
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.2)), Color(1, 1, 1, 0.06) if ctx.rng.randf() < 0.5 else Color(0, 0, 0, 0.25))
	# Painted lane lines, worn.
	for x in [333.0, 667.0]:
		var y := 40.0
		while y < 960.0:
			Kit.clip_poly(cv, Kit.rect_pts(ctx.at(x, y + 25.0), Vector2(ctx.u(8.0), ctx.u(50.0))), ctx.outline, Color(1.0, 0.85, 0.3, 0.35))
			y += 100.0
	# Puddles with neon reflections.
	var keep := []
	for o in ctx.obstacles:
		keep.append([o.pos, o.radius * 1.5])
	for p in Kit.scatter_in(ctx, 5, ctx.u(80.0), keep):
		var r := ctx.u(ctx.rng.randf_range(40.0, 70.0))
		var puddle := Kit.blob(p, r, ctx.rng, 9, 0.3)
		for i in puddle.size():
			puddle[i] = p + (puddle[i] - p) * Vector2(1.0, 0.6)
		Kit.lit(cv, puddle, Color("2a2a5a"), Color("0a0a1a"))
		var col := Color("ff4fd8") if ctx.rng.randf() < 0.5 else Color("2df5ff")
		cv.draw_line(p + Vector2(-r * 0.3, -r * 0.35), p + Vector2(-r * 0.3, r * 0.35), Color(col, 0.5), ctx.u(8.0), true)
		cv.draw_line(p + Vector2(r * 0.15, -r * 0.3), p + Vector2(r * 0.15, r * 0.3), Color(col, 0.3), ctx.u(5.0), true)
	# A manhole cover.
	var mh := ctx.at(500.0, 640.0)
	Kit.ball(cv, mh, ctx.u(38.0), Color("4a4a5a"), Color("1a1a24"))
	for k in 4:
		cv.draw_line(mh + Vector2(-ctx.u(26.0), ctx.u(-18.0 + k * 12.0)), mh + Vector2(ctx.u(26.0), ctx.u(-18.0 + k * 12.0)), Color(0, 0, 0, 0.4), ctx.u(3.0), true)


static func _palm(cv: CanvasItem, ctx: Kit.Ctx, base: Vector2, flip: float) -> void:
	var col := Color("12051f")
	var top := base + Vector2(ctx.u(10.0) * flip, -ctx.u(110.0))
	var trunk := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		trunk.append(base.lerp(top, t) + Vector2(sin(t * PI) * ctx.u(14.0) * flip, 0))
	cv.draw_polyline(trunk, col, ctx.u(9.0), true)
	for k in [[-50.0, 20.0], [-34.0, 38.0], [44.0, 24.0], [30.0, 42.0], [6.0, -32.0]]:
		var tip: Vector2 = top + Vector2(k[0] * flip, k[1]) * ctx.s
		var mid := top.lerp(tip, 0.5) + Vector2(0, -ctx.u(16.0))
		cv.draw_polyline(PackedVector2Array([top, mid, tip]), col, ctx.u(7.0), true)
