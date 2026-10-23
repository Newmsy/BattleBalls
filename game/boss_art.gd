## How farming bosses look (sim/bosses.gd). Render-only and cheap: a few
## dozen batched polygons, arcs and dots per boss, no textures and no
## per-frame allocation beyond the point lists. draw() is shared by the
## arena and BossIcon (menus); draw_death() is the KO burst.
##
## Every boss breathes, sits on a slowly turning rune circle, flinches and
## flashes when hit, shows its wind-up (opts.charge and friends) and bursts
## apart when beaten.
extends RefCounted

const Dot := preload("res://game/dot.gd")
const TALENTS := preload("res://sim/talents.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")

const IRON := Color("3a3f4f")
const IRON_HI := Color("5d6478")
const STEEL := Color("aab4c8")
const HOT := Color("ff8a3d")
const MOLTEN := Color("ffd166")
const HEN := Color("ff6fae")
const HEN_HI := Color("ffb3d4")
const COMB := Color("ff3d5a")
const BEAK := Color("ffc23d")
const SHELL := Color("fff1d6")
const PRISM := Color("7af0ff")
const AMETHYST := Color("b366ff")
const CODE := Color("7cff4f")
const ERROR := Color("ff4fd8")
const INK := Color("1a1033")
const PINATA := [Color("ff6fae"), Color("5ce1ff"), Color("ffd166"), Color("7cff9b"), Color("b366ff")]

## How long the KO burst plays (draw_death).
const DEATH_LIFE := 1.4
## The colours each boss bursts into.
const DEATH_COLORS := {
	"anvil_king": [HOT, MOLTEN, IRON_HI, STEEL],
	"brood_queen": [HEN, HEN_HI, COMB, BEAK],
	"pinata_titan": [Color("ff6fae"), Color("5ce1ff"), Color("ffd166"), Color("7cff9b"), Color("b366ff")],
	"totem_of_nine": [Color("e9e4ff"), Color("c9a6ff"), Color("8a86a0"), Color("ffd166")],
	"prism_wyrm": [PRISM, AMETHYST, Color("2a6f9e"), Color.WHITE],
	"the_glitch": [CODE, ERROR, Color("e9e4ff")],
}


## Boss `id` centred on `c` with footprint radius `r`. opts: t (seconds),
## hit (0-0.35 flash after a hit), hp_frac, stunned (bool), charge (0-1
## while any wind-up runs), swing (0-1 while a hammer is in the air), quake
## (0-1 while a quake winds up), look (unit vector toward the foe).
static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, opts := {}) -> void:
	var t: float = opts.get("t", 0.0)
	var flinch := clampf(float(opts.get("hit", 0.0)) * 3.0, 0.0, 1.0)
	# Idle breathing, and a quick pinch and judder when something lands.
	r *= 1.0 + 0.025 * sin(t * 2.4) - 0.07 * flinch
	c += Vector2(sin(t * 53.0), cos(t * 41.0)) * r * 0.05 * flinch
	match id:
		"anvil_king":
			_anvil_king(ci, c, r, opts)
		"brood_queen":
			_brood_queen(ci, c, r, opts)
		"brood_egg":
			_egg(ci, c, r, opts)
		"brood_chick":
			_chick(ci, c, r, opts)
		"pinata_titan":
			_pinata(ci, c, r, opts)
		"totem_of_nine":
			_totem(ci, c, r, opts)
		"prism_wyrm":
			_wyrm_head(ci, c, r, opts)
		"wyrm_scale":
			_wyrm_scale(ci, c, r, opts)
		"the_glitch":
			_glitch(ci, c, r, opts)
		_:
			Dot.circle(ci, c, r, IRON)
	if flinch > 0.05 and id != "wyrm_scale":
		Dot.arc(ci, c, r * 1.02, 0.0, TAU, 40, Color(1, 1, 1, 0.55 * flinch), maxf(2.0, r * 0.06), true)


## A slowly turning rune circle on the floor under a boss.
static func _sigil(ci: CanvasItem, c: Vector2, r: float, t: float, col: Color, power := 0.0) -> void:
	var a0 := 0.16 + 0.2 * power
	Dot.arc(ci, c, r * 1.2, 0.0, TAU, 48, Color(col, a0), maxf(2.0, r * 0.025), true)
	for k in 12:
		var a := t * 0.35 + k * TAU / 12.0
		Dot.arc(ci, c, r * 1.3, a, a + 0.18, 2, Color(col, 0.3 + 0.4 * power), maxf(2.0, r * 0.04), true)
	for k in 3:
		var a := -t * 0.8 + k * TAU / 3.0
		Dot.circle(ci, c + Vector2.from_angle(a) * r * 1.2, r * (0.04 + 0.02 * power), Color(col, 0.75))


## A closed outline round a polygon.
static func _rim(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	Dot.pline(ci, loop, col, w, true)


## The same pseudo-random number for the same k: shard directions and the
## like, so a burst looks the same every frame.
static func _hash(k: float) -> float:
	var v := sin(k * 12.9898) * 43758.5453
	return v - floorf(v)


static func _anvil_king(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var quake: float = o.get("quake", 0.0)
	var swing: float = o.get("swing", 0.0)
	var heat: float = 0.55 + 0.25 * sin(t * 3.0) + 0.45 * quake
	_sigil(ci, c, r, t, HOT, quake)
	# Heat on the floor under it, swelling as a quake winds up.
	Dot.circle(ci, c, r * (1.05 + 0.2 * quake), Color(HOT, 0.10 + 0.1 * heat))
	c += Vector2(sin(t * 60.0), cos(t * 47.0)) * r * 0.03 * quake
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.1), r * 0.92, Color(0, 0, 0, 0.35))
	c.y -= r * 0.1 * quake # It rears up before it stamps.
	# Base, waist and the wide anvil top with its horn.
	var base := PackedVector2Array([c + Vector2(-0.62, 0.78) * r, c + Vector2(0.62, 0.78) * r, c + Vector2(0.46, 0.48) * r, c + Vector2(-0.46, 0.48) * r])
	var waist := PackedVector2Array([c + Vector2(-0.34, 0.5) * r, c + Vector2(0.34, 0.5) * r, c + Vector2(0.26, -0.08) * r, c + Vector2(-0.26, -0.08) * r])
	var top := PackedVector2Array([c + Vector2(-0.95, -0.2) * r, c + Vector2(-0.6, -0.1) * r, c + Vector2(0.72, -0.1) * r, c + Vector2(0.78, -0.48) * r,
		c + Vector2(-0.42, -0.48) * r, c + Vector2(-0.62, -0.36) * r])
	var body := IRON.lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.6)).lerp(HOT, 0.25 * quake)
	var edge := maxf(2.0, r * 0.03)
	Dot.poly(ci, base, body)
	Dot.poly(ci, waist, body.darkened(0.2))
	Dot.poly(ci, top, body)
	_rim(ci, base, IRON_HI, edge)
	_rim(ci, top, IRON_HI, edge)
	Dot.pline(ci, PackedVector2Array([c + Vector2(-0.42, -0.48) * r, c + Vector2(0.78, -0.48) * r]), STEEL, maxf(2.0, r * 0.05), true)
	for k in 4: # Rivets on the base.
		Dot.circle(ci, c + Vector2(-0.42 + k * 0.28, 0.64) * r, r * 0.035, IRON_HI.lightened(0.2))
	# Cracks glowing with the forge inside: more of them, brighter, as it's hurt.
	var hurt := 1.0 - clampf(o.get("hp_frac", 1.0), 0.0, 1.0)
	var crack := Color(MOLTEN.lerp(HOT, 0.4), clampf(0.35 + hurt + 0.2 * sin(t * 5.0), 0.0, 1.0))
	var cw := maxf(1.5, r * 0.035)
	Dot.pline(ci, PackedVector2Array([c + Vector2(-0.1, -0.44) * r, c + Vector2(0.02, -0.3) * r, c + Vector2(-0.06, -0.16) * r]), crack, cw, true)
	if hurt > 0.3:
		Dot.pline(ci, PackedVector2Array([c + Vector2(0.38, -0.12) * r, c + Vector2(0.3, 0.1) * r, c + Vector2(0.4, 0.4) * r]), crack, cw, true)
	if hurt > 0.6:
		Dot.pline(ci, PackedVector2Array([c + Vector2(-0.5, 0.74) * r, c + Vector2(-0.36, 0.6) * r, c + Vector2(-0.4, 0.5) * r]), crack, cw, true)
		Dot.pline(ci, PackedVector2Array([c + Vector2(-0.7, -0.22) * r, c + Vector2(-0.5, -0.3) * r]), crack, cw, true)
	# A drip of molten metal sliding off the horn.
	var drip := fmod(t * 0.7, 1.0)
	Dot.circle(ci, c + Vector2(-0.9, -0.18 + drip * 0.5) * r, r * 0.04 * (1.0 - drip * 0.5), Color(MOLTEN, 1.0 - drip))
	# Eyes: slots of molten light under a heavy brow, wide open as it winds up.
	var stunned: bool = o.get("stunned", false)
	var eye := Color(MOLTEN, 0.35) if stunned else Color(MOLTEN, clampf(heat, 0.0, 1.0))
	var eh := (0.03 if stunned else 0.06 + 0.05 * quake) * r
	for x in [-0.22, 0.18]:
		var e: Vector2 = c + Vector2(x, -0.3) * r
		if heat > 0.7 and not stunned:
			Dot.circle(ci, e, r * 0.12, Color(MOLTEN, 0.25))
		Dot.poly(ci, PackedVector2Array([e + Vector2(-r * 0.1, -eh), e + Vector2(r * 0.1, -eh * 0.4), e + Vector2(r * 0.1, eh), e + Vector2(-r * 0.1, eh)]), eye)
	Dot.pline(ci, PackedVector2Array([c + Vector2(-0.36, -0.42) * r, c + Vector2(-0.04, -0.36) * r, c + Vector2(0.32, -0.42) * r]), IRON.darkened(0.4), maxf(2.0, r * 0.05), true)
	# Crown of three flickering flames.
	for k in 3:
		var fx := -0.24 + k * 0.24
		var h := (0.2 + 0.08 * sin(t * 9.0 + k * 2.1) + 0.12 * quake) * (1.3 if k == 1 else 1.0)
		var root := c + Vector2(fx, -0.52) * r
		Dot.poly(ci, PackedVector2Array([root + Vector2(-0.08, 0) * r, root + Vector2(0.02 * sin(t * 7.0 + k), -h) * r, root + Vector2(0.08, 0) * r]), HOT)
		Dot.poly(ci, PackedVector2Array([root + Vector2(-0.04, 0) * r, root + Vector2(0.01 * sin(t * 7.0 + k), -h * 0.6) * r, root + Vector2(0.04, 0) * r]), MOLTEN)
	# Embers drifting up off it.
	for k in 5:
		var ph := fmod(t * 0.5 + k * 0.21, 1.0)
		var p := c + Vector2((k - 2) * 0.24 + 0.05 * sin(t * 3.0 + k), -0.5 - ph * 0.9) * r
		Dot.circle(ci, p, r * 0.03 * (1.0 - ph) + 1.0, Color(MOLTEN.lerp(HOT, ph), 1.0 - ph))
	# Its hammer arm: raised while a slam is in the air, resting otherwise.
	var ang := lerpf(0.9, -1.9, minf(1.0, swing * 3.0)) if swing > 0.0 else 0.9 + 0.08 * sin(t * 2.0)
	var shoulder := c + Vector2(0.7, -0.24) * r
	if swing > 0.0: # The swing's smear.
		Dot.arc(ci, shoulder, r * 0.62, ang, 0.9, 12, Color(HOT, 0.35), maxf(3.0, r * 0.18), true)
	var dir := Vector2.from_angle(ang)
	var head := shoulder + dir * r * 0.62
	Dot.pline(ci, PackedVector2Array([shoulder, head]), Color("b07a45"), maxf(3.0, r * 0.08), true)
	var side := dir.orthogonal()
	var hpts := PackedVector2Array([head + side * r * 0.22 - dir * r * 0.12, head + side * r * 0.22 + dir * r * 0.12,
		head - side * r * 0.22 + dir * r * 0.12, head - side * r * 0.22 - dir * r * 0.12])
	Dot.poly(ci, hpts, STEEL)
	_rim(ci, hpts, Color.WHITE.lerp(STEEL, 0.5), maxf(1.5, r * 0.02))
	Dot.circle(ci, head - side * r * 0.22, r * (0.07 + 0.04 * swing), HOT if swing <= 0.0 else MOLTEN)


## opts.face: the way she's gliding (unit vector); opts.charge: 0-1 as her
## next feather volley comes (wings sweep back and glow).
static func _brood_queen(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var face: Vector2 = o.get("face", Vector2.RIGHT)
	var charge: float = o.get("charge", 0.0)
	var flap := sin(t * 7.0) * 0.12 * (1.0 - charge) - 0.25 * charge
	var body := HEN.lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.6))
	_sigil(ci, c, r, t, HEN, charge)
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.12), r * 0.95, Color(0, 0, 0, 0.3))
	if charge > 0.05:
		Dot.circle(ci, c, r * (1.25 + 0.15 * charge), Color(HEN_HI, 0.2 * charge))
	var side := face.orthogonal()
	# Tail fan behind, five feathers swaying.
	for k in 5:
		var a := (k - 2) * 0.32 + 0.08 * sin(t * 3.0 + k)
		var d := (-face).rotated(a)
		var root := c - face * r * 0.55
		var tip := root + d * r * (0.75 + (0.15 if k == 2 else 0.0))
		var sd := d.orthogonal()
		var col := Color("8f7bff") if k % 2 == 0 else Color("5ce1ff")
		Dot.poly(ci, PackedVector2Array([root + sd * r * 0.1, tip, root - sd * r * 0.1]), col)
		Dot.circle(ci, tip - d * r * 0.08, r * 0.07, Color.WHITE.lerp(col, 0.4))
	# Wings out to the sides: three layered feathers each, flapping.
	for k in [-1.0, 1.0]:
		var root: Vector2 = c + side * k * r * 0.55
		for f in 3:
			var reach: float = 1.35 + flap - f * 0.18
			var tip: Vector2 = c + side * k * r * reach - face * r * (0.2 + f * 0.22)
			var shade := body.darkened(0.12 + f * 0.08)
			Dot.poly(ci, PackedVector2Array([root + face * r * (0.3 - f * 0.12), tip, root - face * r * (0.35 + f * 0.1)]), shade.lerp(HEN_HI, 0.5 * charge))
		Dot.pline(ci, PackedVector2Array([root + face * r * 0.3, c + side * k * r * (1.35 + flap) - face * r * 0.2]), Color(HEN_HI, 0.7), maxf(1.5, r * 0.025), true)
	Dot.circle(ci, c, r * 0.82, body)
	Dot.circle(ci, c - face * r * 0.15 - side * r * 0.2, r * 0.4, Color(HEN_HI, 0.5))
	for k in 3: # Scalloped chest feathers.
		Dot.arc(ci, c + face * r * 0.1 + side * (k - 1) * r * 0.22, r * 0.14, face.angle() - 1.2, face.angle() + 1.2, 8, Color(HEN_HI, 0.8), maxf(1.5, r * 0.025), true)
	# A golden tiara behind the comb.
	var crown := c + face * r * 0.2 + Vector2(0, -r * 0.62)
	for k in 3:
		var x := (k - 1) * 0.16
		Dot.poly(ci, PackedVector2Array([crown + Vector2(x - 0.07, 0.05) * r, crown + Vector2(x, -0.22 - (0.06 if k == 1 else 0.0)) * r, crown + Vector2(x + 0.07, 0.05) * r]), BEAK)
		Dot.circle(ci, crown + Vector2(x, -0.02) * r, r * 0.04, Color("5ce1ff") if k == 1 else COMB)
	for k in 3:
		Dot.circle(ci, c + face * r * (0.25 + k * 0.12) + Vector2(0, -r * (0.7 - k * 0.04)), r * 0.12, COMB)
	# Beak: opens as a volley comes.
	var gape := r * (0.02 + 0.14 * charge)
	var tipb := c + face * r * 1.1
	Dot.poly(ci, PackedVector2Array([c + face * r * 0.7 + side * r * 0.15, tipb + side * gape, c + face * r * 0.7]), BEAK)
	Dot.poly(ci, PackedVector2Array([c + face * r * 0.7, tipb - side * gape, c + face * r * 0.7 - side * r * 0.15]), BEAK.darkened(0.15))
	var stunned: bool = o.get("stunned", false)
	for k in [-1.0, 1.0]:
		var e: Vector2 = c + face * r * 0.45 + side * k * r * 0.28
		Dot.circle(ci, e, r * 0.1, Color(1, 1, 1, 0.6) if stunned else INK)
		if not stunned:
			Dot.circle(ci, e - Vector2(r * 0.03, r * 0.03), r * 0.035, Color.WHITE)


## opts.hatch: 0-1 toward hatching (it wobbles more), hp_frac (cracks).
static func _egg(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var h: float = o.get("hatch", 0.0)
	var tilt := sin(t * (6.0 + h * 14.0)) * (0.05 + 0.25 * h * h)
	var pts := PackedVector2Array()
	for k in 16:
		var a := k * TAU / 16.0
		var v := Vector2(cos(a) * 0.82, sin(a) * (1.05 if sin(a) < 0.0 else 0.92)).rotated(tilt)
		pts.append(c + v * r)
	Dot.circle(ci, c + Vector2(r * 0.08, r * 0.15), r * 0.85, Color(0, 0, 0, 0.3))
	if h > 0.6:
		Dot.circle(ci, c, r * 1.15, Color(BEAK, 0.25 * (h - 0.6) / 0.4 * (0.6 + 0.4 * sin(t * 12.0))))
	Dot.poly(ci, pts, SHELL.lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.6)))
	for k in 3:
		Dot.circle(ci, c + Vector2(-0.3 + k * 0.3, -0.2 + 0.25 * (k % 2)).rotated(tilt) * r, r * 0.12, Color(HEN, 0.7))
	var hurt := 1.0 - clampf(o.get("hp_frac", 1.0), 0.0, 1.0)
	if hurt > 0.1 or h > 0.7:
		Dot.pline(ci, PackedVector2Array([c + Vector2(-0.5, 0.0) * r, c + Vector2(-0.2, -0.15) * r, c + Vector2(0.05, 0.05) * r, c + Vector2(0.4, -0.1) * r]), Color("6b4a2a"), maxf(1.5, r * 0.07), true)


static func _chick(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var face: Vector2 = o.get("face", Vector2.RIGHT)
	var side := face.orthogonal()
	Dot.circle(ci, c + Vector2(r * 0.08, r * 0.15), r * 0.95, Color(0, 0, 0, 0.3))
	for k in [-1.0, 1.0]: # Stubby wings, flapping fast.
		var tip: Vector2 = c + side * k * r * (1.15 + 0.12 * sin(t * 20.0)) - face * r * 0.2
		Dot.poly(ci, PackedVector2Array([c + side * k * r * 0.6 + face * r * 0.2, tip, c + side * k * r * 0.6 - face * r * 0.35]), Color("ffd23f"))
	Dot.circle(ci, c, r, Color("ffe066").lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.6)))
	Dot.circle(ci, c - face * r * 0.2 + Vector2(-0.2, -0.3) * r, r * 0.35, Color("fff4b0"))
	Dot.poly(ci, PackedVector2Array([c + face * r * 0.75 + side * r * 0.2, c + face * r * 1.25, c + face * r * 0.75 - side * r * 0.2]), Color("ff8a3d"))
	Dot.circle(ci, c + face * r * 0.35 + side * r * 0.35, r * 0.13, INK)
	Dot.circle(ci, c + face * r * 0.35 - side * r * 0.35, r * 0.13, INK)


## A star piñata on a rope: frilled body, five two-tone cones with
## streamers. opts.pivot: where the rope goes up to (relative to c);
## hp_frac splits it open; a hit gives it an "ouch" face and a spin.
static func _pinata(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var hit: float = o.get("hit", 0.0)
	var pivot: Vector2 = o.get("pivot", Vector2(0, -r * 1.6))
	_sigil(ci, c, r, t, Color("ffb627"))
	Dot.pline(ci, PackedVector2Array([c + pivot, c + pivot * 0.04]), Color("e8d5b5"), maxf(2.0, r * 0.04), true)
	Dot.circle(ci, c + pivot * 0.04, r * 0.06, Color("c9a77a"))
	var spin := sin(t * 1.3) * 0.15 + hit * 0.6 * sin(t * 40.0)
	# Confetti twinkles round it.
	for k in 5:
		var a := t * 0.6 + k * TAU / 5.0
		var tw := 0.5 + 0.5 * sin(t * 5.0 + k * 1.9)
		var p := c + Vector2.from_angle(a) * r * 1.25
		Dot.poly(ci, PackedVector2Array([p + Vector2(0, -r * 0.07 * tw), p + Vector2(r * 0.025, 0), p + Vector2(0, r * 0.07 * tw), p + Vector2(-r * 0.025, 0)]), Color(PINATA[k], 0.85))
	for k in 5:
		var a := -PI / 2.0 + spin + k * TAU / 5.0
		var d := Vector2.from_angle(a)
		var sd := d.orthogonal()
		var tip := c + d * r * 1.05
		var col: Color = PINATA[k]
		Dot.poly(ci, PackedVector2Array([c + d * r * 0.45 + sd * r * 0.27, tip, c + d * r * 0.45 - sd * r * 0.27]), col)
		Dot.poly(ci, PackedVector2Array([c + d * r * 0.6 + sd * r * 0.1, tip - d * r * 0.08, c + d * r * 0.6 - sd * r * 0.1]), col.lightened(0.35))
		for s in 3: # Paper streamers off each tip.
			var wig := sin(t * 6.0 + k + s * 1.3) * 0.25
			var end := tip + d.rotated((s - 1) * 0.45 + wig) * r * 0.32
			Dot.pline(ci, PackedVector2Array([tip, end]), PINATA[(k + s + 1) % 5], maxf(1.5, r * 0.035), true)
	var body := Color("ffb627").lerp(Color.WHITE, clampf(hit * 2.0, 0.0, 0.6))
	for k in 14: # Paper frills round the body.
		var a := spin + k * TAU / 14.0
		var p := c + Vector2.from_angle(a) * r * 0.6
		var sd := Vector2.from_angle(a).orthogonal()
		Dot.poly(ci, PackedVector2Array([p + sd * r * 0.1, p + Vector2.from_angle(a) * r * 0.1, p - sd * r * 0.1]), PINATA[k % 5])
	Dot.circle(ci, c, r * 0.58, body)
	for k in 3: # Paper stripes.
		Dot.pline(ci, PackedVector2Array([c + Vector2(-r * 0.5, (k - 0.6) * r * 0.24), c + Vector2(r * 0.5, (k - 0.6) * r * 0.24)]), PINATA[(k * 2) % 5], maxf(2.0, r * 0.08), true)
	var hurt := 1.0 - clampf(o.get("hp_frac", 1.0), 0.0, 1.0)
	if hurt > 0.3: # Coins and candy peek out of a split.
		Dot.pline(ci, PackedVector2Array([c + Vector2(-0.3, 0.22) * r, c + Vector2(-0.05, 0.36) * r, c + Vector2(0.15, 0.24) * r, c + Vector2(0.35, 0.38) * r]), Color("3a1d0a"), maxf(2.0, r * 0.06), true)
		Dot.circle(ci, c + Vector2(0.0, 0.32) * r, r * 0.07 * (1.0 + hurt), MOLTEN)
		if hurt > 0.6:
			var fall := fmod(t * 1.4, 1.0)
			Dot.circle(ci, c + Vector2(0.12, 0.4 + fall * 0.5) * r, r * 0.05, Color(PINATA[0], 1.0 - fall))
	var stunned: bool = o.get("stunned", false)
	if hit > 0.12 or stunned: # Ouch: squeezed-shut eyes and an O mouth.
		for x in [-0.18, 0.18]:
			var e: Vector2 = c + Vector2(x, -0.22) * r
			Dot.pline(ci, PackedVector2Array([e + Vector2(-0.07, -0.05) * r, e + Vector2(0.03, 0) * r, e + Vector2(-0.07, 0.05) * r]) if x < 0.0 else PackedVector2Array([e + Vector2(0.07, -0.05) * r, e + Vector2(-0.03, 0) * r, e + Vector2(0.07, 0.05) * r]), INK, maxf(1.5, r * 0.04), true)
		Dot.circle(ci, c + Vector2(0, -0.02) * r, r * 0.08, INK)
	else:
		for x in [-0.18, 0.18]:
			var e: Vector2 = c + Vector2(x, -0.22) * r
			Dot.circle(ci, e, r * 0.075, INK)
			Dot.circle(ci, e + Vector2(-0.025, -0.025) * r, r * 0.028, Color.WHITE)
		Dot.pline(ci, PackedVector2Array([c + Vector2(-0.16, -0.06) * r, c + Vector2(0, 0.04) * r, c + Vector2(0.16, -0.06) * r]), INK, maxf(1.5, r * 0.04), true)
		Dot.circle(ci, c + Vector2(-0.3, -0.06) * r, r * 0.06, Color(PINATA[0], 0.6))
		Dot.circle(ci, c + Vector2(0.3, -0.06) * r, r * 0.06, Color(PINATA[0], 0.6))


## The totem from above: a carved stone drum with nine family icons round
## its rim. opts.family lights that family's mask; opts.volley (0-1) makes
## every mask blaze and beams run to them as a volley winds up.
static func _totem(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var lit: String = o.get("family", "")
	var charge: float = o.get("volley", 0.0)
	var fam_col: Color = TALENTS.COLORS.get(lit, Color("e9e4ff"))
	_sigil(ci, c, r, t, fam_col, charge)
	var stone := Color("4a4560").lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.5))
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.1), r * 0.95, Color(0, 0, 0, 0.35))
	Dot.circle(ci, c, r * 0.92, stone.darkened(0.25))
	Dot.arc(ci, c, r * 0.92, 0.0, TAU, 48, stone.lightened(0.15), maxf(2.0, r * 0.03), true)
	Dot.circle(ci, c, r * 0.72, stone)
	var fams: Array = TALENTS.FACTIONS
	var spin := t * 0.15
	for k in fams.size(): # Carved notches between the masks.
		var a := -PI / 2.0 + (k + 0.5) * TAU / fams.size() + spin
		var d := Vector2.from_angle(a)
		Dot.pline(ci, PackedVector2Array([c + d * r * 0.62, c + d * r * 0.9]), stone.darkened(0.45), maxf(1.5, r * 0.025), true)
	for k in fams.size():
		var a := -PI / 2.0 + k * TAU / fams.size() + spin
		var d := Vector2.from_angle(a)
		var p := c + d * r * 0.76
		var col: Color = TALENTS.COLORS[fams[k]]
		var on: bool = fams[k] == lit
		var glow := clampf(charge + (0.6 + 0.3 * sin(t * 4.0) if on else 0.0), 0.0, 1.0)
		if charge > 0.05: # Spirit beams from the core out to every mask.
			Dot.pline(ci, PackedVector2Array([c + d * r * 0.3, p]), Color(col, 0.5 * charge), maxf(2.0, r * 0.05 * charge), true)
		if glow > 0.05:
			Dot.circle(ci, p, r * 0.27, Color(col, 0.35 * glow))
		FamilyIcon.draw(ci, fams[k], p, r * 0.36) # Each mask is its family's icon.
	# Spirit wisps circling the lit family's mask colour.
	for k in 3:
		var a := t * (1.1 + 0.2 * k) + k * TAU / 3.0
		for tail in 3:
			var q := c + Vector2.from_angle(a - tail * 0.12) * r * (1.08 + 0.05 * sin(t * 3.0 + k))
			Dot.circle(ci, q, r * (0.06 - tail * 0.015), Color(fam_col, 0.8 - tail * 0.25))
	# The top of the pole: a moon-white cap carved with a spiral, dimmed by a stun.
	var cap := Color("e9e4ff") if not o.get("stunned", false) else Color("8a86a0")
	Dot.circle(ci, c, r * 0.38, cap.darkened(0.2))
	Dot.circle(ci, c, r * 0.28, cap.lerp(fam_col, 0.3 * charge))
	Dot.arc(ci, c, r * 0.18, -t, -t + PI * 1.4, 12, cap.darkened(0.35), maxf(1.5, r * 0.03), true)
	if lit != "":
		Dot.circle(ci, c, r * (0.1 + 0.05 * charge), fam_col)
	if charge > 0.05:
		Dot.arc(ci, c, r * (0.95 + 0.4 * charge), 0.0, TAU, 40, Color(fam_col, 0.5 * charge), maxf(2.0, r * 0.04), true)


## The Prism Wyrm's head: a cut-crystal wedge facing opts.face, with a
## light sweeping over its facets. opts.lit: its weak spot is on the head;
## opts.charge: 0-1 as its tail lash winds up (the jaw gapes, eyes flare).
static func _wyrm_head(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var face: Vector2 = o.get("face", Vector2.RIGHT)
	var side := face.orthogonal()
	var lit: bool = o.get("lit", true)
	var charge: float = o.get("charge", 0.0)
	var base := Color("2a6f9e").lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.6))
	if lit: # A prism halo: three rainbow arcs turning round it.
		Dot.circle(ci, c, r * 1.25, Color(PRISM, 0.16 + 0.08 * sin(t * 6.0)))
		for k in 3:
			var a := t * 1.5 + k * TAU / 3.0
			Dot.arc(ci, c, r * 1.4, a, a + 1.2, 10, Color.from_hsv(fmod(t * 0.2 + k / 3.0, 1.0), 0.6, 1.0, 0.7), maxf(2.0, r * 0.06), true)
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.1), r * 0.95, Color(0, 0, 0, 0.3))
	# Crest spines down its back.
	for k in 3:
		var root := c - face * r * (0.35 + k * 0.22)
		Dot.poly(ci, PackedVector2Array([root + face * r * 0.1, root - face * r * 0.12 + side * r * 0.02 * sin(t * 4.0 + k) + Vector2(0, -r * 0.3), root - face * r * 0.12]), AMETHYST.lightened(0.15 * k))
	# The jaw splits open as the lash comes.
	var gape := 0.18 * charge
	var upper := PackedVector2Array([c + face.rotated(-gape) * r * 1.15, c + face * r * 0.2 + side * r * 0.85, c - face * r * 0.8 + side * r * 0.55, c - face * r * 0.2])
	var lower := PackedVector2Array([c + face.rotated(gape) * r * 1.15, c - face * r * 0.2, c - face * r * 0.8 - side * r * 0.55, c + face * r * 0.2 - side * r * 0.85])
	if charge > 0.05:
		Dot.circle(ci, c + face * r * 0.7, r * 0.3 * charge, Color(PRISM, 0.8))
	Dot.poly(ci, upper, base.lightened(0.15))
	Dot.poly(ci, lower, base.darkened(0.15))
	Dot.poly(ci, PackedVector2Array([c + face.rotated(-gape) * r * 1.15, c + face * r * 0.2 + side * r * 0.85, c + face * r * 0.1]), base.lightened(0.35))
	_rim(ci, upper, Color(PRISM, 0.6), maxf(1.5, r * 0.025))
	_rim(ci, lower, Color(PRISM, 0.45), maxf(1.5, r * 0.025))
	# A glint sweeping across the facets.
	var sweep := fmod(t * 0.6, 1.4) - 0.2
	if sweep > 0.0 and sweep < 1.0:
		var g := c + face * r * lerpf(-0.7, 1.0, sweep)
		Dot.pline(ci, PackedVector2Array([g + side * r * 0.5 - face * r * 0.15, g - side * r * 0.5 + face * r * 0.15]), Color(1, 1, 1, 0.5), maxf(2.0, r * 0.05), true)
	# Horns and slit eyes, flaring as it winds up.
	var stunned: bool = o.get("stunned", false)
	for k in [-1.0, 1.0]:
		var root: Vector2 = c - face * r * 0.4 + side * k * r * 0.5
		Dot.poly(ci, PackedVector2Array([root + side * k * r * 0.12, root - face * r * 0.75 + side * k * r * 0.4, root - side * k * r * 0.12]), AMETHYST)
		var e: Vector2 = c + face * r * 0.35 + side * k * r * 0.32
		if stunned:
			Dot.circle(ci, e, r * 0.1, Color(1, 1, 1, 0.5))
			continue
		Dot.circle(ci, e, r * (0.13 + 0.08 * charge), Color(PRISM, 0.3 + 0.4 * charge))
		Dot.circle(ci, e, r * 0.1, PRISM.lerp(Color.WHITE, 0.5 * charge))
		Dot.pline(ci, PackedVector2Array([e - face * r * 0.07, e + face * r * 0.07]), INK, maxf(1.5, r * 0.035), true)


## One body scale: a cut hexagonal crystal. While lit (the only part that
## takes damage) it blazes with a rainbow rim; otherwise it's dull armour
## with a slow sheen.
static func _wyrm_scale(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var lit: bool = o.get("lit", false)
	var turn := t * (0.6 if lit else 0.15)
	var pts := PackedVector2Array()
	var inner := PackedVector2Array()
	for k in 6:
		var a := k * TAU / 6.0 + PI / 6.0 + turn
		pts.append(c + Vector2.from_angle(a) * r * 0.95)
		inner.append(c + Vector2.from_angle(a + PI / 6.0) * r * 0.5)
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.1), r * 0.9, Color(0, 0, 0, 0.3))
	if lit:
		Dot.circle(ci, c, r * 1.35, Color(PRISM, 0.22 + 0.12 * sin(t * 8.0)))
	var col := (PRISM if lit else Color("2f4f6e")).lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.5))
	Dot.poly(ci, pts, col)
	for k in 3: # Facet lines.
		Dot.pline(ci, PackedVector2Array([pts[k], pts[k + 3]]), col.darkened(0.25), maxf(1.0, r * 0.03), true)
	Dot.poly(ci, inner, col.lightened(0.3) if lit else col.lightened(0.12))
	if lit:
		_rim(ci, pts, Color.from_hsv(fmod(t * 0.5, 1.0), 0.55, 1.0), maxf(2.0, r * 0.07))
		var tw := 0.5 + 0.5 * sin(t * 9.0)
		var sp := c + Vector2(-0.3, -0.35) * r
		Dot.poly(ci, PackedVector2Array([sp + Vector2(0, -r * 0.2 * tw), sp + Vector2(r * 0.05, 0), sp + Vector2(0, r * 0.2 * tw), sp + Vector2(-r * 0.05, 0)]), Color.WHITE)
	else:
		_rim(ci, pts, Color("4f7fa8", 0.6 + 0.3 * sin(t * 1.5 + c.x * 0.01)), maxf(1.5, r * 0.04))


## The Glitch: a corrupted cube that never sits still, its slices torn
## sideways in green and magenta, with colour-split ghosts, a scanline and
## orbiting dead pixels. opts.phase tints it (Static green, Warp magenta,
## Pull white); opts.charge dissolves it as a warp or pulse winds up;
## opts.look aims its eye.
static func _glitch(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var phase: String = o.get("phase", "static")
	var charge: float = o.get("charge", 0.0)
	var main: Color = {"static": CODE, "warp": ERROR, "pull": Color("e9e4ff")}.get(phase, CODE)
	main = main.lerp(Color.WHITE, clampf(float(o.get("hit", 0.0)) * 2.0, 0.0, 0.5))
	var alt := ERROR if phase != "warp" else CODE
	_sigil(ci, c, r, floorf(t * 8.0) / 8.0, main, charge)
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.1), r * 0.9, Color(0, 0, 0, 0.35))
	if phase == "pull":
		for k in 3:
			Dot.arc(ci, c, r * (1.6 - fmod(t * (1.2 + 2.0 * charge) + k * 0.33, 1.0) * 0.8), 0.0, TAU, 32, Color(main, 0.25 + 0.3 * charge), 3.0, true)
	elif phase == "static": # Crackling arcs round it.
		var beat := floorf(t * 10.0)
		for k in 3:
			if _hash(beat + k * 7.0) < 0.5:
				continue
			var a := _hash(beat * 3.0 + k) * TAU
			var p0 := c + Vector2.from_angle(a) * r * 0.8
			var p1 := c + Vector2.from_angle(a + 0.25) * r * 1.25
			var mid := (p0 + p1) / 2.0 + Vector2.from_angle(a + PI / 2.0) * r * 0.12
			Dot.pline(ci, PackedVector2Array([p0, mid, p1]), Color(CODE, 0.8), maxf(1.5, r * 0.03), true)
	# Dead pixels orbiting, jumping a step at a time.
	var step := floorf(t * 6.0) / 6.0
	for k in 8:
		var a := step * 0.9 + k * TAU / 8.0
		var p := c + Vector2.from_angle(a) * r * (1.15 + 0.1 * _hash(k + floorf(t * 3.0)))
		var half := r * 0.05
		Dot.poly(ci, PackedVector2Array([p + Vector2(-half, -half), p + Vector2(half, -half), p + Vector2(half, half), p + Vector2(-half, half)]), Color(main if k % 2 == 0 else alt, 0.8))
	var h := r * 0.72
	var spread := 1.0 + 0.6 * charge # A wind-up pulls its slices apart.
	for pass_i in 3: # Two colour-split ghosts, then the cube itself.
		var off := Vector2.ZERO
		var tint := main
		var a := 0.92
		if pass_i == 0:
			off = Vector2(-r * 0.07, 0)
			tint = Color("4fe8ff")
			a = 0.35
		elif pass_i == 1:
			off = Vector2(r * 0.07, 0)
			tint = ERROR
			a = 0.35
		for k in 6: # Six slices, each jittered sideways on its own beat.
			var y := (-h + k * h * 2.0 / 6.0) * spread
			var jit := r * 0.12 * sin(t * (17.0 + k * 5.0) + k * 1.7) * (1.0 if fmod(t * 3.0 + k * 0.4, 1.0) < 0.3 else 0.15)
			var col := tint if pass_i < 2 else (main if k % 2 == 0 else alt)
			var q := c + off + Vector2(jit, 0)
			Dot.poly(ci, PackedVector2Array([q + Vector2(-h, y), q + Vector2(h, y), q + Vector2(h, y + h / 3.0 + 1.0), q + Vector2(-h, y + h / 3.0 + 1.0)]), Color(col, a * (1.0 - 0.4 * charge)))
	# A scanline rolling down it.
	var sy := c.y - h + fmod(t * 0.8, 1.0) * h * 2.0
	Dot.pline(ci, PackedVector2Array([Vector2(c.x - h * 1.1, sy), Vector2(c.x + h * 1.1, sy)]), Color(1, 1, 1, 0.45), maxf(2.0, r * 0.03), true)
	# One big eye, a pixel square that blinks and tracks you; a "!" as it winds up.
	var blink: bool = fmod(t * 0.7, 1.0) < 0.06 or o.get("stunned", false)
	var look: Vector2 = o.get("look", Vector2.ZERO)
	Dot.poly(ci, PackedVector2Array([c + Vector2(-0.24, -0.18) * r, c + Vector2(0.24, -0.18) * r, c + Vector2(0.24, (0.0 if blink else 0.22)) * r, c + Vector2(-0.24, (0.0 if blink else 0.22)) * r]), Color("040a06"))
	if blink:
		return
	if charge > 0.3:
		Dot.poly(ci, PackedVector2Array([c + Vector2(-0.04, -0.14) * r, c + Vector2(0.04, -0.14) * r, c + Vector2(0.04, 0.06) * r, c + Vector2(-0.04, 0.06) * r]), ERROR)
		Dot.poly(ci, PackedVector2Array([c + Vector2(-0.04, 0.1) * r, c + Vector2(0.04, 0.1) * r, c + Vector2(0.04, 0.18) * r, c + Vector2(-0.04, 0.18) * r]), ERROR)
		return
	var pc := c + Vector2(0.0, 0.02) * r + look * r * 0.1
	Dot.poly(ci, PackedVector2Array([pc + Vector2(-0.07, -0.08) * r, pc + Vector2(0.07, -0.08) * r, pc + Vector2(0.07, 0.08) * r, pc + Vector2(-0.07, 0.08) * r]), main)


## The boss bursting apart when it's beaten, `age` seconds in (up to
## DEATH_LIFE): a white core flash, a shockwave and shards spinning out in
## its colours. Piñatas burst into candy, The Glitch into pixels.
static func draw_death(ci: CanvasItem, id: String, c: Vector2, r: float, age: float) -> void:
	var k := clampf(age / DEATH_LIFE, 0.0, 1.0)
	var cols: Array = DEATH_COLORS.get(id, [Color.WHITE])
	var fade := 1.0 - k
	if age < 0.35:
		Dot.circle(ci, c, r * (0.9 + age * 2.0), Color(1, 1, 1, 0.9 * (1.0 - age / 0.35)))
	Dot.arc(ci, c, r * (0.8 + k * 3.2), 0.0, TAU, 48, Color(cols[0], 0.7 * fade), maxf(2.0, r * 0.12 * fade), true)
	Dot.arc(ci, c, r * (0.5 + k * 2.2), 0.0, TAU, 40, Color(cols[1 % cols.size()], 0.5 * fade), maxf(2.0, r * 0.06 * fade), true)
	var n := 16
	for i in n:
		var a := i * TAU / n + _hash(i + 1.0) * 0.4
		var speed := 1.6 + 1.8 * _hash(i + 17.0)
		var dist := r * (0.3 + speed * (1.0 - (1.0 - k) * (1.0 - k)))
		var p := c + Vector2.from_angle(a) * dist + Vector2(0, r * 0.6 * k * k) # A little gravity.
		var size := r * (0.2 + 0.16 * _hash(i + 31.0)) * (1.0 - 0.5 * k)
		if size < 1.0:
			continue
		var col := Color(cols[i % cols.size()], fade)
		match id:
			"pinata_titan":
				Dot.circle(ci, p, size * 0.8, col)
				Dot.circle(ci, p - Vector2(size, size) * 0.25, size * 0.3, Color(1, 1, 1, 0.6 * fade))
			"the_glitch":
				var half := size * 0.6
				Dot.poly(ci, PackedVector2Array([p + Vector2(-half, -half), p + Vector2(half, -half), p + Vector2(half, half), p + Vector2(-half, half)]), col)
			_:
				var spin := a + age * (6.0 + 6.0 * _hash(i + 5.0))
				var d := Vector2.from_angle(spin)
				var sd := d.orthogonal()
				Dot.poly(ci, PackedVector2Array([p + d * size, p + sd * size * 0.45, p - d * size * 0.6, p - sd * size * 0.45]), col)


## A boss in a menu. The web build only draws a frame when something changed,
## and every redraw of a boss rebuilds its polygons, so small icons (cards, the
## Bosses list) are drawn once and stay still. A big hero portrait animates at
## HERO_RATE, a multiple of the critter icons' shared clock so their redraws
## land on the same frames (slower than that reads as lag next to the 60 fps
## fight), and keeps its drawing while hidden, off screen or mid-scroll.
class BossIcon extends Control:
	const TouchInput := preload("res://game/ui/touch_input.gd")
	static var _art: Script ## This file, loaded once (it can't preload itself).
	## Below this side an icon is drawn once and never animates.
	const SMALL_SIDE := 120.0
	## Hero redraws a second: a multiple of CritterIcon.IDLE_RATE.
	const HERO_RATE := 30
	var boss_id := "anvil_king"
	var _tick := -1
	var _clip: Control

	func _ready() -> void:
		if _art == null:
			_art = load("res://game/boss_art.gd")
		set_process(minf(custom_minimum_size.x, custom_minimum_size.y) >= SMALL_SIDE)
		var node := get_parent()
		while node != null and _clip == null:
			if node is ScrollContainer:
				_clip = node
			node = node.get_parent()

	func _process(_delta: float) -> void:
		if not is_visible_in_tree() or TouchInput.scrolling():
			return
		var tick: int = Time.get_ticks_msec() * HERO_RATE / 1000
		if tick == _tick:
			return
		var r := get_global_rect()
		if not r.intersects(get_viewport_rect()) or (is_instance_valid(_clip) and not r.intersects(_clip.get_global_rect())):
			return
		_tick = tick
		queue_redraw()

	func _draw() -> void:
		var s := minf(size.x, size.y)
		_art.draw(self, boss_id, size / 2.0, s * 0.36, {"t": Time.get_ticks_msec() / 1000.0})


static func icon(id: String, side: float) -> Control:
	var b := BossIcon.new()
	b.boss_id = id
	b.custom_minimum_size = Vector2(side, side)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b
