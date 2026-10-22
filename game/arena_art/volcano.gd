## Volcano (magma, inferno): cracked basalt plates with magma glowing up
## through every crack, heat glowing round the lava pools, jagged black rock
## walls with lava seams, smoke and embers outside. Inferno runs hotter.
## Render-only.
extends RefCounted

const Kit := preload("res://game/arena_art/kit.gd")


static func paint(cv: CanvasItem, ctx: Kit.Ctx) -> void:
	var hot := ctx.id == "inferno"
	var reach := ctx.canvas.size.x * 0.75
	Kit.rect_fill(cv, ctx.canvas, func(p): return Kit.ramp(["4a160c", "260a06", "0e0606"], p.distance_to(ctx.centre) / reach))
	for p in Kit.scatter_out(ctx, 8, ctx.u(30.0)):
		Kit.glow(cv, p, ctx.u(80.0), Color(0.22, 0.18, 0.2, 0.6), 0.5)

	# Magma underneath, then basalt plates with gaps for it to glow through.
	var magma := ["ffd23f", "ff7a1f", "c0260f"] if not hot else ["ffb21f", "ff4a1f", "8a0f0a"]
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
				cell[k] = mid + (cell[k] - mid) * 0.9
			var tone := Color("4a3c40") if (i + j) % 2 else Color("3e3236")
			for part in Geometry2D.intersect_polygons(cell, ctx.outline):
				Kit.lit(cv, part, tone, Color("150e10"))
			cv.draw_polyline(PackedVector2Array([cell[3], cell[0], cell[1]]), Color(0.6, 0.45, 0.42, 0.4), ctx.u(1.6), true)
	for f in ctx.floors: # Heat glowing round each lava pool.
		if f.kind == "lava" and f.has("pos"):
			Kit.glow(cv, f.pos, f.radius * 2.3, Color(1.0, 0.45, 0.1, 0.5))
			cv.draw_arc(f.pos, f.radius * 1.08, 0.0, TAU, 48, Color("241614"), ctx.u(8.0), true)
	for p in Kit.scatter_in(ctx, 6, ctx.u(60.0), [[ctx.centre, ctx.u(100.0)]]):
		var shard := PackedVector2Array([p + Vector2(0, -ctx.u(14.0)), p + Vector2(ctx.u(7.0), ctx.u(6.0)), p + Vector2(-ctx.u(6.0), ctx.u(8.0))])
		Kit.poly(cv, shard, Color("1a1028"))
		cv.draw_line(shard[0], shard[1], Color("8a6ac0"), ctx.u(1.5), true)
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
	Kit.glow(cv, c, r * 1.5, Color(1.0, 0.4, 0.1, 0.35))
	Kit.shadow(cv, c, r, 0.5)
	Kit.lit(cv, Kit.blob(c, r, ctx.rng, 8, 0.12), Color("5a4a4e"), Color("140c0d"))
	var crack := PackedVector2Array([c + Vector2(-0.6, -0.3) * r, c + Vector2(-0.1, 0.05) * r, c + Vector2(0.2, -0.2) * r, c + Vector2(0.6, 0.35) * r])
	cv.draw_polyline(crack, Color(1.0, 0.45, 0.1, 0.5), r * 0.22, true)
	cv.draw_polyline(crack, Color("ffd23f"), r * 0.07, true)
