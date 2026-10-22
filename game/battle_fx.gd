extends RefCounted
## Extra fight effects drawn by game/arena_view.gd: status effects you can
## read at a glance (burn, poison, bleed, slow goo, ice) and per-critter
## flourishes (Zip's speed blur, Fuse's bombs, Chill's frost, Sooty's embers,
## Bubbles' bubble, Pinball's charge, Count Nibbles' chomp).
## Render-only: reads the sim, never changes it. Call from a CanvasItem's
## _draw() with screen-space positions (world * view scale).

const Dot := preload("res://game/dot.gd")
const A11y := preload("res://game/a11y.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")

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
	"gumdrop": "poison", "honey": "poison", "mossy": "poison", "sooty": "burn",
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
				Dot.circle(ci, p, r, Color(POISON, 0.16))
				for k in 5:
					var f := fmod(t * 0.9 + k * 0.2, 1.0)
					var x := sin(k * 2.3) * r * 0.6
					var at := p + Vector2(x, -r * 0.2 - f * r * 1.1)
					var rad := r * (0.07 + 0.06 * f)
					Dot.circle(ci, at, rad, Color(POISON, 0.75 * (1.0 - f)))
					Dot.arc(ci, at, rad, 0.0, TAU, 12, Color(Color("d9ffb8"), 0.8 * (1.0 - f)), 1.5, true)
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
					Dot.circle(ci, at, r * 0.08, Color(CURSE, 0.7))
					Dot.circle(ci, at - Vector2(cos(a), sin(a) * 0.5) * r * 0.12, r * 0.05, Color(CURSE, 0.35))


## Licking flames round the top of a burning ball, with embers rising.
static func _flames(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.circle(ci, p, r * 1.02, Color(BURN, 0.12))
	for k in 7:
		var a := PI + 0.25 + k * (PI - 0.5) / 6.0
		var base := p + Vector2.from_angle(a) * r * 0.85
		var flick := 0.75 + 0.35 * sin(t * 17.0 + k * 1.9)
		var up := (Vector2.from_angle(a) * 0.5 + Vector2(0, -1.0)).normalized()
		var side := up.orthogonal()
		var h := r * 0.55 * flick
		var w := r * 0.16
		Dot.poly(ci, PackedVector2Array([base - side * w, base + up * h * 0.5 - side * w * 0.6, base + up * h, base + up * h * 0.5 + side * w * 0.6, base + side * w]), Color(BURN, 0.85))
		Dot.poly(ci, PackedVector2Array([base - side * w * 0.45, base + up * h * 0.55, base + side * w * 0.45]), Color(BURN_CORE, 0.9))
	for k in 4:
		var f := fmod(t * 1.1 + k * 0.25, 1.0)
		Dot.circle(ci, p + Vector2(sin(k * 3.1 + t) * r * 0.7, -r * (0.9 + f * 0.9)), 3.0 * (1.0 - f) + 1.0, Color(BURN_CORE, 1.0 - f))


static func _drop(ci: CanvasItem, at: Vector2, rad: float, col: Color) -> void:
	Dot.circle(ci, at, rad, col)
	Dot.poly(ci, PackedVector2Array([at + Vector2(-rad * 0.9, -rad * 0.3), at + Vector2(0, -rad * 2.4), at + Vector2(rad * 0.9, -rad * 0.3)]), col)


## A slowed ball: frosted over with ice shards, or dripping goo.
static func draw_slow(ci: CanvasItem, goo: Color, amount: float, p: Vector2, r: float, t: float) -> void:
	var k := clampf(amount / 0.5, 0.4, 1.0)
	if goo.a > 0.0:
		Dot.arc(ci, p, r * 0.98, 0.0, TAU, 48, Color(goo, 0.75 * k), maxf(3.0, r * 0.12), true)
		for q in 5:
			var x := (q - 2) * r * 0.36
			var f := fmod(t * 0.7 + q * 0.37, 1.0)
			var top := p + Vector2(x, sqrt(maxf(0.0, r * r - x * x)) * 0.92)
			var len := r * (0.15 + 0.35 * f)
			ci.draw_line(top, top + Vector2(0, len), Color(goo, 0.85 * k), maxf(3.0, r * 0.1), true)
			Dot.circle(ci, top + Vector2(0, len), maxf(2.5, r * 0.08), Color(goo, 0.9 * k))
		Dot.circle(ci, p + Vector2(-r * 0.4, -r * 0.45), r * 0.1, Color(1, 1, 1, 0.45 * k))
		return
	Dot.circle(ci, p, r, Color(ICE, 0.18 * k))
	Dot.arc(ci, p, r * 1.0, 0.0, TAU, 48, Color(ICE, 0.75 * k), 2.5, true)
	for q in 8:
		var a := q * TAU / 8.0 + 0.2
		var d := Vector2.from_angle(a)
		var len := r * (0.22 + 0.1 * sin(q * 2.7))
		var base := p + d * r * 0.9
		var side := d.orthogonal() * r * 0.07
		Dot.poly(ci, PackedVector2Array([base - side, base + d * len, base + side]), Color(ICE, 0.85 * k))
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
		Dot.circle(ci, p + back * r * 0.55 * q * (0.6 + k * 0.5), r * (1.0 - 0.08 * q), Color(col, 0.22 * (1.0 - f * 0.7) * k))
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
		Dot.circle(ci, p, blast * s, Color(Color("ff4d4d"), 0.06 + 0.05 * pulse))
		var dashes := 20
		for q in dashes:
			var a := q * TAU / dashes + t * 0.4
			Dot.arc(ci, p, blast * s, a, a + TAU / dashes * 0.5, 4, Color(Color("ff4d4d"), 0.45), 2.0, true)
	Dot.circle(ci, p + Vector2(2, 3) * s, rad, Color(0, 0, 0, 0.35))
	Dot.circle(ci, p, rad, Color("1f2547"))
	Dot.circle(ci, p + Vector2(-rad * 0.3, -rad * 0.3), rad * 0.35, Color(1, 1, 1, 0.18))
	Dot.arc(ci, p, rad, 0.0, TAU, 24, Color("8fa2ff"), 2.0, true)
	var neck := p + Vector2(rad * 0.45, -rad * 0.85)
	ci.draw_line(neck, neck + Vector2(rad * 0.35, -rad * 0.45), Color("d6b37a"), 3.0, true)
	var tip := neck + Vector2(rad * 0.35, -rad * 0.45)
	var flick := 0.7 + 0.3 * sin(t * 30.0 + seed)
	Dot.circle(ci, tip, rad * 0.28 * flick, Color(BURN, 0.9))
	Dot.circle(ci, tip, rad * 0.14 * flick, Color(BURN_CORE))
	var on := armed and fmod(t * 3.0 + seed, 1.0) < 0.5
	Dot.circle(ci, p, rad * 0.32, Color("ff4d4d") if on else Color(Color("ff4d4d"), 0.3))


## Chill's ice trail: frosty slabs with crystal glints.
static func draw_ice(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	Dot.circle(ci, p, rad, Color(ICE, 0.22 * fade))
	Dot.circle(ci, p, rad * 0.6, Color(Color("e8fbff"), 0.2 * fade))
	for q in 3:
		var a := seed * 3.0 + q * TAU / 3.0
		var at := p + Vector2.from_angle(a) * rad * 0.45
		var d := Vector2.from_angle(a + 0.7) * rad * 0.35
		ci.draw_line(at - d, at + d, Color(1, 1, 1, 0.5 * fade), 1.5, true)
	var glint := 0.5 + 0.5 * sin(t * 3.0 + seed * 7.0)
	_sparkle(ci, p + Vector2.from_angle(seed * 5.0) * rad * 0.3, rad * 0.35 * glint * fade, Color(1, 1, 1, 0.8 * fade))


## Sooty's hot patch: scorched ground with glowing cracks and rising embers.
static func draw_embers(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	Dot.circle(ci, p, rad, Color(Color("1a0d08"), 0.55 * fade))
	Dot.circle(ci, p, rad * 0.8, Color(BURN, (0.18 + 0.08 * sin(t * 5.0 + seed)) * fade))
	for q in 5:
		var a := seed * 2.0 + q * TAU / 5.0
		var pts := PackedVector2Array()
		var at := p + Vector2.from_angle(a) * rad * 0.1
		pts.append(at)
		for step in 3:
			at += Vector2.from_angle(a + sin(seed + q * 3.0 + step) * 0.6) * rad * 0.28
			pts.append(at)
		Dot.pline(ci, pts, Color(BURN_CORE, (0.55 + 0.35 * sin(t * 7.0 + q)) * fade), 2.0, true)
	for q in 5:
		var f := fmod(t * 0.8 + q * 0.2 + seed, 1.0)
		var at := p + Vector2(sin(q * 2.4 + seed) * rad * 0.6, -f * rad * 1.2)
		Dot.circle(ci, at, 3.0 * (1.0 - f) + 1.0, Color(BURN_CORE, (1.0 - f) * fade))


## Bubbles' shield: a wobbling soap bubble with a rainbow sheen.
static func draw_bubble(ci: CanvasItem, p: Vector2, r: float, t: float, left: float) -> void:
	var rad := r * 1.25
	var pts := PackedVector2Array()
	for q in 41:
		var a := q * TAU / 40.0
		var wob := 1.0 + 0.035 * sin(a * 3.0 + t * 4.0) * A11y.motion()
		pts.append(p + Vector2.from_angle(a) * rad * wob)
	# The last point closes the outline; the fill takes the 40 distinct ones
	# (a repeated point can fail triangulation).
	Dot.poly(ci, pts.slice(0, 40), Color("9ff3f6", 0.14))
	for q in 40:
		ci.draw_line(pts[q], pts[q + 1], Color.from_hsv(fmod(q / 40.0 + t * 0.3, 1.0), 0.45, 1.0, 0.85 * clampf(left * 2.0, 0.35, 1.0)), 3.0, true)
	Dot.arc(ci, p, rad * 0.8, PI * 1.1, PI * 1.45, 12, Color(1, 1, 1, 0.7), 4.0, true)
	Dot.circle(ci, p + Vector2(-rad * 0.42, -rad * 0.55), rad * 0.07, Color(1, 1, 1, 0.8))


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
			Dot.circle(ci, at, 11.0, Color(Color("ffe066"), 0.3))
		Dot.circle(ci, at, 6.0, Color("ffe066") if on else Color(Color("3a335c"), 0.9))
	if lit >= total:
		var glow := 0.5 + 0.5 * sin(t * 20.0)
		Dot.arc(ci, p, r * 1.08, 0.0, TAU, 48, Color(Color("ffe066"), 0.4 + 0.4 * glow), 4.0, true)
		for q in 3:
			var a := t * 9.0 + q * TAU / 3.0
			var pts := PackedVector2Array([p + Vector2.from_angle(a) * r * 1.0])
			for step in 3:
				pts.append(p + Vector2.from_angle(a + 0.12 * (step + 1)) * r * (1.12 + 0.1 * ((step % 2) * 2 - 1)))
			Dot.pline(ci, pts, Color(Color("fffbe0"), 0.9), 2.0, true)
	elif lit > 0:
		Dot.arc(ci, p, r * 1.08, 0.0, TAU, 48, Color(Color("ffe066"), 0.12 * lit), 3.0, true)


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
		Dot.pline(ci, PackedVector2Array([hinge, mid, lip]), Color(Color("ffffff"), 0.9 * alpha), 4.0, true)
		for f in 3:
			var q := hinge.lerp(lip, 0.35 + f * 0.25)
			var toward: Vector2 = -side * jaw
			Dot.poly(ci, PackedVector2Array([q - dir * size * 0.08, q + toward * size * 0.28, q + dir * size * 0.08]), Color(1, 1, 1, alpha))
	if close >= 1.0:
		Dot.circle(ci, at, size * 0.25 * (1.0 - u), Color(BLEED, 0.6 * alpha))


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
	Dot.pline(ci, pts, Color(col, 0.35 * alpha), 9.0, true)
	Dot.pline(ci, pts, Color(col, 0.9 * alpha), 3.5, true)
	Dot.pline(ci, pts, Color(1, 1, 1, alpha), 1.5, true)


## A crackling electric ring (Static's zap reach).
static func draw_zap_ring(ci: CanvasItem, c: Vector2, rad: float, age: float, seed: float) -> void:
	var u := clampf(age / BOLT_LIFE, 0.0, 1.0)
	var r := rad * (0.5 + 0.5 * sqrt(u))
	var pts := PackedVector2Array()
	var flick := floori(age * 30.0)
	for k in 37:
		var a := k * TAU / 36.0
		pts.append(c + Vector2.from_angle(a) * r * (1.0 + 0.06 * sin(seed * 5.0 + k * 2.9 + flick)))
	Dot.pline(ci, pts, Color(Color("9fe6ff"), 0.8 * (1.0 - u)), 3.0, true)


## Honey's puddle: glossy amber with lobes, a shine and a slow drip ring.
static func draw_honey(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	for q in 5:
		var a := seed + q * TAU / 5.0
		Dot.circle(ci, p + Vector2.from_angle(a) * rad * 0.45, rad * 0.55, Color(HONEY, 0.32 * fade))
	Dot.circle(ci, p, rad * 0.8, Color(Color("ffcf4d"), 0.35 * fade))
	Dot.arc(ci, p, rad * 0.9, 0.0, TAU, 32, Color(Color("8a4b00"), 0.45 * fade), 2.0, true)
	Dot.arc(ci, p + Vector2(-rad * 0.15, -rad * 0.15), rad * 0.45, PI * 1.05, PI * 1.5, 10, Color(1, 1, 1, 0.55 * fade), 3.0, true)
	var f := fmod(t * 0.5 + seed, 1.0)
	Dot.arc(ci, p, rad * (0.3 + 0.6 * f), 0.0, TAU, 24, Color(Color("fff0b3"), 0.35 * (1.0 - f) * fade), 1.5, true)


## Drizzle's shower once it lands: a dark patch, slanted rain, splashes and
## ripples. The warning (before it arms) stays the dashed circle.
static func draw_rain(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float, col: Color) -> void:
	Dot.circle(ci, p, rad, Color(Color("1b2550"), 0.4 * fade))
	Dot.circle(ci, p, rad, Color(col, 0.12 * fade))
	for q in 3:
		var f := fmod(t * 0.9 + q / 3.0 + seed, 1.0)
		var at := p + Vector2(sin(seed * 3.0 + q * 2.2), cos(seed * 2.0 + q * 1.7)) * rad * 0.45
		Dot.arc(ci, at, rad * 0.35 * f, 0.0, TAU, 20, Color(Color("dfe6ff"), 0.5 * (1.0 - f) * fade), 1.5, true)
	for q in 14:
		var x := fmod(q * 37.0 + seed * 50.0, rad * 1.6) - rad * 0.8
		var y := fmod(t * rad * 3.2 + q * 53.0, rad * 1.8) - rad * 0.9
		if Vector2(x, y).length() > rad:
			continue
		ci.draw_line(p + Vector2(x, y), p + Vector2(x - rad * 0.06, y + rad * 0.2), Color(Color("dfe6ff"), 0.75 * fade), 2.0, true)
	for q in 4:
		var f := fmod(t * 2.0 + q * 0.25 + seed, 1.0)
		var at := p + Vector2(sin(q * 4.1 + seed) * rad * 0.6, cos(q * 2.3 + seed) * rad * 0.6)
		Dot.arc(ci, at, 3.0 + 8.0 * f, PI, TAU, 8, Color(Color("dfe6ff"), (1.0 - f) * fade), 1.5, true)


## Pucker's sour: the foe's face puckers green-yellow with sour drips and
## swirls, so you can see it takes extra damage.
static func draw_sour(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.circle(ci, p, r, Color(SOUR, 0.18))
	Dot.arc(ci, p, r * 1.04, 0.0, TAU, 40, Color(SOUR, 0.8), 3.0, true)
	for q in 3:
		var a := t * 2.5 + q * TAU / 3.0
		var at := p + Vector2.from_angle(a) * r * 1.18
		Dot.arc(ci, at, r * 0.13, a, a + PI * 1.4, 10, Color(SOUR, 0.9), 2.5, true)
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
		Dot.poly(ci, PackedVector2Array([p + d * r * 0.92 - side, p + d * (r + len), p + d * r * 0.92 + side]), Color(col.lightened(0.55), 0.95))
	Dot.arc(ci, p, r * 1.02, 0.0, TAU, 48, Color(Color.WHITE, 0.35), 2.0, true)


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
	Dot.poly(ci, pts, shell)
	for q in range(-2, 3):
		var c := p + Vector2(q * r * 0.42, -r * 0.35 + absi(q) * r * 0.22 + bob)
		var hex := PackedVector2Array()
		for k in 6:
			hex.append(c + Vector2.from_angle(k * TAU / 6.0) * r * 0.2)
		Dot.poly(ci, hex, shell.lightened(0.25))
		hex.append(hex[0])
		Dot.pline(ci, hex, shell.darkened(0.4), 2.0, true)
	ci.draw_line(p + Vector2(-r * 1.12, r * 0.35 + bob), p + Vector2(r * 1.12, r * 0.35 + bob), shell.darkened(0.45), 4.0, true)
	Dot.pline(ci, pts, shell.darkened(0.45), 3.0, true)
	Dot.arc(ci, p + Vector2(-r * 0.25, -r * 0.6 + bob), r * 0.35, PI * 1.1, PI * 1.5, 10, Color(1, 1, 1, 0.45), 3.0, true)


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
		Dot.arc(ci, at, rad, 0.0, TAU, 12, Color(Color("dff6ff"), 0.85 * (1.0 - f) * k), 2.0, true)
		Dot.circle(ci, at + Vector2(-rad, -rad) * 0.35, rad * 0.25, Color(1, 1, 1, 0.8 * (1.0 - f) * k))


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
	Dot.circle(ci, c, reach * 0.35 * (1.0 - u), Color(1, 1, 1, 0.9 * a))
	Dot.circle(ci, c, r, Color(col, 0.12 * a))
	for k in 16:
		var d := Vector2.from_angle(k * TAU / 16.0 + 0.2)
		var inner := r * (0.25 + 0.1 * (k % 2))
		ci.draw_line(c + d * inner, c + d * r * (0.95 if k % 2 else 0.75), Color(Color.WHITE.lerp(col, 0.4), 0.7 * a), 3.0 + 3.0 * a, true)
	Dot.arc(ci, c, r, 0.0, TAU, 72, Color(col, 0.9 * a), 6.0 + 12.0 * a, true)
	Dot.arc(ci, c, r * 0.92, 0.0, TAU, 72, Color(1, 1, 1, 0.6 * a), 2.5, true)


## Ember's rebirth: a pillar of fire, flame wings unfolding and sparks.
static func draw_rebirth(ci: CanvasItem, c: Vector2, r: float, age: float, t: float) -> void:
	var u := clampf(age / REBIRTH_LIFE, 0.0, 1.0)
	var a := 1.0 - maxf(0.0, (u - 0.6) / 0.4)
	var rise := minf(1.0, u * 3.0)
	# Pillar.
	var w := r * (0.9 - 0.4 * u)
	Dot.poly(ci, PackedVector2Array([c + Vector2(-w, r * 0.6), c + Vector2(-w * 0.3, -r * 3.2 * rise), c + Vector2(w * 0.3, -r * 3.2 * rise), c + Vector2(w, r * 0.6)]), Color(BURN, 0.45 * a))
	Dot.poly(ci, PackedVector2Array([c + Vector2(-w * 0.5, r * 0.4), c + Vector2(0, -r * 2.6 * rise), c + Vector2(w * 0.5, r * 0.4)]), Color(BURN_CORE, 0.6 * a))
	# Wings.
	var spread := minf(1.0, u * 2.0)
	for side in [-1.0, 1.0]:
		var pts := PackedVector2Array([c + Vector2(side * r * 0.5, -r * 0.2)])
		for k in 5:
			var f := k / 4.0
			pts.append(c + Vector2(side * r * (0.8 + 1.6 * spread * f), -r * (0.6 + 1.3 * spread * sin(f * PI * 0.8)) + sin(t * 9.0 + k) * r * 0.08))
		pts.append(c + Vector2(side * r * (0.6 + 1.2 * spread), r * 0.3))
		Dot.poly(ci, pts, Color(BURN, 0.7 * a))
		Dot.pline(ci, pts, Color(BURN_CORE, 0.9 * a), 2.5, true)
	for k in 10:
		var f := fmod(u * 1.5 + k * 0.1, 1.0)
		Dot.circle(ci, c + Vector2(sin(k * 2.7) * r * 1.2 * f, -r * 2.5 * f), 4.0 * (1.0 - f) + 1.0, Color(BURN_CORE, a * (1.0 - f)))


## Megabot's shield: a hex-grid energy bubble that ripples.
static func draw_hex_shield(ci: CanvasItem, c: Vector2, r: float, t: float, strength: float) -> void:
	var rad := r * 1.25
	var col := Color("7fe6ff")
	Dot.circle(ci, c, rad, Color(col, 0.1 + 0.08 * strength))
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
			Dot.pline(ci, hex, Color(col, pulse * (0.5 + 0.5 * strength)), 1.5, true)
	Dot.arc(ci, c, rad, 0.0, TAU, 48, Color(col, 0.9), 3.0, true)
	Dot.arc(ci, c, rad * 1.06, 0.0, TAU, 48, Color(col, 0.3), 5.0, true)


## Blizz's snowflake mine: an icy crystal that glints, with a frosty blast ring.
static func draw_ice_mine(ci: CanvasItem, p: Vector2, s: float, armed: bool, blast: float, age: float, seed: float, t: float) -> void:
	var grow := clampf(age / 0.25, 0.0, 1.0)
	var rad := 24.0 * s * (0.4 + 0.6 * grow)
	if armed:
		Dot.circle(ci, p, blast * s, Color(ICE, 0.07))
		Dot.arc(ci, p, blast * s, 0.0, TAU, 40, Color(ICE, 0.45), 2.0, true)
	Dot.circle(ci, p, rad * 1.1, Color(Color("7fd4ff"), 0.35))
	var spin := t * 0.6 + seed
	for k in 6:
		var d := Vector2.from_angle(spin + k * TAU / 6.0)
		ci.draw_line(p, p + d * rad, Color("f2fbff"), 3.0, true)
		var mid := p + d * rad * 0.6
		ci.draw_line(mid, mid + d.rotated(0.8) * rad * 0.3, Color("f2fbff"), 2.0, true)
		ci.draw_line(mid, mid + d.rotated(-0.8) * rad * 0.3, Color("f2fbff"), 2.0, true)
	var on := armed and fmod(t * 3.0 + seed, 1.0) < 0.5
	Dot.circle(ci, p, rad * 0.28, Color("bfefff") if on else Color(Color("bfefff"), 0.4))


## Beacon's light: a widening lighthouse cone along the beam.
static func draw_cone(ci: CanvasItem, a: Vector2, b: Vector2, k: float, near_w: float, far_w: float) -> void:
	var side := (b - a).orthogonal().normalized()
	var col := Color("fff2a0")
	Dot.poly(ci, PackedVector2Array([a + side * near_w, b + side * far_w, b - side * far_w, a - side * near_w]), Color(col, 0.16 * k))
	Dot.poly(ci, PackedVector2Array([a + side * near_w * 0.5, b + side * far_w * 0.45, b - side * far_w * 0.45, a - side * near_w * 0.5]), Color(col, 0.22 * k))
	Dot.circle(ci, a, near_w * 1.6, Color(col, 0.5 * k))


## Yo-Yo mid-swing: a taut glowing string to its wall pin and a swoosh arc.
static func draw_swing(ci: CanvasItem, anchor: Vector2, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	ci.draw_line(anchor, p, Color(Color("7ff3ff"), 0.3), 8.0, true)
	ci.draw_line(anchor, p, Color("e8feff"), 2.5, true)
	Dot.circle(ci, anchor, 7.0, Color("ffe066"))
	Dot.arc(ci, anchor, 11.0, 0.0, TAU, 16, Color(Color("ffe066"), 0.6), 2.0, true)
	var rad := anchor.distance_to(p)
	if rad < 1.0 or vel.length() < 0.001:
		return
	var ang := (p - anchor).angle()
	var dir := signf((p - anchor).cross(vel))
	for k in 3:
		var back := 0.25 + k * 0.18
		Dot.arc(ci, anchor, rad + (k - 1) * r * 0.35, ang - dir * back - 0.15, ang - dir * back + 0.15, 10, Color(1, 1, 1, 0.5 - k * 0.12), 3.0, true)


# --- Batch 4: Kraken, Oak, Clockwork, Ivy, Eclipse, Bonbon, Glacia, Leviathan, Frostfang, Puppeteer ---

const LEAF_DARK := Color("1f6b2e")
const LEAF := Color("3fbf4a")
const LEAF_LIGHT := Color("9be36b")
const BARK := Color("6b4423")
const INK := Color("2a0f45")
const WATER := Color("5ff0e6")
const SPLASH_LIFE := 0.8
const FLIP_LIFE := 0.7
const CLOCK_LIFE := 0.6
const CLOCK := Color("ffd166")


## Kraken's arm: a thick tapering tentacle that curls as it sweeps, suckers on
## the inside and a curled tip.
static func draw_tentacle(ci: CanvasItem, from: Vector2, to: Vector2, size: float, col: Color, t: float, seed: float) -> void:
	var span := from.distance_to(to)
	if span < 1.0:
		return
	var along := (to - from) / span
	var side := along.orthogonal()
	var pts := PackedVector2Array()
	var n := 12
	for q in n + 1:
		var k := float(q) / n
		var wave := sin(k * 5.0 - t * 5.0 + seed) * span * 0.09 * sin(k * PI)
		pts.append(from + along * span * k + side * wave)
	for q in n:
		var k := float(q) / n
		var w := lerpf(size * 1.25, size * 0.45, k)
		ci.draw_line(pts[q], pts[q + 1], col.darkened(0.35), w + 3.0, true)
	for q in n:
		var k := float(q) / n
		var w := lerpf(size * 1.25, size * 0.45, k)
		ci.draw_line(pts[q], pts[q + 1], col.lightened(0.1), w, true)
		Dot.circle(ci, pts[q + 1], w * 0.5, col.lightened(0.1))
	for q in range(2, n, 2): # Suckers along the inner side.
		var k := float(q) / n
		var w := lerpf(size * 1.25, size * 0.45, k)
		var d := (pts[q + 1] - pts[q]).normalized().orthogonal()
		Dot.circle(ci, pts[q] + d * w * 0.22, w * 0.2, Color("ffd6f5", 0.9))
	var tip_dir := (pts[n] - pts[n - 1]).normalized()
	var curl := tip_dir.orthogonal()
	Dot.arc(ci, pts[n] + curl * size * 0.35, size * 0.35, tip_dir.angle() - PI / 2.0, tip_dir.angle() + PI, 10, col.lightened(0.1), size * 0.3, true)


## An ink splat: a lumpy dark puddle with drips and a glossy highlight.
static func draw_ink(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	var pts := PackedVector2Array()
	for k in 14:
		var a := k * TAU / 14.0
		var lump := 0.82 + 0.18 * sin(a * 3.0 + seed) + 0.05 * sin(t * 2.0 + k)
		pts.append(p + Vector2(cos(a), sin(a)) * rad * lump)
	Dot.poly(ci, pts, Color(INK, 0.75 * fade))
	for k in 5:
		var a := seed + k * 1.3
		Dot.circle(ci, p + Vector2(cos(a), sin(a)) * rad * 1.08, rad * 0.11, Color(INK, 0.75 * fade))
	Dot.circle(ci, p + Vector2(-0.3, -0.35) * rad, rad * 0.22, Color(Color("b36bff"), 0.35 * fade))
	Dot.circle(ci, p + Vector2(-0.38, -0.42) * rad, rad * 0.08, Color(1, 1, 1, 0.5 * fade))


## Old Oak's root pillar from above: a broad leafy crown over a gnarled trunk,
## with roots splaying out at its foot. k grows it in and out.
static func draw_tree(ci: CanvasItem, p: Vector2, rad: float, k: float, seed: float, t: float) -> void:
	for l in 5: # Roots.
		var a := seed + l * TAU / 5.0
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(p + d * rad * 0.3, p + d * rad * 1.15 * k + d.orthogonal() * rad * 0.15, BARK.darkened(0.2), 5.0, true)
	Dot.circle(ci, p + Vector2(4, 7) * k, rad * 1.05 * k, Color(0, 0, 0, 0.3 * k))
	Dot.circle(ci, p, rad * 0.35, BARK)
	var sway := Vector2(sin(t * 1.7 + seed), cos(t * 1.3 + seed)) * rad * 0.04
	var crown := rad * 1.35 * (0.4 + 0.6 * k) # The canopy overhangs the trunk.
	for l in 7: # Dark outer clumps, then lighter ones on top.
		var a := seed + l * TAU / 7.0
		Dot.circle(ci, p + sway + Vector2(cos(a), sin(a)) * crown * 0.55, crown * 0.48, LEAF_DARK)
	for l in 5:
		var a := seed + 0.5 + l * TAU / 5.0
		Dot.circle(ci, p + sway * 1.5 + Vector2(cos(a), sin(a)) * crown * 0.35 + Vector2(-0.08, -0.1) * crown, crown * 0.38, LEAF)
	Dot.circle(ci, p + sway * 2.0 + Vector2(-0.22, -0.26) * crown, crown * 0.3, LEAF_LIGHT)
	for l in 4: # A few acorns.
		var a := seed * 2.0 + l * 1.7
		Dot.circle(ci, p + sway + Vector2(cos(a), sin(a)) * crown * 0.62, crown * 0.07, Color("c08a3e"))


## Ivy's vine pillar: a twisting stem wound with leaves and a pink flower.
static func draw_vine_pillar(ci: CanvasItem, p: Vector2, rad: float, k: float, seed: float, t: float) -> void:
	Dot.circle(ci, p + Vector2(3, 6) * k, rad * k, Color(0, 0, 0, 0.3 * k))
	Dot.circle(ci, p, rad * 0.55, Color("0b4f37"))
	for l in 3: # The twist.
		var a := t * 0.8 + seed + l * TAU / 3.0
		Dot.arc(ci, p, rad * (0.25 + 0.12 * l), a, a + PI * 1.2, 12, Color("2ee59d"), 3.0, true)
	var n := 9
	for l in n:
		var a := seed + l * TAU / n + 0.15 * sin(t * 2.0 + l)
		var at := p + Vector2(cos(a), sin(a)) * rad * (0.55 + 0.35 * k)
		_leaf(ci, at, a, rad * 0.32 * k, LEAF if l % 2 else LEAF_LIGHT)
	_flower(ci, p + Vector2(-0.1, -0.15) * rad, rad * 0.22 * k, t)


static func _leaf(ci: CanvasItem, at: Vector2, ang: float, ln: float, col: Color) -> void:
	if ln < 1.0:
		return
	var d := Vector2.from_angle(ang)
	var o := d.orthogonal()
	var pts := PackedVector2Array([at - d * ln * 0.5, at + o * ln * 0.3, at + d * ln * 0.5, at - o * ln * 0.3])
	Dot.poly(ci, pts, col)
	ci.draw_line(at - d * ln * 0.45, at + d * ln * 0.45, col.darkened(0.35), 1.2, true)


static func _flower(ci: CanvasItem, at: Vector2, r: float, t: float) -> void:
	for l in 5:
		var a := t * 0.5 + l * TAU / 5.0
		Dot.circle(ci, at + Vector2(cos(a), sin(a)) * r * 0.6, r * 0.5, Color("ff9ecf"))
	Dot.circle(ci, at, r * 0.4, Color("ffe066"))


## Ivy's lash: a wavy vine from the pillar to the foe, sprouting leaves.
static func draw_lash_vine(ci: CanvasItem, from: Vector2, to: Vector2, t: float) -> void:
	var span := from.distance_to(to)
	if span < 1.0:
		return
	var along := (to - from) / span
	var side := along.orthogonal()
	var pts := PackedVector2Array()
	for q in 17:
		var k := q / 16.0
		pts.append(from + along * span * k + side * sin(k * 9.0 + t * 6.0) * 6.0 * sin(k * PI))
	Dot.pline(ci, pts, Color("0b4f37"), 8.0, true)
	Dot.pline(ci, pts, Color("2ee59d"), 3.5, true)
	for q in range(1, 16, 2):
		var a := (pts[q + 1] - pts[q]).angle() + (0.9 if q % 4 == 1 else -0.9)
		_leaf(ci, pts[q] + Vector2.from_angle(a) * 6.0, a, 14.0, LEAF_LIGHT if q % 4 == 1 else LEAF)


## Bonbon's gift wrap: two ribbons crossed over the foe and a bow on top,
## with a candy-stripe sheen. left (1 to 0) is how long the wrap still holds.
static func draw_wrap(ci: CanvasItem, p: Vector2, r: float, t: float, left: float) -> void:
	Dot.circle(ci, p, r * 1.04, Color(Color("ffd6ec"), 0.35))
	for k in 6: # Stripes on the paper.
		var a := k * TAU / 6.0 + t * 0.5
		Dot.arc(ci, p, r * 0.98, a, a + 0.35, 6, Color(Color("ff5fa2"), 0.55), 5.0, true)
	var ribbon := Color("ff3d8b")
	ci.draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), ribbon.darkened(0.3), r * 0.32, true)
	ci.draw_line(p + Vector2(0, -r), p + Vector2(0, r), ribbon.darkened(0.3), r * 0.32, true)
	ci.draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), ribbon, r * 0.22, true)
	ci.draw_line(p + Vector2(0, -r), p + Vector2(0, r), ribbon, r * 0.22, true)
	var top := p + Vector2(0, -r * 0.95)
	var wob := 0.15 * sin(t * 10.0) * (1.0 - left)
	for side in [-1.0, 1.0]: # Bow loops.
		var c := top + Vector2(side * r * 0.32, -r * 0.12)
		var loop := PackedVector2Array([top, c + Vector2(side * r * 0.2, -r * (0.22 + wob)), c + Vector2(side * r * 0.25, r * 0.15), top])
		Dot.poly(ci, PackedVector2Array([loop[0], loop[1], loop[2]]), ribbon)
		Dot.pline(ci, loop, ribbon.darkened(0.3), 2.0, true)
	Dot.circle(ci, top, r * 0.11, ribbon.lightened(0.3))


## Clockwork's tick ring: a clock face rippling out with 12 ticks and a hand
## sweeping round once.
static func draw_clock_ring(ci: CanvasItem, c: Vector2, reach: float, age: float) -> void:
	var k := clampf(age / CLOCK_LIFE, 0.0, 1.0)
	var rad := reach * (0.35 + 0.65 * sqrt(k))
	var a := 1.0 - k
	Dot.arc(ci, c, rad, 0.0, TAU, 64, Color(CLOCK, 0.8 * a), 4.0, true)
	for q in 12:
		var d := Vector2.from_angle(q * TAU / 12.0)
		var inner := 0.84 if q % 3 == 0 else 0.9
		ci.draw_line(c + d * rad * inner, c + d * rad, Color(CLOCK, 0.9 * a), 4.0 if q % 3 == 0 else 2.0, true)
	var hand := Vector2.from_angle(-PI / 2.0 + TAU * k)
	ci.draw_line(c, c + hand * rad * 0.9, Color(CLOCK, 0.7 * a), 3.0, true)
	Dot.circle(ci, c, 5.0, Color(CLOCK, a))


## Clockwork's rewind: ghost copies along the way back and a backwards arrow.
static func draw_rewind(ci: CanvasItem, from: Vector2, to: Vector2, r: float, age: float, life: float) -> void:
	var a := 1.0 - clampf(age / life, 0.0, 1.0)
	for q in 5:
		var k := q / 4.0
		Dot.circle(ci, from.lerp(to, k), r * 0.95, Color(CLOCK, 0.12 * a * (0.4 + k)))
		Dot.arc(ci, from.lerp(to, k), r * 0.95, 0.0, TAU, 32, Color(CLOCK, 0.45 * a * (0.4 + k)), 2.0, true)
	var spin := -age * 12.0
	Dot.arc(ci, to, r * 1.35, spin, spin + PI * 1.4, 24, Color(CLOCK, 0.9 * a), 4.0, true)
	var tip := to + Vector2.from_angle(spin) * r * 1.35
	var back := Vector2.from_angle(spin + PI / 2.0)
	Dot.poly(ci, PackedVector2Array([tip - back * 10.0, tip + Vector2.from_angle(spin) * 9.0, tip - Vector2.from_angle(spin) * 9.0]), Color(CLOCK, 0.9 * a))


## Eclipse flipping: a dark disc slides across a blazing ring (to Moon) or
## off it (to Sun), with corona flares.
static func draw_eclipse_flip(ci: CanvasItem, c: Vector2, r: float, reach: float, age: float, to_moon: bool) -> void:
	var k := clampf(age / FLIP_LIFE, 0.0, 1.0)
	var a := 1.0 - k
	var sun := Color("ffb347")
	var moon := Color("b8c4ff")
	var col := moon if to_moon else sun
	Dot.arc(ci, c, reach * (0.4 + 0.6 * sqrt(k)), 0.0, TAU, 64, Color(col, 0.85 * a), 8.0 * a + 2.0, true)
	for q in 16:
		var d := Vector2.from_angle(q * TAU / 16.0 + k)
		ci.draw_line(c + d * r * 1.1, c + d * r * (1.4 + 0.9 * k), Color(sun.lightened(0.3), 0.8 * a), 3.0, true)
	Dot.circle(ci, c, r * 1.15, Color(sun, 0.55 * a))
	var slide := (k if to_moon else 1.0 - k) * 2.0 - 1.0 # -1 to 1 across the face.
	Dot.circle(ci, c + Vector2(slide * r * 0.9, -slide * r * 0.3), r * 1.05, Color(Color("1a1240"), 0.85 * a))
	Dot.arc(ci, c + Vector2(slide * r * 0.9, -slide * r * 0.3), r * 1.05, 0.0, TAU, 40, Color(moon, 0.8 * a), 2.5, true)


## Moonlight on Eclipse while it heals: a pale crescent and drifting motes.
static func draw_moonlight(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	var moon := Color("b8c4ff")
	Dot.arc(ci, p, r * 1.22, -PI * 0.85, -PI * 0.15, 24, Color(moon, 0.55), 5.0, true)
	for k in 4:
		var f := fmod(t * 0.5 + k / 4.0, 1.0)
		var at := p + Vector2((k - 1.5) * r * 0.5, r * 0.4 - r * 1.4 * f)
		_sparkle(ci, at, 5.0 * (1.0 - f) + 2.0, Color(moon, 0.9 * (1.0 - f)))


## A shard of ice flying along a line: a pointed crystal with a frosty tail.
static func draw_shard(ci: CanvasItem, a: Vector2, b: Vector2, k: float, size: float) -> void:
	var d := (b - a)
	if d.length() < 1.0 or size < 0.5:
		return
	var dir := d.normalized()
	var at := a.lerp(b, clampf(k, 0.0, 1.0))
	var tail := at - dir * minf(d.length() * k, size * 4.0)
	ci.draw_line(tail, at, Color(ICE, 0.35), size * 0.9, true)
	var o := dir.orthogonal()
	var pts := PackedVector2Array([at + dir * size * 1.3, at + o * size * 0.45, at - dir * size * 0.7, at - o * size * 0.45])
	Dot.poly(ci, pts, Color("d9f6ff"))
	Dot.pline(ci, PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("6fb7ff"), 1.5, true)


## Glacia's ice pillar: a cluster of tall crystals seen from above.
static func draw_crystal_pillar(ci: CanvasItem, p: Vector2, rad: float, k: float, seed: float, t: float) -> void:
	Dot.circle(ci, p + Vector2(3, 6) * k, rad * k, Color(0, 0, 0, 0.3 * k))
	Dot.circle(ci, p, rad * (0.5 + 0.5 * k), Color(Color("4b4a8f"), 0.6))
	for l in 6:
		var a := seed + l * TAU / 6.0
		var d := Vector2.from_angle(a)
		var ln := rad * (0.7 + 0.35 * sin(seed * 3.0 + l)) * k
		if ln < 1.0:
			continue # still growing in: a flat triangle can't be drawn
		var o := d.orthogonal()
		var base := p + d * rad * 0.1
		var pts := PackedVector2Array([base + o * rad * 0.18, base + d * ln, base - o * rad * 0.18])
		Dot.poly(ci, pts, Color("bfe9ff") if l % 2 else Color("d9d0ff"))
		ci.draw_line(base, base + d * ln, Color(1, 1, 1, 0.6), 1.5, true)
	_sparkle(ci, p + Vector2(-0.2, -0.3) * rad, rad * 0.25 * (0.6 + 0.4 * sin(t * 4.0 + seed)), Color.WHITE)


## Frost creeping over a bitten foe: one crystal per stack, gathering on its rim.
static func draw_frost_stacks(ci: CanvasItem, p: Vector2, r: float, stacks: int, total: int, t: float) -> void:
	var share := clampf(float(stacks) / maxf(1.0, total), 0.0, 1.0)
	Dot.arc(ci, p, r * 1.02, -PI / 2.0, -PI / 2.0 + TAU * share, 40, Color(ICE, 0.85), 5.0, true)
	for q in stacks * 3:
		var a := -PI / 2.0 + TAU * share * (q + 0.5) / (stacks * 3.0)
		var at := p + Vector2.from_angle(a) * r * 1.02
		_sparkle(ci, at, r * 0.14 * (0.8 + 0.2 * sin(t * 6.0 + q)), Color("e8fbff"))


## Frostfang hunting a frozen foe: icy breath streaming off it.
static func draw_frost_breath(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	if vel.length() < 0.001:
		return
	var back := -vel.normalized()
	for k in 7:
		var f := fmod(t * 2.5 + k / 7.0, 1.0)
		var at := p + back * r * (0.8 + 1.6 * f) + back.orthogonal() * sin(k * 2.3 + t * 3.0) * r * 0.35 * f
		Dot.circle(ci, at, r * (0.12 + 0.18 * f), Color(ICE, 0.5 * (1.0 - f)))


## Leviathan under the water: a fin cutting the surface with a V-shaped wake.
static func draw_fin(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	var dir := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	var o := dir.orthogonal()
	Dot.circle(ci, p, r * 0.9, Color(Color("0b2a4a"), 0.45))
	for k in 3:
		var f := fmod(t * 1.5 + k / 3.0, 1.0)
		var back := p - dir * r * (0.4 + 1.6 * f)
		ci.draw_line(back + o * r * (0.3 + 0.8 * f), p - dir * r * 0.2 + o * r * 0.15, Color(WATER, 0.5 * (1.0 - f)), 2.5, true)
		ci.draw_line(back - o * r * (0.3 + 0.8 * f), p - dir * r * 0.2 - o * r * 0.15, Color(WATER, 0.5 * (1.0 - f)), 2.5, true)
	var fin := PackedVector2Array([p + dir * r * 0.5, p - dir * r * 0.4 + o * r * 0.18, p - dir * r * 0.55, p - dir * r * 0.4 - o * r * 0.18])
	Dot.poly(ci, fin, Color("2fb3b0"))
	ci.draw_line(p - dir * r * 0.5, p + dir * r * 0.5, Color(WATER, 0.9), 2.0, true)


## Leviathan's tail in a fight: one tapering body from its back through the
## stinging segments the sim placed along its path, ending in a fluke.
static func draw_sea_tail(ci: CanvasItem, root: Vector2, r: float, segs: Array, col: Color) -> void:
	if segs.is_empty():
		return
	var pts: Array = [root]
	pts.append_array(segs)
	for pass_ in 2: # A dark outline, then the body over it.
		var body := col.darkened(0.45) if pass_ == 0 else col
		for i in pts.size() - 1:
			var w := r * lerpf(0.9, 0.35, float(i + 1) / pts.size()) + (6.0 if pass_ == 0 else 0.0)
			Dot.pline(ci, PackedVector2Array([pts[i], pts[i + 1]]), body, w, true)
			Dot.circle(ci, pts[i + 1], w / 2.0, body)
	var tip: Vector2 = pts[-1]
	var back: Vector2 = tip - pts[-2]
	if back.length() < 0.5:
		return
	back = back.normalized()
	for k in [-1.0, 1.0]:
		Dot.poly(ci, PackedVector2Array([tip, tip + back.rotated(k * 0.9) * r * 0.75, tip + back.rotated(k * 0.3) * r * 0.4]), Color("5ee6d0"))


## Leviathan bursting up: a white-water ring and a column of spray.
static func draw_splash(ci: CanvasItem, c: Vector2, reach: float, age: float, seed: float) -> void:
	var k := clampf(age / SPLASH_LIFE, 0.0, 1.0)
	var a := 1.0 - k
	Dot.circle(ci, c, reach * 0.35 * (1.0 - k * 0.5), Color(Color("e8feff"), 0.5 * a))
	Dot.arc(ci, c, reach * (0.3 + 0.7 * sqrt(k)), 0.0, TAU, 64, Color(WATER, 0.9 * a), 10.0 * a + 2.0, true)
	Dot.arc(ci, c, reach * (0.2 + 0.5 * sqrt(k)), 0.0, TAU, 48, Color(Color.WHITE, 0.6 * a), 4.0, true)
	for q in 14:
		var ang := seed + q * TAU / 14.0
		var up := sin(k * PI) * reach * 0.3
		var at := c + Vector2.from_angle(ang) * reach * (0.2 + 0.6 * k) + Vector2(0, -up)
		Dot.circle(ci, at, 6.0 * a + 2.0, Color(Color("bff8ff"), 0.85 * a))


## A foe Puppeteer hurled: a motion streak and a dangling cut string.
static func draw_thrown(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	if vel.length() < 0.001:
		return
	var back := -vel.normalized()
	for k in 4:
		var o := back.orthogonal() * (k - 1.5) * r * 0.45
		ci.draw_line(p + back * r + o, p + back * r * (2.6 - 0.3 * absf(k - 1.5)) + o, Color(1, 1, 1, 0.45), 3.0, true)
	var string_end := p + back * r * 1.6 + Vector2(sin(t * 12.0) * 6.0, 10.0)
	ci.draw_line(p - Vector2(0, r), string_end, Color("fff3c4"), 2.0, true)


# --- Batch 5: Flicker, Pucker, Spiker, Speedster, Gumdrop, Vampire, Zapper, Mole, Magmo, Wrecker, Munch ---

const LAVA := Color("ff5a1f")
const DIRT := Color("8a5a2b")
const BLOOD := Color("c8102e")


## Speedster's afterimage: a fading see-through copy of it with speed lines.
static func draw_afterimage(ci: CanvasItem, p: Vector2, rad: float, fade: float, col: Color) -> void:
	Dot.circle(ci, p, rad, Color(col, 0.22 * fade))
	Dot.arc(ci, p, rad, 0.0, TAU, 28, Color(col.lightened(0.4), 0.5 * fade), 2.0, true)
	for k in 3:
		var y := (k - 1) * rad * 0.45
		ci.draw_line(p + Vector2(-rad * 0.7, y), p + Vector2(rad * 0.7, y), Color(1, 1, 1, 0.18 * fade), 2.0, true)


## Gumdrop's gum string: a thick sagging pink strand with drips.
static func draw_gum_string(ci: CanvasItem, a: Vector2, b: Vector2, t: float) -> void:
	var pts := PackedVector2Array()
	var sag := minf(a.distance_to(b) * 0.18, 40.0)
	for q in 15:
		var k := q / 14.0
		var thin := 1.0 - 0.5 * sin(k * PI)
		pts.append(a.lerp(b, k) + Vector2(0, sag * sin(k * PI) + sin(t * 4.0 + k * 6.0) * 2.0 * thin))
	Dot.pline(ci, pts, Color(GOO.darkened(0.25), 0.9), 11.0, true)
	Dot.pline(ci, pts, GOO, 7.0, true)
	Dot.pline(ci, pts, Color(1, 1, 1, 0.45), 2.0, true)
	for q in [4, 7, 10]:
		var drip := fmod(t * 0.9 + q * 0.37, 1.0)
		Dot.circle(ci, pts[q] + Vector2(0, 6.0 + drip * 14.0), 3.5 * (1.0 - drip * 0.5), Color(GOO, 0.9 * (1.0 - drip)))


## Count Nibbles' blood shield: a dark red bubble with a drip running down.
static func draw_blood_shield(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.circle(ci, p, r * 1.16, Color(BLOOD, 0.18))
	Dot.arc(ci, p, r * 1.16, 0.0, TAU, 48, Color(BLOOD.lightened(0.2), 0.9), 4.0, true)
	Dot.arc(ci, p, r * 1.24, -PI * 0.8, -PI * 0.2, 20, Color(1, 1, 1, 0.35), 2.0, true)
	for k in 3:
		var f := fmod(t * 0.6 + k / 3.0, 1.0)
		var a := PI * 0.25 + k * PI * 0.25
		var at := p + Vector2.from_angle(a) * r * 1.16 + Vector2(0, f * r * 0.3)
		_drop(ci, at, r * 0.08 * (1.0 - 0.5 * f), Color(BLOOD, 0.9 * (1.0 - f)))


## Mole underground: a mound of loose dirt that shuffles as it moves.
static func draw_burrow(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	Dot.circle(ci, p, r * 0.95, Color(DIRT.darkened(0.4), 0.85))
	for k in 9:
		var a := k * TAU / 9.0 + sin(t * 6.0 + k) * 0.15
		Dot.circle(ci, p + Vector2.from_angle(a) * r * (0.55 + 0.1 * sin(t * 9.0 + k * 2.0)), r * 0.3, DIRT if k % 2 else DIRT.lightened(0.15))
	Dot.circle(ci, p, r * 0.4, DIRT.lightened(0.25))
	if vel.length() > 0.001: # A furrow behind it.
		var back := -vel.normalized()
		for k in 4:
			Dot.circle(ci, p + back * r * (1.0 + 0.5 * k), r * (0.28 - 0.05 * k), Color(DIRT, 0.6 - 0.12 * k))


## Magmo's lava puddle: a crusted pool with glowing cracks and popping bubbles.
static func draw_lava(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	Dot.circle(ci, p, rad * 1.05, Color(LAVA.darkened(0.6), 0.6 * fade))
	Dot.circle(ci, p, rad, Color(LAVA, 0.55 * fade))
	Dot.circle(ci, p, rad * 0.6, Color(Color("ffb347"), 0.45 * fade))
	for k in 5: # Dark crust plates drifting on top.
		var a := seed + k * 1.3 + t * 0.15
		Dot.circle(ci, p + Vector2.from_angle(a) * rad * 0.55, rad * 0.2, Color(Color("4a1a0a"), 0.6 * fade))
	for k in 3:
		var f := fmod(t * 0.9 + k / 3.0 + seed, 1.0)
		var at := p + Vector2.from_angle(seed * 2.0 + k * 2.1) * rad * 0.4
		Dot.arc(ci, at, rad * 0.12 * (0.4 + f), 0.0, TAU, 12, Color(Color("ffe066"), 0.8 * (1.0 - f) * fade), 2.0, true)


## Wrecker's chain: oval links from its body out to the ball.
static func draw_chain(ci: CanvasItem, a: Vector2, b: Vector2, link: float) -> void:
	var span := a.distance_to(b)
	if span < 1.0:
		return
	var dir := (b - a) / span
	var n := maxi(2, int(span / (link * 1.5)))
	for q in n:
		var c := a + dir * span * (q + 0.5) / n
		var flat := q % 2 == 1
		var w := link * (0.75 if not flat else 0.35)
		var pts := PackedVector2Array()
		for k in 13:
			var ang := k * TAU / 12.0
			pts.append(c + dir * cos(ang) * link * 0.8 + dir.orthogonal() * sin(ang) * w * 0.5)
		Dot.pline(ci, pts, Color("2a2f36"), 4.5, true)
		Dot.pline(ci, pts, Color("9aa3ad"), 2.0, true)


## A spike shot: a sharp silver thorn pointing where it flies.
static func draw_spike_shot(ci: CanvasItem, p: Vector2, r: float, vel: Vector2) -> void:
	var dir := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	var o := dir.orthogonal()
	ci.draw_line(p, p - dir * r * 3.0, Color(1, 1, 1, 0.25), r, true)
	Dot.poly(ci, PackedVector2Array([p + dir * r * 1.8, p + o * r * 0.6 - dir * r * 0.6, p - o * r * 0.6 - dir * r * 0.6]), Color("e8e8f0"))
	ci.draw_line(p - dir * r * 0.6, p + dir * r * 1.8, Color("8a8aa0"), 1.5, true)


# --- Batch 6: Brewster, Clam, Drako, Gearbox, Hook, Jawbreaker, Mammoth,
# Swarm, Whiff, Yeti -----------------------------------------------------------

const SHELL := Color("f7c6d9")
const PEARL := Color("fff6fb")
const COG := Color("a7c957")
const FUR_SNOW := Color("eef6ff")
const FUR_BROWN := Color("8a5a3b")
const STINK := Color("9be36b")
const SNOW := Color("f4fbff")
## Potion colours by the puddle a blob makes.
const POTIONS := {"fire": Color("ff7a1f"), "goo": Color("7cff6b"), "brew": Color("b6ff3b")}
const AVALANCHE_LIFE := 0.8
const HOOK_LIFE := 0.45


## Clam's shell clamped over it. k is how shut it is (1 shut, 0 open): the
## two scalloped halves part as it opens, showing the pearl inside.
static func draw_clam_shell(ci: CanvasItem, p: Vector2, r: float, k: float, t: float) -> void:
	if r < 2.0:
		return
	var gap := (1.0 - k) * r * 0.7
	if k < 0.95: # The pearl peeking out.
		Dot.circle(ci, p, r * 0.32, PEARL)
		Dot.circle(ci, p + Vector2(-r * 0.1, -r * 0.1), r * 0.1, Color.WHITE)
	for side in [-1.0, 1.0]:
		var off := Vector2(0, side * gap)
		var pts := PackedVector2Array()
		for i in 17: # A half dome, flat edge along the middle (no repeated point).
			var a: float = PI * i / 16.0
			pts.append(p + off + Vector2(cos(a) * r * 1.12, side * sin(a) * r * 1.05))
		Dot.poly(ci, pts, Color(SHELL, 0.92))
		for q in 5: # Ridges fanning from the hinge.
			var a: float = PI * (q + 1) / 6.0
			ci.draw_line(p + off, p + off + Vector2(cos(a) * r * 1.05, side * sin(a) * r * 0.98), Color(SHELL.darkened(0.3), 0.8), 2.0, true)
		Dot.pline(ci, pts, Color(SHELL.darkened(0.35)), 2.5, true)
	if k >= 0.95: # Shut tight: a glint runs round the rim.
		var a := fmod(t * 3.0, PI)
		Dot.circle(ci, p + Vector2(cos(a) * r * 1.1, -sin(a) * r * 1.0), r * 0.08, Color(1, 1, 1, 0.8))


## Clam's pearl shot: glossy with a rainbow sheen.
static func draw_pearl(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.circle(ci, p, r * 1.5, Color(PEARL, 0.25))
	Dot.circle(ci, p, r, PEARL)
	Dot.arc(ci, p, r * 0.75, t * 5.0, t * 5.0 + PI * 0.8, 12, Color.from_hsv(fmod(t * 0.7, 1.0), 0.35, 1.0, 0.9), r * 0.25, true)
	Dot.circle(ci, p + Vector2(-r * 0.35, -r * 0.35), r * 0.25, Color.WHITE)


## Brewster's potion blob in flight: a round flask that tumbles.
static func draw_potion(ci: CanvasItem, p: Vector2, r: float, liquid: Color, spin: float) -> void:
	var up := Vector2.from_angle(spin - PI / 2.0)
	ci.draw_line(p + up * r * 0.7, p + up * r * 1.45, Color("d6f5ff", 0.9), r * 0.5, true) # Neck.
	ci.draw_line(p + up * r * 1.4, p + up * r * 1.7, Color("a0703c"), r * 0.55, true) # Cork.
	Dot.circle(ci, p, r * 1.05, Color("d6f5ff", 0.5)) # Glass.
	Dot.circle(ci, p + up * -r * 0.15, r * 0.82, liquid)
	Dot.circle(ci, p + up * r * 0.1 + up.orthogonal() * r * 0.3, r * 0.14, Color(1, 1, 1, 0.7))
	Dot.arc(ci, p, r * 1.05, spin + PI * 1.1, spin + PI * 1.5, 8, Color(1, 1, 1, 0.8), 2.0, true)


## Brewster's cauldron: bubbles rising and popping off the top.
static func draw_cauldron(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.arc(ci, p + Vector2(0, -r * 0.35), r * 0.75, PI * 1.08, PI * 1.92, 16, Color("b6ff3b", 0.85), r * 0.14, true)
	for k in 4:
		var f := fmod(t * 0.9 + k * 0.27, 1.0)
		var x := sin(k * 2.3 + t * 2.0) * r * 0.4
		var at := p + Vector2(x, -r * (0.6 + 1.0 * f))
		var br := r * (0.1 + 0.06 * sin(k * 1.7)) * (0.6 + 0.6 * f)
		Dot.arc(ci, at, br, 0.0, TAU, 12, Color("b6ff3b", 0.85 * (1.0 - f)), 2.0, true)


## Drako stoking its fire: smoke and embers from the mouth (k: 0..1 full).
static func draw_stoke(ci: CanvasItem, p: Vector2, r: float, k: float, vel: Vector2, t: float) -> void:
	if k <= 0.0:
		return
	var fwd := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	var mouth := p + fwd * r * 0.85
	Dot.circle(ci, mouth, r * (0.2 + 0.25 * k), Color(BURN, 0.25 + 0.4 * k))
	Dot.circle(ci, mouth, r * (0.1 + 0.12 * k), Color(BURN_CORE, 0.5 + 0.4 * k))
	for q in int(2 + 4 * k): # Smoke puffs curling up and back.
		var f := fmod(t * 1.3 + q * 0.21, 1.0)
		var at := mouth - fwd * r * 0.6 * f + Vector2(sin(t * 3.0 + q) * r * 0.15, -r * 0.9 * f)
		Dot.circle(ci, at, r * (0.08 + 0.12 * f), Color(0.35, 0.33, 0.38, 0.45 * (1.0 - f) * k))
	if k >= 1.0: # Full: flickering sparks.
		for q in 3:
			var a := t * 9.0 + q * TAU / 3.0
			Dot.circle(ci, mouth + Vector2.from_angle(a) * r * 0.3, r * 0.06, BURN_CORE)


## Drako's breath as a stream of fireballs along a beam (k: beam strength).
static func draw_fireballs(ci: CanvasItem, a: Vector2, b: Vector2, k: float, t: float, size: float) -> void:
	var n := 6
	for i in n:
		var f := fmod(i / float(n) + t * 2.5, 1.0)
		var at := a.lerp(b, f)
		var rr := size * (0.5 + 0.7 * f) * k
		Dot.circle(ci, at, rr * 1.5, Color(BURN, 0.3 * k))
		Dot.circle(ci, at, rr, Color(BURN, 0.9 * k))
		Dot.circle(ci, at, rr * 0.5, Color(BURN_CORE, k))


## Gearbox's cog: teeth round its rim, spinning faster in each gear and
## glowing hot in top gear.
static func draw_cog(ci: CanvasItem, p: Vector2, r: float, gear: int, top: int, t: float) -> void:
	var hot := gear >= top
	var col: Color = Color("ff5a3d") if hot else COG.lerp(Color("ffd23f"), gear / maxf(1.0, top))
	var turn := t * (0.6 + 1.8 * gear)
	for q in 10:
		var d := Vector2.from_angle(turn + q * TAU / 10.0)
		ci.draw_line(p + d * r * 0.98, p + d * r * 1.2, col.darkened(0.25), r * 0.22, true)
	Dot.arc(ci, p, r * 1.0, 0.0, TAU, 40, col, 3.0, true)
	if hot:
		Dot.arc(ci, p, r * 1.3, 0.0, TAU, 40, Color(col, 0.3 + 0.2 * sin(t * 14.0)), 5.0, true)


## Hook's grapple: a wavy rope with a hook at the end, reeling in.
static func draw_hook(ci: CanvasItem, from: Vector2, to: Vector2, k: float, t: float) -> void:
	var d := to - from
	if d.length() < 2.0:
		return
	var n := d.normalized()
	var side := n.orthogonal()
	var pts := PackedVector2Array()
	for i in 13:
		var f := i / 12.0
		pts.append(from + d * f + side * sin(f * TAU * 2.0 + t * 20.0) * 8.0 * (1.0 - k) * sin(PI * f))
	Dot.pline(ci, pts, Color("c9a26b"), 4.0, true)
	Dot.pline(ci, pts, Color("f1d6a8", 0.7), 1.5, true)
	# The hook: a curl round the far end with a barb.
	Dot.arc(ci, to - n * 6.0 + side * 8.0, 9.0, n.angle() + PI * 0.5, n.angle() + PI * 1.6, 12, Color("d9e2ec"), 4.0, true)
	ci.draw_line(to - n * 6.0, to + n * 10.0, Color("d9e2ec"), 4.0, true)
	ci.draw_line(to + n * 10.0, to + n * 2.0 + side * 6.0, Color("d9e2ec"), 3.0, true)


## A jawbreaker candy: layered rings of colour with a shine.
static func draw_jawbreaker(ci: CanvasItem, p: Vector2, r: float, hue: int, t: float) -> void:
	var cols := [Color("ff5fa2"), Color("ffd23f"), Color("6ee7ff"), Color("a6ff6e"), Color("c58bff")]
	Dot.circle(ci, p, r * 1.3, Color(cols[hue % 5], 0.25))
	for q in 4:
		Dot.circle(ci, p, r * (1.0 - q * 0.22), cols[(hue + q) % 5])
	Dot.arc(ci, p, r * 0.8, t * 3.0, t * 3.0 + 1.2, 8, Color(1, 1, 1, 0.75), 2.0, true)
	Dot.circle(ci, p + Vector2(-r * 0.4, -r * 0.4), r * 0.18, Color.WHITE)


## Shaggy fur round the rim (Yeti white, Mammoth brown), ruffling.
static func draw_fur(ci: CanvasItem, p: Vector2, r: float, col: Color, t: float) -> void:
	for q in 22:
		var a := q * TAU / 22.0
		var d := Vector2.from_angle(a)
		var tip := d.rotated(0.35 + 0.12 * sin(t * 5.0 + q)) * r * (1.2 + 0.05 * sin(q * 3.1))
		ci.draw_line(p + d * r * 0.97, p + tip, col, 3.5, true)


## Swarm's hive: a honeycomb pattern over its body.
static func draw_hive(ci: CanvasItem, p: Vector2, r: float) -> void:
	var cell := r * 0.32
	for q in 7:
		var c := p if q == 6 else p + Vector2.from_angle(q * TAU / 6.0 + PI / 6.0) * cell * 1.75
		var pts := PackedVector2Array()
		for i in 7: # Closed outline (polyline, so the repeated point is fine).
			pts.append(c + Vector2.from_angle(i * TAU / 6.0) * cell)
		Dot.pline(ci, pts, Color("7a4a00", 0.55), 2.0, true)


## A bee: striped body, flapping wings and a stinger, facing `dir`.
static func draw_bee(ci: CanvasItem, p: Vector2, r: float, dir: Vector2, t: float, flying: bool) -> void:
	var fwd := dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	var side := fwd.orthogonal()
	if flying: # A buzzing trail.
		for q in 3:
			Dot.circle(ci, p - fwd * r * (1.6 + q * 0.9) + side * sin(t * 30.0 + q) * r * 0.4, r * (0.25 - q * 0.06), Color("ffc93c", 0.4 - q * 0.1))
	var flap := 0.5 + 0.5 * sin(t * 45.0)
	for s in [-1.0, 1.0]:
		Dot.circle(ci, p + side * s * r * (0.7 + 0.3 * flap) - fwd * r * 0.1, r * 0.55, Color(1, 1, 1, 0.5))
	Dot.circle(ci, p, r, Color("ffc93c"))
	for q in [-0.35, 0.25]:
		ci.draw_line(p + fwd * r * q + side * r * 0.9, p + fwd * r * q - side * r * 0.9, Color("2a1d05"), r * 0.3, true)
	ci.draw_line(p - fwd * r, p - fwd * r * 1.5, Color("2a1d05"), 2.0, true)
	Dot.circle(ci, p + fwd * r * 0.7, r * 0.18, Color("2a1d05"))


## Whiff's stink cloud: lumpy green puffs and wavy stink lines rising.
static func draw_stink(ci: CanvasItem, p: Vector2, rad: float, t: float) -> void:
	for k in 7:
		var a := t * 0.5 + k * TAU / 7.0
		var at := p + Vector2(cos(a), sin(a)) * rad * (0.55 + 0.08 * sin(t * 2.0 + k))
		Dot.circle(ci, at, rad * (0.36 + 0.05 * sin(t * 3.0 + k * 1.3)), Color(STINK, 0.09))
	Dot.arc(ci, p, rad, 0.0, TAU, 48, Color(STINK, 0.22), 2.0, true)
	for k in 4: # Wavy stink lines drifting up and fading.
		var f := fmod(t * 0.45 + k * 0.25, 1.0)
		var x := (k - 1.5) * rad * 0.35
		var pts := PackedVector2Array()
		for i in 7:
			var g := i / 6.0
			pts.append(p + Vector2(x + sin(g * TAU + t * 5.0 + k) * rad * 0.06, -rad * (0.2 + 0.7 * f) - g * rad * 0.35))
		Dot.pline(ci, pts, Color(STINK.lightened(0.2), 0.7 * (1.0 - f)), 3.0, true)


## Yeti's avalanche: a wave of snow rolling out with chunks and flakes.
static func draw_avalanche(ci: CanvasItem, c: Vector2, reach: float, age: float, seed: float) -> void:
	var f := clampf(age / AVALANCHE_LIFE, 0.0, 1.0)
	var rad := reach * (0.25 + 0.75 * sqrt(f))
	var fade := 1.0 - f
	Dot.circle(ci, c, rad, Color(SNOW, 0.12 * fade))
	for q in 18: # Snow chunks riding the front.
		var a := seed + q * TAU / 18.0
		var at := c + Vector2.from_angle(a) * rad * (0.92 + 0.08 * sin(q * 2.7))
		Dot.circle(ci, at, reach * 0.06 * (0.6 + 0.4 * sin(q * 1.9)) * (0.5 + fade), Color(SNOW, 0.85 * fade))
	for q in 10: # Flakes inside.
		var a := seed * 2.0 + q * 0.83
		_flake(ci, c + Vector2.from_angle(a) * rad * fmod(q * 0.37 + 0.2, 0.9), reach * 0.035, Color(Color("d8f1ff"), fade))
	Dot.arc(ci, c, rad, 0.0, TAU, 64, Color(Color("9fd8ff"), 0.8 * fade), 5.0, true)


static func _flake(ci: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	for q in 3:
		var d := Vector2.from_angle(q * PI / 3.0) * r
		ci.draw_line(at - d, at + d, col, 2.0, true)


# --- Batch 7: Comet, Mortar, Painter, Sonar, Splitter, Sprout, Zigzag, Zing,
# Gust ---------------------------------------------------------------------------

const STARDUST := Color("ff8ae2")
const SONAR := Color("b48cff")
const ZIG := Color("ffe14d")
const SAP := Color("8ac926")
const PAINTS := [Color("ff5d8f"), Color("ffd23f"), Color("4cc9f0"), Color("80ed99"), Color("b388ff")]
const SONAR_LIFE := 0.7
const EDGE_GLYPH_LIFE := 0.7
const MITOSIS_LIFE := 0.6


## Comet's blazing tail streaming behind it, with twinkles.
static func draw_comet_tail(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	if vel.length() < 0.001:
		return
	var back := -vel.normalized()
	var side := back.orthogonal()
	for q in 6:
		var f := (q + 1) / 6.0
		Dot.circle(ci, p + back * r * (0.6 + 1.6 * f) + side * sin(t * 12.0 + q) * r * 0.08, r * (0.75 - 0.6 * f), Color(STARDUST.lerp(Color("ffe9a8"), f), 0.4 * (1.0 - f)))
	for q in 4:
		var f := fmod(t * 1.7 + q * 0.25, 1.0)
		var at := p + back * r * (0.8 + 2.0 * f) + side * r * 0.5 * sin(q * 2.1 + t)
		_twinkle(ci, at, r * 0.18 * (1.0 - f), Color(1, 1, 1, 0.9 * (1.0 - f)))


## A four-point twinkle.
static func _twinkle(ci: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	if r < 0.5:
		return
	ci.draw_line(at - Vector2(r, 0), at + Vector2(r, 0), col, 2.0, true)
	ci.draw_line(at - Vector2(0, r), at + Vector2(0, r), col, 2.0, true)
	Dot.circle(ci, at, r * 0.3, col)


## Comet's stardust trail: a glittering patch with twinkling stars.
static func draw_stardust(ci: CanvasItem, p: Vector2, rad: float, fade: float, seed: float, t: float) -> void:
	Dot.circle(ci, p, rad * 0.65, Color(STARDUST, 0.2 * fade))
	for q in 3:
		var a := seed + q * 2.1
		var tw := 0.5 + 0.5 * sin(t * 6.0 + seed * 3.0 + q * 2.0)
		_twinkle(ci, p + Vector2.from_angle(a) * rad * 0.45, rad * 0.3 * tw * fade, Color(Color("fff0fb"), 0.9 * fade))


## Comet's shooting star: a bright head racing along the beam with a sparkly wake.
static func draw_shooting_star(ci: CanvasItem, a: Vector2, b: Vector2, k: float, t: float) -> void:
	var head := a.lerp(b, clampf(1.2 - k, 0.0, 1.0))
	ci.draw_line(a, head, Color(STARDUST, 0.35 * k), 8.0, true)
	ci.draw_line(a, head, Color(1, 1, 1, 0.7 * k), 2.5, true)
	for q in 5:
		var f := q / 5.0
		_twinkle(ci, a.lerp(head, f) + (b - a).orthogonal().normalized() * sin(t * 20.0 + q) * 6.0, 5.0 * f * k, Color(Color("ffe9a8"), k))
	Dot.circle(ci, head, 9.0, Color(STARDUST, 0.6 * k))
	_twinkle(ci, head, 14.0 * k, Color.WHITE)


## Mortar's barrel, pointing at `aim`.
static func draw_barrel(ci: CanvasItem, p: Vector2, r: float, aim: Vector2, recoil: float) -> void:
	var d := aim.normalized() if aim.length() > 0.001 else Vector2.UP
	var base := p + d * r * (0.55 - 0.25 * recoil)
	ci.draw_line(base, base + d * r * 0.7, Color("2b2f36"), r * 0.42, true)
	ci.draw_line(base + d * r * 0.62, base + d * r * 0.72, Color("ffb347"), r * 0.5, true)


## Mortar's shell in flight: a black cannonball with a fizzing fuse.
static func draw_cannonball(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	Dot.circle(ci, p, r, Color("23262b"))
	Dot.circle(ci, p + Vector2(-r * 0.35, -r * 0.35), r * 0.25, Color(1, 1, 1, 0.35))
	var fuse := p + Vector2(r * 0.6, -r * 0.8)
	ci.draw_line(p + Vector2(r * 0.4, -r * 0.6), fuse, Color("c9a26b"), 2.5, true)
	var fl := 0.6 + 0.4 * sin(t * 40.0)
	Dot.circle(ci, fuse, r * 0.3 * fl, Color(BURN, 0.8))
	Dot.circle(ci, fuse, r * 0.15 * fl, BURN_CORE)


## Painter: drips of paint running down its body.
static func draw_paint_drips(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	for q in 5:
		var a := PI * (0.15 + 0.7 * q / 4.0)
		var top := p + Vector2(cos(a), -sin(a)) * r * 0.95
		var f := fmod(t * 0.5 + q * 0.37, 1.0)
		var col: Color = PAINTS[q]
		Dot.circle(ci, top, r * 0.16, col)
		ci.draw_line(top, top + Vector2(0, r * 0.35 * f), col, r * 0.12, true)
		Dot.circle(ci, top + Vector2(0, r * 0.35 * f), r * 0.08, col)


## Sonar's ping: three arcs of sound rippling out.
static func draw_sonar(ci: CanvasItem, c: Vector2, reach: float, age: float) -> void:
	for q in 3:
		var f := clampf(age / SONAR_LIFE - q * 0.15, 0.0, 1.0)
		if f <= 0.0 or f >= 1.0:
			continue
		Dot.arc(ci, c, reach * f, 0.0, TAU, 56, Color(SONAR, 0.85 * (1.0 - f)), 4.0 * (1.0 - f) + 1.0, true)


## Sonar's bat wings, flapping either side of the body.
static func draw_bat_wings(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	var flap := 0.55 + 0.45 * sin(t * 10.0)
	for s in [-1.0, 1.0]:
		var root := p + Vector2(s * r * 0.8, -r * 0.1)
		var tip := p + Vector2(s * r * (1.5 + 0.2 * flap), -r * (0.2 + 0.7 * flap))
		var low := p + Vector2(s * r * 1.35, r * 0.3)
		var mid := p + Vector2(s * r * 1.45, -r * 0.05)
		if r > 3.0: # Two triangles, so the shape can't fold over itself.
			Dot.poly(ci, PackedVector2Array([root, tip, mid]), Color("3b2a5c"))
			Dot.poly(ci, PackedVector2Array([root, mid, low]), Color("3b2a5c"))
			Dot.pline(ci, PackedVector2Array([root, tip, mid, low]), Color(SONAR, 0.8), 2.0, true)


## Splitter's split: a gooey bridge snapping between the two halves.
static func draw_mitosis(ci: CanvasItem, a: Vector2, b: Vector2, r: float, age: float, col: Color) -> void:
	var f := clampf(age / MITOSIS_LIFE, 0.0, 1.0)
	var thick := r * 0.8 * (1.0 - f)
	if thick < 1.0:
		return
	ci.draw_line(a, b, Color(col, 0.7 * (1.0 - f)), thick, true)
	Dot.circle(ci, a.lerp(b, 0.5), thick * 0.4, Color(col.lightened(0.3), 0.8 * (1.0 - f)))


## Sprout's seed pillar: a sapling with leaves and a bud, growing in.
static func draw_sapling(ci: CanvasItem, p: Vector2, rad: float, k: float, t: float) -> void:
	Dot.circle(ci, p, rad * (0.4 + 0.6 * k), Color("4a2f1b", 0.8)) # Soil.
	if k < 0.05:
		return
	var h := rad * 1.3 * k
	var sway := sin(t * 2.0 + p.x * 0.01) * rad * 0.1
	var top := p + Vector2(sway, -h)
	ci.draw_line(p, top, Color("2f6b12"), rad * 0.18, true)
	for s in [-1.0, 1.0]:
		var at := p.lerp(top, 0.55)
		Dot.circle(ci, at + Vector2(s * rad * 0.35 * k, 0), rad * 0.28 * k, SAP)
		ci.draw_line(at, at + Vector2(s * rad * 0.35 * k, 0), Color("2f6b12"), 2.0, true)
	Dot.circle(ci, top, rad * 0.22 * k, Color("ff9ecf"))
	Dot.arc(ci, p, rad, 0.0, TAU, 32, Color(SAP, 0.6 * k), 2.0, true)


## Zigzag charged: little sparks jumping round its rim.
static func draw_charged(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	for q in 3:
		var a := floorf(t * 14.0) * 1.7 + q * TAU / 3.0
		var at := p + Vector2.from_angle(a) * r * 1.05
		var out := at + Vector2.from_angle(a + 0.6) * r * 0.3
		ci.draw_line(at, out, ZIG, 3.0, true)
		ci.draw_line(out, out + Vector2.from_angle(a - 0.5) * r * 0.25, ZIG, 3.0, true)


## Zing's stinger: a sharp black-and-yellow dart.
static func draw_stinger(ci: CanvasItem, p: Vector2, r: float, vel: Vector2) -> void:
	var d := vel.normalized() if vel.length() > 0.001 else Vector2.RIGHT
	ci.draw_line(p - d * r * 2.2, p - d * r * 0.5, Color(ZIG, 0.35), r * 0.8, true) # Blur.
	ci.draw_line(p - d * r * 0.8, p + d * r * 0.4, Color("ffc93c"), r * 1.0, true)
	ci.draw_line(p - d * r * 0.2, p + d * r * 0.05, Color("2a1d05"), r * 1.05, true)
	ci.draw_line(p + d * r * 0.4, p + d * r * 1.6, Color("2a1d05"), maxf(1.5, r * 0.3), true)


## Zing's wasp stripes and wings.
static func draw_wasp(ci: CanvasItem, p: Vector2, r: float, t: float) -> void:
	var flap := 0.5 + 0.5 * sin(t * 50.0)
	for s in [-1.0, 1.0]:
		Dot.circle(ci, p + Vector2(s * r * (0.85 + 0.15 * flap), -r * 0.75), r * 0.42, Color(1, 1, 1, 0.45))
	for q in [-0.45, 0.45]:
		Dot.arc(ci, p + Vector2(0, r * q), r * 0.95 * sqrt(1.0 - q * q), PI * 0.12, PI * 0.88, 10, Color("2a1d05", 0.75), 4.0, true)


## Gust's wind: swirls curling round it, faster in a huff.
static func draw_gusts(ci: CanvasItem, p: Vector2, r: float, reach: float, t: float, huffing: bool) -> void:
	var n := 6 if huffing else 3
	for q in n:
		var f := fmod(t * (1.2 if huffing else 0.5) + q / float(n), 1.0)
		var a := q * TAU / n + t * 0.8
		var rr := r * 1.2 + (reach - r) * f
		Dot.arc(ci, p, rr, a, a + (0.9 if huffing else 0.6), 12, Color(Color("e8fff0"), (0.7 if huffing else 0.4) * (1.0 - f)), 3.0, true)
		var tip := p + Vector2.from_angle(a + 0.9) * rr
		Dot.arc(ci, tip + Vector2.from_angle(a + 0.9 - PI / 2.0) * r * 0.2, r * 0.2, a, a + PI * 1.4, 8, Color(Color("e8fff0"), 0.5 * (1.0 - f)), 2.0, true)


# --- Tier looks: higher tiers glow, T5 blazes -----------------------------------

const ASCEND := Color("ffd23f")


## A tier aura behind the critter: T3 a soft ring, T4 a double ring with
## orbiting sparks, T5 a blazing gold crown of rays and stars. `col` is the
## critter's own colour, mixed in so each critter keeps its identity.
static func draw_tier_aura(ci: CanvasItem, p: Vector2, r: float, tier: int, col: Color, t: float) -> void:
	if tier < 3 or r < 2.0:
		return
	var glow := col.lerp(ASCEND, 0.6 if tier >= 5 else 0.3)
	var pulse := 0.5 + 0.5 * sin(t * 3.0)
	Dot.circle(ci, p, r * (1.25 + 0.05 * pulse), Color(glow, 0.1 + 0.05 * (tier - 3)))
	Dot.arc(ci, p, r * 1.22, 0.0, TAU, 48, Color(glow, 0.35 + 0.15 * pulse), 2.0, true)
	if tier < 4:
		return
	Dot.arc(ci, p, r * 1.36, t * 0.8, t * 0.8 + PI * 1.4, 32, Color(glow, 0.35), 2.0, true)
	var n := 3 if tier == 4 else 6
	for q in n: # Orbiting sparks.
		var a := t * (1.4 if tier == 4 else 2.0) + q * TAU / n
		var at := p + Vector2.from_angle(a) * r * 1.36
		Dot.circle(ci, at, r * 0.09, Color(glow, 0.5))
		Dot.circle(ci, at, r * 0.05, Color.WHITE)
	if tier < 5:
		return
	for q in 12: # A crown of flickering gold rays.
		var a := q * TAU / 12.0 + t * 0.4
		var flick := 0.6 + 0.4 * sin(t * 9.0 + q * 1.7)
		var d := Vector2.from_angle(a)
		ci.draw_line(p + d * r * 1.15, p + d * r * (1.45 + 0.3 * flick), Color(ASCEND, 0.7 * flick), r * 0.12, true)
	Dot.circle(ci, p, r * 1.6, Color(ASCEND, 0.06 + 0.04 * pulse))
	Dot.arc(ci, p, r * 1.55 + 2.0 * pulse, 0.0, TAU, 56, Color(ASCEND, 0.35 + 0.25 * pulse), 3.5, true)


## T5 critters shed gold sparkles as they move.
static func draw_ascend_trail(ci: CanvasItem, p: Vector2, r: float, vel: Vector2, t: float) -> void:
	if vel.length() < 0.001:
		return
	var back := -vel.normalized()
	for q in 4:
		var f := fmod(t * 2.0 + q * 0.25, 1.0)
		var at := p + back * r * (1.1 + 1.4 * f) + back.orthogonal() * sin(q * 2.3 + t * 4.0) * r * 0.4
		_twinkle(ci, at, r * 0.2 * (1.0 - f), Color(ASCEND, 0.9 * (1.0 - f)))


# --- T5 ability events: Honey's lob, Phoenix's sunfire ---

const SUN := Color("ffe14d")
const SUNFIRE_LIFE := 0.7
const HONEY_LOB_LIFE := 0.5

## Phoenix T5 sunfire: a white-gold flash with rays bursting out to the reach.
static func draw_sunfire(ci: CanvasItem, c: Vector2, reach: float, age: float, seed: float) -> void:
	if reach < 2.0:
		return
	var k := clampf(age / SUNFIRE_LIFE, 0.0, 1.0)
	var a := 1.0 - k
	Dot.circle(ci, c, reach * (0.25 + 0.75 * sqrt(k)), Color(SUN, 0.22 * a))
	Dot.circle(ci, c, reach * 0.3 * (1.0 - k), Color(Color.WHITE, 0.8 * a))
	for q in 16:
		var ang := seed + q * TAU / 16.0 + k * 0.4
		var r0 := reach * (0.15 + 0.5 * k)
		var r1 := reach * (0.4 + 0.6 * sqrt(k)) * (1.0 if q % 2 == 0 else 0.8)
		ci.draw_line(c + Vector2.from_angle(ang) * r0, c + Vector2.from_angle(ang) * r1, Color(SUN if q % 2 == 0 else Color("ff8a1f"), 0.9 * a), 6.0 * a + 1.5, true)
	Dot.arc(ci, c, reach * (0.3 + 0.7 * sqrt(k)), 0.0, TAU, 64, Color(Color("ff8a1f"), 0.9 * a), 8.0 * a + 2.0, true)


## Honey T5 lob: a glob of honey arcing from Honey to the foe, splatting as it lands.
static func draw_honey_lob(ci: CanvasItem, from: Vector2, to: Vector2, r: float, age: float) -> void:
	var k := clampf(age / HONEY_LOB_LIFE, 0.0, 1.0)
	var fly := clampf(k / 0.7, 0.0, 1.0)
	var lift := from.distance_to(to) * 0.35 + 40.0
	if fly < 1.0:
		for q in 4: # The glob and its dripping trail.
			var f := maxf(fly - q * 0.06, 0.0)
			var at := from.lerp(to, f) - Vector2(0, 4.0 * lift * f * (1.0 - f))
			Dot.circle(ci, at, r * (1.0 - q * 0.2), Color(HONEY, 1.0 - q * 0.22))
		var head := from.lerp(to, fly) - Vector2(0, 4.0 * lift * fly * (1.0 - fly))
		Dot.circle(ci, head + Vector2(-r * 0.3, -r * 0.3), r * 0.3, Color(Color("fff3c4"), 0.9))
	else: # Splat.
		var s := (k - 0.7) / 0.3
		var a := 1.0 - s
		Dot.arc(ci, to, r * (1.5 + 4.0 * s), 0.0, TAU, 32, Color(HONEY, 0.9 * a), 5.0 * a + 1.0, true)
		for q in 8:
			var at := to + Vector2.from_angle(q * TAU / 8.0) * r * (1.2 + 3.0 * s)
			Dot.circle(ci, at, r * 0.35 * a + 1.0, Color(Color("ffe08a"), a))


## A family-edge hit: the attacker's family glyph pops off the target, swells,
## drifts up and shrinks away (`t` 0..1 over EDGE_GLYPH_LIFE).
static func draw_edge_glyph(ci: CanvasItem, family: String, c: Vector2, size: float, t: float) -> void:
	var grow := minf(1.0, t / 0.15)
	var k := grow * (1.0 + 0.25 * (1.0 - grow)) * (1.0 - smoothstep(0.6, 1.0, t))
	if k <= 0.05:
		return
	FamilyIcon.draw(ci, family, c + Vector2(0, -size * 0.8 * t), size * k)
