## Critter Plunge finish dressing: the checkered line stays the rule, and
## each course dresses it as somewhere to land, a pair of its own props
## either side of the line and an arch in its colour over it (a candy jar on
## Gumdrop Drop, a steam pool on Lava Tubes, a treasure chest in the Kelp
## Forest). Render only, a handful of draw calls, drawn only when the line
## is on screen.
extends RefCounted

const Dot := preload("res://game/dot.gd")


## Paints course `id`'s finish on `cv` with the line at screen y `fy`, the
## shaft `w` pixels wide and `s` pixels per world unit; `tint` is the
## course's piece colour, `t` the race clock for the little animations.
static func paint(cv: CanvasItem, id: String, fy: float, w: float, s: float, tint: Color, t: float) -> void:
	# The arch: two posts and a banner across, under the props.
	var post := 26.0 * s
	for x in [post, w - post]:
		Dot.rect(cv, Rect2(x - post / 2.0, fy - 150.0 * s, post, 190.0 * s), tint.darkened(0.35))
	Dot.rect(cv, Rect2(0.0, fy - 170.0 * s, w, 34.0 * s), tint.darkened(0.2))
	Dot.rect(cv, Rect2(0.0, fy - 166.0 * s, w, 8.0 * s), Color(tint.lightened(0.5), 0.6))
	for side in [-1.0, 1.0]:
		var c := Vector2(w / 2.0 + side * (w / 2.0 - 120.0 * s), fy + 110.0 * s)
		_prop(cv, id, c, 70.0 * s, tint, t, side)


## One prop, `r` pixels in radius, centred at `c`.
static func _prop(cv: CanvasItem, id: String, c: Vector2, r: float, tint: Color, t: float, side: float) -> void:
	match id:
		"gumdrop": # A candy jar of gumballs.
			Dot.circle(cv, c + Vector2(0, r * 0.15), r, Color(1, 1, 1, 0.25))
			for k in 7:
				var a := k * 2.4
				Dot.circle(cv, c + Vector2(cos(a), sin(a) * 0.6 + 0.4) * r * 0.55, r * 0.22, [Color("ff5d8f"), Color("ffd166"), Color("7cf5d0"), Color("5fd4ff")][k % 4])
			Dot.rect(cv, Rect2(c.x - r * 0.5, c.y - r * 1.05, r, r * 0.25), tint)
		"honey": # A honey pot, dripping.
			Dot.circle(cv, c, r * 0.85, Color("c9822a"))
			Dot.rect(cv, Rect2(c.x - r * 0.6, c.y - r * 0.95, r * 1.2, r * 0.3), Color("8a5a1c"))
			Dot.circle(cv, c + Vector2(r * 0.3, -r * 0.6 + fmod(t * 20.0, r * 0.8)), r * 0.12, Color("ffcf4d"))
		"sunstone": # A temple door between columns.
			Dot.rect(cv, Rect2(c.x - r * 0.9, c.y - r, r * 0.3, r * 2.0), Color("c9b48a"))
			Dot.rect(cv, Rect2(c.x + r * 0.6, c.y - r, r * 0.3, r * 2.0), Color("c9b48a"))
			Dot.rect(cv, Rect2(c.x - r * 0.55, c.y - r * 0.7, r * 1.1, r * 1.7), Color("3a2a18"))
			Dot.circle(cv, c + Vector2(0, -r * 1.1), r * 0.35, Color("ffd76a"))
		"vines": # A stone idol's face.
			Dot.circle(cv, c, r, Color("8c8a74"))
			for x in [-0.35, 0.35]:
				Dot.circle(cv, c + Vector2(x, -0.15) * r, r * 0.16, Color("2a2a1e"))
			Dot.rect(cv, Rect2(c.x - r * 0.4, c.y + r * 0.25, r * 0.8, r * 0.3), Color("2a2a1e"))
		"nebula": # A star gate, its ring turning.
			Dot.ring(cv, c, r, r * 0.18, Color("b38cff"))
			Dot.circle(cv, c, r * 0.8, Color(0.4, 0.2, 0.8, 0.35))
			Dot.circle(cv, c + Vector2(cos(t * 2.0), sin(t * 2.0)) * r, r * 0.14, Color.WHITE)
		"rocks": # A smoking crater.
			Dot.circle(cv, c + Vector2(0, r * 0.3), r, Color("3a332c"))
			Dot.circle(cv, c + Vector2(0, r * 0.35), r * 0.7, Color("1c1814"))
			Dot.circle(cv, c + Vector2(0, -r * 0.4 - fmod(t * 15.0, r * 0.6)), r * 0.2, Color(1, 1, 1, 0.2))
		"kelp": # A treasure chest.
			Dot.rect(cv, Rect2(c.x - r, c.y - r * 0.3, r * 2.0, r), Color("8a5a2c"))
			Dot.rect(cv, Rect2(c.x - r, c.y - r * 0.7, r * 2.0, r * 0.4), Color("a86a34"))
			Dot.rect(cv, Rect2(c.x - r * 0.15, c.y - r * 0.4, r * 0.3, r * 0.35), Color("ffd166"))
			Dot.circle(cv, c + Vector2(r * 0.5, -r * 0.8), r * 0.15, Color("ffd166"))
		"trench": # A sub hatch with bolts.
			Dot.circle(cv, c, r, Color("5a6a78"))
			Dot.ring(cv, c, r * 0.75, r * 0.12, Color("9aaabb"))
			for k in 6:
				Dot.circle(cv, c + Vector2.from_angle(k * TAU / 6.0) * r * 0.88, r * 0.08, Color("2a3440"))
		"clouds": # A rainbow coming down into a cloud.
			for k in 4:
				Dot.arc(cv, c + Vector2(-side * r, r * 0.4), r * (1.3 - k * 0.15), PI, PI * 1.5 if side > 0 else TAU, 16, [Color("ff6b8a"), Color("ffd166"), Color("7cf5d0"), Color("5fd4ff")][k], r * 0.14)
			for k in 3:
				Dot.circle(cv, c + Vector2((k - 1) * r * 0.45, r * 0.35), r * 0.38, Color.WHITE)
		"storm": # A flashing lightning bolt.
			var on := fmod(t, 2.0) < 0.15
			Dot.poly(cv, PackedVector2Array([c + Vector2(0.1, -1.0) * r, c + Vector2(-0.4, 0.1) * r, c + Vector2(0.0, 0.1) * r,
				c + Vector2(-0.2, 1.0) * r, c + Vector2(0.45, -0.2) * r, c + Vector2(0.05, -0.2) * r]), Color("fff3a0") if on else Color("ffd166"))
		"icicles": # A snowdrift.
			for k in 3:
				Dot.circle(cv, c + Vector2((k - 1) * r * 0.6, r * 0.3 - (0.3 if k == 1 else 0.0) * r), r * 0.6, Color("f4fbff"))
		"crystal": # A cracked-open geode.
			Dot.circle(cv, c, r, Color("4a3a5e"))
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.45
				Dot.poly(cv, PackedVector2Array([c + Vector2.from_angle(a - 0.15) * r * 0.2, c + Vector2.from_angle(a) * r * 0.85, c + Vector2.from_angle(a + 0.15) * r * 0.2]), Color("8ff0ff"))
		"lava": # A steaming cooling pool.
			Dot.circle(cv, c + Vector2(0, r * 0.4), r, Color("ff7a1f"))
			Dot.circle(cv, c + Vector2(0, r * 0.4), r * 0.7, Color("ffb040"))
			for k in 2:
				Dot.circle(cv, c + Vector2((k - 0.5) * r * 0.6, -fmod(t * 25.0 + k * 30.0, r * 1.2)), r * 0.25, Color(1, 1, 1, 0.2))
		"sunset": # A neon sign, flickering.
			var lit := Color("ff5fd2") if fmod(t, 1.7) > 0.1 else Color("ff5fd2").darkened(0.5)
			Dot.rect(cv, Rect2(c.x - r, c.y - r * 0.5, r * 2.0, r), Color("1d0b2c"))
			Dot.ring(cv, c, r * 0.4, r * 0.1, lit)
		"glitch": # Pixel blocks.
			for k in 6:
				var cell := Vector2((k % 3 - 1) * 0.6, (k / 3 - 0.5) * 0.6) * r
				var on := int(t * 4.0 + k) % 3 != 0
				Dot.rect(cv, Rect2(c + cell - Vector2.ONE * r * 0.25, Vector2.ONE * r * 0.5), Color("5cf2ff") if on else Color("ff5fd2"))
		"dunes": # A sandstone gate.
			Dot.rect(cv, Rect2(c.x - r, c.y - r, r * 2.0, r * 2.0), Color("c9924d"))
			Dot.rect(cv, Rect2(c.x - r * 0.45, c.y - r * 0.4, r * 0.9, r * 1.4), Color("5a3a1a"))
			Dot.circle(cv, c + Vector2(0, -r * 0.4), r * 0.45, Color("5a3a1a"))
		"graves": # A crypt gate's bars.
			Dot.rect(cv, Rect2(c.x - r, c.y - r * 0.8, r * 2.0, r * 1.6), Color("2a2e36"))
			for k in 5:
				Dot.rect(cv, Rect2(c.x - r * 0.8 + k * r * 0.4, c.y - r * 0.7, r * 0.08, r * 1.4), Color("9db0b8"))
		"manor": # A grandfather clock, its pendulum swinging.
			Dot.rect(cv, Rect2(c.x - r * 0.4, c.y - r * 1.1, r * 0.8, r * 2.2), Color("4a2a3a"))
			Dot.circle(cv, c + Vector2(0, -r * 0.7), r * 0.32, Color("f4e8c8"))
			Dot.line(cv, c + Vector2(0, -r * 0.2), c + Vector2(sin(t * 3.0) * r * 0.2, r * 0.7), Color("ffd166"), r * 0.08)
		"toys": # A jack-in-the-box, bobbing.
			Dot.rect(cv, Rect2(c.x - r * 0.6, c.y, r * 1.2, r * 0.9), Color("ff5d8f"))
			var up := absf(sin(t * 2.0)) * r * 0.4
			Dot.line(cv, c, c - Vector2(0, r * 0.4 + up), Color("ffd166"), r * 0.12)
			Dot.circle(cv, c - Vector2(0, r * 0.7 + up), r * 0.35, Color("ffe8b8"))
		"pinball": # Jackpot lights chasing.
			for k in 5:
				var on := int(t * 6.0) % 5 == k
				Dot.circle(cv, c + Vector2((k - 2) * r * 0.42, 0), r * 0.17, Color("ffd166") if on else Color("ff6fae").darkened(0.4))
		_:
			Dot.circle(cv, c, r * 0.6, Color(tint, 0.6))
