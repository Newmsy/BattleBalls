## Haunted (graveyard, manor, arcane): moonlit grass with a flagstone path,
## fog and fireflies inside a spiked iron fence, tombstones for pillars, a
## full moon, bare trees and jack-o'-lanterns outside. Manor moves indoors
## (floorboards, a red rug, panelled walls, candles); Arcane is a wizard's
## tower (slate and a glowing rune circle). Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["2a1f4a", "171230", "0a0814"], (p - ctx.canvas.position).dot(Vector2.ONE) / ctx.canvas.size.dot(Vector2.ONE)))
	for p in Kit.scatter_out(ctx, 40, ctx.u(4.0)):
		Kit.disc(cv, p, ctx.u(ctx.rng.randf_range(1.0, 2.0)), Color(1, 1, 1, ctx.rng.randf_range(0.3, 0.8)))
	match ctx.id:
		"manor":
			_manor(cv, ctx)
		"arcane":
			_arcane(cv, ctx)
		_:
			_graveyard(cv, ctx)


## A tombstone (manor: a marble bust plinth; arcane: a crystal orb).
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	if ctx.id == "arcane":
		Kit.glow(cv, c, r * 1.6, Color(0.6, 0.4, 1.0, 0.45))
		Kit.shadow(cv, c, r, 0.5)
		Kit.ball(cv, c, r, Color("6a6488"), Color("1e1a30"))
		Kit.ball(cv, c, r * 0.62, Color("f0e0ff"), Color("7a3cff"))
		Kit.disc(cv, c + Vector2(-0.22, -0.25) * r, r * 0.16, Color(1, 1, 1, 0.8))
		return
	if ctx.id == "manor":
		Kit.shadow(cv, c, r, 0.55)
		Kit.ball(cv, c, r, Color("f4f0ea"), Color("8a8494"))
		Kit.ring(cv, c, r * 0.82, Color("d9a54a"), r * 0.1)
		Kit.ball(cv, c, r * 0.45, Color("ffffff"), Color("b8b0c0"))
		return
	# Moonlight from the top right throws a long shadow down to the left.
	var sh := PackedVector2Array([c + Vector2(-0.6, 0.6) * r, c + Vector2(0.6, 0.2) * r, c + Vector2(-0.4, 1.5) * r, c + Vector2(-1.5, 1.6) * r])
	Kit.poly(cv, Kit.smooth(sh, 2), Color(0, 0, 0, 0.4))
	var slab := PackedVector2Array()
	for i in 13:
		slab.append(c + Vector2.from_angle(PI + i * PI / 12.0) * r * 0.85 + Vector2(0, -r * 0.1))
	slab.append(c + Vector2(r * 0.85, r * 0.85))
	slab.append(c + Vector2(-r * 0.85, r * 0.85))
	Kit.lit(cv, slab, Color("c9d0e6"), Color("5a6078"))
	cv.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, r * 0.35), Color("3e4356"), r * 0.13, true)
	cv.draw_line(c + Vector2(-r * 0.32, -r * 0.2), c + Vector2(r * 0.32, -r * 0.2), Color("3e4356"), r * 0.13, true)
	Kit.poly(cv, Kit.rect_pts(c + Vector2(0, r * 0.88), Vector2(r * 2.0, r * 0.25)), Color("4a5062"))
	Kit.poly(cv, Kit.blob(c + Vector2(-0.45, 0.72) * r, r * 0.22, ctx.rng, 6, 0.3), Color("5f8a4a"))


static func _graveyard(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var moon := ctx.canvas.position + Vector2(ctx.canvas.size.x - ctx.u(64.0), ctx.u(64.0))
	var lamp := ctx.at(900.0, 100.0)
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["6a8f78", "3a5a48", "22382e", "131c1a"], p.distance_to(lamp) / (ctx.full.size.x * 1.2)))
	for p in Kit.scatter_in(ctx, 320, ctx.u(4.0)):
		var tip := p + Vector2(ctx.rng.randf_range(-ctx.u(4.0), ctx.u(4.0)), -ctx.u(ctx.rng.randf_range(8.0, 14.0)))
		cv.draw_line(p, tip, [Color("5f8a62"), Color("3a5e44"), Color("7aa070")][ctx.rng.randi() % 3], ctx.u(2.0), true)
	# A winding flagstone path.
	for i in 11:
		var t := i / 10.0
		var p := ctx.at(80.0 + 840.0 * t, 500.0 + 70.0 * sin(t * TAU))
		if not Geometry2D.is_point_in_polygon(p, Kit.offset(ctx.outline, -ctx.u(20.0))):
			continue
		var stone := Kit.blob(p, ctx.u(ctx.rng.randf_range(24.0, 30.0)), ctx.rng, 7, 0.2)
		Kit.shadow(cv, p, ctx.u(24.0), 0.3)
		Kit.lit(cv, stone, Color("a2a5b5"), Color("4f5262"))
	for k in [[230, 230, 170], [720, 380, 150], [300, 760, 190], [770, 800, 130]]:
		Kit.glow(cv, ctx.at(k[0], k[1]), ctx.u(k[2]), Color(0.85, 0.9, 1.0, 0.22), 0.32)
	for p in Kit.scatter_in(ctx, 14, ctx.u(40.0)):
		Kit.glow(cv, p, ctx.u(14.0), Color(0.85, 1.0, 0.45, 0.45))
		Kit.disc(cv, p, ctx.u(2.5), Color("f2ffc2"))
	Kit.inner_shadow(cv, ctx, ctx.u(46.0), 0.5)
	# The fence: shaded bars with spear tips, two rails, stone posts.
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall), Color(0.1, 0.1, 0.16, 0.6), Color(0.05, 0.05, 0.1, 0.2))
	var inner := Kit.along(ctx.outline, ctx.wall * 0.1, ctx.u(22.0))
	var outer := Kit.along(ctx.outline, ctx.wall * 0.85, ctx.u(22.0))
	for i in mini(inner.size(), outer.size()):
		cv.draw_line(inner[i], outer[i], Color("3a3d50"), ctx.u(4.5), true)
		var dir := (outer[i] - inner[i]).normalized()
		Kit.poly(cv, PackedVector2Array([outer[i] + dir * ctx.u(9.0), outer[i] + dir.orthogonal() * ctx.u(5.0), outer[i] - dir.orthogonal() * ctx.u(5.0)]), Color("2b2d3a"))
	for d in [0.3, 0.7]:
		var rail := Kit.offset(ctx.outline, ctx.wall * d)
		rail.append(rail[0])
		cv.draw_polyline(rail, Color("2b2d3a"), ctx.u(4.0), true)
	for v in Kit.offset(ctx.outline, ctx.wall * 0.5):
		Kit.ball(cv, v, ctx.u(13.0), Color("8a8ea0"), Color("2e3040"))
	# The moon, bare trees and jack-o'-lanterns where there's room.
	if Kit.room_outside(ctx, moon, ctx.u(30.0)):
		Kit.glow(cv, moon, ctx.u(120.0), Color(1.0, 0.98, 0.85, 0.35))
		Kit.ball(cv, moon, ctx.u(52.0), Color("fffbe6"), Color("d9d0a8"))
		Kit.disc(cv, moon + Vector2(-ctx.u(14.0), ctx.u(8.0)), ctx.u(8.0), Color(0.8, 0.76, 0.6, 0.6))
		Kit.disc(cv, moon + Vector2(ctx.u(12.0), ctx.u(18.0)), ctx.u(5.0), Color(0.8, 0.76, 0.6, 0.6))
	for k in [[Vector2(0.06, 0.95), 1.0], [Vector2(0.94, 0.5), -1.0]]:
		var base: Vector2 = ctx.canvas.position + ctx.canvas.size * k[0]
		if Kit.room_outside(ctx, base, ctx.u(20.0)):
			_tree(cv, ctx, base, k[1])
	for k in [Vector2(0.07, 0.07), Vector2(0.93, 0.93)]:
		var p: Vector2 = ctx.canvas.position + ctx.canvas.size * k
		if Kit.room_outside(ctx, p, ctx.u(16.0)):
			_pumpkin(cv, ctx, p)


static func _manor(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.floor_fill(cv, ctx, func(_p): return Color("2a160e"))
	var h := ctx.u(44.0)
	var y := ctx.full.position.y
	var row := 0
	while y < ctx.full.end.y:
		var x := ctx.full.position.x - (row % 3) * ctx.u(90.0)
		while x < ctx.full.end.x:
			var w := ctx.u(ctx.rng.randf_range(200.0, 320.0))
			var plank := PackedVector2Array([Vector2(x + ctx.u(1.5), y + ctx.u(1.5)), Vector2(x + w - ctx.u(1.5), y + ctx.u(1.5)), Vector2(x + w - ctx.u(1.5), y + h - ctx.u(1.5)), Vector2(x + ctx.u(1.5), y + h - ctx.u(1.5))])
			var tone: Color = [Color("6a3a22"), Color("5c321c"), Color("74422a")][ctx.rng.randi() % 3]
			Kit.clip_grad(cv, plank, ctx.outline, tone.lightened(0.1), tone.darkened(0.2), Vector2(0, y), Vector2(0, y + h))
			Kit.line(cv, PackedVector2Array([Vector2(x + w * 0.1, y + h * 0.4), Vector2(x + w * 0.5, y + h * 0.48), Vector2(x + w * 0.9, y + h * 0.38)]), Color(0, 0, 0, 0.15), ctx.u(1.5), ctx.outline)
			x += w
		y += h
		row += 1
	# A red rug with a gold border.
	var rug := Rect2(ctx.at(230.0, 300.0), Vector2(540.0, 400.0) * ctx.s)
	var pts := PackedVector2Array([rug.position, Vector2(rug.end.x, rug.position.y), rug.end, Vector2(rug.position.x, rug.end.y)])
	Kit.shadow(cv, rug.get_center(), rug.size.x * 0.5, 0.25)
	Kit.lit(cv, pts, Color("b8283a"), Color("6a0f1e"))
	var b := Kit.offset(pts, -ctx.u(22.0))
	b.append(b[0])
	cv.draw_polyline(b, Color("d9a54a"), ctx.u(6.0), true)
	for k in 5:
		var c := rug.position + Vector2(rug.size.x * (k + 0.5) / 5.0, rug.size.y / 2.0)
		Kit.poly(cv, PackedVector2Array([c + Vector2(0, -ctx.u(60.0)), c + Vector2(ctx.u(34.0), 0), c + Vector2(0, ctx.u(60.0)), c + Vector2(-ctx.u(34.0), 0)]), Color(0.95, 0.75, 0.35, 0.35))
	Kit.inner_shadow(cv, ctx, ctx.u(46.0), 0.55)
	for v in ctx.outline: # Candles in the corners.
		var p := v.lerp(ctx.centre, 0.06)
		Kit.glow(cv, p, ctx.u(130.0), Color(1.0, 0.75, 0.35, 0.3))
	Kit.blocks(ctx, ctx.u(110.0), ctx.wall, func(q, _e, _i):
		Kit.lit(cv, q, Color("5a3020"), Color("24120a"))
		cv.draw_polyline(Kit.offset(q, -ctx.u(5.0)) + PackedVector2Array([Kit.offset(q, -ctx.u(5.0))[0]]), Color(0.85, 0.6, 0.3, 0.45), ctx.u(1.5), true))
	var trim := ctx.outline.duplicate()
	trim.append(trim[0])
	cv.draw_polyline(trim, Color("d9a54a"), ctx.u(3.0), true)
	for v in Kit.offset(ctx.outline, ctx.wall * 0.5):
		Kit.glow(cv, v, ctx.u(30.0), Color(1.0, 0.8, 0.4, 0.6))
		Kit.disc(cv, v, ctx.u(6.0), Color("f4ecd8"))
		Kit.disc(cv, v + Vector2(0, -ctx.u(7.0)), ctx.u(3.5), Color("ffd23f"))


static func _arcane(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["3a3260", "221c40", "120e24"], p.distance_to(ctx.centre) / (ctx.full.size.x * 0.55)))
	var c := ctx.centre
	for k in 6: # Slate flagstones in rings.
		var r0 := ctx.u(70.0 + k * 70.0)
		var n := 8 + k * 5
		for i in n:
			var a0 := i * TAU / n + k * 0.3
			var a1 := (i + 1) * TAU / n + k * 0.3
			var tile := PackedVector2Array([c + Vector2.from_angle(a0 + 0.01) * (r0 + ctx.u(2.0)), c + Vector2.from_angle(a1 - 0.01) * (r0 + ctx.u(2.0)), c + Vector2.from_angle(a1 - 0.01) * (r0 + ctx.u(68.0)), c + Vector2.from_angle(a0 + 0.01) * (r0 + ctx.u(68.0))])
			Kit.clip_grad(cv, tile, ctx.outline, Color(1, 1, 1, 0.06 + 0.04 * (i % 2)), Color(0, 0, 0, 0.15), c, c + Vector2.from_angle((a0 + a1) / 2.0) * (r0 + ctx.u(70.0)))
	# The rune circle.
	Kit.glow(cv, c, ctx.u(260.0), Color(0.5, 0.3, 1.0, 0.3))
	for rr in [180.0, 210.0, 120.0]:
		cv.draw_arc(c, ctx.u(rr), 0.0, TAU, 96, Color(0.75, 0.6, 1.0, 0.25), ctx.u(10.0), true)
		cv.draw_arc(c, ctx.u(rr), 0.0, TAU, 96, Color("c9a6ff"), ctx.u(2.5), true)
	var star := Kit.star_pts(c, ctx.u(180.0), ctx.u(70.0), 5)
	star.append(star[0])
	cv.draw_polyline(star, Color(0.3, 0.85, 1.0, 0.8), ctx.u(2.5), true)
	for i in 24: # Runes between the rings.
		var a := i * TAU / 24.0
		var p := c + Vector2.from_angle(a) * ctx.u(195.0)
		var d := Vector2.from_angle(a)
		var t := d.orthogonal()
		var g := ctx.u(7.0)
		match i % 4:
			0: cv.draw_polyline(PackedVector2Array([p - d * g + t * g, p + d * g, p - d * g - t * g]), Color("c9a6ff"), ctx.u(2.0), true)
			1: cv.draw_polyline(PackedVector2Array([p - t * g, p + t * g, p + t * g + d * g]), Color("c9a6ff"), ctx.u(2.0), true)
			2: cv.draw_arc(p, g * 0.8, 0.0, TAU, 12, Color("c9a6ff"), ctx.u(2.0), true)
			_: cv.draw_polyline(PackedVector2Array([p - d * g, p + d * g, p + d * g + t * g * 0.8]), Color("c9a6ff"), ctx.u(2.0), true)
	Kit.inner_shadow(cv, ctx, ctx.u(40.0), 0.55)
	Kit.blocks(ctx, ctx.u(44.0), ctx.wall, func(q, _e, i):
		Kit.lit(cv, q, Color("5a4a80") if i % 2 else Color("4e4074"), Color("1a1430"))
		cv.draw_line(q[1], q[2], Color(0.05, 0.03, 0.12, 0.8), ctx.u(2.0), true))
	var n := 0
	for p in Kit.along(ctx.outline, ctx.wall * 0.5, ctx.u(88.0)):
		var col := Color("c9a6ff") if n % 2 else Color("4fd8ff")
		Kit.glow(cv, p, ctx.u(14.0), Color(col, 0.6))
		Kit.disc(cv, p, ctx.u(3.0), col)
		n += 1


static func _tree(cv: CanvasItem, ctx: Kit.Ctx, base: Vector2, f: float) -> void:
	var col := Color("07050d")
	var top := base + Vector2(ctx.u(8.0) * f, -ctx.u(100.0))
	cv.draw_polyline(PackedVector2Array([base, base.lerp(top, 0.5) + Vector2(ctx.u(10.0) * f, 0), top]), col, ctx.u(10.0), true)
	for k in [[0.55, 30.0, -36.0], [0.75, -26.0, -30.0], [1.0, 20.0, -24.0], [1.0, -10.0, -34.0]]:
		var from: Vector2 = base.lerp(top, k[0])
		var tip: Vector2 = from + Vector2(k[1] * f, k[2]) * ctx.s
		cv.draw_polyline(PackedVector2Array([from, from.lerp(tip, 0.5) + Vector2(0, -ctx.u(6.0)), tip]), col, ctx.u(4.0), true)


static func _pumpkin(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2) -> void:
	var s := ctx.u(18.0)
	Kit.glow(cv, p, s * 3.0, Color(1.0, 0.55, 0.15, 0.4))
	Kit.ball(cv, p, s, Color("ffb347"), Color("c0501a"), 0.8)
	for x in [-0.4, 0.4]:
		cv.draw_arc(p + Vector2(x * s, 0), s * 0.75, -1.2, 1.2, 12, Color("b5501a"), maxf(1.0, s * 0.08), true)
	cv.draw_line(p + Vector2(0, -s * 0.8), p + Vector2(s * 0.1, -s * 1.15), Color("4a6b2a"), s * 0.2, true)
	Kit.poly(cv, PackedVector2Array([p + Vector2(-0.5, -0.15) * s, p + Vector2(-0.3, -0.45) * s, p + Vector2(-0.1, -0.15) * s]), Color("ffe46b"))
	Kit.poly(cv, PackedVector2Array([p + Vector2(0.1, -0.15) * s, p + Vector2(0.3, -0.45) * s, p + Vector2(0.5, -0.15) * s]), Color("ffe46b"))
	Kit.poly(cv, PackedVector2Array([p + Vector2(-0.5, 0.15) * s, p + Vector2(0.5, 0.15) * s, p + Vector2(0.3, 0.45) * s, p + Vector2(-0.3, 0.45) * s]), Color("ffe46b"))
