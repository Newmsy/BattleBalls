## Sky Kingdom (cloud, storm): open sky with a warm sun, sun rays, a faint
## rainbow and drifting puffs inside a fluffy cloud rim, floating grass
## islands for pillars. Storm is slate and violet with rain and lightning.
## Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var storm := ctx.id == "storm"
	var top := ctx.canvas.position.y
	var h := ctx.canvas.size.y
	var back := ["3f97f0", "8fd0ff", "ffd9b0"] if not storm else ["141a30", "222a44", "0c1020"]
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(back, (p.y - top) / h))
	var floor_stops := ["5aaaf5", "a8dcff", "ffe4c4"] if not storm else ["34406a", "283256", "1a2040"]
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(floor_stops, (p.y - top) / h), 8)
	var c := ctx.centre
	if not storm:
		for i in 12: # Sun rays.
			var a := i * TAU / 12.0
			var far := ctx.full.size.x
			var ray := PackedVector2Array([c, c + Vector2.from_angle(a - 0.08) * far, c + Vector2.from_angle(a + 0.08) * far])
			Kit.clip_grad(cv, ray, ctx.outline, Color(1, 1, 1, 0.16), Color(1, 1, 1, 0.0), c, c + Vector2.from_angle(a) * far * 0.7)
		var bow := ctx.at(60.0, 940.0)
		var cols := ["ff6b6b", "ffb347", "ffe36b", "7be07b", "5fb8ff", "a98bff"]
		for i in cols.size():
			var arc := PackedVector2Array()
			for k in 40:
				arc.append(bow + Vector2.from_angle(-PI / 2.0 + k * (PI / 2.0) / 39.0) * ctx.u(300.0 + i * 11.0))
			Kit.line(cv, arc, Color(cols[i], 0.3), ctx.u(11.0), ctx.outline)
	else:
		for _i in 70: # Rain.
			var p := Vector2(ctx.rng.randf_range(ctx.full.position.x, ctx.full.end.x), ctx.rng.randf_range(ctx.full.position.y, ctx.full.end.y))
			Kit.line(cv, PackedVector2Array([p, p + Vector2(-ctx.u(8.0), ctx.u(26.0))]), Color(0.75, 0.85, 1.0, 0.22), ctx.u(2.0), ctx.outline)
	var puffs := [[Vector2(260, 330), 30.0], [Vector2(740, 670), 34.0], [Vector2(560, 130), 22.0], [Vector2(440, 870), 22.0]]
	for k in puffs:
		_puff(cv, ctx, ctx.at(k[0].x, k[0].y), ctx.u(k[1]), storm, 0.75)
	if not storm:
		Kit.glow(cv, c, ctx.u(150.0), Color(1.0, 0.97, 0.7, 0.85))
		Kit.ball(cv, c, ctx.u(44.0), Color("fff6bf"), Color("ffcf3a"))
		for k in [[150, 160], [180, 180], [160, 195], [820, 820], [845, 838]]:
			var b := ctx.at(k[0], k[1])
			Dot.pline(cv, PackedVector2Array([b, b + Vector2(ctx.u(7.0), -ctx.u(6.0)), b + Vector2(ctx.u(14.0), 0)]), Color("3e5f9a"), ctx.u(2.4), true)
			Dot.pline(cv, PackedVector2Array([b + Vector2(ctx.u(14.0), 0), b + Vector2(ctx.u(21.0), -ctx.u(6.0)), b + Vector2(ctx.u(28.0), 0)]), Color("3e5f9a"), ctx.u(2.4), true)
	else:
		var bolt := PackedVector2Array()
		for k in [[-30, -150], [30, -150], [0, -30], [50, -30], [-35, 150], [-5, 20], [-55, 20]]:
			bolt.append(c + Vector2(k[0], k[1]) * ctx.s)
		Kit.glow(cv, c, ctx.u(170.0), Color(1.0, 0.9, 0.5, 0.25))
		Kit.poly(cv, bolt, Color(1.0, 0.92, 0.5, 0.45))
	Kit.inner_shadow(cv, ctx, ctx.u(30.0), 0.35, Color("26346a"))

	# The rim: a ring of fluffy clouds, lavender underneath.
	for p in Kit.along(ctx.outline, ctx.wall * 0.55, ctx.u(24.0)):
		_puff_ball(cv, p, ctx.wall * ctx.rng.randf_range(0.58, 0.8), storm)


## A floating grass island with a tree and a little waterfall.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.glow(cv, c + Vector2(r * 0.3, r * 0.9), r * 1.2, Color(0.15, 0.25, 0.55, 0.35), 0.5)
	var rock := PackedVector2Array([c + Vector2(-r, 0.0), c + Vector2(-0.6 * r, 0.65 * r), c + Vector2(-0.1 * r, 1.4 * r), c + Vector2(0.15 * r, 0.9 * r), c + Vector2(0.55 * r, 0.75 * r), c + Vector2(r, 0.0)])
	Kit.grad(cv, rock, Color("a8774a"), Color("4a2e1a"), c, c + Vector2(0, r * 1.4))
	Dot.line(cv, c + Vector2(0.45 * r, 0.1 * r), c + Vector2(0.45 * r, 0.95 * r), Color("dff4ff"), r * 0.12, true)
	Kit.ball(cv, c, r, Color("a8f07a"), Color("3f9a3f"), 0.55)
	Kit.disc(cv, c + Vector2(-0.3, 0.22) * r, r * 0.1, Color("ff7ab0"))
	Kit.disc(cv, c + Vector2(0.15, 0.3) * r, r * 0.09, Color("ffe36b"))
	Kit.disc(cv, c + Vector2(0.05, -0.05) * r, r * 0.38, Color(0, 0, 0, 0.2))
	Kit.ball(cv, c + Vector2(-0.05, -0.18) * r, r * 0.34, Color("8ee06e"), Color("2f8a3a"))


static func _puff(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, s: float, storm: bool, a: float) -> void:
	for k in [[-1.1, 0.2, 0.7], [0.0, 0.0, 1.0], [1.1, 0.2, 0.75], [0.5, -0.5, 0.7], [-0.5, -0.4, 0.65]]:
		var p := c + Vector2(k[0], k[1]) * s
		Kit.disc(cv, p + Vector2(0, s * 0.2), k[2] * s, Color(Color("b9c3ec") if not storm else Color("2a3048"), a))
	for k in [[-1.1, 0.2, 0.7], [0.0, 0.0, 1.0], [1.1, 0.2, 0.75], [0.5, -0.5, 0.7], [-0.5, -0.4, 0.65]]:
		Kit.disc(cv, c + Vector2(k[0], k[1]) * s, k[2] * s, Color(Color.WHITE if not storm else Color("7a84a0"), a))


static func _puff_ball(cv: CanvasItem, p: Vector2, r: float, storm: bool) -> void:
	Kit.disc(cv, p + Vector2(0, r * 0.25), r, Color("b9c3ec") if not storm else Color("2a3048"))
	Kit.ball(cv, p, r, Color.WHITE if not storm else Color("9aa3bb"), Color("dfe5ff") if not storm else Color("5a6278"))
