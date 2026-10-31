## Fight art for the round-2 critters (2026-10-31): Boing's springs, Kernel's
## kernels, Boomer's boomerangs, Snowbo's snow, Zorp's tractor beam and
## Gourdo's scare. Render only: arena_view hands each piece over here first.
extends RefCounted

const Dot := preload("res://game/dot.gd")

const STEEL := Color("c9d3ea")
const STEEL_DARK := Color("6b7590")
const KERNEL := Color("ffcf5c")
const POPCORN := Color("fff6dc")
const WOOD := Color("d99a4c")
const WOOD_DARK := Color("8a5a1c")
const SNOW := Color("f4fbff")
const BEAM := Color("7dffb2")
const SCARE := Color("ffb02e")


## A zone this file draws; false leaves it to arena_view.
static func draw_zone(ci: CanvasItem, z, p: Vector2, s: float, fade: float, t: float) -> bool:
	match z.kind:
		"spring":
			# A coiled spring pad: squashes when something's on it, fades out at the end.
			var r: float = z.radius * s
			var a := minf(1.0, fade * 3.0)
			var arm: float = clampf(z.age / maxf(z.arm, 0.01), 0.0, 1.0)
			Dot.circle(ci, p + Vector2(2, 3) * s, r, Color(0, 0, 0, 0.3 * a))
			Dot.circle(ci, p, r, Color(STEEL_DARK, 0.85 * a))
			for k in 3:
				var rr := r * (0.85 - k * 0.22) * (0.6 + 0.4 * arm)
				Dot.arc(ci, p + Vector2(0, -k * 2.0) * s, rr, 0.0, TAU, 28, Color(STEEL.lightened(0.1 * k), a), maxf(2.0, r * 0.1), true)
			Dot.circle(ci, p + Vector2(0, -6.0) * s, r * 0.22, Color("5cf0b0", a * (0.6 + 0.4 * sin(t * 6.0))))
			return true
	return false


## A shot this file draws; false leaves it to arena_view.
static func draw_shot(ci: CanvasItem, shot, p: Vector2, r: float, t: float) -> bool:
	match shot.kind:
		"kernel":
			# A hot kernel: golden, steaming, spinning as it ricochets.
			var spin: float = t * 14.0 + shot.pos.x * 0.03
			var d: Vector2 = shot.vel.normalized() if shot.vel.length() > 0.001 else Vector2.RIGHT
			Dot.line(ci, p, p - d * r * 2.4, Color(1, 0.8, 0.4, 0.35), r * 0.9, true)
			var pts := PackedVector2Array()
			for k in 8:
				var a := spin + k * TAU / 8.0
				pts.append(p + Vector2(cos(a), sin(a)) * r * (1.15 if k % 2 == 0 else 0.85))
			Dot.poly(ci, pts, KERNEL)
			Dot.circle(ci, p + Vector2(-0.3, -0.3) * r, r * 0.45, POPCORN)
			return true
	return false


## Per-ball extras: boomerangs in flight, snow on a snowed-up ball, Zorp's
## beam on a lifted foe, a scared foe's sweat and Boing's launch streaks.
static func draw_ball(ci: CanvasItem, sim, b, s: float, t: float) -> void:
	if b.state.has("boomerangs"):
		for fl in b.state.boomerangs:
			draw_boomerang(ci, fl.pos * s, 26.0 * s, fl.age * 14.0, int(sim.balls[b.index].def.get("tier", 1)) >= 5)
	if not b.alive():
		return
	var p: Vector2 = b.pos * s
	var r: float = b.radius * s
	if int(b.state.get("snow", 0)) > 0 and sim.tick < int(b.state.get("snow_until", -1)):
		# Snow lumps stuck round its rim, one per lump.
		for k in int(b.state.snow):
			var a: float = -PI * 0.5 + (k - 1) * 1.6 + b.index
			var q := p + Vector2(cos(a), sin(a)) * r * 0.86
			Dot.circle(ci, q, r * 0.34, Color("cfe6f5"))
			Dot.circle(ci, q + Vector2(-0.08, -0.08) * r, r * 0.28, SNOW)
	if sim.tick < int(b.state.get("lifted_until", -1)):
		# Zorp's tractor beam: a green cone from above with rings rising through it.
		var top := p + Vector2(0, -r * 3.2)
		Dot.poly(ci, PackedVector2Array([top + Vector2(-r * 0.4, 0), top + Vector2(r * 0.4, 0), p + Vector2(r * 1.25, r * 0.4), p + Vector2(-r * 1.25, r * 0.4)]), Color(BEAM, 0.28))
		for k in 3:
			var q := fmod(t * 1.5 + k / 3.0, 1.0)
			var y := lerpf(r * 0.4, -r * 3.0, q)
			Dot.arc(ci, Vector2(p.x, p.y + y), r * lerpf(1.2, 0.45, q), 0.0, TAU, 24, Color(BEAM, 0.7 * (1.0 - q)), 2.5, true)
	if sim.tick < int(b.state.get("scared_until", -1)):
		# A scared foe sweats and shakes.
		var j := Vector2(sin(t * 60.0), cos(t * 47.0)) * 2.0
		var dp := p + Vector2(r * 0.7, -r * 0.75) + j
		Dot.poly(ci, PackedVector2Array([dp + Vector2(0, -r * 0.2), dp + Vector2(r * 0.1, 0), dp + Vector2(-r * 0.1, 0)]), Color("9fd8ff"))
		Dot.circle(ci, dp + Vector2(0, r * 0.02), r * 0.1, Color("9fd8ff"))
	if sim.tick < int(b.state.get("launched_until", -1)) and b.vel.length() > 0.001:
		var d: Vector2 = b.vel.normalized()
		for k in 3:
			var o := d.orthogonal() * (k - 1) * r * 0.45
			Dot.line(ci, p - d * r * 1.1 + o, p - d * r * (1.9 + 0.2 * k) + o, Color(STEEL, 0.6), maxf(2.0, r * 0.08), true)


## Boomer's boomerang, spinning.
static func draw_boomerang(ci: CanvasItem, p: Vector2, size: float, spin: float, gold: bool) -> void:
	var tip := Color("ffd23f") if gold else Color("e8433f")
	for k in [-1.0, 1.0]:
		var a := spin + (0.0 if k > 0 else 1.9)
		var e := p + Vector2(cos(a), sin(a)) * size
		Dot.line(ci, p, e, WOOD_DARK, size * 0.42, true)
		Dot.line(ci, p, e, WOOD, size * 0.3, true)
		Dot.circle(ci, e, size * 0.2, tip)
	Dot.circle(ci, p, size * 0.2, WOOD)


## Popups and bursts for round-2 events. `view` is the ArenaView.
static func event(view, sim, e: Dictionary) -> void:
	match e.type:
		"scare":
			if e.source < sim.balls.size():
				view._add_popup(e.pos + Vector2(0, -sim.balls[e.source].radius - 30), "BOO!", SCARE, 1.3)
		"wake":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 30), "AWAKE!", Color("ffe9a3"), 1.1)
		"snowball":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 30), "SNOWBALL!", SNOW, 1.1)
		"abduct":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 40), "BEAM UP!", BEAM, 1.0)
		"pop":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 30), "POP!", POPCORN, 1.0)
