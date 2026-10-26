## Ocean Floor (kelp, trench, reef): a sunlit seabed with light rays and
## caustics, a reef rim of coral, sea fans and anemones, kelp on rocks for
## pillars, shells and starfish, fish and bubbles outside. Trench is deeper
## and bluer. Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var deep := ctx.id == "trench"
	var reach := ctx.canvas.size.x * 0.8
	var top := ctx.canvas.position + Vector2(ctx.canvas.size.x * 0.5, 0.0)
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["1aa0c0", "0a5a80", "042238"], p.distance_to(top) / reach))
	for p in Kit.scatter_out(ctx, 10, ctx.u(14.0)):
		_fish(cv, ctx, p)
	for p in Kit.scatter_out(ctx, 18, ctx.u(6.0)):
		Dot.arc(cv, p, ctx.u(ctx.rng.randf_range(3.0, 7.0)), 0.0, TAU, 16, Color(0.85, 0.97, 1.0, 0.7), ctx.u(1.5), true)

	# The seabed: sunlit in the middle, fading to teal at the edges.
	var light := ctx.at(450.0, 380.0)
	var stops := ["f6e6c0", "e8d2a2", "d2ba8a", "8fa898"] if not deep else ["cfe0d8", "a9c4c0", "7fa4ac", "41687e"]
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(stops, p.distance_to(light) / (ctx.full.size.x * 0.72)))
	var ripple := Color(0.5, 0.38, 0.2, 0.25) if not deep else Color(0.15, 0.3, 0.4, 0.25)
	var y := ctx.full.position.y + ctx.u(30.0)
	while y < ctx.full.end.y:
		var wave := PackedVector2Array()
		for i in 41:
			var x := ctx.full.position.x + ctx.full.size.x * i / 40.0
			wave.append(Vector2(x, y + sin(i * 0.9 + y * 0.05) * ctx.u(6.0)))
		Kit.line(cv, wave, ripple, ctx.u(2.0), ctx.outline)
		y += ctx.u(36.0)
	# Caustics: wobbly light loops across the sand.
	var cell := ctx.u(90.0)
	var gy := ctx.full.position.y
	while gy < ctx.full.end.y:
		var gx := ctx.full.position.x
		while gx < ctx.full.end.x:
			var c := Vector2(gx, gy) + Vector2(ctx.rng.randf_range(0.2, 0.8), ctx.rng.randf_range(0.2, 0.8)) * cell
			var loop := Kit.blob(c, cell * 0.36, ctx.rng, 6, 0.3)
			loop.append(loop[0])
			Kit.line(cv, loop, Color(1, 1, 1, 0.13), ctx.u(2.0), ctx.outline)
			gx += cell
		gy += cell
	# Light rays slanting down from the surface.
	for k in [[0.05, 0.06, 0.32], [0.3, 0.035, 0.22], [0.52, 0.07, 0.3], [0.78, 0.03, 0.2]]:
		var x0: float = ctx.full.position.x + ctx.full.size.x * k[0]
		var w: float = ctx.full.size.x * k[1]
		var drop := ctx.full.size.x * 0.4
		var ray := PackedVector2Array([Vector2(x0, ctx.full.position.y), Vector2(x0 + w, ctx.full.position.y), Vector2(x0 + w + drop, ctx.full.end.y), Vector2(x0 + drop, ctx.full.end.y)])
		Kit.clip_grad(cv, ray, ctx.outline, Color(1, 1, 1, k[2]), Color(1, 1, 1, 0.0), ctx.full.position, Vector2(ctx.full.position.x, ctx.full.end.y))
	# Shells, starfish and pebbles near the edges, clear of the pillars.
	var keep := []
	for o in ctx.obstacles:
		keep.append([o.pos, o.radius * 1.6])
	keep.append([ctx.centre, ctx.full.size.x * 0.3])
	var spots := Kit.scatter_in(ctx, 9, ctx.u(40.0), keep)
	for i in spots.size():
		match i % 3:
			0: _star(cv, ctx, spots[i], ctx.u(15.0))
			1: _shell(cv, ctx, spots[i], ctx.u(14.0))
			_: Kit.ball(cv, spots[i], ctx.u(6.0), Color("d8c8b0"), Color("8a7a66"))
	Kit.inner_shadow(cv, ctx, ctx.u(40.0), 0.45)

	# The reef rim: dark rock studded with coral.
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall), Color("4a3d5c"), Color("221a30"))
	var n := 0
	for p in Kit.along(ctx.outline, ctx.wall * 0.55, ctx.u(30.0)):
		var r := ctx.wall * ctx.rng.randf_range(0.42, 0.55)
		match n % 4:
			0: _brain(cv, p, r, Color("ff8f7a"), Color("c9533f"))
			1: _fan(cv, ctx, p, r * 1.3, [Color("b48cff"), Color("ff7bbd")][ctx.rng.randi() % 2])
			2: _anemone(cv, p, r, [Color("ffb84d"), Color("ff6f91"), Color("5fe0c8")][ctx.rng.randi() % 3])
			_: _brain(cv, p, r * 0.85, Color("ffd27a"), Color("c99439"))
		n += 1


## Kelp on a rock, its leaves fanning out.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.shadow(cv, c, r * 1.3, 0.4)
	Kit.lit(cv, Kit.blob(c, r * 0.8, ctx.rng, 8, 0.15), Color("9aa09a"), Color("3a4240"))
	for i in 7:
		var a := i * TAU / 7.0 + 0.3
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal()
		var leaf := PackedVector2Array()
		for k in 9:
			var t := k / 8.0
			leaf.append(c + dir * r * (0.3 + 1.15 * t) + side * r * 0.22 * sin(t * PI) + side * r * 0.12 * sin(t * 5.0))
		for k in range(8, -1, -1):
			var t := k / 8.0
			leaf.append(c + dir * r * (0.3 + 1.15 * t) - side * r * 0.12 * sin(t * PI) + side * r * 0.12 * sin(t * 5.0))
		Kit.grad(cv, leaf, Color("7ee89a"), Color("2a8a4a"), c, c + dir * r * 1.4)
	for i in 7:
		Kit.ball(cv, c + Vector2.from_angle(i * TAU / 7.0 + 0.55) * r * 0.62, r * 0.1, Color("d8ffb8"), Color("6ab84a"))


static func _fish(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2) -> void:
	var dir := 1.0 if ctx.rng.randf() < 0.5 else -1.0
	var s := ctx.u(ctx.rng.randf_range(7.0, 11.0))
	var col: Color = [Color("ffd166"), Color("ff8a5c"), Color("8ae0ff")][ctx.rng.randi() % 3]
	for k in 3:
		var at := p + Vector2(k * s * 2.6 * dir, (k % 2) * s * 1.4)
		Kit.poly(cv, Kit.circle_pts(at, s, 14, 0.5), col)
		Kit.poly(cv, PackedVector2Array([at - Vector2(s * 0.8 * dir, 0), at - Vector2(s * 1.6 * dir, -s * 0.6), at - Vector2(s * 1.6 * dir, s * 0.6)]), col.darkened(0.15))
		Kit.disc(cv, at + Vector2(s * 0.5 * dir, -s * 0.1), s * 0.15, Color("1a2030"))


static func _brain(cv: CanvasItem, c: Vector2, r: float, col: Color, line_col: Color) -> void:
	Kit.disc(cv, c + Vector2(r, r) * 0.15, r * 1.05, Color(0, 0, 0, 0.3))
	Kit.ball(cv, c, r, col.lightened(0.2), col.darkened(0.2))
	for k in [-0.45, 0.0, 0.45]:
		var wav := PackedVector2Array()
		for i in 9:
			var x := -0.7 + i * 0.175
			wav.append(c + Vector2(x, k + 0.12 * sin(i * 1.8)) * r)
		Dot.pline(cv, wav, line_col, maxf(1.0, r * 0.1), true)


static func _fan(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float, col: Color) -> void:
	var rot := ctx.rng.randf() * TAU
	var fan := PackedVector2Array([c])
	for i in 11:
		fan.append(c + Vector2.from_angle(rot - 0.8 + i * 0.16) * r)
	Kit.grad(cv, fan, col.darkened(0.25), col.lightened(0.2), c, c + Vector2.from_angle(rot) * r)
	for i in 5:
		Dot.line(cv, c, c + Vector2.from_angle(rot - 0.64 + i * 0.32) * r * 0.95, Color(1, 1, 1, 0.4), maxf(1.0, r * 0.05), true)


static func _anemone(cv: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	for i in 12:
		var a := i * TAU / 12.0
		Dot.line(cv, c, c + Vector2.from_angle(a) * r * 1.1, col, r * 0.28, true)
		Kit.disc(cv, c + Vector2.from_angle(a) * r * 1.1, r * 0.16, col.lightened(0.3))
	Kit.ball(cv, c, r * 0.5, col.lightened(0.3), col.darkened(0.3))


static func _star(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	var pts := Kit.star_pts(c, r, r * 0.42, 5, ctx.rng.randf() * TAU)
	Kit.shadow(cv, c, r * 0.8, 0.3)
	Kit.lit(cv, pts, Color("ffa66b"), Color("d4541c"))
	for i in 5:
		Kit.disc(cv, c.lerp(pts[i * 2], 0.55), r * 0.08, Color(1, 0.9, 0.7, 0.8))


static func _shell(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	var rot := ctx.rng.randf_range(-0.6, 0.6)
	var fan := PackedVector2Array([c + Vector2(0, r * 0.5).rotated(rot)])
	for i in 13:
		fan.append(c + Vector2.from_angle(PI + 0.2 + i * (PI - 0.4) / 12.0 + rot) * r)
	Kit.lit(cv, fan, Color("fff0e0"), Color("e0a080"))
	for i in 5:
		Dot.line(cv, fan[0], c + Vector2.from_angle(PI + 0.5 + i * 0.55 + rot) * r * 0.95, Color("c98060"), maxf(1.0, r * 0.08), true)
