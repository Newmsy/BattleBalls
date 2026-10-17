## How farming bosses look (sim/bosses.gd). Render-only and cheap: a handful
## of polygons per boss, no per-frame allocation beyond the point lists.
## draw() is shared by the arena and BossIcon (menus).
extends RefCounted

const Dot := preload("res://game/dot.gd")

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


## Boss `id` centred on `c` with footprint radius `r`. opts: t (seconds),
## hit (0-1 flash), hp_frac, swing (0-1 while a hammer is in the air),
## stunned (bool), quake (0-1 while a quake winds up).
static func draw(ci: CanvasItem, id: String, c: Vector2, r: float, opts := {}) -> void:
	match id:
		"anvil_king":
			_anvil_king(ci, c, r, opts)
		"brood_queen":
			_brood_queen(ci, c, r, opts)
		"brood_egg":
			_egg(ci, c, r, opts)
		"brood_chick":
			_chick(ci, c, r, opts)
		_:
			Dot.circle(ci, c, r, IRON)


static func _anvil_king(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var quake: float = o.get("quake", 0.0)
	var shake := Vector2(sin(t * 60.0), cos(t * 47.0)) * r * 0.025 * quake
	c += shake
	var glow: float = 0.55 + 0.25 * sin(t * 3.0) + 0.4 * quake
	# Heat on the floor under it.
	Dot.circle(ci, c, r * 1.05, Color(HOT, 0.10 + 0.08 * glow))
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.1), r * 0.92, Color(0, 0, 0, 0.35))
	# Base, waist and the wide anvil top with its horn.
	var base := PackedVector2Array([c + Vector2(-0.62, 0.78) * r, c + Vector2(0.62, 0.78) * r, c + Vector2(0.46, 0.48) * r, c + Vector2(-0.46, 0.48) * r])
	var waist := PackedVector2Array([c + Vector2(-0.34, 0.5) * r, c + Vector2(0.34, 0.5) * r, c + Vector2(0.26, -0.08) * r, c + Vector2(-0.26, -0.08) * r])
	var top := PackedVector2Array([c + Vector2(-0.95, -0.2) * r, c + Vector2(-0.6, -0.1) * r, c + Vector2(0.72, -0.1) * r, c + Vector2(0.78, -0.48) * r,
		c + Vector2(-0.42, -0.48) * r, c + Vector2(-0.62, -0.36) * r])
	var hit: float = o.get("hit", 0.0)
	var body := IRON.lerp(Color.WHITE, clampf(hit * 2.0, 0.0, 0.6))
	Dot.poly(ci, base, body)
	Dot.poly(ci, waist, body.darkened(0.15))
	Dot.poly(ci, top, body)
	Dot.pline(ci, PackedVector2Array([c + Vector2(-0.42, -0.48) * r, c + Vector2(0.78, -0.48) * r]), IRON_HI, maxf(2.0, r * 0.05), true)
	# Cracks glowing with the forge inside: brighter as it takes damage.
	var hurt := 1.0 - clampf(o.get("hp_frac", 1.0), 0.0, 1.0)
	var crack := Color(MOLTEN.lerp(HOT, 0.4), clampf(0.35 + hurt, 0.0, 1.0))
	Dot.pline(ci, PackedVector2Array([c + Vector2(-0.1, -0.44) * r, c + Vector2(0.02, -0.3) * r, c + Vector2(-0.06, -0.16) * r]), crack, maxf(1.5, r * 0.035), true)
	if hurt > 0.4:
		Dot.pline(ci, PackedVector2Array([c + Vector2(0.38, -0.12) * r, c + Vector2(0.3, 0.1) * r, c + Vector2(0.4, 0.4) * r]), crack, maxf(1.5, r * 0.03), true)
	# Eyes: a slot of molten light under the brow; dim and dizzy when stunned.
	var stunned: bool = o.get("stunned", false)
	var eye := Color(MOLTEN, 0.4) if stunned else Color(MOLTEN, clampf(glow, 0.0, 1.0))
	Dot.circle(ci, c + Vector2(-0.22, -0.3) * r, r * 0.07, eye)
	Dot.circle(ci, c + Vector2(0.18, -0.3) * r, r * 0.07, eye)
	# Crown of three studs.
	for k in 3:
		Dot.circle(ci, c + Vector2(-0.24 + k * 0.24, -0.58) * r, r * 0.07, MOLTEN if k == 1 else HOT)
	# Its hammer arm: raised while a slam is in the air, resting otherwise.
	var swing: float = o.get("swing", 0.0)
	var ang := lerpf(0.9, -1.9, minf(1.0, swing * 3.0)) if swing > 0.0 else 0.9
	var shoulder := c + Vector2(0.7, -0.24) * r
	var dir := Vector2.from_angle(ang)
	var head := shoulder + dir * r * 0.62
	Dot.pline(ci, PackedVector2Array([shoulder, head]), Color("b07a45"), maxf(3.0, r * 0.08), true)
	var side := dir.orthogonal()
	var hpts := PackedVector2Array([head + side * r * 0.2 - dir * r * 0.1, head + side * r * 0.2 + dir * r * 0.1,
		head - side * r * 0.2 + dir * r * 0.1, head - side * r * 0.2 - dir * r * 0.1])
	Dot.poly(ci, hpts, STEEL)
	Dot.circle(ci, head - side * r * 0.2, r * 0.06, HOT)


## opts.face: the way she's gliding (unit vector).
static func _brood_queen(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var t: float = o.get("t", 0.0)
	var face: Vector2 = o.get("face", Vector2.RIGHT)
	var flap := sin(t * 7.0) * 0.12
	var body := HEN.lerp(Color.WHITE, clampf(o.get("hit", 0.0) * 2.0, 0.0, 0.6))
	Dot.circle(ci, c + Vector2(r * 0.06, r * 0.12), r * 0.95, Color(0, 0, 0, 0.3))
	# Wings out to the sides, flapping.
	var side := face.orthogonal()
	for k in [-1.0, 1.0]:
		var root: Vector2 = c + side * k * r * 0.6
		var tip: Vector2 = c + side * k * r * (1.25 + flap) - face * r * 0.35
		Dot.poly(ci, PackedVector2Array([root + face * r * 0.3, tip, root - face * r * 0.45]), body.darkened(0.2))
	Dot.circle(ci, c, r * 0.82, body)
	Dot.circle(ci, c - face * r * 0.15 + side * r * -0.2, r * 0.4, Color(HEN_HI, 0.5))
	# Tail fan behind, comb on top, beak in front.
	for k in 3:
		Dot.circle(ci, c - face * r * 0.85 + side * (k - 1) * r * 0.22, r * 0.16, Color("8f7bff") if k == 1 else Color("5ce1ff"))
	for k in 3:
		Dot.circle(ci, c + face * r * (0.25 + k * 0.12) - side * r * 0.0 + Vector2(0, -r * (0.72 - k * 0.04)), r * 0.13, COMB)
	var tipb := c + face * r * 1.08
	Dot.poly(ci, PackedVector2Array([c + face * r * 0.7 + side * r * 0.14, tipb, c + face * r * 0.7 - side * r * 0.14]), BEAK)
	var eye := Color("1a1033") if not o.get("stunned", false) else Color(1, 1, 1, 0.6)
	Dot.circle(ci, c + face * r * 0.45 + side * r * 0.28, r * 0.09, eye)
	Dot.circle(ci, c + face * r * 0.45 - side * r * 0.28, r * 0.09, eye)


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
	Dot.poly(ci, pts, SHELL.lerp(Color.WHITE, clampf(o.get("hit", 0.0) * 2.0, 0.0, 0.6)))
	for k in 3:
		Dot.circle(ci, c + Vector2(-0.3 + k * 0.3, -0.2 + 0.25 * (k % 2)).rotated(tilt) * r, r * 0.12, Color(HEN, 0.7))
	var hurt := 1.0 - clampf(o.get("hp_frac", 1.0), 0.0, 1.0)
	if hurt > 0.1 or h > 0.7:
		Dot.pline(ci, PackedVector2Array([c + Vector2(-0.5, 0.0) * r, c + Vector2(-0.2, -0.15) * r, c + Vector2(0.05, 0.05) * r, c + Vector2(0.4, -0.1) * r]), Color("6b4a2a"), maxf(1.5, r * 0.07), true)


static func _chick(ci: CanvasItem, c: Vector2, r: float, o: Dictionary) -> void:
	var face: Vector2 = o.get("face", Vector2.RIGHT)
	Dot.circle(ci, c + Vector2(r * 0.08, r * 0.15), r * 0.95, Color(0, 0, 0, 0.3))
	Dot.circle(ci, c, r, Color("ffe066").lerp(Color.WHITE, clampf(o.get("hit", 0.0) * 2.0, 0.0, 0.6)))
	Dot.circle(ci, c - face * r * 0.2 + Vector2(-0.2, -0.3) * r, r * 0.35, Color("fff4b0"))
	var side := face.orthogonal()
	Dot.poly(ci, PackedVector2Array([c + face * r * 0.75 + side * r * 0.2, c + face * r * 1.25, c + face * r * 0.75 - side * r * 0.2]), Color("ff8a3d"))
	Dot.circle(ci, c + face * r * 0.35 + side * r * 0.35, r * 0.13, Color("1a1033"))
	Dot.circle(ci, c + face * r * 0.35 - side * r * 0.35, r * 0.13, Color("1a1033"))


## A boss in a menu (the Anvil King's screen and Play tile). Redraws slowly.
class BossIcon extends Control:
	var boss_id := "anvil_king"
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if fmod(_t, 0.1) < delta:
			queue_redraw()

	func _draw() -> void:
		var s := minf(size.x, size.y)
		load("res://game/boss_art.gd").draw(self, boss_id, size / 2.0, s * 0.42, {"t": _t})


static func icon(id: String, side: float) -> Control:
	var b := BossIcon.new()
	b.boss_id = id
	b.custom_minimum_size = Vector2(side, side)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b
