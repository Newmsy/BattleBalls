extends RefCounted
## Extra fight effects drawn by game/arena_view.gd: status effects you can
## read at a glance (burn, poison, bleed, slow goo, ice) and per-critter
## flourishes (Zip's speed blur, Fuse's bombs, Chill's frost, Sooty's embers,
## Bubbles' bubble, Pinball's charge, Count Nibbles' chomp).
## Render-only: reads the sim, never changes it. Call from a CanvasItem's
## _draw() with screen-space positions (world * view scale).

const A11y := preload("res://game/a11y.gd")

const BURN := Color("ff7a1f")
const BURN_CORE := Color("ffe066")
const POISON := Color("8cff4f")
const BLEED := Color("ff2d55")
const CURSE := Color("c58bff")
const ICE := Color("bfefff")
const GOO := Color("ff8cc6")
const HONEY := Color("ffb627")

## How a damage-over-time looks, by the critter that applied it. Anything
## not listed burns.
const DOT_LOOKS := {
	"thorns": "bleed", "fin": "bleed", "mirror": "bleed", "prism": "bleed",
	"gumdrop": "poison", "honey": "poison", "sooty": "burn",
	"blackhole": "curse", "glowbug": "curse", "gravity": "curse",
}
## Slows that read as sticky goo rather than ice, by source critter or zone.
const GOO_LOOKS := {"gumdrop": GOO, "bonbon": GOO, "sundae": GOO, "honey": HONEY, "splat": GOO, "sour": Color("9ef01a"),
	"fizz": GOO, "ink": Color("8a5cc8"), "inkpool": Color("8a5cc8"), "goo": Color("7cff6b"), "brew": Color("b6ff3b")}

## Name shown in the popup when a damage-over-time first lands.
const DOT_WORDS := {"burn": "BURN!", "poison": "POISON!", "bleed": "BLEED!", "curse": "CURSED!"}
const DOT_COLORS := {"burn": BURN, "poison": POISON, "bleed": BLEED, "curse": CURSE}

const CHOMP_LIFE := 0.32


static func dot_kind(sim, d: Dictionary) -> String:
	var src: int = d.get("source", -1)
	if src < 0 or src >= sim.balls.size():
		return "burn"
	return DOT_LOOKS.get(sim.balls[src].type_id, "burn")


## Distinct looks of the damage-over-time effects on `b`.
static func dot_kinds(sim, b) -> Array:
	var out: Array = []
	for d in b.dots:
		var k := dot_kind(sim, d)
		if not k in out:
			out.append(k)
	return out


## The colour a slowed ball's goo takes, or null-equivalent Color(0,0,0,0) for ice.
static func slow_goo(sim, b) -> Color:
	for key in b.statuses:
		var st: Dictionary = b.statuses[key]
		if st.kind == "slow" and sim.tick < st.until and st.source >= 0 and st.source < sim.balls.size():
			var src: String = sim.balls[st.source].type_id
			if GOO_LOOKS.has(src):
				return GOO_LOOKS[src]
	for z in sim.zones:
		if z.slow > 0.0 and GOO_LOOKS.has(z.kind) and z.pos.distance_to(b.pos) < z.radius + b.radius:
			return GOO_LOOKS[z.kind]
	return Color(0, 0, 0, 0)


# --- Status effects on a ball ----------------------------------------------------

static func draw_dots(ci: CanvasItem, kinds: Array, p: Vector2, r: float, t: float) -> void:
	for kind in kinds:
		match kind:
			"burn":
				_flames(ci, p, r, t)
			"poison":
				ci.draw_circle(p, r, Color(POISON, 0.16))
				for k in 5:
					var f := fmod(t * 0.9 + k * 0.2, 1.0)
					var x := sin(k * 2.3) * r * 0.6
					var at := p + Vector2(x, -r * 0.2 - f * r * 1.1)
					var rad := r * (0.07 + 0.06 * f)
					ci.draw_circle(at, rad, Color(POISON, 0.75 * (1.0 - f)))
					ci.draw_arc(at, rad, 0.0, TAU, 12, Color(Color("d9ffb8"), 0.8 * (1.0 - f)), 1.5, true)
			"bleed":
				for k in 3:
					var a := -0.9 + k * 0.6
					var c := p + Vector2.from_angle(a) * r * 0.35
					var d := Vector2.from_angle(a + PI / 2.0) * r * 0.3
					ci.draw_line(c - d, c + d, Color(BLEED, 0.85), maxf(2.0, r * 0.07), true)
				for k in 4:
					var f := fmod(t * 1.3 + k * 0.25, 1.0)
					var at := p + Vector2((k - 1.5) * r * 0.35, r * (0.55 + f * 0.8))
					_drop(ci, at, r * 0.09, Color(BLEED, 0.9 * (1.0 - f)))
			"curse":
				for k in 6:
					var a := t * 2.0 + k * TAU / 6.0
					var at := p + Vector2(cos(a), sin(a) * 0.5) * r * 1.1
					ci.draw_circle(at, r * 0.08, Color(CURSE, 0.7))
					ci.draw_circle(at - Vector2(cos(a), sin(a) * 0.5) * r * 0.12, r * 0.05, Color(CURSE, 0.35))


## Licking flames round the top of a burning ball, with embers rising.
static func _flames(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	ci.draw_circle(p, r * 1.02, Color(BURN, 0.12))
	for k in 7:
		var a := PI + 0.25 + k * (PI - 0.5) / 6.0
		var base := p + Vector2.from_angle(a) * r * 0.85
		var flick := 0.75 + 0.35 * sin(t * 17.0 + k * 1.9)
		var up := (Vector2.from_angle(a) * 0.5 + Vector2(0, -1.0)).normalized()
		var side := up.orthogonal()
		var h := r * 0.55 * flick
		var w := r * 0.16
		ci.draw_colored_polygon(PackedVector2Array([base - side * w, base + up * h * 0.5 - side * w * 0.6, base + up * h, base + up * h * 0.5 + side * w * 0.6, base + side * w]), Color(BURN, 0.85))
		ci.draw_colored_polygon(PackedVector2Array([base - side * w * 0.45, base + up * h * 0.55, base + side * w * 0.45]), Color(BURN_CORE, 0.9))
	for k in 4:
		var f := fmod(t * 1.1 + k * 0.25, 1.0)
		ci.draw_circle(p + Vector2(sin(k * 3.1 + t) * r * 0.7, -r * (0.9 + f * 0.9)), 3.0 * (1.0 - f) + 1.0, Color(BURN_CORE, 1.0 - f))


static func _drop(ci: CanvasItem, at: Vector2, rad: float, col: Color) -> void:
	ci.draw_circle(at, rad, col)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-rad * 0.9, -rad * 0.3), at + Vector2(0, -rad * 2.4), at + Vector2(rad * 0.9, -rad * 0.3)]), col)


## A slowed ball: frosted over with ice shards, or dripping goo.
static func draw_slow(ci: CanvasItem, goo: Color, amount: float, p: Vector2, r: float, t: float) -> void:
	var k := clampf(amount / 0.5, 0.4, 1.0)
	if goo.a > 0.0:
		ci.draw_arc(p, r * 0.98, 0.0, TAU, 48, Color(goo, 0.75 * k), maxf(3.0, r * 0.12), true)
		for q in 5:
			var x := (q - 2) * r * 0.36
			var f := fmod(t * 0.7 + q * 0.37, 1.0)
			var top := p + Vector2(x, sqrt(maxf(0.0, r * r - x * x)) * 0.92)
			var len := r * (0.15 + 0.35 * f)
			ci.draw_line(top, top + Vector2(0, len), Color(goo, 0.85 * k), maxf(3.0, r * 0.1), true)
			ci.draw_circle(top + Vector2(0, len), maxf(2.5, r * 0.08), Color(goo, 0.9 * k))
		ci.draw_circle(p + Vector2(-r * 0.4, -r * 0.45), r * 0.1, Color(1, 1, 1, 0.45 * k))
		return
	ci.draw_circle(p, r, Color(ICE, 0.18 * k))
	ci.draw_arc(p, r * 1.0, 0.0, TAU, 48, Color(ICE, 0.75 * k), 2.5, true)
	for q in 8:
		var a := q * TAU / 8.0 + 0.2
		var d := Vector2.from_angle(a)
		var len := r * (0.22 + 0.1 * sin(q * 2.7))
		var base := p + d * r * 0.9
		var side := d.orthogonal() * r * 0.07
		ci.draw_colored_polygon(PackedVector2Array([base - side, base + d * len, base + side]), Color(ICE, 0.85 * k))
	var glint := fmod(t * 0.8, 1.0)
	_sparkle(ci, p + Vector2.from_angle(glint * TAU) * r * 0.6, r * 0.14 * (1.0 - absf(glint * 2.0 - 1.0)), Color(1, 1, 1, 0.9 * k))


static func _sparkle(ci: CanvasItem, at: Vector2, size: float, col: Color) -> void:
	if size <= 0.5:
		return
	ci.draw_line(at - Vector2(size, 0), at + Vector2(size, 0), col, 2.0, true)
	ci.draw_line(at - Vector2(0, size), at + Vector2(0, size), col, 2.0, true)


# --- Per-critter flourishes ------------------------------------------------------

## Zip (and anything faster than its base speed): fading copies trailing
## behind plus speed lines, stronger the faster it goes.
static func draw_speed_blur(ci: CanvasItem, col: Color, p: Vector2, r: float, vel: Vector2, ratio: float, t: float) -> void:
	var k := clampf((ratio - 1.05) / 0.8, 0.0, 1.0)
	if k <= 0.0 or vel.length() < 0.001:
		return
	var back := -vel.normalized()
	var copies := 2 + int(k * 3.0)
	for q in range(copies, 0, -1):
		var f := float(q) / copies
		ci.draw_circle(p + back * r * 0.55 * q * (0.6 + k * 0.5), r * (1.0 - 0.08 * q), Color(col, 0.22 * (1.0 - f * 0.7) * k))
	var side := back.orthogonal()
	for q in 5:
		var o := (q - 2) * r * 0.32
		var jitter := 0.6 + 0.4 * sin(t * 25.0 + q * 2.1)
		var a := p + back * r * 0.9 + side * o
		ci.draw_line(a, a + back * r * (1.0 + 1.6 * k) * jitter, Color(1, 1, 1, 0.55 * k), 2.5, true)


## Fuse's bombs: a round bomb with a lit fuse and a hazard ring showing the
## blast reach; they puff in when dropped and flash red when armed.
static func draw_bomb(ci: CanvasItem, p: Vector2, s: float, armed: bool, blast: float, age: float, seed: float, t: float) -> void:
	var grow := clampf(age / 0.25, 0.0, 1.0)
	var rad := 26.0 * s * (0.4 + 0.6 * grow)
	if armed:
		var pulse := 0.5 + 0.5 * sin(t * 6.0 + seed)
		ci.draw_circle(p, blast * s, Color(Color("ff4d4d"), 0.06 + 0.05 * pulse))
		var dashes := 20
		for q in dashes:
			var a := q * TAU / dashes + t * 0.4
			ci.draw_arc(p, blast * s, a, a + TAU / dashes * 0.5, 4, Color(Color("ff4d4d"), 0.45), 2.0, true)
	ci.draw_circle(p + Vector2(2, 3) * s, rad, Color(0, 0, 0, 0.35))
	ci.draw_circle(p, rad, Color("1f2547"))
	ci.draw_circle(p + Vector2(-rad * 0.3, -rad * 0.3), rad * 0.35, Color(1, 1, 1, 0.18))
	ci.draw_arc(p, rad, 0.0, TAU, 24, Color("8fa2ff"), 2.0, true)
	var neck := p + Vector2(rad * 0.45, -rad * 0.85)
	ci.draw_line(neck, neck + Vector2(rad * 0.35, -rad * 0.45), Color("d6b37a"), 3.0, true)
	var tip := neck + Vector2(rad * 0.35, -rad * 0.45)
	var flick := 0.7 + 0.3 * sin(t * 30.0 + seed)
	ci.draw_circle(tip, rad * 0.28 * flick, Color(BURN, 0.9))
	ci.draw_circle(tip, rad * 0.14 * flick, Color(BURN_CORE))
	var on := armed and fmod(t * 3.0 + seed, 1.0) < 0.5
	ci.draw_circle(p, rad * 0.32, Color("ff4d4d") if on else Color(Color("ff4d4d"), 0.3))


## Chill's ice trail: frosty slabs with crystal glints.
static func draw_ice(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	ci.draw_circle(p, rad, Color(ICE, 0.22 * fade))
	ci.draw_circle(p, rad * 0.6, Color(Color("e8fbff"), 0.2 * fade))
	for q in 3:
		var a := seed * 3.0 + q * TAU / 3.0
		var at := p + Vector2.from_angle(a) * rad * 0.45
		var d := Vector2.from_angle(a + 0.7) * rad * 0.35
		ci.draw_line(at - d, at + d, Color(1, 1, 1, 0.5 * fade), 1.5, true)
	var glint := 0.5 + 0.5 * sin(t * 3.0 + seed * 7.0)
	_sparkle(ci, p + Vector2.from_angle(seed * 5.0) * rad * 0.3, rad * 0.35 * glint * fade, Color(1, 1, 1, 0.8 * fade))


## Sooty's hot patch: scorched ground with glowing cracks and rising embers.
static func draw_embers(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	ci.draw_circle(p, rad, Color(Color("1a0d08"), 0.55 * fade))
	ci.draw_circle(p, rad * 0.8, Color(BURN, (0.18 + 0.08 * sin(t * 5.0 + seed)) * fade))
	for q in 5:
		var a := seed * 2.0 + q * TAU / 5.0
		var pts := PackedVector2Array()
		var at := p + Vector2.from_angle(a) * rad * 0.1
		pts.append(at)
		for step in 3:
			at += Vector2.from_angle(a + sin(seed + q * 3.0 + step) * 0.6) * rad * 0.28
			pts.append(at)
		ci.draw_polyline(pts, Color(BURN_CORE, (0.55 + 0.35 * sin(t * 7.0 + q)) * fade), 2.0, true)
	for q in 5:
		var f := fmod(t * 0.8 + q * 0.2 + seed, 1.0)
		var at := p + Vector2(sin(q * 2.4 + seed) * rad * 0.6, -f * rad * 1.2)
		ci.draw_circle(at, 3.0 * (1.0 - f) + 1.0, Color(BURN_CORE, (1.0 - f) * fade))


## Bubbles' shield: a wobbling soap bubble with a rainbow sheen.
static func draw_bubble(ci: CanvasItem, p: Vector2, r: float, t: float, left: float) -> void:
	var rad := r * 1.25
	var pts := PackedVector2Array()
	for q in 41:
		var a := q * TAU / 40.0
		var wob := 1.0 + 0.035 * sin(a * 3.0 + t * 4.0) * A11y.motion()
		pts.append(p + Vector2.from_angle(a) * rad * wob)
	ci.draw_colored_polygon(pts, Color("9ff3f6", 0.14))
	for q in 40:
		ci.draw_line(pts[q], pts[q + 1], Color.from_hsv(fmod(q / 40.0 + t * 0.3, 1.0), 0.45, 1.0, 0.85 * clampf(left * 2.0, 0.35, 1.0)), 3.0, true)
	ci.draw_arc(p, rad * 0.8, PI * 1.1, PI * 1.45, 12, Color(1, 1, 1, 0.7), 4.0, true)
	ci.draw_circle(p + Vector2(-rad * 0.42, -rad * 0.55), rad * 0.07, Color(1, 1, 1, 0.8))


## Pinball's charge: a ring of bulbs that lights one per wall and crackles
## when the board is full.
static func draw_pinball(ci: CanvasItem, p: Vector2, r: float, lit: int, total: int, t: float) -> void:
	if total <= 0:
		return
	var rad := r * 1.2
	for q in total:
		var a := -PI / 2.0 + (q - (total - 1) / 2.0) * 0.42
		var at := p + Vector2.from_angle(a) * rad
		var on := q < lit
		if on:
			ci.draw_circle(at, 11.0, Color(Color("ffe066"), 0.3))
		ci.draw_circle(at, 6.0, Color("ffe066") if on else Color(Color("3a335c"), 0.9))
	if lit >= total:
		var glow := 0.5 + 0.5 * sin(t * 20.0)
		ci.draw_arc(p, r * 1.08, 0.0, TAU, 48, Color(Color("ffe066"), 0.4 + 0.4 * glow), 4.0, true)
		for q in 3:
			var a := t * 9.0 + q * TAU / 3.0
			var pts := PackedVector2Array([p + Vector2.from_angle(a) * r * 1.0])
			for step in 3:
				pts.append(p + Vector2.from_angle(a + 0.12 * (step + 1)) * r * (1.12 + 0.1 * ((step % 2) * 2 - 1)))
			ci.draw_polyline(pts, Color(Color("fffbe0"), 0.9), 2.0, true)
	elif lit > 0:
		ci.draw_arc(p, r * 1.08, 0.0, TAU, 48, Color(Color("ffe066"), 0.12 * lit), 3.0, true)


## Count Nibbles' bite: two fanged jaws snapping shut on the hit.
static func draw_chomp(ci: CanvasItem, at: Vector2, dir: Vector2, size: float, age: float) -> void:
	var u := clampf(age / CHOMP_LIFE, 0.0, 1.0)
	var close := minf(1.0, u * 3.0) ## Snaps shut in the first third, then fades.
	var alpha := 1.0 - maxf(0.0, (u - 0.4) / 0.6)
	var open := (1.0 - close) * 0.9 + 0.08
	var side := dir.orthogonal()
	for jaw: float in [-1.0, 1.0]:
		var hinge := at - dir * size * 0.6
		var lip: Vector2 = hinge + (dir * cos(open) + side * jaw * sin(open)) * size * 1.3
		var mid: Vector2 = hinge.lerp(lip, 0.5) + side * jaw * size * 0.35
		ci.draw_polyline(PackedVector2Array([hinge, mid, lip]), Color(Color("ffffff"), 0.9 * alpha), 4.0, true)
		for f in 3:
			var q := hinge.lerp(lip, 0.35 + f * 0.25)
			var toward: Vector2 = -side * jaw
			ci.draw_colored_polygon(PackedVector2Array([q - dir * size * 0.08, q + toward * size * 0.28, q + dir * size * 0.08]), Color(1, 1, 1, alpha))
	if close >= 1.0:
		ci.draw_circle(at, size * 0.25 * (1.0 - u), Color(BLEED, 0.6 * alpha))
