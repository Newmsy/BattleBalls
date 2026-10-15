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


# --- Batch 2 ---------------------------------------------------------------------

const BOLT_LIFE := 0.3
const SOUR := Color("d4ff3a")

## A jagged lightning bolt from `a` to `b` (Static, thunder). `seed` picks
## the zigzag; it re-rolls every few frames so the bolt crackles.
static func draw_bolt(ci: CanvasItem, a: Vector2, b: Vector2, age: float, seed: float, col := Color("bfe8ff")) -> void:
	var u := clampf(age / BOLT_LIFE, 0.0, 1.0)
	var alpha := 1.0 - u
	var flick := floori(age * 30.0)
	var pts := PackedVector2Array([a])
	var side := (b - a).orthogonal().normalized()
	var len := a.distance_to(b)
	var steps := clampi(int(len / 18.0), 4, 14)
	for k in range(1, steps):
		var f := float(k) / steps
		var j := sin(seed * 13.7 + k * 7.3 + flick * 3.1) * len * 0.09
		pts.append(a.lerp(b, f) + side * j)
	pts.append(b)
	ci.draw_polyline(pts, Color(col, 0.35 * alpha), 9.0, true)
	ci.draw_polyline(pts, Color(col, 0.9 * alpha), 3.5, true)
	ci.draw_polyline(pts, Color(1, 1, 1, alpha), 1.5, true)


## A crackling electric ring (Static's zap reach).
static func draw_zap_ring(ci: CanvasItem, c: Vector2, rad: float, age: float, seed: float) -> void:
	var u := clampf(age / BOLT_LIFE, 0.0, 1.0)
	var r := rad * (0.5 + 0.5 * sqrt(u))
	var pts := PackedVector2Array()
	var flick := floori(age * 30.0)
	for k in 37:
		var a := k * TAU / 36.0
		pts.append(c + Vector2.from_angle(a) * r * (1.0 + 0.06 * sin(seed * 5.0 + k * 2.9 + flick)))
	ci.draw_polyline(pts, Color(Color("9fe6ff"), 0.8 * (1.0 - u)), 3.0, true)


## Honey's puddle: glossy amber with lobes, a shine and a slow drip ring.
static func draw_honey(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	for q in 5:
		var a := seed + q * TAU / 5.0
		ci.draw_circle(p + Vector2.from_angle(a) * rad * 0.45, rad * 0.55, Color(HONEY, 0.32 * fade))
	ci.draw_circle(p, rad * 0.8, Color(Color("ffcf4d"), 0.35 * fade))
	ci.draw_arc(p, rad * 0.9, 0.0, TAU, 32, Color(Color("8a4b00"), 0.45 * fade), 2.0, true)
	ci.draw_arc(p + Vector2(-rad * 0.15, -rad * 0.15), rad * 0.45, PI * 1.05, PI * 1.5, 10, Color(1, 1, 1, 0.55 * fade), 3.0, true)
	var f := fmod(t * 0.5 + seed, 1.0)
	ci.draw_arc(p, rad * (0.3 + 0.6 * f), 0.0, TAU, 24, Color(Color("fff0b3"), 0.35 * (1.0 - f) * fade), 1.5, true)


## Drizzle's shower once it lands: a dark patch, slanted rain, splashes and
## ripples. The warning (before it arms) stays the dashed circle.
static func draw_rain(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float, col: Color) -> void:
	ci.draw_circle(p, rad, Color(Color("1b2550"), 0.4 * fade))
	ci.draw_circle(p, rad, Color(col, 0.12 * fade))
	for q in 3:
		var f := fmod(t * 0.9 + q / 3.0 + seed, 1.0)
		var at := p + Vector2(sin(seed * 3.0 + q * 2.2), cos(seed * 2.0 + q * 1.7)) * rad * 0.45
		ci.draw_arc(at, rad * 0.35 * f, 0.0, TAU, 20, Color(Color("dfe6ff"), 0.5 * (1.0 - f) * fade), 1.5, true)
	for q in 14:
		var x := fmod(q * 37.0 + seed * 50.0, rad * 1.6) - rad * 0.8
		var y := fmod(t * rad * 3.2 + q * 53.0, rad * 1.8) - rad * 0.9
		if Vector2(x, y).length() > rad:
			continue
		ci.draw_line(p + Vector2(x, y), p + Vector2(x - rad * 0.06, y + rad * 0.2), Color(Color("dfe6ff"), 0.75 * fade), 2.0, true)
	for q in 4:
		var f := fmod(t * 2.0 + q * 0.25 + seed, 1.0)
		var at := p + Vector2(sin(q * 4.1 + seed) * rad * 0.6, cos(q * 2.3 + seed) * rad * 0.6)
		ci.draw_arc(at, 3.0 + 8.0 * f, PI, TAU, 8, Color(Color("dfe6ff"), (1.0 - f) * fade), 1.5, true)


## Pucker's sour: the foe's face puckers green-yellow with sour drips and
## swirls, so you can see it takes extra damage.
static func draw_sour(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	ci.draw_circle(p, r, Color(SOUR, 0.18))
	ci.draw_arc(p, r * 1.04, 0.0, TAU, 40, Color(SOUR, 0.8), 3.0, true)
	for q in 3:
		var a := t * 2.5 + q * TAU / 3.0
		var at := p + Vector2.from_angle(a) * r * 1.18
		ci.draw_arc(at, r * 0.13, a, a + PI * 1.4, 10, Color(SOUR, 0.9), 2.5, true)
	for q in 3:
		var f := fmod(t * 1.1 + q * 0.33, 1.0)
		_drop(ci, p + Vector2((q - 1) * r * 0.45, r * (0.7 + 0.6 * f)), r * 0.08, Color(SOUR, 0.9 * (1.0 - f)))


## Puff puffed up: a ring of long spines bristling out.
static func draw_spines(ci: CanvasItem, p: Vector2, r: float, col: Color, t: float) -> void:
	var n := 18
	for q in n:
		var a := q * TAU / n + 0.1 * sin(t * 3.0)
		var d := Vector2.from_angle(a)
		var side := d.orthogonal() * r * 0.07
		var len := r * (0.38 + 0.06 * sin(t * 12.0 + q))
		ci.draw_colored_polygon(PackedVector2Array([p + d * r * 0.92 - side, p + d * (r + len), p + d * r * 0.92 + side]), Color(col.lightened(0.55), 0.95))
	ci.draw_arc(p, r * 1.02, 0.0, TAU, 48, Color(Color.WHITE, 0.35), 2.0, true)


## Shelly tucked in: a domed hex shell over the body, eyes peeking out under it.
static func draw_shell(ci: CanvasItem, p: Vector2, r: float, col: Color, t: float) -> void:
	var shell := Color("2e8b57").lerp(col, 0.3)
	var bob := sin(t * 3.0) * r * 0.02
	var pts := PackedVector2Array()
	for q in 25:
		var a := PI + q * PI / 24.0
		pts.append(p + Vector2(cos(a) * r * 1.12, sin(a) * r * 1.1 + r * 0.25 + bob))
	pts.append(p + Vector2(r * 1.12, r * 0.35 + bob))
	pts.append(p + Vector2(-r * 1.12, r * 0.35 + bob))
	ci.draw_colored_polygon(pts, shell)
	for q in range(-2, 3):
		var c := p + Vector2(q * r * 0.42, -r * 0.35 + absi(q) * r * 0.22 + bob)
		var hex := PackedVector2Array()
		for k in 6:
			hex.append(c + Vector2.from_angle(k * TAU / 6.0) * r * 0.2)
		ci.draw_colored_polygon(hex, shell.lightened(0.25))
		hex.append(hex[0])
		ci.draw_polyline(hex, shell.darkened(0.4), 2.0, true)
	ci.draw_line(p + Vector2(-r * 1.12, r * 0.35 + bob), p + Vector2(r * 1.12, r * 0.35 + bob), shell.darkened(0.45), 4.0, true)
	ci.draw_polyline(pts, shell.darkened(0.45), 3.0, true)
	ci.draw_arc(p + Vector2(-r * 0.25, -r * 0.6 + bob), r * 0.35, PI * 1.1, PI * 1.5, 10, Color(1, 1, 1, 0.45), 3.0, true)


## Little bubbles streaming behind a fast swimmer (Minnow, sea critters).
static func draw_bubble_trail(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, ratio: float, t: float) -> void:
	var k := clampf((ratio - 1.05) / 0.6, 0.0, 1.0)
	if k <= 0.0 or vel.length() < 0.001:
		return
	var back := -vel.normalized()
	var side := back.orthogonal()
	for q in 8:
		var f := fmod(t * 2.5 + q * 0.125, 1.0)
		var at := p + back * r * (0.9 + 1.8 * f) + side * sin(q * 2.3 + t * 6.0) * r * 0.4
		var rad := r * (0.06 + 0.07 * (1.0 - f))
		ci.draw_arc(at, rad, 0.0, TAU, 12, Color(Color("dff6ff"), 0.85 * (1.0 - f) * k), 2.0, true)
		ci.draw_circle(at + Vector2(-rad, -rad) * 0.35, rad * 0.25, Color(1, 1, 1, 0.8 * (1.0 - f) * k))


# --- Batch 3 ---------------------------------------------------------------------

const NOVA_LIFE := 0.7
const REBIRTH_LIFE := 1.0

## Void's and Supernova's blast: a white flash, a starburst of rays and a
## thick shockwave ring racing out to the full reach.
static func draw_nova(ci: CanvasItem, c: Vector2, reach: float, age: float, col: Color) -> void:
	var u := clampf(age / NOVA_LIFE, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - u, 3.0)
	var r := reach * ease
	var a := 1.0 - u
	ci.draw_circle(c, reach * 0.35 * (1.0 - u), Color(1, 1, 1, 0.9 * a))
	ci.draw_circle(c, r, Color(col, 0.12 * a))
	for k in 16:
		var d := Vector2.from_angle(k * TAU / 16.0 + 0.2)
		var inner := r * (0.25 + 0.1 * (k % 2))
		ci.draw_line(c + d * inner, c + d * r * (0.95 if k % 2 else 0.75), Color(Color.WHITE.lerp(col, 0.4), 0.7 * a), 3.0 + 3.0 * a, true)
	ci.draw_arc(c, r, 0.0, TAU, 72, Color(col, 0.9 * a), 6.0 + 12.0 * a, true)
	ci.draw_arc(c, r * 0.92, 0.0, TAU, 72, Color(1, 1, 1, 0.6 * a), 2.5, true)


## Ember's rebirth: a pillar of fire, flame wings unfolding and sparks.
static func draw_rebirth(ci: CanvasItem, c: Vector2, r: float, age: float, t: float) -> void:
	var u := clampf(age / REBIRTH_LIFE, 0.0, 1.0)
	var a := 1.0 - maxf(0.0, (u - 0.6) / 0.4)
	var rise := minf(1.0, u * 3.0)
	# Pillar.
	var w := r * (0.9 - 0.4 * u)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, r * 0.6), c + Vector2(-w * 0.3, -r * 3.2 * rise), c + Vector2(w * 0.3, -r * 3.2 * rise), c + Vector2(w, r * 0.6)]), Color(BURN, 0.45 * a))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.5, r * 0.4), c + Vector2(0, -r * 2.6 * rise), c + Vector2(w * 0.5, r * 0.4)]), Color(BURN_CORE, 0.6 * a))
	# Wings.
	var spread := minf(1.0, u * 2.0)
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array([c + Vector2(side * r * 0.5, -r * 0.2)])
		for k in 5:
			var f := k / 4.0
			pts.append(c + Vector2(side * r * (0.8 + 1.6 * spread * f), -r * (0.6 + 1.3 * spread * sin(f * PI * 0.8)) + sin(t * 9.0 + k) * r * 0.08))
		pts.append(c + Vector2(side * r * (0.6 + 1.2 * spread), r * 0.3))
		ci.draw_colored_polygon(pts, Color(BURN, 0.7 * a))
		ci.draw_polyline(pts, Color(BURN_CORE, 0.9 * a), 2.5, true)
	for k in 10:
		var f := fmod(u * 1.5 + k * 0.1, 1.0)
		ci.draw_circle(c + Vector2(sin(k * 2.7) * r * 1.2 * f, -r * 2.5 * f), 4.0 * (1.0 - f) + 1.0, Color(BURN_CORE, a * (1.0 - f)))


## Megabot's shield: a hex-grid energy bubble that ripples.
static func draw_hex_shield(ci: CanvasItem, c: Vector2, r: float, t: float, strength: float) -> void:
	var rad := r * 1.25
	var col := Color("7fe6ff")
	ci.draw_circle(c, rad, Color(col, 0.1 + 0.08 * strength))
	var cell := rad * 0.32
	for q in range(-3, 4):
		for k in range(-3, 4):
			var at := c + Vector2(q * cell * 1.5, (k + (q % 2) * 0.5) * cell * 1.732)
			if at.distance_to(c) > rad - cell * 0.6:
				continue
			var hex := PackedVector2Array()
			for v in 7:
				hex.append(at + Vector2.from_angle(v * TAU / 6.0) * cell * 0.9)
			var pulse := 0.25 + 0.25 * sin(t * 6.0 - at.distance_to(c) * 0.08)
			ci.draw_polyline(hex, Color(col, pulse * (0.5 + 0.5 * strength)), 1.5, true)
	ci.draw_arc(c, rad, 0.0, TAU, 48, Color(col, 0.9), 3.0, true)
	ci.draw_arc(c, rad * 1.06, 0.0, TAU, 48, Color(col, 0.3), 5.0, true)


## Blizz's snowflake mine: an icy crystal that glints, with a frosty blast ring.
static func draw_ice_mine(ci: CanvasItem, p: Vector2, s: float, armed: bool, blast: float, age: float, seed: float, t: float) -> void:
	var grow := clampf(age / 0.25, 0.0, 1.0)
	var rad := 24.0 * s * (0.4 + 0.6 * grow)
	if armed:
		ci.draw_circle(p, blast * s, Color(ICE, 0.07))
		ci.draw_arc(p, blast * s, 0.0, TAU, 40, Color(ICE, 0.45), 2.0, true)
	ci.draw_circle(p, rad * 1.1, Color(Color("7fd4ff"), 0.35))
	var spin := t * 0.6 + seed
	for k in 6:
		var d := Vector2.from_angle(spin + k * TAU / 6.0)
		ci.draw_line(p, p + d * rad, Color("f2fbff"), 3.0, true)
		var mid := p + d * rad * 0.6
		ci.draw_line(mid, mid + d.rotated(0.8) * rad * 0.3, Color("f2fbff"), 2.0, true)
		ci.draw_line(mid, mid + d.rotated(-0.8) * rad * 0.3, Color("f2fbff"), 2.0, true)
	var on := armed and fmod(t * 3.0 + seed, 1.0) < 0.5
	ci.draw_circle(p, rad * 0.28, Color("bfefff") if on else Color(Color("bfefff"), 0.4))


## Beacon's light: a widening lighthouse cone along the beam.
static func draw_cone(ci: CanvasItem, a: Vector2, b: Vector2, k: float, near_w: float, far_w: float) -> void:
	var side := (b - a).orthogonal().normalized()
	var col := Color("fff2a0")
	ci.draw_colored_polygon(PackedVector2Array([a + side * near_w, b + side * far_w, b - side * far_w, a - side * near_w]), Color(col, 0.16 * k))
	ci.draw_colored_polygon(PackedVector2Array([a + side * near_w * 0.5, b + side * far_w * 0.45, b - side * far_w * 0.45, a - side * near_w * 0.5]), Color(col, 0.22 * k))
	ci.draw_circle(a, near_w * 1.6, Color(col, 0.5 * k))


## Yo-Yo mid-swing: a taut glowing string to its wall pin and a swoosh arc.
static func draw_swing(ci: CanvasItem, anchor: Vector2, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	ci.draw_line(anchor, p, Color(Color("7ff3ff"), 0.3), 8.0, true)
	ci.draw_line(anchor, p, Color("e8feff"), 2.5, true)
	ci.draw_circle(anchor, 7.0, Color("ffe066"))
	ci.draw_arc(anchor, 11.0, 0.0, TAU, 16, Color(Color("ffe066"), 0.6), 2.0, true)
	var rad := anchor.distance_to(p)
	if rad < 1.0 or vel.length() < 0.001:
		return
	var ang := (p - anchor).angle()
	var dir := signf((p - anchor).cross(vel))
	for k in 3:
		var back := 0.25 + k * 0.18
		ci.draw_arc(anchor, rad + (k - 1) * r * 0.35, ang - dir * back - 0.15, ang - dir * back + 0.15, 10, Color(1, 1, 1, 0.5 - k * 0.12), 3.0, true)
