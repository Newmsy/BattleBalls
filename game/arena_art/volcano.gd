## Volcano (magma, inferno): cooled basalt plates with only a dim ember
## glow in the cracks, so the real lava (drawn on top) is the only bright
## thing that burns. Heat glows round the lava, jagged black rock walls with
## lava seams, smoke and embers outside. Inferno runs hotter.
## Render-only.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var hot := ctx.id == "inferno"
	var reach := ctx.canvas.size.x * 0.75
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["4a160c", "260a06", "0e0606"], p.distance_to(ctx.centre) / reach))
	for p in Kit.scatter_out(ctx, 8, ctx.u(30.0)):
		Kit.glow(cv, p, ctx.u(80.0), Color(0.22, 0.18, 0.2, 0.6), 0.5)

	# Dim embers underneath, then basalt plates with thin cracks over them.
	var magma := ["7a2c12", "4a180c", "2a0e08"] if not hot else ["8a2a10", "561208", "2a0806"]
	Kit.floor_fill(cv, ctx, func(p): return Kit.ramp(magma, p.distance_to(ctx.centre) / (ctx.full.size.x * 0.65)))
	var n := 9
	var step := ctx.full.size.x / n
	var grid := []
	for i in n + 1:
		var col := []
		for j in n + 1:
			var jitter := Vector2.ZERO if i == 0 or j == 0 or i == n or j == n else Vector2(ctx.rng.randf_range(-0.22, 0.22), ctx.rng.randf_range(-0.22, 0.22)) * step
			col.append(ctx.full.position + Vector2(i, j) * step + jitter)
		grid.append(col)
	for i in n:
		for j in n:
			var cell := PackedVector2Array([grid[i][j], grid[i + 1][j], grid[i + 1][j + 1], grid[i][j + 1]])
			var mid := (cell[0] + cell[1] + cell[2] + cell[3]) / 4.0
			for k in 4:
				cell[k] = mid + (cell[k] - mid) * 0.96
			var tone := Color("3a3134") if (i + j) % 2 else Color("312a2d")
			for part in Geometry2D.intersect_polygons(cell, ctx.outline):
				Kit.lit(cv, part, tone, Color("150e10"))
			Dot.pline(cv, PackedVector2Array([cell[3], cell[0], cell[1]]), Color(0.6, 0.45, 0.42, 0.4), ctx.u(1.6), true)
	for f in ctx.floors: # Heat glowing round each lava pool and strip.
		if f.kind != "lava":
			continue
		if f.has("pos"):
			Kit.glow(cv, f.pos, f.radius * 2.3, Color(1.0, 0.45, 0.1, 0.5))
			Dot.arc(cv, f.pos, f.radius * 1.08, 0.0, TAU, 48, Color("241614"), ctx.u(8.0), true)
		else:
			var r: Rect2 = f.rect
			var c := r.get_center()
			for k in 3:
				Kit.glow(cv, c + Vector2(0, (k - 1) * r.size.y * 0.33), r.size.x * 2.6, Color(1.0, 0.45, 0.1, 0.35))
	for p in Kit.scatter_in(ctx, 6, ctx.u(60.0), [[ctx.centre, ctx.u(100.0)]]):
		var shard := PackedVector2Array([p + Vector2(0, -ctx.u(14.0)), p + Vector2(ctx.u(7.0), ctx.u(6.0)), p + Vector2(-ctx.u(6.0), ctx.u(8.0))])
		Kit.poly(cv, shard, Color("1a1028"))
		Dot.line(cv, shard[0], shard[1], Color("8a6ac0"), ctx.u(1.5), true)
	Kit.inner_shadow(cv, ctx, ctx.u(38.0), 0.55)

	# Jagged rock walls with glowing seams.
	Kit.strip(cv, Kit.offset(ctx.outline, -ctx.u(2.0)), Kit.offset(ctx.outline, ctx.wall), Color("ff6a1f"), Color("7a1a0a"))
	Kit.blocks(ctx, ctx.u(42.0), ctx.wall, func(q, _e, _i):
		var mid: Vector2 = (q[0] + q[1] + q[2] + q[3]) / 4.0
		var rock := PackedVector2Array()
		for k in 4:
			rock.append(mid + (q[k] - mid) * ctx.rng.randf_range(0.78, 0.92))
		rock.insert(2, mid + (q[1].lerp(q[2], 0.5) - mid) * 0.95 + Vector2(ctx.rng.randf_range(-1, 1), ctx.rng.randf_range(-1, 1)) * ctx.u(4.0))
		Kit.lit(cv, rock, Color("5a4a4e"), Color("140c0d")))


## A basalt boulder with a glowing crack.
static func pillar(cv: CanvasItem, ctx: Kit.Ctx, c: Vector2, r: float) -> void:
	Kit.glow(cv, c, r * 1.6, Color(1.0, 0.45, 0.1, 0.6))
	Kit.shadow(cv, c, r, 0.5)
	var rock := Kit.blob(c, r, ctx.rng, 8, 0.12)
	Kit.lit(cv, rock, Color("9a8488"), Color("3a2a2c"))
	var rim := rock.duplicate()
	rim.append(rock[0])
	Dot.pline(cv, rim, Color("ff8a3d"), maxf(1.5, r * 0.08), true)
	var crack := PackedVector2Array([c + Vector2(-0.6, -0.3) * r, c + Vector2(-0.1, 0.05) * r, c + Vector2(0.2, -0.2) * r, c + Vector2(0.6, 0.35) * r])
	Dot.pline(cv, crack, Color(1.0, 0.45, 0.1, 0.5), r * 0.22, true)
	Dot.pline(cv, crack, Color("ffd23f"), r * 0.07, true)
