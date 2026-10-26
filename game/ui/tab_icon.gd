## The bottom tab bar's icons, in the Neon Critters look: Count Nibbles and
## Optic, a loot sack, the Play ball, two balls fusing and a Summon Egg. Lit (full
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
	g._tint()
	return g


func set_active(on: bool) -> void:
	if on != active:
		active = on
		_tint()
		queue_redraw()


## The critter art has its own colours, so an idle Critters tab is dimmed whole.
func _tint() -> void:
	if kind == "critters":
		self_modulate = Color.WHITE if active else Color(.62, .6, .78)


## A colour as this tab shows it: itself when lit, faded when idle.
func _c(col: Color) -> Color:
	return col if active else col.lerp(DIM, .45)


func _glow(c: Vector2, r: float, col: Color) -> void:
	if active:
		Dot.glow(self, c, r * 1.1, Color(col, .26), .35)


func _sparkle(p: Vector2, r: float, col := Color.WHITE) -> void:
	if active:
		Dot.poly(self, CritterArt.star_pts(p, r, r * .3, 4), col)


func _draw() -> void:
	var s := size.y
	var c := Vector2(size.x / 2.0, s / 2.0)
	var u := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	match kind:
		"critters":
			# Count Nibbles and Optic, drawn like their real art, side by side.
			_glow(u.call(0, .04), s * .54, Color("39c6ff"))
			CritterArt.draw_critter(self, "vampire", u.call(-.2, .1), s * .31, {"look": Vector2(.6, .2)})
			CritterArt.draw_critter(self, "laser", u.call(.22, .12), s * .29, {"look": Vector2(-.6, .1)})
		"bag":
			var sack := Color("ffb347")
			_glow(u.call(0, .08), s * .54, sack)
			# Tuft above the tie, then the round sack, then the red cord.
			Dot.poly(self, PackedVector2Array([u.call(-.24, -.42), u.call(0, -.24), u.call(.24, -.42), u.call(.14, -.18), u.call(-.14, -.18)]), _c(Color("d98a2b")))
			Dot.circle(self, u.call(0, .14), s * .36, _c(Color("c9782a")))
			Dot.circle(self, u.call(-.03, .11), s * .32, _c(sack))
			Dot.poly(self, PackedVector2Array([u.call(-.16, -.2), u.call(.16, -.2), u.call(.26, -.02), u.call(-.26, -.02)]), _c(sack))
			Dot.line(self, u.call(-.19, -.17), u.call(.19, -.17), _c(Color("ff5a7a")), s * .08, true)
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
			Dot.pline(self, tri, col, s * .05, true) # Softens the corners.
		"fuse":
			_glow(u.call(0, .04), s * .54, Color("ff5ad6"))
			var pink := Color("ff5ad6")
			var cyan := Color("39c6ff")
			for k in 2:
				var y := .0 + k * .16
				Dot.line(self, u.call(-.5, y - .02), u.call(-.4, y - .02), _c(Color(pink, .7)), s * .05, true)
				Dot.line(self, u.call(.4, y - .02), u.call(.5, y - .02), _c(Color(cyan, .7)), s * .05, true)
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
			# A matte creature egg (the summon screen's eggs): bone shell lit
			# from the top left, speckles, a hairline crack, a thin violet rim.
			var shell := Color("ddd2bd").lerp(Color("c86bff"), .22).darkened(.1)
			_glow(u.call(0, .04), s * .5, Color("c86bff"))
			var egg := PackedVector2Array()
			var lit := PackedVector2Array()
			for i in 28:
				var a := i * TAU / 28.0
				var q := Vector2(cos(a) * .32 * (1.0 - .14 * maxf(0.0, -sin(a))), sin(a) * (.44 if sin(a) < 0.0 else .36) + .06)
				egg.append(c + q * s)
				lit.append(c + (q * .9 + Vector2(-.02, -.03)) * s)
			Dot.poly(self, egg, _c(shell.darkened(.3)))
			Dot.poly(self, lit, _c(shell))
			for p in [Vector2(-.12, -.18), Vector2(.12, -.06), Vector2(-.04, .2), Vector2(.16, .24), Vector2(-.18, .1), Vector2(.05, -.28)]:
				Dot.circle(self, u.call(p.x, p.y), s * .025, _c(Color(shell.darkened(.45), .55)))
			Dot.pline(self, PackedVector2Array([u.call(-.04, -.36), u.call(.03, -.25), u.call(-.03, -.17), u.call(.05, -.08)]), _c(shell.darkened(.5)), s * .025, true)
			egg.append(egg[0])
			Dot.pline(self, egg, _c(Color("a46be0")), s * .035, true)
			Dot.circle(self, u.call(-.13, -.2), s * .06, _c(Color(1, 1, 1, .2)))
			_sparkle(u.call(.36, -.3), s * .09)
