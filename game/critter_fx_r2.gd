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
const BEAN_COLORS := {"bean_hot": Color("ff4a3d"), "bean_sour": Color("7ee04a"), "bean_fizz": Color("4aa8ff")}
const SHADOW := Color("5b4b9e")
const STAR := Color("ffd76a")
const RIFT_A := Color("38e0d0")
const RIFT_B := Color("b07cff")
const FLAME := Color("ff6a1f")


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
		"track":
			# Choo's toy railway: two wooden rails with sleepers.
			var r: float = z.radius * s
			var a := minf(1.0, fade * 4.0) * minf(1.0, z.age * 4.0)
			for k in 28:
				var ang := k * TAU / 28.0
				var d := Vector2(cos(ang), sin(ang))
				Dot.line(ci, p + d * (r - 20.0 * s), p + d * (r + 20.0 * s), Color(WOOD_DARK, 0.85 * a), 7.0 * s, true)
			for off in [-12.0, 12.0]:
				Dot.arc(ci, p, r + off * s, 0.0, TAU, 64, Color(STEEL_DARK, a), 5.0 * s, true)
				Dot.arc(ci, p, r + off * s, 0.0, TAU, 64, Color(STEEL, 0.8 * a), 2.0 * s, true)
			return true
		"bean_hot", "bean_sour", "bean_fizz", "bean_rainbow":
			# A glossy jelly bean on the floor, coloured by flavour; rainbow cycles.
			var col: Color = BEAN_COLORS.get(z.kind, Color.WHITE)
			if z.kind == "bean_rainbow":
				col = Color.from_hsv(fmod(t * 0.6, 1.0), 0.75, 1.0)
			var a := minf(1.0, fade * 3.0) * (0.5 + 0.5 * clampf(z.age / maxf(z.arm, 0.01), 0.0, 1.0))
			var w: float = z.radius * s
			var tilt: float = float(int(z.pos.x * 7.0 + z.pos.y) % 7) * 0.45
			var ax := Vector2(cos(tilt), sin(tilt))
			Dot.circle(ci, p + Vector2(2, 3) * s, w * 0.9, Color(0, 0, 0, 0.3 * a))
			Dot.line(ci, p - ax * w * 0.45, p + ax * w * 0.45, Color(col.darkened(0.25), a), w * 1.15, true)
			Dot.line(ci, p - ax * w * 0.45, p + ax * w * 0.45, Color(col, a), w * 0.95, true)
			Dot.circle(ci, p - ax * w * 0.3 + Vector2(-0.2, -0.25) * w, w * 0.18, Color(1, 1, 1, 0.7 * a))
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
	_draw_r2b(ci, sim, b, s, t)
	_draw_r2c(ci, sim, b, s, t)
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


## Rares and Epics: Shade's shadows, Astra's stars, Rift's portals and a
## blazing foe's flames.
static func _draw_r2b(ci: CanvasItem, sim, b, s: float, t: float) -> void:
	if b.state.has("shade_trail") and b.alive():
		var trail: Array = b.state.shade_trail
		var lag: int = int(round(float(b.def.get("shadow_delay", 1.0)) * sim.TICK_RATE))
		var backs := [lag]
		if int(b.def.get("shadow_two", 0)) > 0:
			backs.append(lag * 2)
		for k in backs.size():
			if trail.size() <= backs[k]:
				continue
			var sp: Vector2 = trail[trail.size() - 1 - backs[k]] * s
			var sr: float = b.radius * s
			var fa: float = 0.5 - 0.15 * k
			for w in 3: # Trailing wisps.
				var off: Vector2 = Vector2(sin(t * 3.0 + w * 2.1), cos(t * 2.3 + w)) * sr * 0.25
				Dot.circle(ci, sp + off + Vector2(0, sr * (0.5 + 0.2 * w)), sr * (0.45 - 0.1 * w), Color(SHADOW, fa * 0.5))
			Dot.circle(ci, sp, sr, Color(SHADOW.darkened(0.3), fa))
			Dot.arc(ci, sp, sr, 0.0, TAU, 32, Color("b07cff", fa), 2.0, true)
			for e in [-1.0, 1.0]:
				Dot.circle(ci, sp + Vector2(e * sr * 0.3, -sr * 0.1), sr * 0.13, Color(1, 1, 1, fa + 0.3))
	if b.state.has("astra_stars") or b.state.has("astra_lit") or b.state.has("star_flash"):
		var tw: float = 0.75 + 0.25 * sin(t * 7.0)
		for q in b.state.get("astra_stars", []):
			_star(ci, q * s, 11.0 * s * tw, STAR)
		var fl: Dictionary = b.state.get("star_flash", {})
		var lit: Dictionary = b.state.get("astra_lit", {})
		var age: float = (sim.tick - int(fl.get("tick", -9999))) / float(sim.TICK_RATE)
		var pts: Array = lit.get("points", fl.get("points", [])) if not lit.is_empty() else (fl.get("points", []) if age < 0.6 else [])
		if not pts.is_empty():
			var flash: float = clampf(1.0 - age / 0.6, 0.0, 1.0)
			var poly: PackedVector2Array = PackedVector2Array([pts[0] * s, pts[1] * s, pts[2] * s])
			Dot.poly(ci, poly, Color(STAR, 0.12 + 0.35 * flash))
			for i in 3:
				Dot.line(ci, poly[i], poly[(i + 1) % 3], Color(STAR, 0.6 + 0.4 * flash), 3.0 + 4.0 * flash, true)
				_star(ci, poly[i], 13.0 * s, Color("fff3c4"))
	if b.state.has("rift_portals"):
		var pts: Array = b.state.rift_portals.points
		for i in pts.size():
			var pp: Vector2 = pts[i] * s
			var pr: float = float(b.def.get("portal_radius", 44.0)) * s
			Dot.circle(ci, pp, pr, Color("0b0920", 0.35))
			for k in 3:
				var a0: float = t * (3.0 + k) * (1.0 if i % 2 == 0 else -1.0) + k * 2.1
				Dot.arc(ci, pp, pr * (1.0 - k * 0.22), a0, a0 + PI * 1.3, 20, RIFT_A if k % 2 == 0 else RIFT_B, 3.0, true)
	if b.alive() and sim.tick < int(b.state.get("ablaze_until", -1)):
		var p: Vector2 = b.pos * s
		var r: float = b.radius * s
		for k in 5:
			var a := -PI * 0.5 + (k - 2) * 0.45
			var h: float = r * (0.5 + 0.25 * sin(t * 12.0 + k * 1.7))
			var base: Vector2 = p + Vector2(cos(a), sin(a)) * r * 0.8
			var tip: Vector2 = base + Vector2(cos(a), sin(a) - 0.6).normalized() * h
			Dot.line(ci, base, tip, Color(FLAME, 0.75), r * 0.22, true)
			Dot.line(ci, base, base.lerp(tip, 0.6), Color("ffd23f", 0.85), r * 0.1, true)


## Reaper's countdown over a doomed foe and Choo's train.
static func _draw_r2c(ci: CanvasItem, sim, b, s: float, t: float) -> void:
	if b.alive() and b.state.has("doomed"):
		var d: Dictionary = b.state.doomed
		var p: Vector2 = b.pos * s
		var r: float = b.radius * s
		var total := maxf(1.0, float(int(d.at) - int(d.from)))
		var left := clampf(float(int(d.at) - sim.tick) / total, 0.0, 1.0)
		var c := p + Vector2(0, -r - 82.0 * s)
		Dot.circle(ci, c, 26.0 * s, Color(0.05, 0.05, 0.1, 0.8))
		Dot.arc(ci, c, 26.0 * s, -PI * 0.5, -PI * 0.5 + TAU * left, 32, Color("5cf0f0"), 4.0 * s, true)
		var n := ceili(left * total / sim.TICK_RATE)
		# A little skull: dome, eyes, jaw; it pulses each count.
		var pulse := 1.0 + 0.15 * maxf(0.0, sin(t * TAU))
		Dot.circle(ci, c + Vector2(0, -2) * s, 14.0 * s * pulse, Color("e8eef5"))
		Dot.circle(ci, c + Vector2(-5, -3) * s, 3.5 * s, Color("12131c"))
		Dot.circle(ci, c + Vector2(5, -3) * s, 3.5 * s, Color("12131c"))
		for k in 3:
			Dot.line(ci, c + Vector2(-5 + k * 5, 7) * s, c + Vector2(-5 + k * 5, 11) * s, Color("12131c"), 1.5 * s, true)
		if n > 0:
			for k in n:
				Dot.circle(ci, c + Vector2((k - (n - 1) * 0.5) * 12.0, 36.0) * s, 4.0 * s, Color("5cf0f0"))
	if b.state.has("choo"):
		var ch: Dictionary = b.state.choo
		var r: float = float(ch.r)
		var gap: float = (26.0 * 2.2) / r
		var gold := int(b.def.get("tier", 1)) >= 5
		for k in range(int(b.def.get("train_cars", 3)) - 1, -1, -1):
			var a: float = float(ch.ang) - k * gap
			var q: Vector2 = (ch.c + Vector2(cos(a), sin(a)) * r) * s
			var fwd := Vector2(-sin(a), cos(a))
			var side := fwd.orthogonal()
			var body := Color("e8433f") if k == 0 else (Color("3d7be8") if k % 2 == 1 else Color("ffd23f"))
			var w := 30.0 * s
			var pts := PackedVector2Array([q + fwd * w + side * w * 0.75, q + fwd * w - side * w * 0.75, q - fwd * w - side * w * 0.75, q - fwd * w + side * w * 0.75])
			Dot.poly(ci, pts, body.darkened(0.3))
			var inner := PackedVector2Array()
			for v in pts:
				inner.append(q + (v - q) * 0.8)
			Dot.poly(ci, inner, body)
			for e in [-1.0, 1.0]:
				Dot.circle(ci, q + side * w * 0.8 * e + fwd * w * 0.45, 6.0 * s, Color("ffd23f") if gold else Color("2a2a33"))
				Dot.circle(ci, q + side * w * 0.8 * e - fwd * w * 0.45, 6.0 * s, Color("ffd23f") if gold else Color("2a2a33"))
			if k == 0:
				Dot.circle(ci, q + fwd * w * 0.4, 8.0 * s, Color("2a2a33"))
				for m in 3: # Puffs of smoke.
					var age := fmod(t * 1.5 + m / 3.0, 1.0)
					Dot.circle(ci, q + fwd * w * 0.4 - fwd * age * 40.0 * s + Vector2(0, -age * 30.0 * s), (6.0 + age * 10.0) * s, Color(1, 1, 1, 0.5 * (1.0 - age)))


static func _star(ci: CanvasItem, p: Vector2, size: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var a := -PI * 0.5 + k * TAU / 8.0
		pts.append(p + Vector2(cos(a), sin(a)) * size * (1.0 if k % 2 == 0 else 0.4))
	Dot.poly(ci, pts, col)


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
		"bean":
			if e.ball != e.source:
				var names := {"bean_hot": "HOT!", "bean_sour": "SOUR!", "bean_fizz": "FIZZ!", "bean_rainbow": "RAINBOW!"}
				view._add_popup(e.pos + Vector2(0, -40), names.get(e.kind, "NOM!"), BEAN_COLORS.get(e.kind, Color("ff6fae")), 1.0)
			else:
				view._add_popup(e.pos + Vector2(0, -40), "NOM!", Color("ff6fae"), 0.9)
		"constellation":
			view._add_popup(e.pos, "STARS!", STAR, 1.0)
		"firestorm":
			view._add_popup(e.pos + Vector2(0, -40), "FIRESTORM!", FLAME, 1.2)
		"warp":
			view._add_popup(e.to + Vector2(0, -50), "WARP!", RIFT_A, 0.9)
		"doom":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 130), "DOOMED!", Color("5cf0f0"), 1.1)
		"doom_break":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 40), "CURSE BROKEN!", Color("e8eef5"), 1.0)
		"reap":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 40), "REAPED!", Color("5cf0f0"), 1.3)
		"track":
			view._add_popup(e.pos, "CHOO CHOO!", Color("ffd23f"), 1.1)
		"pop":
			view._add_popup(e.pos + Vector2(0, -sim.balls[e.ball].radius - 30), "POP!", POPCORN, 1.0)
