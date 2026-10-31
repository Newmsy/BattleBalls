## Art for the round-2 critters (2026-10-31): Boing, Snowbo, Zorp, Snooze,
## Kernel, Gourdo, Boomer, Beans, Shade, Astra, Blaze, Rift, Reaper and Choo.
## Kept apart from critter_art.gd so that file stays readable; it uses the same
## unit-space kit (body centre (0, 0), radius 1, y down). Every tier adds
## something you can see: T2 and T4 a small step, T3 a clear one and T5 the
## full look.
extends RefCounted

const A := preload("res://game/ui/critter_art.gd")
const Dot := preload("res://game/dot.gd")

const BODIES := ["bean", "shadow", "swirl"]
const FEATURES := ["springcoil", "carrot", "snowcap", "saucer", "ufodome", "nightcap", "craters", "popcorn", "kernelband",
	"pumpkinface", "pumpkinstem", "boomerang", "toystripes", "beanbuddies", "beanspecks", "shadowtwin", "shadowcrown",
	"constellation", "starpins", "blazecrest", "blazeembers", "portals", "riftrim", "reaperhood", "scythe", "reaperface",
	"chimney", "wheels", "cowcatcher"]

const INK := Color("1a1530")
const GOLD := Color("ffd23f")
const GOLD_LIGHT := Color("fff1b0")


# --- Short names for the kit (unit space) ----------------------------------
static func _f(ci, pts, col) -> void: A._ufill(ci, pts, col)
static func _s(ci, pts, col, w) -> void: A._ustroke(ci, pts, col, w)
static func _o(ci, p, rad, col) -> void: A._ucirc(ci, p, rad, col)
static func _e(ci, p, rx, ry, col, rot := 0.0) -> void: A._uell(ci, p, rx, ry, col, rot)
static func _l(ci, a, b, col, w) -> void: A._uline(ci, a, b, col, w)
static func _ar(ci, p, rad, a0, a1, col, w) -> void: A._uarc(ci, p, rad, a0, a1, col, w)
static func _st(ci, p, r1, r2, n, col, rot := -PI / 2) -> void: A._ustar(ci, p, r1, r2, n, col, rot)
static func _gl(ci, p, size, t, ph := 0.0, col := Color.WHITE) -> void: A._uglint(ci, p, size, t, ph, col)
static func _q(a: Vector2, ctrl: Vector2, b: Vector2, n := 12) -> PackedVector2Array: return A._quad(a, ctrl, b, n)
static func _sh(col: Color, amt: float) -> Color: return A.shade(col, amt)
static func _h(i: float) -> float: return A._hash(i)


## Ellipse outline in unit space.
static func _ep(p: Vector2, rx: float, ry: float, a0 := 0.0, a1 := TAU, n := 24, rot := 0.0) -> PackedVector2Array:
	return A.ellipse_pts(p, rx, ry, rot, a0, a1, n)


## A shaded little ball (popcorn, mini beans, shadow eyes...) in unit space.
static func _ball(ci, p: Vector2, rad: float, col: Color) -> void:
	_o(ci, p, rad, _sh(col, -.25))
	_o(ci, p + Vector2(-.25, -.25) * rad, rad * .72, col)
	_o(ci, p + Vector2(-.38, -.42) * rad, rad * .28, Color(1, 1, 1, .55))


## A flame tongue from base p pointing along angle a (unit space).
static func _tongue(ci, p: Vector2, a: float, L: float, w: float, col: Color) -> void:
	var d := Vector2(cos(a), sin(a))
	var side := d.orthogonal()
	var pts := PackedVector2Array()
	for i in 9:
		var k := float(i) / 8.0
		pts.append(p + side * w * (1.0 - k) * sin(k * PI * .5 + .6) + d * L * k)
	for i in range(8, -1, -1):
		var k := float(i) / 8.0
		pts.append(p - side * w * (1.0 - k) * sin(k * PI * .5 + .6) + d * L * k * .96)
	_f(ci, pts, col)


# --- Bodies ----------------------------------------------------------------

static func body(ci: CanvasItem, style: String, col: Color, c: Vector2, r: float, s: Dictionary) -> void:
	var t: float = s.t
	var n: int = s.tier
	match style:
		"bean":
			# Beans: a jelly-bean kidney, glossy, leaning a little.
			var pts := PackedVector2Array()
			for i in 40:
				var a := i * TAU / 40.0
				var rad := 1.0 - .16 * maxf(0.0, cos(a + PI * .5)) * maxf(0.0, cos(a + PI * .5))
				pts.append(c + Vector2(cos(a) * 1.12, sin(a) * .9 * rad) .rotated(-.18) * r)
			A._shaped(ci, pts, c, r, col)
			A._hit_shape = pts
		"shadow":
			# Shade: a dusky ball whose edge frays into smoke.
			var dark := Color(col).darkened(.35)
			for i in 10:
				var a := i * TAU / 10.0 + t * .4
				_o(ci, Vector2(cos(a), sin(a)) * (.9 + .06 * sin(t * 3.0 + i)), .22, Color(dark, .55))
			A._body(ci, c, r, dark)
			_o(ci, Vector2(.05, .08), .78, Color(0.05, 0.03, .12, .35))
		"swirl":
			# Rift: a teal ball with a violet whirlpool turning in it.
			A._body(ci, c, r, col)
			A._clip_on()
			var arms := 2 if n < 2 else 3
			for k in arms:
				var pts := PackedVector2Array()
				for i in 22:
					var q := float(i) / 21.0
					var a := -t * 1.2 + k * TAU / arms + q * 3.4
					pts.append(Vector2(cos(a), sin(a)) * (.08 + q * 1.0))
				_s(ci, pts, Color("6f3bd6", .75 if n < 3 else .9), .12 + .05 * float(n >= 3))
			_o(ci, Vector2.ZERO, .16 + .03 * n, Color("2a1470", .8))
			A._clip = false
			A._gloss(ci, c, r, col)
			A._ring(ci, c, r, _sh(col, -.5), maxf(1.5, r * .07))
		_:
			A._body(ci, c, r, col)


# --- Features --------------------------------------------------------------

static func feature(ci: CanvasItem, name: String, c: Color, t: float, n: int, s: Dictionary) -> void:
	var look: Vector2 = s.get("look", Vector2.RIGHT)
	match name:
		# ----- Boing (Tech Common): a spring bot.
		"springcoil":
			# The spring it sits on squashes and stretches; copper at T3, double at T4, gold at T5.
			var sq := .5 + .5 * sin(t * 4.0)
			var col := Color("9aa8c7") if n < 3 else (Color("d98a4a") if n < 5 else GOLD)
			var loops := 3 if n < 4 else 4
			for k in ([0] if n < 4 else [-1, 1]):
				var x: float = k * .32
				for i in loops:
					var y := .8 + i * (.18 + .06 * sq)
					_ar(ci, Vector2(x, y), .36 if n < 4 else .26, 0.0, PI, _sh(col, -.35), .09)
					_ar(ci, Vector2(x, y + .02), .36 if n < 4 else .26, PI, TAU, col, .09)
				var foot := .8 + loops * (.18 + .06 * sq)
				A._urect(ci, x - .4, foot - .02, .8, .12, _sh(col, -.45), .05)
			if n >= 2:
				for k in [-1, 1]:
					A._urect(ci, k * 1.02 - .12, -.14, .24, .28, Color("6b7590"), .05)
					_o(ci, Vector2(k * 1.02, 0), .07, Color("c9d3ea"))
			if n >= 3:
				# An antenna with a go-light.
				_l(ci, Vector2(0, -.92), Vector2(0, -1.3), Color("6b7590"), .06)
				_o(ci, Vector2(0, -1.36), .12, Color("5cf0b0") if n < 5 else GOLD)
				_o(ci, Vector2(0, -1.36), .2, Color(.36, .94, .69, .25 + .15 * sin(t * 6.0)))
			if n >= 5:
				# Springy ears that wobble.
				for k in [-1, 1]:
					for i in 3:
						var p := Vector2(k * (1.0 + i * .14), -.45 - i * .1 + .05 * sin(t * 7.0 + i))
						A._uring(ci, p, .12, GOLD, .05)
		"carrot":
			# Snowbo's face: carrot nose and a coal smile (more coal from T2).
			var dir := 1.0 if look.x >= 0.0 else -1.0
			var nose := Vector2(look.x * .2, .12)
			_f(ci, PackedVector2Array([nose + Vector2(0, -.08), nose + Vector2(dir * .62, .03), nose + Vector2(0, .1)]), Color("ff8a2a"))
			_l(ci, nose + Vector2(dir * .12, -.04), nose + Vector2(dir * .16, .06), Color("c45a10"), .025)
			var coals := 5 if n < 2 else 7
			for i in coals:
				var k := (i - (coals - 1) / 2.0) / ((coals - 1) / 2.0)
				_o(ci, Vector2(k * .34 + look.x * .2, .42 + .12 * (1.0 - k * k)), .055, Color("1c1c26"))
			if n >= 2:
				A._clip_on()
				A._urect(ci, -1, .62, 2, .24, Color("e8433f"))
				if n >= 4:
					for i in 5:
						A._urect(ci, -.9 + i * .4, .62, .14, .24, Color.WHITE)
				A._clip = false
			if n >= 5:
				A._urect(ci, -.5, -1.75, 1.0, .9, Color("1c1c26"), .05)
				A._urect(ci, -.78, -.92, 1.56, .16, Color("1c1c26"), .06)
				A._urect(ci, -.5, -1.07, 1.0, .15, Color("e8433f"))
				for k in [-1, 1]:
					_e(ci, Vector2(.3 + k * .12, -1.0), .15, .07, Color("3f9a3a"), k * .5)
				_o(ci, Vector2(.3, -1.0), .07, Color("e8344a"))
				for i in 6:
					var q := fmod(t * .35 + i / 6.0, 1.0)
					_st(ci, Vector2(-1.4 + _h(i) * 2.8, -1.7 + q * 3.2), .07, .025, 6, Color(1, 1, 1, .9 * (1.0 - q)))
			if n >= 4:
				# Frost freckles and a rosy chill.
				for k in [-1, 1]:
					_e(ci, Vector2(k * .55, .22), .14, .08, Color(.55, .8, 1, .45))
		"snowcap":
			# Back: twig arms (T1); a red scarf (T2), earmuffs (T3), stripes on the scarf (T4),
			# and at T5 a top hat with holly and snow falling round it.
			for k in [-1, 1]:
				var root := Vector2(k * .85, .2)
				var tip := Vector2(k * 1.5, -.25 + .04 * sin(t * 3.0 + k))
				_l(ci, root, tip, Color("6b4316"), .07)
				_l(ci, root.lerp(tip, .6), root.lerp(tip, .6) + Vector2(k * .12, -.22), Color("6b4316"), .05)
			if n >= 2:
				var tail := PackedVector2Array([Vector2(.5, .7), Vector2(.78, 1.25 + .05 * sin(t * 4.0)), Vector2(.52, 1.3), Vector2(.35, .75)])
				_f(ci, tail, Color("c8302c"))
			if n >= 3:
				_ar(ci, Vector2(0, -.15), 1.04, PI * 1.12, PI * 1.88, Color("3fa9f5"), .08)
				for k in [-1, 1]:
					_o(ci, Vector2(k * .98, -.18), .26, Color("3fa9f5"))
					_o(ci, Vector2(k * .98, -.18), .17, Color("bfe6ff"))
		# ----- Zorp (Cosmic Common): a little alien in a saucer.
		"ufodome":
			# Back: the glass dome round its head, with antennae (two from T4).
			for k in ([0] if n < 4 else [-1, 1]):
				var base := Vector2(k * .45, -.9)
				var tip := Vector2(k * .65, -1.45) + Vector2(sin(t * 3.0 + k) * .06, 0)
				_l(ci, base, tip, Color("4bd68a"), .06)
				_o(ci, tip, .1, Color("ff5d7a") if n < 5 else GOLD)
			_o(ci, Vector2(0, -.05), 1.2, Color(.6, 1, .85, .1 if n < 4 else .18))
			_ar(ci, Vector2(0, -.05), 1.2, PI * 1.05, PI * 1.95, Color(.8, 1, .95, .45), .05)
			_ar(ci, Vector2(0, -.05), 1.06, PI * 1.25, PI * 1.45, Color(1, 1, 1, .7), .06)
		"saucer":
			# Front: the saucer rim it rides in, lights chasing round it; more lights by tier,
			# a stripe at T3, and at T5 a gold rim with a tractor-beam glow under it.
			if n >= 5:
				_f(ci, PackedVector2Array([Vector2(-.7, .85), Vector2(.7, .85), Vector2(1.1, 1.75), Vector2(-1.1, 1.75)]), Color(.6, 1, .8, .32 + .08 * sin(t * 4.0)))
			var rim := Color("8a95a8") if n < 5 else GOLD
			_e(ci, Vector2(0, .72), 1.5, .38, _sh(rim, -.35))
			_e(ci, Vector2(0, .64), 1.5, .32, rim)
			_e(ci, Vector2(0, .58), 1.2, .14, _sh(rim, .3))
			if n >= 3:
				_s(ci, _ep(Vector2(0, .7), 1.32, .24, PI * .05, PI * .95, 16), Color("6f6bff"), .06)
			var lights := 3 if n < 2 else (5 if n < 4 else 7)
			for i in lights:
				var k := (i - (lights - 1) / 2.0) / ((lights - 1) / 2.0)
				var on := fmod(t * 3.0 - i * .35, 1.0) < .5
				var lc: Color = [Color("ffc93c"), Color("ff5d7a"), Color("5cf0b0")][i % 3] if n < 5 else A._hsl(t * 120.0 + i * 50.0, .9, .65)
				_o(ci, Vector2(k * 1.18, .74 + .12 * (1.0 - k * k)), .085, lc if on else _sh(lc, -.5))
		# ----- Snooze (Cosmic Uncommon): a sleepy moon.
		"craters":
			# Front: moon craters (more by tier); at T4 a crescent shadow creeps over its side.
			A._clip_on()
			var cr := [Vector2(-.55, -.5), Vector2(.6, .45), Vector2(-.3, .62), Vector2(.7, -.35), Vector2(-.78, .15)]
			for i in mini(cr.size(), 2 + n / 2):
				_o(ci, cr[i], .13 + .04 * (i % 2), _sh(c, -.18))
				_o(ci, cr[i] + Vector2(.02, .03), .09 + .04 * (i % 2), _sh(c, -.06))
			if n >= 4:
				_f(ci, _ep(Vector2(.55, 0), .8, 1.1, PI * -.5, PI * .5, 18) + _ep(Vector2(1.0, 0), .25, 1.1, PI * .5, PI * -.5, 10), Color(.18, .16, .4, .45))
			A._clip = false
		"nightcap":
			# Back: a floppy nightcap (stripes from T2, a star at T3, gold stars at T5)
			# and Zzz drifting up (one at T1, two at T3, three at T5 with a little orbit of stars).
			var flop := .06 * sin(t * 1.5)
			var cap := PackedVector2Array([Vector2(-.95, -.45), Vector2(-.6, -1.05), Vector2(.1, -1.25), Vector2(.85, -1.05 + flop), Vector2(1.3, -.4 + flop), Vector2(1.05, -.55), Vector2(.75, -.62), Vector2(.95, -.4)])
			var capcol := Color("4a46d6")
			_f(ci, cap, capcol)
			if n >= 2:
				for i in 3:
					var x := -.6 + i * .5
					_s(ci, PackedVector2Array([Vector2(x, -.55 - .1 * i), Vector2(x + .18, -1.12 + .03 * i)]), Color(1, 1, 1, .5), .08)
			var bob := Vector2(1.3, -.36 + flop)
			_o(ci, bob, .2, Color.WHITE if n < 5 else GOLD_LIGHT)
			if n >= 3:
				_st(ci, Vector2(-.05, -.95), .14, .06, 5, Color("ffd23f") if n < 5 else GOLD_LIGHT)
			if n >= 5:
				_st(ci, Vector2(.5, -.85), .1, .04, 5, GOLD)
				_o(ci, bob, .32, Color(1, .9, .5, .25 + .15 * sin(t * 3.0)))
				for i in 3:
					var a := t * .8 + i * TAU / 3.0
					_st(ci, Vector2(cos(a) * 1.45, sin(a) * .45 + .1), .1, .04, 4, Color(1, .95, .7, .85))
			var zs := 1 if n < 3 else (2 if n < 5 else 3)
			for i in zs:
				var q := fmod(t * .4 + i / 3.0, 1.0)
				A._utext(ci, Vector2(-1.0 - q * .5, -.7 - q * .9), "z", .42 + .2 * q, Color(.92, .94, 1, 1.0 - q * .8))
		# ----- Kernel (Fire Uncommon): popcorn.
		"popcorn":
			# Back: popped puffs on top, more each tier; at T3 butter drips, T4 steam,
			# T5 a towering golden crown of popcorn with kernels hopping off it.
			var puffs := [Vector2(-.3, -1.08), Vector2(.32, -1.1), Vector2(0, -1.32), Vector2(-.75, -.82), Vector2(.75, -.84), Vector2(-.32, -1.55), Vector2(.36, -1.52), Vector2(0, -1.78)]
			var cnt: int = [3, 4, 5, 6, 8][n - 1]
			for i in cnt:
				var p: Vector2 = puffs[i] + Vector2(0, .03 * sin(t * 4.0 + i))
				var pc := Color("fff6dc") if n < 5 else Color("fff1b0")
				for j in 4:
					var a: float = j * TAU / 4.0 + i
					_o(ci, p + Vector2(cos(a), sin(a)) * .12, .15, _sh(pc, -.12))
				for j in 4:
					var a: float = j * TAU / 4.0 + i
					_o(ci, p + Vector2(cos(a), sin(a)) * .1 + Vector2(-.02, -.03), .12, pc)
				_o(ci, p + Vector2(.02, .05), .05, Color("e3a52b"))
			if n >= 4:
				for i in 2:
					var q := fmod(t * .5 + i * .5, 1.0)
					_o(ci, Vector2(-.5 + i, -1.3 - q * .8), .1 + q * .14, Color(.88, .88, .94, .75 * (1.0 - q)))
			if n >= 5:
				for i in 3:
					var q := fmod(t * .9 + i / 3.0, 1.0)
					var x := -1.2 + i * 1.2
					_o(ci, Vector2(x + q * .3, -1.0 - sin(q * PI) * .7), .09, Color("fff6dc"))
		"kernelband":
			# Front: the kernel's pale tip and seam; butter drips at T3; a red-and-white
			# striped bucket band at T2, gold-trimmed at T5.
			A._clip_on()
			_f(ci, PackedVector2Array([Vector2(-.45, 1.0), Vector2(0, .55), Vector2(.45, 1.0)]), Color(1, .97, .85, .6))
			if n >= 2:
				A._urect(ci, -1, .62, 2, .4, Color.WHITE)
				for i in 6:
					A._urect(ci, -1 + i * .36, .62, .18, .4, Color("e8433f"))
				A._urect(ci, -1, .6, 2, .06, GOLD if n >= 5 else Color("c8302c"))
			A._clip = false
			if n >= 3:
				for i in 3:
					var x := -.55 + i * .5
					var L := .18 + .1 * _h(i) + .04 * sin(t * 2.0 + i)
					A._urect(ci, x - .05, -.72, .1, L, Color("ffd23f"), .05)
					_o(ci, Vector2(x, -.72 + L), .07, Color("ffd23f"))
		# ----- Gourdo (Spooky Uncommon): a jack-o'-lantern.
		"pumpkinface":
			# Front: ribs and a carved face lit from inside. The glow brightens by tier and
			# turns spooky violet fire at T5. The face follows where it's rolling.
			A._clip_on()
			for k in [-.55, 0.0, .55]:
				_s(ci, _q(Vector2(k * .7, -1.0), Vector2(k * 1.35, 0), Vector2(k * .7, 1.0), 12), _sh(c, -.35), .07)
			A._clip = false
			var glow := Color("ffe36b") if n < 3 else (Color("fff3a0") if n < 5 else Color("d6b0ff"))
			var fl := .75 + .25 * sin(t * 9.0) * sin(t * 5.3)
			var o := look * .12
			var hit: float = s.get("hit", 0.0)
			for k in [-1, 1]:
				var ec := o + Vector2(k * .36, -.2)
				var eye := PackedVector2Array([ec + Vector2(-.24, .16), ec + Vector2(k * .04, -.24), ec + Vector2(.24, .16)])
				if hit > 0.0:
					eye = PackedVector2Array([ec + Vector2(-.17, -.02), ec + Vector2(.17, -.06), ec + Vector2(.17, .04), ec + Vector2(-.17, .06)])
				_f(ci, eye, _sh(c, -.55))
				_f(ci, eye, glow.darkened(.25 * (1.0 - fl)))
			var m := o + Vector2(0, .3)
			var teeth := 3 if n < 4 else 4
			var mouth := PackedVector2Array([m + Vector2(-.62, -.1)])
			for i in range(1, teeth * 2):
				var x := -.56 + i * 1.12 / (teeth * 2)
				mouth.append(m + Vector2(x, .04 if i % 2 == 0 else -.1))
			mouth.append(m + Vector2(.62, -.1))
			mouth.append_array(_q(m + Vector2(.62, -.1), m + Vector2(0, .62), m + Vector2(-.62, -.1), 12).slice(1, 12))
			_f(ci, mouth, glow.darkened(.25 * (1.0 - fl)))
			if n >= 3:
				_o(ci, o + Vector2(0, .05), .9, Color(glow, .06 + .05 * fl))
		"pumpkinstem":
			# Back: the stem (a leaf at T2, a curly vine at T3, a bat flitting round at T4,
			# and at T5 a gold stem with violet ghost-fire wisps rising).
			var stem := Color("3f7a2a") if n < 5 else GOLD
			_f(ci, PackedVector2Array([Vector2(-.16, -.85), Vector2(-.12, -1.38), Vector2(.24, -1.52), Vector2(.16, -.85)]), stem)
			if n >= 2:
				_e(ci, Vector2(.42, -1.08), .28, .13, Color("4f9a3a"), -.5)
				_s(ci, PackedVector2Array([Vector2(.2, -1.0), Vector2(.62, -1.18)]), Color("2f6a22"), .03)
			if n >= 3:
				var vine := PackedVector2Array()
				for i in 16:
					var a := i * .55
					vine.append(Vector2(-.15 - i * .045, -1.1) + Vector2(cos(a), sin(a)) * .1 * (1.0 - i / 20.0))
				_s(ci, vine, Color("4f9a3a"), .035)
			if n >= 4:
				var a := t * 1.4
				var bp := Vector2(cos(a) * 1.4, sin(a) * .4 - .7)
				var flap := .1 + .08 * sin(t * 14.0)
				for k in [-1, 1]:
					_f(ci, PackedVector2Array([bp, bp + Vector2(k * .3, -flap), bp + Vector2(k * .22, .06), bp + Vector2(k * .12, .02)]), Color("2a1f4a"))
				_o(ci, bp, .08, Color("2a1f4a"))
			if n >= 5:
				for i in 4:
					var q := fmod(t * .7 + i / 4.0, 1.0)
					_tongue(ci, Vector2(-.6 + i * .4, -.75 - q * .3), -PI / 2 + sin(t * 3.0 + i) * .2, .35 * (1.0 - q * .5), .1, Color(.7, .45, 1, .55 * (1.0 - q)))
		# ----- Boomer (Toybox Uncommon): a painted wooden toy.
		"toystripes":
			# Front: painted bands (a second colour at T2, a headband at T3, painted stars at T4,
			# gold paint at T5).
			A._clip_on()
			A._urect(ci, -1, .42, 2, .16, Color("e8433f"))
			if n >= 2:
				A._urect(ci, -1, .64, 2, .12, Color("3fa9f5"))
			if n >= 5:
				A._urect(ci, -1, .54, 2, .06, GOLD)
			if n >= 3:
				A._urect(ci, -1, -.82, 2, .2, Color("5fd068"))
				for i in 4:
					_o(ci, Vector2(-.6 + i * .4, -.72), .04, Color.WHITE)
			A._clip = false
			if n >= 4:
				for p in [Vector2(-.72, .1), Vector2(.75, .05)]:
					_st(ci, p, .1, .045, 5, GOLD if n >= 5 else Color("ffc93c"))
		"boomerang":
			# Back: the boomerang it carries (painted tips at T2); at T5 two crossed
			# gold-tipped boomerangs with a spin-whoosh.
			var count := 1 if n < 5 else 2
			for j in count:
				var side := 1.0 - 2.0 * j
				var xf := Transform2D(side * (.42 + .06 * sin(t * 2.0 + j)), Vector2(side * .62, -1.12))
				for k in [-1, 1]:
					var arm := PackedVector2Array([xf * Vector2(0, -.18), xf * Vector2(k * .55, -.08), xf * Vector2(k * 1.0, .3)])
					A._utaper(ci, arm, .34, .24, _sh(Color("c98a3c"), -.25))
					A._utaper(ci, arm, .26, .17, Color("d99a4c"))
					if n >= 2:
						_o(ci, xf * Vector2(k * 1.0, .3), .14, GOLD if n >= 5 else Color("e8433f"))
			if n >= 5:
				_ar(ci, Vector2(0, -.9), 1.4, -PI * .95 + t, -PI * .6 + t, Color(1, 1, 1, .8), .05)
		# ----- Beans (Sweet Rare): a jelly bean.
		"beanspecks":
			# Front: speckles (more at T2), a shine stripe (T3), sugar sparkles (T4);
			# at T5 the specks cycle through every flavour colour.
			A._clip_on()
			var specks := 9 if n < 2 else 14
			for i in specks:
				var p := Vector2(_h(i) * 2.0 - 1.0, _h(i + 9) * 1.6 - .8) * .85
				if absf(p.y + .08) < .28 and absf(p.x) < .6:
					continue
				var sc := Color(1, 1, 1, .55) if n < 5 else A._hsl(t * 90.0 + i * 40.0, .9, .7)
				_e(ci, p, .05, .035, sc, _h(i + 3) * 3.0)
			A._clip = false
			if n >= 2:
				A._clip_on()
				_s(ci, _q(Vector2(-1.1, .55), Vector2(0, -.05), Vector2(1.1, .35), 14), _sh(c, -.18), .14)
				A._clip = false
			if n >= 3:
				_s(ci, _q(Vector2(-.75, -.45), Vector2(-.2, -.85), Vector2(.5, -.7), 12), Color(1, 1, 1, .45), .09)
			if n >= 4:
				for i in 3:
					_gl(ci, Vector2(-.9 + i * .9, -.95 + (i % 2) * .15), .12, t, i * 2.0)
		"beanbuddies":
			# Back: little flavour beans tag along (red and green at T3, blue too at T4,
			# a rainbow bean at T5).
			if n < 3:
				return
			var cols := [Color("ff5a1f"), Color("5fd068"), Color("3fa9f5")]
			var count := 2 if n < 4 else 3
			for i in count:
				var a := PI * (.8 + i * .2) + .08 * sin(t * 2.0 + i)
				var p := Vector2(cos(a), sin(a)) * 1.3 + Vector2(0, .3)
				_e(ci, p, .24, .17, _sh(cols[i], -.25), a)
				_e(ci, p + Vector2(-.03, -.03), .2, .13, cols[i], a)
				_e(ci, p + Vector2(-.08, -.07), .07, .04, Color(1, 1, 1, .6), a)
			if n >= 5:
				var p := Vector2(1.3, -.75) + Vector2(0, .05 * sin(t * 3.0))
				_e(ci, p, .26, .18, A._hsl(t * 120.0, .9, .6), -.6)
				_e(ci, p + Vector2(-.08, -.07), .08, .04, Color(1, 1, 1, .7), -.6)
				_gl(ci, p + Vector2(.2, -.2), .12, t)
		# ----- Shade (Spooky Rare): a living shadow.
		"shadowtwin":
			# Back: its shadow, a step behind (darker with eyes at T3, a second one at T5),
			# and smoky wisps trailing off it (more each tier).
			var back := -look.normalized() if look.length() > .01 else Vector2.LEFT
			var twins := 1 if n < 5 else 2
			for j in range(twins, 0, -1):
				var p := back * (.55 + .5 * j)
				var a := (.22 if n < 3 else .38) / j
				_o(ci, p, .92, Color(.2, .14, .4, a))
				if n >= 3:
					for k in [-1, 1]:
						_e(ci, p + Vector2(k * .28, -.1), .1, .14, Color(1, 1, 1, .45 / j))
			var wisps := 1 + n
			for i in wisps:
				var side := back.orthogonal() * ((i - (wisps - 1) / 2.0) * .32)
				var q := fmod(t * .8 + i * .37, 1.0)
				var base := back * .8 + side
				A._utaper(ci, PackedVector2Array([base, base + back * .5 + side * .3 + back.orthogonal() * sin(t * 3.0 + i) * .12, base + back * (.9 + .3 * q) + side * .5]), .26, .02, Color(.35, .25, .7, .5))
			if n >= 2:
				_ar(ci, Vector2.ZERO, 1.04, 0.0, TAU, Color(.69, .49, 1, .8 if n >= 4 else .45), .06 if n >= 4 else .035)
		"shadowcrown":
			# Front (T5): a crown of violet shadow-flame on its head.
			if n < 5:
				return
			for i in 5:
				var x := -.5 + i * .25
				_tongue(ci, Vector2(x, -.85 - absf(x) * .2), -PI / 2 + x * .5, .75 + .15 * sin(t * 6.0 + i) - absf(x) * .4, .2, Color(.6, .4, 1, .9))
				_tongue(ci, Vector2(x, -.85 - absf(x) * .2), -PI / 2 + x * .5, .4 + .08 * sin(t * 6.0 + i) - absf(x) * .2, .1, Color(.9, .85, 1, .95))
		# ----- Astra (Cosmic Rare): a constellation.
		"constellation":
			# Front: a star pattern on its starfield body; more stars join by tier, the lines
			# glow from T4 and turn gold at T5.
			for i in 10:
				var sp := Vector2(_h(i + 50) * 1.6 - .8, _h(i + 70) * 1.6 - .8)
				_o(ci, sp, .025 + .02 * _h(i), Color(1, 1, 1, .35 + .35 * absf(sin(t * 2.0 + i))))
			var pts := [Vector2(-.6, -.45), Vector2(-.15, -.68), Vector2(.4, -.5), Vector2(.62, .05), Vector2(.2, .5), Vector2(-.45, .42)]
			var cnt: int = [3, 4, 5, 6, 6][n - 1]
			var lc := Color(1, .85, .45, .55) if n < 4 else (Color(1, .9, .55, .75 + .2 * sin(t * 3.0)) if n < 5 else Color(GOLD, .9))
			var line := PackedVector2Array()
			for i in cnt:
				line.append(pts[i])
			if cnt >= 6:
				line.append(pts[0])
			_s(ci, line, lc, .035 if n < 4 else .05)
			if n >= 2:
				_gl(ci, Vector2(-.72, .7), .16, t, 1.0, Color("fff1b0"))
			for i in cnt:
				var k := .7 + .3 * sin(t * 4.0 + i * 1.7)
				_st(ci, pts[i], .12 * k, .045 * k, 4, Color("fff1b0"))
				_o(ci, pts[i], .05, Color.WHITE)
		"starpins":
			# Back (T3+): stars pinned out round it; at T5 three of them join into a
			# glowing triangle round the ball.
			if n < 3:
				return
			var pins := 1 if n < 4 else 2
			if n >= 5:
				pins = 3
			var ring := PackedVector2Array()
			for i in pins:
				var a := -PI / 2 + i * TAU / 3.0 + t * .25
				var p := Vector2(cos(a), sin(a)) * 1.5
				ring.append(p)
			if n >= 5:
				var tri := ring.duplicate()
				_f(ci, tri, Color(1, .82, .3, .08))
				tri.append(ring[0])
				_s(ci, tri, Color(1, .85, .4, .5), .03)
			for p in ring:
				_st(ci, p, .2, .07, 4, GOLD if n >= 5 else Color("fff1b0"))
				_o(ci, p, .07, Color.WHITE)
		# ----- Blaze (Fire Epic): wildfire.
		"blazecrest":
			# Back: a swept-back mane of yellow-hot flame (a tall crest of 3 tongues at T1,
			# 5 at T2, white-hot hearts at T3, flames down its sides at T4, and at T5
			# blue-hot tips and a flame tail streaming behind it).
			var lean := clampf(-look.x, -1.0, 1.0) * .45
			if n >= 5:
				var back := -look.normalized() if look.length() > .01 else Vector2.LEFT
				for i in 3:
					var b := back * .6 + back.orthogonal() * (i - 1) * .35
					_tongue(ci, b, back.angle() + (i - 1) * .25, 1.15 + .2 * sin(t * 8.0 + i), .42, Color("ff9a1f"))
					_tongue(ci, b, back.angle() + (i - 1) * .25, .75 + .1 * sin(t * 8.0 + i), .24, Color("fff3c4"))
			var tongues := 3 if n < 2 else (5 if n < 4 else 7)
			var spread := .55 if n < 2 else (.8 if n < 4 else 1.35)
			for i in tongues:
				var k := (i - (tongues - 1) / 2.0) / maxf(1.0, (tongues - 1) / 2.0)
				var a := -PI / 2 + k * spread
				var L := (1.45 - .55 * absf(k)) * (1.0 + .1 * sin(t * 9.0 + i * 1.3))
				var base := Vector2(cos(a), sin(a)) * .65
				var wob := a + lean + sin(t * 5.0 + i) * .08
				_tongue(ci, base, wob, L, .46, Color("ff9a1f"))
				_tongue(ci, base, wob, L * .78, .32, Color("ffd23f"))
				if n >= 3:
					_tongue(ci, base, wob, L * .45, .16, Color("fff8e0"))
				if n >= 5:
					_o(ci, base + Vector2(cos(wob), sin(wob)) * L * .6, .08, Color("8fd8ff"))
		"blazeembers":
			# Front: embers drifting up off it (more each tier, gold sparks at T5).
			var cnt := 2 + n
			for i in cnt:
				var q := fmod(t * .6 + _h(i) , 1.0)
				var p := Vector2((_h(i + 7) - .5) * 1.6 + sin(t * 2.0 + i) * .1, .4 - q * 2.2)
				_o(ci, p, .05 * (1.0 - q * .5), Color(1, .75 if n < 5 else .9, .3, 1.0 - q))
		# ----- Rift (Cosmic Epic): a wormhole.
		"portals":
			# Back: a pair of portal rings orbiting it (bigger with a swirl at T3, three at T5).
			var count := 2 if n < 5 else 3
			var big := .26 if n < 3 else .34
			for i in count:
				var a := t * .6 + i * TAU / count
				var p := Vector2(cos(a) * 1.5, sin(a) * .55 - .2)
				var pc := Color("b07cff") if i % 2 == 0 else Color("38e0d0")
				_e(ci, p, big, big * .5, Color(pc, .25))
				A._ustroke(ci, _ep(p, big, big * .5, 0.0, TAU, 20), pc, .06)
				if n >= 3:
					_ar(ci, p, big * .4, t * 3.0, t * 3.0 + 3.5, Color(1, 1, 1, .6), .03)
			if n >= 5:
				for i in 4:
					var q := fmod(t * .5 + i / 4.0, 1.0)
					var a := i * 1.7 + t * .3
					_o(ci, Vector2(cos(a), sin(a)) * (1.7 - q * .8), .04, Color(1, 1, 1, q))
		"riftrim":
			# Front: the event-horizon rim (glows violet at T4, gold-flecked at T5).
			if n < 2:
				return
			var w := .04 if n < 4 else .07
			_ar(ci, Vector2.ZERO, .98, t, t + PI * 1.3, Color(.7, .5, 1, .6), w)
			if n >= 4:
				_ar(ci, Vector2.ZERO, .98, t + PI, t + PI * 1.9, Color(.3, .95, .9, .6), w)
			if n >= 5:
				for i in 6:
					var a := -t * .8 + i * TAU / 6.0
					_gl(ci, Vector2(cos(a), sin(a)) * 1.0, .1, t, i, GOLD_LIGHT)
		# ----- Reaper (Spooky Legendary).
		"reaperhood":
			# Back: the hood, peaked over its head (a tattered hem at T3, gold trim at T5),
			# and from T4 lost souls drifting round it.
			var hc := Color("1d2033")
			var rim := _q(Vector2(-1.2, .6), Vector2(-1.45, -1.05), Vector2(.05, -1.5), 14)
			rim.append_array(_q(Vector2(.05, -1.5), Vector2(.55, -1.75 + .05 * sin(t * 1.6)), Vector2(.75, -1.35), 6))
			rim.append_array(_q(Vector2(.75, -1.35), Vector2(1.45, -.9), Vector2(1.2, .6), 12))
			var hood := rim.duplicate()
			if n >= 3:
				for i in 6:
					hood.append(Vector2(1.0 - i * .4, .6 + (.24 if i % 2 == 0 else .06)))
			_f(ci, hood, hc)
			_s(ci, _q(Vector2(-.95, -.6), Vector2(-.75, -1.25), Vector2(.05, -1.4), 10), Color(.4, .45, .65, .6), .05)
			if n >= 5:
				_s(ci, rim, GOLD, .06)
			if n >= 4:
				for i in 2 + int(n >= 5):
					var a := t * .9 + i * TAU / 3.0
					var p := Vector2(cos(a) * 1.55, sin(a) * .5 + .1)
					_o(ci, p, .13, Color(.55, .95, .95, .5))
					A._utaper(ci, PackedVector2Array([p, p + Vector2(-sin(a), cos(a) * .3) * .35]), .22, .02, Color(.55, .95, .95, .35))
		"scythe":
			# Back: the scythe (a shine on the blade at T2, an hourglass charm at T3,
			# and at T5 a gold-edged blade glowing ghost-blue).
			var sway := .05 * sin(t * 1.4)
			var xf := Transform2D(.35 + sway, Vector2(1.0, -.2))
			_l(ci, xf * Vector2(0, 1.4), xf * Vector2(0, -1.5), Color("4a3524"), .1)
			var blade := PackedVector2Array()
			blade.append_array(_q(xf * Vector2(0, -1.5), xf * Vector2(-.9, -1.85), xf * Vector2(-1.75, -1.15), 12))
			blade.append_array(_q(xf * Vector2(-1.75, -1.15), xf * Vector2(-.85, -1.45), xf * Vector2(0, -1.25), 12))
			if n >= 5:
				var gb := PackedVector2Array()
				for p in blade:
					gb.append(p)
				_f(ci, gb, Color(.4, 1, 1, .22 + .1 * sin(t * 4.0)))
			_f(ci, blade, Color("c9d3ea"))
			if n >= 2:
				_s(ci, _q(xf * Vector2(-.25, -1.5), xf * Vector2(-.9, -1.75), xf * Vector2(-1.55, -1.25), 10), Color(1, 1, 1, .8), .04)
			if n >= 5:
				_s(ci, _q(xf * Vector2(0, -1.5), xf * Vector2(-.9, -1.85), xf * Vector2(-1.75, -1.15), 12), GOLD, .05)
			if n >= 3:
				var hp := xf * Vector2(0, -1.05)
				_f(ci, PackedVector2Array([hp + Vector2(-.12, -.15), hp + Vector2(.12, -.15), hp, hp + Vector2(.12, .15), hp + Vector2(-.12, .15), hp]), GOLD)
				_o(ci, hp + Vector2(0, .08), .05, Color(.55, .95, .95))
		"reaperface":
			# Front: the dark hole in the hood its eyes glow out of (the glow brightens by tier).
			_e(ci, Vector2(look.x * .08, -.05), .74, .64, Color("05060d"))
			if n >= 2:
				_l(ci, Vector2(-.3, .76), Vector2(.3, .76), Color("8a95a8"), .05)
				for k in [-1, 1]:
					_o(ci, Vector2(k * .3, .76), .1, GOLD if n >= 5 else Color("c9d3ea"))
			if n >= 3:
				_e(ci, Vector2(look.x * .08, -.05), .8, .7, Color(.36, .94, .94, .06 + .03 * n))
		# ----- Choo (Toybox Legendary): a toy steam train.
		"chimney":
			# Back: the smokestack puffing smoke (a bell at T2, a whistle of steam at T4;
			# gold stack and rainbow puffs at T5).
			var sc := Color("1c1c26") if n < 5 else GOLD
			A._urect(ci, .25, -1.45, .32, .62, sc, .04)
			A._urect(ci, .17, -1.55, .48, .16, _sh(sc, .15), .05)
			for i in 3:
				var q := fmod(t * .6 + i / 3.0, 1.0)
				var pc := Color(.9, .9, .95, .7 * (1.0 - q)) if n < 5 else Color(A._hsl(i * 120.0 + t * 60.0, .8, .75), .8 * (1.0 - q))
				_o(ci, Vector2(.41 + q * .5, -1.7 - q * .7), .12 + q * .2, pc)
			if n >= 2:
				var sw := .12 * sin(t * 5.0)
				_f(ci, PackedVector2Array([Vector2(-.45, -.95), Vector2(-.6 + sw * .2, -1.25), Vector2(-.3 + sw * .2, -1.25)]), GOLD)
				_o(ci, Vector2(-.45 + sw * .2, -1.3), .07, GOLD)
			if n >= 4:
				for i in 2:
					var q := fmod(t * 1.1 + i * .5, 1.0)
					_o(ci, Vector2(-.95 - q * .4, -.7 - q * .3), .07 + q * .1, Color(1, 1, 1, .6 * (1.0 - q)))
		"wheels":
			# Back: wheels peeking out below (gold hubs at T3, spokes spin; six wheels and
			# a stretch of rails at T5).
			var spin := t * 3.0
			var xs := [-.65, .65] if n < 5 else [-.85, 0.0, .85]
			if n >= 5:
				_l(ci, Vector2(-1.6, 1.28), Vector2(1.6, 1.28), Color("c98a3c"), .07)
				for i in 7:
					_l(ci, Vector2(-1.5 + i * .5, 1.2), Vector2(-1.5 + i * .5, 1.38), Color("8a5a00"), .06)
			for x in xs:
				var p := Vector2(x, .82)
				_o(ci, p, .34, Color("2a2a36"))
				_o(ci, p, .26, Color("e8433f") if n < 3 else GOLD)
				for k in 3:
					var a := spin + k * PI / 3.0
					_l(ci, p - Vector2(cos(a), sin(a)) * .24, p + Vector2(cos(a), sin(a)) * .24, Color("8a5a00"), .04)
				_o(ci, p, .07, Color("2a2a36"))
		"cowcatcher":
			# Front: boiler bands (gold from T3), the cow-catcher grille, and a headlamp at T3
			# that throws a beam at T5.
			A._clip_on()
			A._urect(ci, -1, -.6, 2, .1, Color("2a2a36") if n < 3 else GOLD)
			A._urect(ci, -1, .5, 2, .1, Color("2a2a36") if n < 3 else GOLD)
			A._clip = false
			var g := PackedVector2Array([Vector2(-.55, .78), Vector2(.55, .78), Vector2(0, 1.12)])
			_f(ci, g, Color("2a2a36") if n < 4 else GOLD)
			for i in 3:
				_l(ci, Vector2(-.36 + i * .36, .8), Vector2(0, 1.08), Color("8a5a00"), .03)
			if n >= 3:
				var lp := Vector2(look.x * .3, -.82)
				if n >= 5:
					var d := look.normalized() if look.length() > .01 else Vector2.RIGHT
					_f(ci, PackedVector2Array([lp, lp + d.rotated(-.3) * 1.3, lp + d.rotated(.3) * 1.3]), Color(1, .95, .6, .2 + .08 * sin(t * 5.0)))
				_o(ci, lp, .16, Color("2a2a36"))
				_o(ci, lp, .11, Color("fff1b0"))
