## Critter Plunge backdrops: a wash and a motif painted over a course's arena
## art (game/arena_art.gd) when the floor is baked, so courses whose arenas
## share a family's painting still look like different places (Newms: no two
## courses with the same background). Everything stays inside the floor
## square, clear of its trimmed top and bottom, so the square tiles down the
## shaft. Render-only, painted once per course.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx, course_id: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("plunge backdrop " + course_id)
	match course_id:
		"vines": _vines(cv, ctx, rng)
		"rocks": _craters(cv, ctx, rng)
		"kelp": _kelp(cv, ctx, rng)
		"trench": _deep(cv, ctx, rng)
		"icicles": _snow(cv, ctx, rng)
		"crystal": _shards(cv, ctx, rng)
		"toys": _playroom(cv, ctx, rng)


## A point inside the square, clear of its trimmed top and bottom.
static func _spot(ctx: Kit.Ctx, rng: RandomNumberGenerator, pad := 60.0) -> Vector2:
	return ctx.at(rng.randf_range(pad, 1000.0 - pad), rng.randf_range(110.0 + pad, 890.0 - pad))


static func _wash(cv: CanvasItem, ctx: Kit.Ctx, col: Color) -> void:
	cv.draw_rect(ctx.full, col)


## Vine Ruins: a green, overgrown cast and vines hanging down the stones.
static func _vines(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(0.15, 0.45, 0.12, 0.22))
	for k in 7:
		var x := 70.0 + k * 143.0 + rng.randf_range(-30.0, 30.0)
		var pts := PackedVector2Array()
		var span := rng.randf_range(380.0, 700.0)
		var y := 110.0
		while y < 110.0 + span:
			pts.append(ctx.at(x + 18.0 * sin(y * 0.02 + k), y))
			y += 20.0
		Kit.line(cv, pts, Color("2f5a1c"), ctx.u(7.0))
		Kit.line(cv, pts, Color("4f8a2c"), ctx.u(3.0))
		for j in range(2, pts.size(), 3):
			var side := 1.0 if j % 2 == 0 else -1.0
			Kit.poly(cv, Kit.blob(pts[j] + Vector2(ctx.u(12.0) * side, 0.0), ctx.u(rng.randf_range(9.0, 14.0)), rng, 6, 0.3), Color("5f9e34", 0.9))


## Rock Belt: rusty dust and craters.
static func _craters(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(0.55, 0.28, 0.1, 0.24))
	for k in 9:
		var c := _spot(ctx, rng, 80.0)
		var r := ctx.u(rng.randf_range(28.0, 70.0))
		Kit.disc(cv, c, r, Color(0.12, 0.06, 0.04, 0.4))
		Kit.disc(cv, c + Vector2(r, r) * 0.12, r * 0.8, Color(0.25, 0.13, 0.07, 0.35))
		Kit.ring(cv, c, r, Color(0.85, 0.55, 0.32, 0.45), ctx.u(4.0))


## Kelp Forest: a green cast and tall fronds swaying up from below.
static func _kelp(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(0.1, 0.4, 0.15, 0.2))
	for k in 6:
		var x := 90.0 + k * 165.0 + rng.randf_range(-25.0, 25.0)
		var pts := PackedVector2Array()
		var y := 890.0
		var top := rng.randf_range(160.0, 420.0)
		while y > top:
			pts.append(ctx.at(x + 22.0 * sin(y * 0.015 + k * 1.3), y))
			y -= 22.0
		Kit.line(cv, pts, Color("1f6a3a", 0.85), ctx.u(10.0))
		for j in range(1, pts.size(), 2):
			var side := 1.0 if j % 4 == 1 else -1.0
			Kit.poly(cv, Kit.blob(pts[j] + Vector2(ctx.u(16.0) * side, 0.0), ctx.u(13.0), rng, 5, 0.4), Color("2f8a4a", 0.8))


## Deep Trench: near-black water lit by glowing specks.
static func _deep(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(0.0, 0.02, 0.1, 0.5))
	for k in 40:
		var c := _spot(ctx, rng, 30.0)
		var r := ctx.u(rng.randf_range(2.5, 6.0))
		var col := Color("5ff6ff") if rng.randf() < 0.7 else Color("c58bff")
		Kit.disc(cv, c, r * 3.0, Color(col, 0.12))
		Kit.disc(cv, c, r, Color(col, 0.8))


## Icicle Run: snowflakes on the ice.
static func _snow(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(0.85, 0.95, 1.0, 0.12))
	for k in 14:
		var c := _spot(ctx, rng, 50.0)
		var r := ctx.u(rng.randf_range(16.0, 34.0))
		var rot := rng.randf() * PI
		for a in 3:
			var d := Vector2.from_angle(rot + a * PI / 3.0) * r
			Kit.line(cv, PackedVector2Array([c - d, c + d]), Color(1, 1, 1, 0.55), ctx.u(3.0))
			for side in [-1.0, 1.0]:
				var tip: Vector2 = c + d * 0.6 * side
				var arm := Vector2.from_angle(rot + a * PI / 3.0 + 0.6) * r * 0.25
				Kit.line(cv, PackedVector2Array([tip, tip + arm * side]), Color(1, 1, 1, 0.45), ctx.u(2.0))


## Crystal Cave: a violet cast and crystal clusters growing out of the rock.
static func _shards(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(0.45, 0.15, 0.65, 0.26))
	for k in 10:
		var base := _spot(ctx, rng, 70.0)
		for j in 3:
			var rot := rng.randf_range(-0.7, 0.7) - PI / 2.0
			var span := ctx.u(rng.randf_range(40.0, 80.0))
			var w := span * 0.22
			var dir := Vector2.from_angle(rot)
			var side := dir.orthogonal() * w
			var shard := PackedVector2Array([base - side, base + dir * span * 0.8 - side, base + dir * span, base + dir * span * 0.8 + side, base + side])
			Kit.poly(cv, shard, Color("b98cff", 0.55))
			Kit.line(cv, PackedVector2Array([base, base + dir * span]), Color(1, 1, 1, 0.4), ctx.u(2.0))


## Toy Chest: a warm playroom cast with toy blocks and stars strewn about.
static func _playroom(cv: CanvasItem, ctx: Kit.Ctx, rng: RandomNumberGenerator) -> void:
	_wash(cv, ctx, Color(1.0, 0.62, 0.25, 0.22))
	var cols := [Color("ff5d73"), Color("ffd166"), Color("4cc9f0"), Color("7ae582")]
	for k in 12:
		var c := _spot(ctx, rng, 60.0)
		var col: Color = cols[k % cols.size()]
		if k % 3 == 2:
			Kit.poly(cv, Kit.star_pts(c, ctx.u(26.0), ctx.u(11.0), 5, rng.randf() * TAU), Color(col, 0.55))
		else:
			var size := ctx.u(rng.randf_range(34.0, 52.0))
			Kit.poly(cv, Kit.rect_pts(c, Vector2(size, size), rng.randf() * TAU), Color(col, 0.5))
