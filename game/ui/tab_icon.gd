## The bottom tab bar's icons, in the Neon Critters look: a critter face,
## a loot sack, the Play ball, two balls fusing and a Summon Egg. Lit (full
## colour, a soft glow, sparkles) on the open tab, dim and flat on the rest.
## Static: drawn once and again only when `set_active` flips. Render-only.
extends Control

const Dot := preload("res://game/dot.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const DIM := Color("4a4580") ## What an idle tab's colours fade towards.
const INK := Color("0b0a1f")
const ACCENT := Color("8f7bff")

var kind := "critters"
var active := false


static func make(kind_: String, side: float) -> Control:
	var g = load("res://game/ui/tab_icon.gd").new()
	g.kind = kind_
	g.custom_minimum_size = Vector2(side, side)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return g


func set_active(on: bool) -> void:
	if on != active:
		active = on
		queue_redraw()


## A colour as this tab shows it: itself when lit, faded when idle.
func _c(col: Color) -> Color:
	return col if active else col.lerp(DIM, .45)


func _glow(c: Vector2, r: float, col: Color) -> void:
	if active:
		Dot.circle(self, c, r, Color(col, .12))
		Dot.circle(self, c, r * .8, Color(col, .14))


func _sparkle(p: Vector2, r: float, col := Color.WHITE) -> void:
	if active:
		Dot.poly(self, CritterArt.star_pts(p, r, r * .3, 4), col)


func _draw() -> void:
	var s := size.y
	var c := Vector2(size.x / 2.0, s / 2.0)
	var u := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	match kind:
		"critters":
			var body := Color("39c6ff")
			_glow(u.call(0, .04), s * .54, body)
			for side in [-1.0, 1.0]:
				draw_line(u.call(side * .12, -.2), u.call(side * .22, -.4), _c(Color("1a8fd6")), s * .06, true)
				Dot.circle(self, u.call(side * .22, -.41), s * .07, _c(Color("ffd45c")))
			Dot.circle(self, u.call(0, .06), s * .38, _c(Color("1a7fc4")))
			Dot.circle(self, u.call(-.03, .03), s * .33, _c(body))
			Dot.circle(self, u.call(-.17, -.1), s * .07, _c(Color(1, 1, 1, .55)))
			for side in [-1.0, 1.0]:
				Dot.circle(self, u.call(side * .13, .01), s * .1, _c(Color.WHITE))
				Dot.circle(self, u.call(side * .13 + .03, .0), s * .052, INK)
			draw_arc(u.call(0, .12), s * .1, .15 * PI, .85 * PI, 10, INK, s * .05, true)
		"bag":
			var sack := Color("ffb347")
			_glow(u.call(0, .08), s * .54, sack)
			# Tuft above the tie, then the round sack, then the red cord.
			Dot.poly(self, PackedVector2Array([u.call(-.24, -.42), u.call(0, -.24), u.call(.24, -.42), u.call(.14, -.18), u.call(-.14, -.18)]), _c(Color("d98a2b")))
			Dot.circle(self, u.call(0, .14), s * .36, _c(Color("c9782a")))
			Dot.circle(self, u.call(-.03, .11), s * .32, _c(sack))
			Dot.poly(self, PackedVector2Array([u.call(-.16, -.2), u.call(.16, -.2), u.call(.26, -.02), u.call(-.26, -.02)]), _c(sack))
			draw_line(u.call(-.19, -.17), u.call(.19, -.17), _c(Color("ff5a7a")), s * .08, true)
			Dot.poly(self, CritterArt.star_pts(u.call(0, .17), s * .15, s * .065, 5), _c(Color("fff1b0")))
			Dot.circle(self, u.call(-.18, .02), s * .05, _c(Color(1, 1, 1, .5)))
			_sparkle(u.call(.36, -.3), s * .11)
			_sparkle(u.call(-.38, .3), s * .07, Color("ffe066"))
		"play":
			# Lit only on Play's own home: the big call to action. Elsewhere
			# a dark disc with a violet rim, so it still reads as a button.
			if active:
				Dot.circle(self, c, s * .5, Color(ACCENT, .22))
				Dot.circle(self, c, s * .48, Color("ff5ad6"))
				Dot.circle(self, c, s * .43, ACCENT)
				Dot.circle(self, u.call(-.03, -.05), s * .34, Color("a593ff"))
				Dot.circle(self, u.call(-.17, -.18), s * .06, Color(1, 1, 1, .5))
			else:
				Dot.circle(self, c, s * .48, ACCENT)
				Dot.circle(self, c, s * .43, Color("1b1842"))
			var tri := PackedVector2Array([u.call(-.12, -.2), u.call(.23, 0), u.call(-.12, .2)])
			if active:
				var drop := PackedVector2Array()
				for p in tri:
					drop.append(p + Vector2(.02, .03) * s)
				Dot.poly(self, drop, Color("3a2a99"))
			var col := Color.WHITE if active else ACCENT
			Dot.poly(self, tri, col)
			tri.append(tri[0])
			draw_polyline(tri, col, s * .05, true) # Softens the corners.
		"fuse":
			_glow(u.call(0, .04), s * .54, Color("ff5ad6"))
			var pink := Color("ff5ad6")
			var cyan := Color("39c6ff")
			for k in 2:
				var y := .0 + k * .16
				draw_line(u.call(-.5, y - .02), u.call(-.4, y - .02), _c(Color(pink, .7)), s * .05, true)
				draw_line(u.call(.4, y - .02), u.call(.5, y - .02), _c(Color(cyan, .7)), s * .05, true)
			Dot.circle(self, u.call(-.17, .06), s * .25, _c(Color("c23a9e")))
			Dot.circle(self, u.call(-.19, .04), s * .21, _c(pink))
			Dot.circle(self, u.call(.17, .06), s * .25, _c(Color("1a7fc4")))
			Dot.circle(self, u.call(.15, .04), s * .21, _c(cyan))
			Dot.circle(self, u.call(-.27, -.05), s * .05, _c(Color(1, 1, 1, .6)))
			Dot.circle(self, u.call(.07, -.05), s * .05, _c(Color(1, 1, 1, .6)))
			# The spark where they meet.
			Dot.poly(self, CritterArt.star_pts(u.call(0, .04), s * .24, s * .07, 4), _c(Color("ffe066")))
			Dot.circle(self, u.call(0, .04), s * .06, _c(Color.WHITE))
			_sparkle(u.call(.02, -.36), s * .09)
		"summon":
			var shell := Color("c86bff")
			_glow(u.call(0, .04), s * .54, shell)
			var egg := PackedVector2Array()
			var inner := PackedVector2Array()
			for i in 24:
				var a := i * TAU / 24.0
				var q := Vector2(cos(a) * .34, sin(a) * (.44 if sin(a) < 0.0 else .38) + .06)
				egg.append(c + q * s)
				inner.append(c + (q * .86 + Vector2(-.03, -.02)) * s)
			Dot.poly(self, egg, _c(Color("8a3fd6")))
			Dot.poly(self, inner, _c(shell))
			# A zigzag crack across the middle, light leaking out of it.
			var crack := PackedVector2Array()
			for i in 7:
				crack.append(u.call(-.3 + i * .1, (.0 if i % 2 == 0 else .08)))
			draw_polyline(crack, _c(Color("ffe9ff")), s * .055, true)
			Dot.poly(self, CritterArt.star_pts(u.call(0, -.18), s * .11, s * .045, 5), _c(Color("ffe9ff")))
			Dot.circle(self, u.call(-.15, -.24), s * .055, _c(Color(1, 1, 1, .7)))
			_sparkle(u.call(.38, -.3), s * .11)
			_sparkle(u.call(-.38, -.08), s * .07, Color("ffe9ff"))
			_sparkle(u.call(.34, .32), s * .06, Color("ffe066"))
