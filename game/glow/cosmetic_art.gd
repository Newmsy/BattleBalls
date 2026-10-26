## Draws cosmetics with plain CanvasItem draw calls, for the arena, the shop's
## try-on preview and its tiles. Render-only: these functions get positions
## and a clock, never the sim, and nothing they do feeds back into a fight.
##
## Readability (design/monetisation.md §1 rule 3): callers draw the YOU/FOE
## rings, tags and HP badges after everything here, so cosmetics can never
## cover them. Shapes come from the critter art kit (game/ui/critter_art.gd).
extends RefCounted

const Dot := preload("res://game/dot.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")

const INK := Color("1a1530")
## Rainbow trail hues: skips the YOU green and FOE pink so rings stay readable.
const RAINBOW := [0.07, 0.14, 0.5, 0.6, 0.75]
## How long effects play, in seconds.
const SPARK_LIFE := 0.45
const KO_LIFE := 1.4


static func _rand(i: float, seed_: float) -> float:
	var v := sin(i * 12.9898 + seed_ * 78.233) * 43758.5453
	return v - floorf(v)


## A cosmetic's two colours at time `t`. A Prism Spark Dye (game/glow/dyes.gd)
## sets `shimmer`: its colours slowly trade places.
static func pair(it: Dictionary, t := 0.0) -> Array:
	var a := Catalog.color(it, 0)
	var b := Catalog.color(it, 1)
	if not it.get("shimmer", false):
		return [a, b]
	var m := .5 + .5 * sin(t * 1.6)
	return [a.lerp(b, m), b.lerp(a, m)]


# --- Hats ------------------------------------------------------------------------

## A hat on a ball of radius `r` centred at `c`. `tilt` leans it (radians).
static func draw_hat(ci: CanvasItem, it: Dictionary, c: Vector2, r: float, t := 0.0, tilt := -0.18) -> void:
	var ab := pair(it, t)
	var a: Color = ab[0]
	var b: Color = ab[1]
	var rot := Transform2D(tilt, c)
	var P := func(x: float, y: float) -> Vector2: return rot * (Vector2(x, y) * r)
	var poly := func(pts: Array, col: Color) -> void:
		var pv := PackedVector2Array()
		for p in pts:
			pv.append(P.call(p.x, p.y))
		Dot.poly(ci, pv, col)
	match it.style:
		"cone":
			poly.call([Vector2(-.42, -.82), Vector2(.42, -.82), Vector2(.04, -1.72)], a)
			for k in 3:
				var y := -.95 - k * .24
				var w := .36 - k * .11
				Dot.line(ci, P.call(-w, y), P.call(w * .9, y - .08), b, maxf(2.0, r * .07), true)
			Dot.circle(ci, P.call(.04, -1.74), r * .13, b)
		"crown":
			var pts := [Vector2(-.48, -.78), Vector2(.48, -.78), Vector2(.52, -1.28), Vector2(.26, -1.04), Vector2(0, -1.36), Vector2(-.26, -1.04), Vector2(-.52, -1.28)]
			poly.call(pts, a)
			Dot.line(ci, P.call(-.48, -.84), P.call(.48, -.84), a.darkened(.3), maxf(2.0, r * .08), true)
			for x in [-.52, 0.0, .52]:
				Dot.circle(ci, P.call(x, -1.3 if x != 0.0 else -1.38), r * .08, b)
			Dot.circle(ci, P.call(0, -.98), r * .07, b)
		"phones":
			var band := PackedVector2Array()
			for i in 17:
				var ang := PI + PI * i / 16.0
				band.append(P.call(cos(ang) * 1.0, sin(ang) * 1.08 - .02))
			Dot.pline(ci, band, b, maxf(3.0, r * .13), true)
			for k in [-1.0, 1.0]:
				CritterArt._ell(ci, P.call(k * .98, -.05), r * .2, r * .3, a, tilt)
				CritterArt._ell(ci, P.call(k * 1.02, -.05), r * .1, r * .18, a.lightened(.4), tilt)
		"tophat":
			poly.call([Vector2(-.62, -.78), Vector2(.62, -.78), Vector2(.62, -.9), Vector2(-.62, -.9)], a)
			poly.call([Vector2(-.36, -.88), Vector2(.36, -.88), Vector2(.4, -1.6), Vector2(-.4, -1.6)], a)
			poly.call([Vector2(-.37, -1.0), Vector2(.37, -1.0), Vector2(.37, -1.12), Vector2(-.37, -1.12)], b)
			Dot.line(ci, P.call(-.26, -1.5), P.call(-.22, -1.1), Color(1, 1, 1, .25), maxf(2.0, r * .06), true)
		"beanie":
			var dome := []
			for i in 13:
				var ang := PI + PI * i / 12.0
				dome.append(Vector2(cos(ang) * .74, -.74 + sin(ang) * .62))
			poly.call(dome, a)
			poly.call([Vector2(-.78, -.66), Vector2(.78, -.66), Vector2(.78, -.86), Vector2(-.78, -.86)], a.darkened(.25))
			for x in [-.5, -.25, 0.0, .25, .5]:
				Dot.line(ci, P.call(x, -.68), P.call(x, -.84), b, maxf(1.5, r * .04), true)
			Dot.circle(ci, P.call(0, -1.42), r * .16, b)
		"halo":
			var bob := sin(t * 2.4) * .05
			var e := CritterArt.ellipse_pts(P.call(0, -1.28 + bob), r * .56, r * .16, tilt)
			e.append(e[0])
			Dot.pline(ci, e, Color(b, .45), maxf(5.0, r * .2), true)
			Dot.pline(ci, e, a, maxf(2.5, r * .09), true)
		"visor":
			poly.call([Vector2(-.82, -.44), Vector2(.82, -.44), Vector2(.7, -.68), Vector2(-.7, -.68)], Color(a, .8))
			Dot.line(ci, P.call(-.84, -.44), P.call(.84, -.44), b, maxf(2.0, r * .08), true)
			var shine := fmod(t * .6, 1.6) - .8
			Dot.line(ci, P.call(shine - .08, -.46), P.call(shine + .04, -.66), Color(1, 1, 1, .6), maxf(2.0, r * .06), true)
		"cap":
			var dome := []
			for i in 13:
				var ang := PI + PI * i / 12.0
				dome.append(Vector2(cos(ang) * .7, -.72 + sin(ang) * .5))
			poly.call(dome, a)
			poly.call([Vector2(.2, -.76), Vector2(1.05, -.72), Vector2(1.0, -.64), Vector2(.2, -.66)], a.darkened(.3))
			Dot.circle(ci, P.call(0, -1.2), r * .07, b)
			Dot.circle(ci, P.call(-.2, -.96), r * .12, b)
		"horns":
			for k in [-1.0, 1.0]:
				var pts := [Vector2(k * .3, -.86), Vector2(k * .62, -.7), Vector2(k * .74, -1.2), Vector2(k * .58, -1.48)]
				poly.call(pts, a)
				Dot.line(ci, P.call(k * .5, -.86), P.call(k * .64, -1.3), Color(b, .6), maxf(1.5, r * .05), true)
		_:
			Dot.circle(ci, P.call(0, -1.0), r * .2, a)


# --- Trails ----------------------------------------------------------------------

## A trail through `pts` (oldest first, newest last) behind a ball of radius `r`.
static func draw_trail(ci: CanvasItem, it: Dictionary, pts: Array, r: float, t := 0.0) -> void:
	var n := pts.size()
	if n < 2:
		return
	var ab := pair(it, t)
	var a: Color = ab[0]
	var b: Color = ab[1]
	for i in range(n - 1):
		var f := float(i + 1) / n ## 0 old -> 1 new
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[i + 1]
		match it.style:
			"sparkle":
				if i % 2 == 0:
					var tw := .6 + .4 * sin(t * 12.0 + i)
					var s := r * (.08 + .16 * f) * tw
					Dot.poly(ci, CritterArt.star_pts(p, s, s * .35, 4, t * 2.0 + i), Color(a if i % 4 == 0 else b, f))
			"rainbow":
				var col: Color
				if a == Color.WHITE:
					col = Color.from_hsv(RAINBOW[posmod(i / 2, RAINBOW.size())], .75, 1.0, f * .7)
				else:
					col = Color(a.lerp(b, f), f * .7)
				Dot.line(ci, p, q, col, r * (.15 + .35 * f), true)
			"pixel":
				if i % 2 == 0:
					var s := r * (.1 + .2 * f)
					var g := Vector2(snappedf(p.x, s), snappedf(p.y, s))
					Dot.rect(ci, Rect2(g - Vector2(s, s) / 2.0, Vector2(s, s)), Color(a if (i / 2) % 2 == 0 else b, f))
			"bubbles":
				if i % 3 == 0:
					var rr := r * (.1 + .22 * (1.0 - f) + .04 * sin(t * 5.0 + i))
					Dot.arc(ci, p, rr, 0, TAU, 16, Color(a, f * .8), maxf(1.5, r * .04), true)
					Dot.circle(ci, p + Vector2(-rr * .35, -rr * .35), rr * .2, Color(b, f * .8))
			"comet":
				Dot.line(ci, p, q, Color(a, f * .35), r * 1.2 * f, true)
				Dot.line(ci, p, q, Color(b, f * .8), r * .3 * f, true)
			_:
				Dot.line(ci, p, q, Color(a, f * .6), r * .3 * f, true)


# --- Hit sparks -------------------------------------------------------------------

## A collision spark at `p`, `k` from 0 (just hit) to 1 (gone). `s` scales it.
static func draw_spark(ci: CanvasItem, it: Dictionary, p: Vector2, k: float, s := 1.0, seed_ := 0.0) -> void:
	var ab := pair(it, seed_ + k)
	var a: Color = ab[0]
	var b: Color = ab[1]
	var fade := 1.0 - k
	match it.style:
		"hearts":
			for i in 6:
				var dir := Vector2.from_angle(i * TAU / 6.0 + _rand(i, seed_) * .5)
				_heart(ci, p + dir * (14.0 + 60.0 * k) * s, (9.0 + 4.0 * fade) * s, Color(a if i % 2 == 0 else b, fade))
		"glitch":
			for i in 7:
				var off := Vector2(_rand(i, seed_ + floorf(k * 8.0)) - .5, _rand(i + 9, seed_) - .5) * 80.0 * s
				var w := (14.0 + 30.0 * _rand(i + 3, seed_)) * s
				Dot.rect(ci, Rect2(p + off, Vector2(w, 6.0 * s)), Color(a if i % 2 == 0 else b, fade))
		"pow":
			var pts := CritterArt.star_pts(p, (34.0 + 24.0 * k) * s, (20.0 + 12.0 * k) * s, 10, .2)
			Dot.poly(ci, pts, Color(a, fade))
			pts.append(pts[0])
			Dot.pline(ci, pts, Color(b, fade), 3.0 * s, true)
			var fs := int(22 * s)
			var w := FONT.get_string_size("POW", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			ci.draw_string(FONT, p + Vector2(-w / 2.0, fs * .36), "POW", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK, fade))
		"stars":
			for i in 5:
				var dir := Vector2.from_angle(i * TAU / 5.0 + seed_)
				Dot.poly(ci, CritterArt.star_pts(p + dir * (10.0 + 50.0 * k) * s, 9.0 * s, 4.0 * s, 5), Color(a if i % 2 == 0 else b, fade))
		"rings":
			for i in 3:
				var kk := clampf(k * 1.4 - i * .2, 0.0, 1.0)
				if kk > 0.0:
					Dot.arc(ci, p, (8.0 + 60.0 * kk) * s, 0, TAU, 32, Color(a if i % 2 == 0 else b, 1.0 - kk), 4.0 * s, true)
		_:
			Dot.poly(ci, CritterArt.star_pts(p, (10.0 + 70.0 * k) * s, (5.0 + 30.0 * k) * s, 8), Color(a, fade))


static func _heart(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	Dot.circle(ci, p + Vector2(-s * .5, -s * .2), s * .55, col)
	Dot.circle(ci, p + Vector2(s * .5, -s * .2), s * .55, col)
	Dot.poly(ci, PackedVector2Array([p + Vector2(-s * 1.02, 0), p + Vector2(s * 1.02, 0), p + Vector2(0, s * 1.1)]), col)


# --- KO effects --------------------------------------------------------------------

## The pop when a foe is knocked out at `p` (radius `r`), `k` from 0 to 1.
static func draw_ko(ci: CanvasItem, it: Dictionary, p: Vector2, r: float, k: float, seed_ := 0.0) -> void:
	var ab := pair(it, seed_ + k * 3.0)
	var a: Color = ab[0]
	var b: Color = ab[1]
	var fade := clampf(1.4 - k * 1.4, 0.0, 1.0)
	match it.style:
		"confetti":
			for i in 28:
				var dir := Vector2.from_angle(_rand(i, seed_) * TAU)
				var sp := (.6 + _rand(i + 40, seed_)) * r * 2.4
				var q := p + dir * sp * k + Vector2(0, r * 1.6 * k * k)
				var sz := r * (.08 + .06 * _rand(i + 7, seed_))
				var rot := Transform2D(k * 9.0 + i, q)
				var pts := PackedVector2Array([rot * Vector2(-sz, -sz * .5), rot * Vector2(sz, -sz * .5), rot * Vector2(sz, sz * .5), rot * Vector2(-sz, sz * .5)])
				Dot.poly(ci, pts, Color(a if i % 2 == 0 else b, fade))
		"disco":
			var c := p + Vector2(0, -r * (1.0 - minf(1.0, k * 3.0)) * 1.5)
			var rr := r * .6
			for i in 8:
				var ang := i * TAU / 8.0 + k * 3.0
				var col := Color(a if i % 2 == 0 else b, fade * .35)
				Dot.poly(ci, PackedVector2Array([c, c + Vector2.from_angle(ang - .08) * r * 3.0, c + Vector2.from_angle(ang + .08) * r * 3.0]), col)
			Dot.circle(ci, c, rr, Color(b.darkened(.3), fade))
			for gx in range(-2, 3):
				for gy in range(-2, 3):
					var q := c + Vector2(gx, gy) * rr * .36
					if q.distance_to(c) < rr * .9:
						var lit := _rand(gx * 5 + gy, floorf(k * 12.0)) > .6
						Dot.rect(ci, Rect2(q - Vector2.ONE * rr * .15, Vector2.ONE * rr * .3), Color(a.lightened(.5) if lit else a, fade))
		"shatter":
			for i in 24:
				var dir := Vector2.from_angle(_rand(i, seed_) * TAU)
				var q := p + dir * r * (.3 + 2.2 * k * (.5 + _rand(i + 3, seed_)))
				var sz := r * .18 * (1.0 - k * .5)
				Dot.rect(ci, Rect2(q - Vector2.ONE * sz / 2.0, Vector2.ONE * sz), Color(a if i % 3 else b, fade))
		"fireworks":
			for burst in 3:
				var kk := clampf(k * 1.5 - burst * .25, 0.0, 1.0)
				if kk <= 0.0:
					continue
				var c := p + Vector2(_rand(burst, seed_) - .5, _rand(burst + 5, seed_) - .8) * r * 2.4
				for i in 12:
					var dir := Vector2.from_angle(i * TAU / 12.0)
					var col := Color(a if burst % 2 == 0 else b, 1.0 - kk)
					Dot.line(ci, c + dir * r * 1.2 * kk * .6, c + dir * r * 1.2 * kk, col, maxf(2.0, r * .06), true)
		_:
			Dot.arc(ci, p, r * (1.0 + 2.0 * k), 0, TAU, 32, Color(a, fade), 4.0, true)
