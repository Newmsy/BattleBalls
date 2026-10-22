## Candy Shop (candy, syrup, hive): pink frosting with sprinkles inside a
## candy-cane rim, wrapped sweets on a berry tablecloth outside, lollipop
## pillars and gumdrop bumpers. Hive swaps the frosting for honey and wax.
## Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")

const SPRINKLES := [Color("ff5fa2"), Color("4fc3f7"), Color("ffd54f"), Color("81e07f"), Color("b388ff"), Color("ffffff")]


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var hive := ctx.id == "hive"
	var reach := ctx.full.size.x * 0.75
	# The tablecloth outside, with faint woven checks.
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["7a2e58", "5a1d42", "3a1028"], p.distance_to(ctx.centre) / reach))
	var step := ctx.u(80.0)
	var x := ctx.canvas.position.x
	while x < ctx.canvas.end.x:
		cv.draw_rect(Rect2(x, ctx.canvas.position.y, ctx.u(26.0), ctx.canvas.size.y), Color(1, 1, 1, 0.04))
		cv.draw_rect(Rect2(ctx.canvas.position.x, x - ctx.canvas.position.x + ctx.canvas.position.y, ctx.canvas.size.x, ctx.u(26.0)), Color(1, 1, 1, 0.04))
		x += step
	for p in Kit.scatter_out(ctx, 16, ctx.u(24.0)):
		_sweet(cv, ctx, p)

	# The floor: frosting (or honey), lit from the top left.
	var light := ctx.at(380.0, 330.0)
	var stops := ["fff3f8", "ffd3e6", "ffb3d4", "f08cbd"] if not hive else ["fff1c2", "ffd978", "f2b84b", "c98a24"]
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(stops, p.distance_to(light) / reach))
	if hive:
		_honeycomb(cv, ctx)
	else:
		var keep := [[ctx.centre, ctx.u(120.0)]]
		for f in ctx.floors:
			if f.has("pos"):
				keep.append([f.pos, f.radius + ctx.u(10.0)])
		for p in Kit.scatter_in(ctx, 150, ctx.u(34.0), keep):
			var col: Color = SPRINKLES[ctx.rng.randi() % SPRINKLES.size()]
			Kit.poly(cv, Kit.rect_pts(p, Vector2(ctx.u(14.0), ctx.u(4.5)), ctx.rng.randf() * PI), col)
	# The middle: a chocolate puddle, a caramel swirl or a honey pool.
	match ctx.id:
		"syrup":
			_swirl(cv, ctx)
		"hive":
			_puddle(cv, ctx, ["ffe08a", "f2a91f", "c47a10"], Color("fff3c4"))
		_:
			_puddle(cv, ctx, ["a8673d", "6b3a1f", "4a2512"], Color("ffe3f0"))
	# A frosting (or wax) rim round the floor with drips.
	var rim_col := Color("fff7fb") if not hive else Color("fff0b8")
	Kit.wavy_rim(cv, ctx, ctx.u(8.0), func(t, _p): return ctx.u(14.0) + ctx.u(6.0) * sin(t * TAU * 37.0) + ctx.u(26.0) * pow(maxf(0.0, sin(t * TAU * 11.0 + 0.7)), 12.0), rim_col)
	Kit.inner_shadow(cv, ctx, ctx.u(40.0), 0.3)

	# The rim: candy cane (or honey wax), rounded with a highlight.
	if hive:
		Kit.blocks(ctx, ctx.u(40.0), ctx.wall, func(q, _e, i): Kit.lit(cv, q, Color("ffcf5a") if i % 2 == 0 else Color("f2b23a"), Color("b8741a")))
	else:
		Kit.blocks(ctx, ctx.u(22.0), ctx.wall, func(q, _e, i): Kit.poly(cv, q, Color("ff3355") if i % 2 == 0 else Color("fff4f7")), ctx.u(18.0))
	var mid := Kit.offset(ctx.outline, ctx.wall * 0.45)
	Kit.strip(cv, ctx.outline, mid, Color(0.3, 0.0, 0.1, 0.25), Color(1, 1, 1, 0.3))
	Kit.strip(cv, mid, Kit.offset(ctx.outline, ctx.wall), Color(1, 1, 1, 0.3), Color(0.25, 0.0, 0.08, 0.45))


## A lollipop: white candy with a pink spiral.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	var stripe := Color("ff2f74") if ctx.id != "hive" else Color("e08a10")
	Kit.shadow(cv, c, r, 0.45)
	Kit.ball(cv, c, r, Color.WHITE, Color("ffd0e2") if ctx.id != "hive" else Color("ffe7b8"))
	var spiral := PackedVector2Array()
	for i in 90:
		var t := i / 89.0
		spiral.append(c + Vector2.from_angle(t * TAU * 2.6 + 0.6) * r * (0.88 - t * 0.85))
	cv.draw_polyline(spiral, stripe, r * 0.17, true)
	Kit.ring(cv, c, r, Color(stripe.darkened(0.3), 0.7), r * 0.07)
	Kit.disc(cv, c + Vector2(-0.38, -0.42) * r, r * 0.2, Color(1, 1, 1, 0.65))


## A pink gumdrop with sugar crystals (still a bumper's pink).
static func bumper(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.shadow(cv, c, r, 0.45)
	Kit.ball(cv, c, r, Color("ffc6df"), Color("e0457f"))
	for i in 14:
		var a := i * 2.39996
		var d := r * 0.8 * sqrt((i + 0.5) / 14.0)
		Kit.disc(cv, c + Vector2.from_angle(a) * d, r * 0.07, Color(1, 1, 1, 0.8))
	Kit.ring(cv, c, r, Color("ff6fae"), r * 0.08)
	Kit.disc(cv, c + Vector2(-0.35, -0.4) * r, r * 0.22, Color(1, 1, 1, 0.55))


## A wrapped sweet: a shiny oval with a twist each side.
static func _sweet(cv: CanvasItem, ctx: Kit.Ctx, p: Vector2) -> void:
	var rot := ctx.rng.randf() * TAU
	var size := ctx.u(ctx.rng.randf_range(10.0, 15.0))
	var col: Color = SPRINKLES[ctx.rng.randi() % 5]
	var tie: Color = SPRINKLES[ctx.rng.randi() % 5]
	var ax := Vector2.from_angle(rot)
	Kit.shadow(cv, p, size, 0.35)
	for sgn: float in [-1.0, 1.0]:
		var base := p + ax * size * sgn
		var tip := p + ax * size * 1.9 * sgn
		Kit.poly(cv, PackedVector2Array([base, tip + ax.orthogonal() * size * 0.7, tip - ax.orthogonal() * size * 0.7]), tie)
	var oval := Kit.circle_pts(Vector2.ZERO, size, 20, 0.7)
	for i in oval.size():
		oval[i] = p + oval[i].rotated(rot)
	Kit.lit(cv, oval, col.lightened(0.35), col.darkened(0.2))
	Kit.disc(cv, p - Vector2(size, size) * 0.3, size * 0.25, Color(1, 1, 1, 0.6))


static func _puddle(cv: CanvasItem, ctx: Kit.Ctx, stops: Array, trim: Color) -> void:
	var c := ctx.centre
	var r := ctx.u(82.0)
	var shape := Kit.blob(c, r, ctx.rng, 10, 0.1)
	Kit.shadow(cv, c, r, 0.3)
	Kit.tris(cv, shape, _shade(shape, c - Vector2(r, r) * 0.3, r * 1.6, stops), Geometry2D.triangulate_polygon(shape))
	var arc := PackedVector2Array()
	for i in 20:
		arc.append(c + Vector2.from_angle(-2.6 + i * 0.09) * r * 0.66)
	cv.draw_polyline(arc, Color(1, 1, 1, 0.35), ctx.u(7.0), true)
	var dash := shape.duplicate()
	dash.append(shape[0])
	for i in range(0, dash.size() - 1, 3):
		cv.draw_line(dash[i], dash[i + 1], trim, ctx.u(4.0), true)


static func _swirl(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var c := ctx.centre
	var pts := PackedVector2Array()
	for i in 120:
		var t := i / 119.0
		pts.append(c + Vector2.from_angle(t * TAU * 2.4) * ctx.u(10.0 + 95.0 * t))
	cv.draw_polyline(pts, Color("b86b2c"), ctx.u(18.0), true)
	cv.draw_polyline(pts, Color("e8a464"), ctx.u(7.0), true)


## Honeycomb cells over the honey floor.
static func _honeycomb(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var r := ctx.u(44.0)
	var w := r * sqrt(3.0)
	var row := 0
	var y := ctx.full.position.y - r
	while y < ctx.full.end.y + r:
		var x := ctx.full.position.x - w + (w / 2.0 if row % 2 else 0.0)
		while x < ctx.full.end.x + w:
			var hex := PackedVector2Array()
			for i in 7:
				hex.append(Vector2(x, y) + Vector2.from_angle(i * TAU / 6.0 + PI / 6.0) * r * 0.94)
			Kit.line(cv, hex, Color(0.6, 0.35, 0.05, 0.28), ctx.u(4.0), ctx.outline)
			x += w
		y += r * 1.5
		row += 1


static func _shade(pts: PackedVector2Array, lamp: Vector2, reach: float, stops: Array) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(Kit.ramp(stops, p.distance_to(lamp) / reach))
	return cols
