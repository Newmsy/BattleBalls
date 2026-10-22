## Toybox (toybox, speedway, pinball, bumpers, arcade): the playroom maps.
## Toy Chest is a soft playroom rug with crayons and marbles inside a wooden
## toy-chest rim, letter blocks for pillars and beach balls for bumpers.
## Speedway is a slot-car table, Pinball a starry playfield with lane arrows
## and chrome rails, Bumper Lab glossy lab tiles, Portal Hall a loud arcade
## carpet with a cabinet rim. Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")

const TOY := [Color("ff5a5a"), Color("ffb63f"), Color("4fc3ff"), Color("6fdc6a"), Color("b07cff")]


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	match ctx.id:
		"speedway":
			_speedway(cv, ctx)
		"pinball":
			_pinball(cv, ctx)
		"bumpers":
			_lab(cv, ctx)
		"arcade":
			_arcade(cv, ctx)
		_:
			_toybox(cv, ctx)


## A wooden letter block (pinball and the lab: a chrome post).
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	if ctx.id != "toybox":
		Kit.shadow(cv, c + Vector2(0.15, 0.2) * r, r, 0.5)
		Kit.ball(cv, c, r, Color("f4f8ff"), Color("4a5468"))
		Kit.ring(cv, c, r * 0.72, Color(TOY[2], 0.9), r * 0.12)
		Kit.ball(cv, c, r * 0.4, Color("ffffff"), Color("8a94a8"))
		return
	var h := r * 0.82
	Kit.shadow(cv, c + Vector2(0.18, 0.24) * r, r, 0.5)
	var face := Kit.rect_pts(c, Vector2.ONE * h * 2.0, 0.12)
	Kit.lit(cv, face, Color("ffe2a8"), Color("c88a48"))
	Kit.poly(cv, Kit.rect_pts(c, Vector2.ONE * h * 1.5, 0.12), Color("ff5a5a"))
	# A big chunky "A".
	var t := Transform2D(0.12, c)
	var w := maxf(2.0, h * 0.2)
	cv.draw_polyline(PackedVector2Array([t * Vector2(-h * 0.45, h * 0.5), t * Vector2(0, -h * 0.55), t * Vector2(h * 0.45, h * 0.5)]), Color("fff6e0"), w, true)
	cv.draw_line(t * Vector2(-h * 0.24, h * 0.1), t * Vector2(h * 0.24, h * 0.1), Color("fff6e0"), w, true)


## A beach ball with pink panels, so it still reads as a bumper.
static func bumper(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.shadow(cv, c + Vector2(0.15, 0.22) * r, r, 0.45)
	Kit.ball(cv, c, r, Color("ffffff"), Color("c8c0d8"))
	var cols := [Color("ff4fa8"), Color("ffd23f"), Color("ff4fa8"), Color("4fc3ff"), Color("ff4fa8"), Color("6fdc6a")]
	for i in 6:
		var a0 := i * TAU / 6.0 - 0.6
		var pts := PackedVector2Array([c])
		for k in 9:
			pts.append(c + Vector2.from_angle(a0 + k * TAU / 6.0 / 8.0 * 0.7) * r * 0.97)
		Kit.poly(cv, pts, cols[i] if i % 2 == 0 else Color(cols[i], 0.85))
	Kit.ball(cv, c, r * 0.18, Color("ffffff"), Color("d0d0d0"))
	Kit.glow(cv, c + Vector2(-0.35, -0.4) * r, r * 0.45, Color(1, 1, 1, 0.6))
	if ctx.id == "pinball":
		Kit.ring(cv, c, r, Color("e8eef8"), r * 0.08)


static func _toybox(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	_floorboards(cv, ctx, ctx.canvas, Color("c08550"))
	# The rug: soft blue with a stitched border and rainbow corner stars.
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["9fdcff", "7ac4f2", "5aa8e0"], p.distance_to(ctx.at(400, 380)) / (ctx.full.size.x * 0.75)))
	var step := ctx.u(125.0)
	for i in 8:
		for j in 8:
			if (i + j) % 2 == 0:
				continue
			var box := PackedVector2Array([ctx.full.position + Vector2(i, j) * step, ctx.full.position + Vector2(i + 1, j) * step, ctx.full.position + Vector2(i + 1, j + 1) * step, ctx.full.position + Vector2(i, j + 1) * step])
			Kit.clip_poly(cv, box, ctx.outline, Color(1, 1, 1, 0.1))
	var stitch := Kit.offset(ctx.outline, -ctx.u(26.0))
	for e in stitch.size():
		var a := stitch[e]
		var b := stitch[(e + 1) % stitch.size()]
		var n := int(a.distance_to(b) / ctx.u(18.0))
		for k in n:
			cv.draw_line(a.lerp(b, (k + 0.15) / n), a.lerp(b, (k + 0.6) / n), Color(1, 1, 1, 0.75), ctx.u(2.5), true)
	var keep := []
	for o in ctx.obstacles:
		keep.append([o.pos, o.radius * 1.5])
	keep.append([ctx.at(150, 850), ctx.u(130.0)])
	keep.append([ctx.at(850, 150), ctx.u(130.0)])
	for p in Kit.scatter_in(ctx, 5, ctx.u(60.0), keep): # Crayons.
		var d := Vector2.from_angle(ctx.rng.randf() * TAU)
		var col: Color = TOY[ctx.rng.randi() % TOY.size()]
		var a := p - d * ctx.u(26.0)
		var b := p + d * ctx.u(20.0)
		cv.draw_line(a + Vector2(2, 3) * ctx.s, b + Vector2(2, 3) * ctx.s, Color(0, 0, 0, 0.2), ctx.u(11.0), true)
		cv.draw_line(a, b, col, ctx.u(10.0), true)
		cv.draw_line(a.lerp(b, 0.3), a.lerp(b, 0.42), col.darkened(0.3), ctx.u(10.5), true)
		Kit.poly(cv, PackedVector2Array([b + d.orthogonal() * ctx.u(5.0), b - d.orthogonal() * ctx.u(5.0), b + d * ctx.u(11.0)]), col.lightened(0.3))
	for p in Kit.scatter_in(ctx, 9, ctx.u(30.0), keep): # Marbles.
		Kit.shadow(cv, p, ctx.u(7.0), 0.3)
		var col: Color = TOY[ctx.rng.randi() % TOY.size()]
		Kit.ball(cv, p, ctx.u(7.0), col.lightened(0.5), col.darkened(0.2))
		Kit.disc(cv, p + Vector2(-2, -2) * ctx.s, ctx.u(2.0), Color(1, 1, 1, 0.9))
	Kit.inner_shadow(cv, ctx, ctx.u(40.0), 0.4, Color("1a2a5a"))
	# The toy chest rim: painted wooden planks with brass corners.
	Kit.blocks(ctx, ctx.u(90.0), ctx.wall, func(q, _e, i):
		var col: Color = TOY[i % TOY.size()]
		Kit.lit(cv, q, col.lightened(0.15), col.darkened(0.35))
		cv.draw_line(q[0].lerp(q[3], 0.5), q[1].lerp(q[2], 0.5), Color(1, 1, 1, 0.25), ctx.u(2.0), true))
	for v in Kit.offset(ctx.outline, ctx.wall * 0.5):
		Kit.ball(cv, v, ctx.u(11.0), Color("ffe9a0"), Color("b07a1a"))


static func _speedway(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	_floorboards(cv, ctx, ctx.canvas, Color("8a5a38"))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["4fae5a", "3a8f48", "2a6e38"], p.distance_to(ctx.centre) / (ctx.full.size.x * 0.6)))
	# The track: a grey loop over the belts, kerbs on both edges.
	var c := ctx.centre
	var outer := Kit.offset(ctx.outline, -ctx.u(70.0))
	var inner := Kit.offset(ctx.outline, -ctx.u(310.0))
	Kit.strip(cv, outer, inner, Color("4a4e58"), Color("3a3e48"))
	for loop: PackedVector2Array in [outer, inner]:
		for e in loop.size():
			var a := loop[e]
			var b := loop[(e + 1) % loop.size()]
			var n := maxi(1, int(a.distance_to(b) / ctx.u(26.0)))
			for k in n:
				cv.draw_line(a.lerp(b, float(k) / n), a.lerp(b, (k + 1.0) / n), Color("ff4a4a") if k % 2 else Color("ffffff"), ctx.u(7.0), false)
	var lane := Kit.offset(ctx.outline, -ctx.u(190.0))
	for e in lane.size():
		var a := lane[e]
		var b := lane[(e + 1) % lane.size()]
		var n := maxi(1, int(a.distance_to(b) / ctx.u(40.0)))
		for k in n:
			cv.draw_line(a.lerp(b, (k + 0.2) / n), a.lerp(b, (k + 0.65) / n), Color(1, 1, 0.7, 0.6), ctx.u(3.0), true)
	# Chequered start line across the bottom straight.
	var sq := ctx.u(13.0)
	for i in 2:
		for j in 18:
			var p := ctx.at(560.0, 765.0) + Vector2(i * sq, j * sq)
			if p.y > ctx.at(0, 910).y:
				break
			cv.draw_rect(Rect2(p, Vector2.ONE * sq), Color.WHITE if (i + j) % 2 else Color("1a1a1a"))
	Kit.glow(cv, c, ctx.u(150.0), Color(1, 1, 0.6, 0.18))
	Kit.inner_shadow(cv, ctx, ctx.u(36.0), 0.45)
	# Orange plastic track barrier.
	Kit.blocks(ctx, ctx.u(70.0), ctx.wall, func(q, _e, i):
		Kit.lit(cv, q, Color("ffa040") if i % 2 else Color("ff8a2a"), Color("b04a10"))
		cv.draw_line(q[0].lerp(q[3], 0.35), q[1].lerp(q[2], 0.35), Color(1, 1, 1, 0.4), ctx.u(2.0), true))


static func _pinball(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["3a2a6a", "1a1238"], (p - ctx.canvas.position).y / ctx.canvas.size.y))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["2a4ab8", "1a2c80", "10185a"], p.distance_to(ctx.at(500, 420)) / (ctx.full.size.x * 0.7)))
	# Painted stars, lane arrows and inserts like a real playfield.
	for p in Kit.scatter_in(ctx, 30, ctx.u(30.0)):
		var star := Kit.star_pts(p, ctx.u(ctx.rng.randf_range(5.0, 10.0)), ctx.u(2.5), 5)
		Kit.poly(cv, star, Color(1, 0.95, 0.6, ctx.rng.randf_range(0.3, 0.7)))
	for k in [[Vector2(500, 830), -PI / 2.0], [Vector2(500, 170), PI / 2.0], [Vector2(170, 500), 0.0], [Vector2(830, 500), PI]]:
		var base: Vector2 = ctx.at(k[0].x, k[0].y)
		var d := Vector2.from_angle(k[1])
		for i in 3:
			var tip := base + d * ctx.u(22.0 + i * 30.0)
			var col: Color = [Color("ff4fa8"), Color("ffd23f"), Color("4fe8ff")][i]
			Kit.glow(cv, tip, ctx.u(22.0), Color(col, 0.35))
			Kit.poly(cv, PackedVector2Array([tip + d * ctx.u(12.0), tip - d * ctx.u(6.0) + d.orthogonal() * ctx.u(14.0), tip - d * ctx.u(6.0) - d.orthogonal() * ctx.u(14.0)]), col)
	for i in 8: # Round inserts around the centre bumper.
		var p := ctx.centre + Vector2.from_angle(i * TAU / 8.0 + PI / 8.0) * ctx.u(130.0)
		Kit.glow(cv, p, ctx.u(18.0), Color(1, 0.4, 0.8, 0.4))
		Kit.ball(cv, p, ctx.u(8.0), Color("ffd0f0"), Color("c02a8a"))
	Kit.inner_shadow(cv, ctx, ctx.u(36.0), 0.5)
	_chrome(cv, ctx)


static func _lab(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["3a4a5a", "1e2834"], (p - ctx.canvas.position).y / ctx.canvas.size.y))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["ffffff", "e6eef6", "c4d2e2"], p.distance_to(ctx.at(400, 380)) / (ctx.full.size.x * 0.75)))
	var step := ctx.u(100.0)
	for i in 11:
		var x := ctx.full.position.x + i * step
		Kit.line(cv, PackedVector2Array([Vector2(x, ctx.full.position.y), Vector2(x, ctx.full.end.y)]), Color(0.4, 0.55, 0.7, 0.35), ctx.u(2.0), ctx.outline)
		var y := ctx.full.position.y + i * step
		Kit.line(cv, PackedVector2Array([Vector2(ctx.full.position.x, y), Vector2(ctx.full.end.x, y)]), Color(0.4, 0.55, 0.7, 0.35), ctx.u(2.0), ctx.outline)
	for o in ctx.obstacles: # Hazard rings and test markings round each bumper.
		cv.draw_arc(o.pos, o.radius * 1.7, 0.0, TAU, 64, Color(1.0, 0.3, 0.6, 0.35), ctx.u(4.0), true)
		for i in 8:
			var a := i * TAU / 8.0
			cv.draw_line(o.pos + Vector2.from_angle(a) * o.radius * 1.55, o.pos + Vector2.from_angle(a) * o.radius * 1.85, Color(1.0, 0.3, 0.6, 0.6), ctx.u(3.0), true)
	for k in [Vector2(700, 300), Vector2(300, 700)]:
		var p := ctx.at(k.x, k.y)
		var box := Kit.rect_pts(p, Vector2(150, 90) * ctx.s)
		Kit.poly(cv, box, Color(0.2, 0.4, 0.6, 0.08))
		var loop := box.duplicate()
		loop.append(box[0])
		cv.draw_polyline(loop, Color(0.3, 0.5, 0.7, 0.4), ctx.u(2.0), true)
		Kit.ring(cv, p, ctx.u(22.0), Color(0.3, 0.5, 0.7, 0.4), ctx.u(2.0))
		cv.draw_line(p - Vector2(ctx.u(30.0), 0), p + Vector2(ctx.u(30.0), 0), Color(0.3, 0.5, 0.7, 0.4), ctx.u(2.0), true)
		cv.draw_line(p - Vector2(0, ctx.u(30.0)), p + Vector2(0, ctx.u(30.0)), Color(0.3, 0.5, 0.7, 0.4), ctx.u(2.0), true)
	Kit.inner_shadow(cv, ctx, ctx.u(34.0), 0.3, Color("2a4a6a"))
	Kit.blocks(ctx, ctx.u(110.0), ctx.wall, func(q, _e, _i):
		Kit.lit(cv, q, Color("e8eef4"), Color("8a98a8"))
		var mid: Vector2 = (q[0] + q[1] + q[2] + q[3]) / 4.0
		Kit.disc(cv, mid, ctx.u(3.5), Color("4fe8ff")))
	var trim := ctx.outline.duplicate()
	trim.append(trim[0])
	cv.draw_polyline(trim, Color("4fe8ff"), ctx.u(2.5), true)


static func _arcade(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["2a1040", "120620"], (p - ctx.canvas.position).y / ctx.canvas.size.y))
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(["2a1a50", "1a0e36", "0e0620"], p.distance_to(ctx.centre) / (ctx.full.size.x * 0.65)))
	# Classic arcade carpet: neon squiggles, triangles and rings.
	var cols := [Color("ff4fa8"), Color("4fe8ff"), Color("ffd23f"), Color("6fff7a")]
	for p in Kit.scatter_in(ctx, 70, ctx.u(14.0)):
		var col: Color = cols[ctx.rng.randi() % cols.size()]
		col.a = 0.55
		match ctx.rng.randi() % 3:
			0:
				var a := ctx.rng.randf() * TAU
				var pts := PackedVector2Array()
				for k in 7:
					pts.append(p + Vector2(k * ctx.u(6.0) - ctx.u(18.0), (ctx.u(6.0) if k % 2 else -ctx.u(6.0))).rotated(a))
				cv.draw_polyline(pts, col, ctx.u(3.0), true)
			1:
				var tri := Kit.star_pts(p, ctx.u(12.0), ctx.u(12.0) * 0.5, 3, ctx.rng.randf() * TAU)
				tri = PackedVector2Array([tri[0], tri[2], tri[4], tri[0]])
				cv.draw_polyline(tri, col, ctx.u(3.0), true)
			_:
				cv.draw_arc(p, ctx.u(8.0), 0.0, TAU, 16, col, ctx.u(3.0), true)
	for f in ctx.floors: # A glowing pad under each portal.
		if f.has("pos"):
			Kit.glow(cv, f.pos, f.radius * 2.0, Color(0.6, 0.3, 1.0, 0.35))
	Kit.inner_shadow(cv, ctx, ctx.u(36.0), 0.55)
	# Cabinet rim: black panels with rows of arcade buttons.
	Kit.blocks(ctx, ctx.u(100.0), ctx.wall, func(q, _e, i):
		Kit.lit(cv, q, Color("2e2a40"), Color("0e0c18"))
		var mid: Vector2 = (q[0] + q[1] + q[2] + q[3]) / 4.0
		var along: Vector2 = (q[1] - q[0]) * 0.22
		for k in [-1, 0, 1]:
			var col: Color = cols[(i + k + 1) % cols.size()]
			Kit.glow(cv, mid + along * k, ctx.u(12.0), Color(col, 0.4))
			Kit.ball(cv, mid + along * k, ctx.u(5.5), col.lightened(0.4), col.darkened(0.3)))
	var trim := ctx.outline.duplicate()
	trim.append(trim[0])
	cv.draw_polyline(trim, Color("ff4fa8"), ctx.u(2.5), true)


static func _floorboards(cv: CanvasItem, ctx: Kit.Ctx, box: Rect2, base: Color) -> void:
	cv.draw_rect(box, base.darkened(0.35))
	var h := ctx.u(36.0)
	var y := box.position.y
	var row := 0
	while y < box.end.y:
		var x := box.position.x - (row % 3) * ctx.u(70.0)
		h = minf(h, box.end.y - y)
		while x < box.end.x:
			var w := minf(ctx.u(ctx.rng.randf_range(180.0, 300.0)), box.end.x - x)
			var tone := base.lightened(ctx.rng.randf_range(-0.08, 0.1))
			Kit.grad(cv, PackedVector2Array([Vector2(x + 1, y + 1), Vector2(x + w - 1, y + 1), Vector2(x + w - 1, y + h - 1), Vector2(x + 1, y + h - 1)]), tone.lightened(0.08), tone.darkened(0.15), Vector2(0, y), Vector2(0, y + h))
			x += w
		y += h
		row += 1


static func _chrome(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	Kit.strip(cv, ctx.outline, Kit.offset(ctx.outline, ctx.wall), Color("f4f8ff"), Color("5a6478"))
	for d in [0.35, 0.7]:
		var rail := Kit.offset(ctx.outline, ctx.wall * d)
		rail.append(rail[0])
		cv.draw_polyline(rail, Color(1, 1, 1, 0.55), ctx.u(2.0), true)
	for p in Kit.along(ctx.outline, ctx.wall * 0.5, ctx.u(80.0)):
		Kit.ball(cv, p, ctx.u(4.0), Color("ffffff"), Color("6a7488"))
