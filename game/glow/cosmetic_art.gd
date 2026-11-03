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
		"shades": # Sunglasses pushed up on the forehead.
			for k in [-1.0, 1.0]:
				poly.call([Vector2(k * .08, -.66), Vector2(k * .6, -.7), Vector2(k * .56, -.44), Vector2(k * .14, -.42)], b)
				Dot.line(ci, P.call(k * .5, -.64), P.call(k * .38, -.48), Color(1, 1, 1, .55), maxf(1.5, r * .05), true)
				var rim := PackedVector2Array([P.call(k * .08, -.66), P.call(k * .6, -.7), P.call(k * .56, -.44), P.call(k * .14, -.42), P.call(k * .08, -.66)])
				Dot.pline(ci, rim, a, maxf(2.0, r * .07), true)
				Dot.line(ci, P.call(k * .6, -.66), P.call(k * .86, -.58), a, maxf(2.0, r * .07), true)
			Dot.line(ci, P.call(-.08, -.6), P.call(.08, -.6), a, maxf(2.0, r * .07), true)
		"antenna": # Two bobbing stalks with glowing tips.
			for k in [-1.0, 1.0]:
				var tip := Vector2(k * (.5 + .04 * sin(t * 3.0 + k)), -1.56 + .05 * sin(t * 4.0 + k * 2.0))
				var mid := Vector2(k * .18, -1.2)
				var stalk := PackedVector2Array()
				for i in 7:
					var u := i / 6.0
					var q := Vector2(k * .14, -.86).lerp(mid, u).lerp(mid.lerp(tip, u), u)
					stalk.append(P.call(q.x, q.y))
				Dot.pline(ci, stalk, a, maxf(2.0, r * .07), true)
				Dot.circle(ci, P.call(tip.x, tip.y), r * .15, b)
				Dot.circle(ci, P.call(tip.x - .04, tip.y - .05), r * .06, Color(1, 1, 1, .7))
		"mohawk": # A row of spikes over the crown, swaying a little.
			var sway := sin(t * 3.0) * .04
			for i in 5:
				var x := -.36 + i * .18
				var h := 1.5 + .22 * (1.0 - absf(x) / .36)
				poly.call([Vector2(x - .13, -.8 + absf(x) * .25), Vector2(x + .13, -.8 + absf(x) * .25), Vector2(x * 1.25 + sway, -h + absf(x) * .25)], a if i % 2 == 0 else b)
		"antlers": # Reindeer antlers with bright tips.
			for k in [-1.0, 1.0]:
				var w := maxf(2.5, r * .1)
				var main := PackedVector2Array([P.call(k * .28, -.82), P.call(k * .42, -1.14), P.call(k * .62, -1.5)])
				Dot.pline(ci, main, a, w, true)
				Dot.line(ci, P.call(k * .4, -1.08), P.call(k * .78, -1.2), a, w * .8, true)
				Dot.line(ci, P.call(k * .52, -1.32), P.call(k * .34, -1.56), a, w * .8, true)
				for tip in [Vector2(k * .62, -1.5), Vector2(k * .78, -1.2), Vector2(k * .34, -1.56)]:
					Dot.circle(ci, P.call(tip.x, tip.y), r * .07, b)
		"earmuffs": # A thin band with two fluffy puffs.
			var band := PackedVector2Array()
			for i in 13:
				var ang := PI + PI * i / 12.0
				band.append(P.call(cos(ang) * .96, sin(ang) * 1.02 - .1))
			Dot.pline(ci, band, a, maxf(2.0, r * .08), true)
			for k in [-1.0, 1.0]:
				var at: Vector2 = P.call(k * .94, -.12)
				for j in 6:
					Dot.circle(ci, at + Vector2.from_angle(j * TAU / 6.0 + t * .3) * r * .14, r * .13, b)
				Dot.circle(ci, at, r * .2, b)
		"scarf": # A knitted scarf round the neck, its tail flapping.
			var flap := sin(t * 5.0) * .06
			var band := PackedVector2Array([P.call(-.82, .5), P.call(-.4, .66), P.call(0, .7), P.call(.4, .66), P.call(.82, .5)])
			Dot.pline(ci, band, a, maxf(4.0, r * .24), true)
			for x in [-.5, -.1, .3]:
				Dot.line(ci, P.call(x, .58), P.call(x + .1, .78), b, maxf(2.0, r * .07), true)
			poly.call([Vector2(.36, .62), Vector2(.6, .6), Vector2(.72 + flap, 1.12), Vector2(.48 + flap, 1.14)], a)
			for j in 3:
				var fx := .5 + flap + j * .08
				Dot.line(ci, P.call(fx, 1.12), P.call(fx, 1.24), b, maxf(1.5, r * .05), true)
		"flowercrown": # A ring of little flowers.
			for i in 5:
				var x := -.6 + i * .3
				var cen: Vector2 = P.call(x, -.86 + absf(x) * .18)
				var pr := r * .1
				for j in 5:
					Dot.circle(ci, cen + Vector2.from_angle(j * TAU / 5.0 + i) * pr, pr * .8, b if i % 2 == 0 else a.lightened(.3))
				Dot.circle(ci, cen, pr * .7, a)
		"sprout": # A seedling with two leaves, swaying.
			var sw := sin(t * 2.2) * .06
			Dot.line(ci, P.call(0, -.86), P.call(sw, -1.36), a.darkened(.2), maxf(2.0, r * .07), true)
			for k in [-1.0, 1.0]:
				CritterArt._ell(ci, P.call(sw + k * .22, -1.3 - (.05 if k > 0 else 0.0)), r * .22, r * .1, a, tilt + k * .5)
			Dot.circle(ci, P.call(sw, -1.4), r * .08, b)
		"lure": # An anglerfish lure arching over, its bulb pulsing.
			var bob := sin(t * 2.0) * .05
			var stalk := PackedVector2Array([P.call(-.1, -.86), P.call(.12, -1.42), P.call(.5, -1.56 + bob), P.call(.74, -1.3 + bob)])
			Dot.pline(ci, stalk, a, maxf(2.0, r * .07), true)
			Dot.circle(ci, P.call(.74, -1.22 + bob), r * .16, Color(b, .7 + .3 * sin(t * 3.0)))
			Dot.circle(ci, P.call(.7, -1.27 + bob), r * .06, Color(1, 1, 1, .8))
		"jelly": # A jellyfish cap, tentacles drifting.
			for k in [-1.0, -.4, .4, 1.0]:
				var x: float = k * .62
				var tent := PackedVector2Array()
				for j in 5:
					tent.append(P.call(x + sin(t * 3.0 + j + k * 2.0) * .06, -.82 + j * .12))
				Dot.pline(ci, tent, Color(b, .8), maxf(1.5, r * .05), true)
			var dome := []
			for i in 13:
				var ang := PI + PI * i / 12.0
				dome.append(Vector2(cos(ang) * .8, -.84 + sin(ang) * .6))
			poly.call(dome, Color(a, .85))
			for x in [-.5, -.17, .17, .5]:
				Dot.circle(ci, P.call(x, -.86), r * .06, b)
		"sunhat": # A wide straw sun hat with a ribbon.
			var brim := CritterArt.ellipse_pts(P.call(0, -.8), r * 1.18, r * .24, tilt)
			Dot.poly(ci, brim, a)
			var dome := []
			for i in 13:
				var ang := PI + PI * i / 12.0
				dome.append(Vector2(cos(ang) * .56, -.84 + sin(ang) * .5))
			poly.call(dome, a.lightened(.12))
			poly.call([Vector2(-.56, -.86), Vector2(.56, -.86), Vector2(.54, -.98), Vector2(-.54, -.98)], b)
		"float": # A rubber ring round the middle (front half only).
			var e := CritterArt.ellipse_pts(c + Vector2(0, r * .32), r * 1.12, r * .34, 0.0, 0.0, PI, 16)
			Dot.pline(ci, e, a, maxf(4.0, r * .3), true)
			for j in [3, 8, 13]:
				Dot.line(ci, e[j - 1], e[j], b, maxf(4.0, r * .3), true)
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
					var s := r * (.14 + .26 * f) * tw
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
					var s := r * (.14 + .26 * f)
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
			"streak": # Two taillight streaks, one each side.
				var side := (q - p).orthogonal().normalized() * r * .38
				Dot.line(ci, p + side, q + side, Color(a, f * .9), maxf(2.0, r * .2 * f), true)
				Dot.line(ci, p - side, q - side, Color(b, f * .9), maxf(2.0, r * .2 * f), true)
			"grid": # A synthwave rail: a line with crossbars that widen near the ball.
				Dot.line(ci, p, q, Color(a, f * .7), maxf(1.5, r * .08), true)
				if i % 3 == 0:
					var side := (q - p).orthogonal().normalized() * r * (.25 + .6 * f)
					Dot.line(ci, p - side, p + side, Color(b, f * .8), maxf(1.5, r * .07), true)
			"snow": # Snowflakes left drifting behind.
				if i % 3 == 0:
					_flake(ci, p + Vector2(0, (1.0 - f) * r * .4), r * (.12 + .16 * f), t * .8 + i, Color(a if i % 6 == 0 else b, f), maxf(1.2, r * .04))
			"ribbon": # A ribbon of light waving between two colours.
				var off := (q - p).orthogonal().normalized() * r * .35
				var w0 := sin(i * .6 - t * 4.0)
				var w1 := sin((i + 1) * .6 - t * 4.0)
				Dot.line(ci, p + off * w0, q + off * w1, Color(a.lerp(b, .5 + .5 * sin(i * .3 + t * 2.0)), .2 + f * .7), maxf(2.0, r * .34 * f), true)
			"petals": # Petals falling away behind.
				if i % 3 == 0:
					CritterArt._ell(ci, p + Vector2(0, (1.0 - f) * r * .7), r * (.1 + .12 * f), r * (.05 + .06 * f), Color(a if i % 6 == 0 else b, f), i * .9 + t)
			"fireflies": # A few blinking lights.
				if i % 3 == 0:
					var side := (q - p).orthogonal().normalized() * r * (_rand(i, 3.0) - .5) * 1.2
					Dot.circle(ci, p + side, r * (.07 + .07 * f), Color(a if i % 6 == 0 else b, (.4 + .6 * f) * (.55 + .45 * sin(t * 6.0 + i * 1.7))))
			"ink": # A cloud of ink that spreads as it fades.
				if i % 2 == 0:
					Dot.circle(ci, p, r * (.16 + .3 * (1.0 - f)), Color(a, f * .3))
					if i % 6 == 0:
						Dot.circle(ci, p + Vector2(r * .2, -r * .1), r * .05, Color(b, f))
			"wake": # A boat wake spreading out behind.
				if i % 2 == 0:
					var side := (q - p).orthogonal().normalized() * r * (.3 + .8 * (1.0 - f))
					var back := (p - q).normalized() * r * .2
					Dot.line(ci, p + side, p + side + back, Color(a, f * .8), maxf(1.5, r * .08), true)
					Dot.line(ci, p - side, p - side + back, Color(a, f * .8), maxf(1.5, r * .08), true)
					if i % 6 == 0:
						Dot.circle(ci, p, r * .06, Color(b, f))
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
		"tube": # Bent neon tubes zigzagging outward.
			for i in 4:
				var ang := i * TAU / 4.0 + .4 + seed_
				var d := Vector2.from_angle(ang)
				var n := d.orthogonal()
				var o := p + d * (10.0 + 40.0 * k) * s
				var zz := PackedVector2Array([o, o + d * 12.0 * s + n * 7.0 * s, o + d * 24.0 * s - n * 7.0 * s, o + d * 36.0 * s])
				Dot.pline(ci, zz, Color(a if i % 2 == 0 else b, fade), 5.0 * s, true)
				Dot.pline(ci, zz, Color(1, 1, 1, fade * .7), 1.6 * s, true)
		"notes": # Music notes hopping out of the hit.
			for i in 4:
				var dir := Vector2.from_angle(-PI / 2 + (i - 1.5) * .7 + (_rand(i, seed_) - .5) * .3)
				var q := p + dir * (12.0 + 50.0 * k) * s + Vector2(0, -10.0 * k * s)
				var col := Color(a if i % 2 == 0 else b, fade)
				CritterArt._ell(ci, q, 7.0 * s, 5.0 * s, col, -.4)
				Dot.line(ci, q + Vector2(6.0, -1.0) * s, q + Vector2(6.0, -22.0) * s, col, 2.5 * s, true)
				Dot.line(ci, q + Vector2(6.0, -22.0) * s, q + Vector2(14.0, -15.0) * s, col, 2.5 * s, true)
		"rings":
			for i in 3:
				var kk := clampf(k * 1.4 - i * .2, 0.0, 1.0)
				if kk > 0.0:
					Dot.arc(ci, p, (8.0 + 60.0 * kk) * s, 0, TAU, 32, Color(a if i % 2 == 0 else b, 1.0 - kk), 4.0 * s, true)
		"flake": # Snowflakes spinning out.
			for i in 3:
				var dir := Vector2.from_angle(i * TAU / 3.0 + seed_)
				_flake(ci, p + dir * (10.0 + 46.0 * k) * s, (10.0 + 4.0 * fade) * s, k * 3.0 + i, Color(a if i % 2 == 0 else b, fade), 2.5 * s)
		"bloom": # Little flowers popping open.
			for i in 4:
				var dir := Vector2.from_angle(i * TAU / 4.0 + .5 + seed_)
				var cen := p + dir * (12.0 + 40.0 * k) * s
				var pr := (3.0 + 6.0 * minf(1.0, k * 3.0)) * s
				for j in 5:
					Dot.circle(ci, cen + Vector2.from_angle(j * TAU / 5.0) * pr, pr * .8, Color(b, fade))
				Dot.circle(ci, cen, pr * .7, Color(a, fade))
		"bubblepop": # Bubbles that float out and pop.
			for i in 5:
				var dir := Vector2.from_angle(i * TAU / 5.0 + seed_)
				var cen := p + dir * (10.0 + 44.0 * k) * s
				var br := (5.0 + 9.0 * k) * s
				Dot.arc(ci, cen, br, 0, TAU, 16, Color(a, fade), 2.5 * s, true)
				Dot.circle(ci, cen + Vector2(-br * .35, -br * .35), br * .25, Color(b, fade))
		"splash": # Water drops flying out and falling.
			for i in 8:
				var dir := Vector2.from_angle(-PI / 2 + (i - 3.5) * .38)
				var cen := p + dir * (10.0 + 54.0 * k) * s + Vector2(0, 40.0 * k * k * s)
				var dr := (5.0 - 2.0 * k) * s
				Dot.circle(ci, cen, dr, Color(a if i % 2 == 0 else b, fade))
				Dot.poly(ci, PackedVector2Array([cen + dir.orthogonal() * dr, cen - dir.orthogonal() * dr, cen - dir * dr * 2.6]), Color(a if i % 2 == 0 else b, fade))
		_:
			Dot.poly(ci, CritterArt.star_pts(p, (10.0 + 70.0 * k) * s, (5.0 + 30.0 * k) * s, 8), Color(a, fade))


## A six-armed snowflake.
static func _flake(ci: CanvasItem, c: Vector2, size: float, rot: float, col: Color, w: float) -> void:
	for j in 3:
		var d := Vector2.from_angle(rot + j * PI / 3.0) * size
		Dot.line(ci, c - d, c + d, col, w, true)
		for sgn in [-1.0, 1.0]:
			var m: Vector2 = c + d * .55 * sgn
			Dot.line(ci, m, m + (d * .3 * sgn).rotated(.8), col, w * .8, true)


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
		"sign": # A neon "KO!" sign that pops in and flickers out.
			if k > .55 and _rand(floorf(k * 18.0), seed_) < .35:
				return
			var fs := int(r * (1.1 + .5 * minf(1.0, k * 5.0)))
			var w := FONT.get_string_size("KO!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var at := p + Vector2(-w / 2.0, fs * .35 - r * .4 * k)
			ci.draw_string_outline(FONT, at, "KO!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(4, int(fs * .14)), Color(a, fade))
			ci.draw_string(FONT, at, "KO!", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(b.lightened(.5), fade))
		"eq": # Equalizer bars jumping to the beat, then dropping away.
			var n := 9
			var bw := r * .32
			var base := p + Vector2(0, r * .9)
			for i in n:
				var hop := _rand(i, floorf(k * 10.0) + seed_)
				var h := r * (.4 + 2.2 * hop * (1.0 - absf(i - (n - 1) / 2.0) / n)) * minf(1.0, k * 6.0)
				var x := base.x + (i - (n - 1) / 2.0) * bw * 1.25 - bw / 2.0
				Dot.rect(ci, Rect2(x, base.y - h, bw, h), Color(a.lerp(b, float(i) / (n - 1)), fade))
				Dot.rect(ci, Rect2(x, base.y - h - bw * .55, bw, bw * .3), Color(1, 1, 1, fade * .8))
		"shards": # Ice shards bursting out, turning as they fly.
			for i in 12:
				var dir := Vector2.from_angle(_rand(i, seed_) * TAU)
				var q := p + dir * r * (.3 + 2.0 * k * (.6 + _rand(i + 4, seed_)))
				var rot := dir.angle() + k * 4.0 * (_rand(i + 9, seed_) - .5)
				var ln := r * (.45 + .3 * _rand(i + 2, seed_))
				var pts := PackedVector2Array([q + Vector2.from_angle(rot) * ln, q + Vector2.from_angle(rot + 2.6) * ln * .3, q + Vector2.from_angle(rot - 2.6) * ln * .3])
				Dot.poly(ci, pts, Color(a if i % 3 else b, fade))
				Dot.line(ci, pts[0], pts[1], Color(1, 1, 1, fade * .7), maxf(1.0, r * .03), true)
		"globe": # A snow globe forms round the KO, snow settles, then it pops.
			var gr := r * (1.3 + (.4 if k > .8 else 0.0) * (k - .8) * 5.0)
			Dot.rect(ci, Rect2(p.x - r * .9, p.y + gr * .82, r * 1.8, r * .4), Color(b, fade))
			Dot.arc(ci, p, gr, 0, TAU, 32, Color(a, fade * .9), maxf(2.0, r * .08), true)
			Dot.line(ci, p + Vector2(-gr * .5, -gr * .6), p + Vector2(-gr * .7, -gr * .2), Color(1, 1, 1, fade * .5), maxf(2.0, r * .06), true)
			for i in 16:
				var x := (_rand(i, seed_) - .5) * gr * 1.4
				var y := fmod(_rand(i + 20, seed_) * gr * 1.6 + k * gr * 1.2, gr * 1.6) - gr * .8
				Dot.circle(ci, p + Vector2(x, y), r * .06, Color(1, 1, 1, fade * .9))
		"butterflies": # Butterflies fluttering up and away.
			for i in 6:
				var dir := Vector2.from_angle(-PI / 2 + (i - 2.5) * .55)
				var cen := p + dir * r * (.4 + 2.2 * k) + Vector2(sin(k * 9.0 + i) * r * .2, 0)
				var flap := absf(sin(k * 28.0 + i * 1.3))
				var col := Color(a if i % 2 == 0 else b, fade)
				for side in [-1.0, 1.0]:
					CritterArt._ell(ci, cen + Vector2(side * r * .24 * flap, -r * .09), r * .24 * flap + 1.0, r * .2, col)
					CritterArt._ell(ci, cen + Vector2(side * r * .15 * flap, r * .15), r * .15 * flap + 1.0, r * .13, col)
				Dot.line(ci, cen + Vector2(0, -r * .15), cen + Vector2(0, r * .18), Color(INK, fade), maxf(1.5, r * .04), true)
		"bigbloom": # A big flower opens where the foe was.
			var open := 1.0 - pow(1.0 - minf(1.0, k * 2.5), 3.0)
			for i in 8:
				var ang := i * TAU / 8.0 + k * .6
				CritterArt._ell(ci, p + Vector2.from_angle(ang) * r * .8 * open, r * .5 * open + 1.0, r * .24 * open + 1.0, Color(a if i % 2 == 0 else b, fade), ang)
			Dot.circle(ci, p, r * .38 * open + 1.0, Color(b.lightened(.4), fade))
		"whirlpool": # A whirlpool spins up and drains away.
			for arm in 3:
				var pts := PackedVector2Array()
				for j in 14:
					var u := j / 13.0
					var ang := arm * TAU / 3.0 + u * 4.0 - k * 9.0
					pts.append(p + Vector2.from_angle(ang) * r * (.15 + 1.6 * u) * (1.0 - k * .5))
				Dot.pline(ci, pts, Color(a if arm % 2 == 0 else b, fade), maxf(2.0, r * .1), true)
		"school": # A school of little fish darting off.
			for i in 10:
				var dir := Vector2.from_angle(_rand(i, seed_) * TAU)
				var cen := p + dir * r * (.4 + 2.4 * k * (.6 + .5 * _rand(i + 6, seed_)))
				var col := Color(a if i % 3 else b, fade)
				CritterArt._ell(ci, cen, r * .3, r * .13, col, dir.angle())
				Dot.poly(ci, PackedVector2Array([cen - dir * r * .24, cen - dir * r * .5 + dir.orthogonal() * r * .15, cen - dir * r * .5 - dir.orthogonal() * r * .15]), col)
		"wave": # A splash crown rising and breaking.
			for i in 3:
				var kk := clampf(k * 1.4 - i * .18, 0.0, 1.0)
				if kk > 0.0:
					Dot.arc(ci, p + Vector2(0, r * .5), r * (.6 + 1.8 * kk), PI * 1.1, PI * 1.9, 20, Color(a if i % 2 == 0 else b, 1.0 - kk), maxf(3.0, r * .12), true)
			for i in 10:
				var dir := Vector2.from_angle(PI * 1.1 + i * PI * .8 / 9.0)
				Dot.circle(ci, p + dir * r * (.8 + 1.6 * k) + Vector2(0, r * 2.0 * k * k), r * .08, Color(b, fade))
		"sunburst": # A sun rises with turning rays.
			var grow := minf(1.0, k * 4.0)
			for i in 12:
				var ang := i * TAU / 12.0 + k * 1.5
				var d := Vector2.from_angle(ang)
				Dot.poly(ci, PackedVector2Array([p + d.orthogonal() * r * .14 + d * r * .8 * grow, p - d.orthogonal() * r * .14 + d * r * .8 * grow, p + d * r * (1.2 + .9 * grow)]), Color(b, fade))
			Dot.circle(ci, p, r * .7 * grow + 1.0, Color(a, fade))
		_:
			Dot.arc(ci, p, r * (1.0 + 2.0 * k), 0, TAU, 32, Color(a, fade), 4.0, true)
