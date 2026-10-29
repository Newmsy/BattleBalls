## Small drawn icons the font doesn't have: tier stars, power bolt, energy,
## coins, hammers, Summon Eggs, Glow Gems, the pass star, gear (slot icons shell, core,
## charm, plus one icon per gear type), locks, the back arrow, the info "i"
## the tab icons and the home mode icons (target, bounce, tower, vault, ghost,
## friends, map, swords, sparkle), the Arena's trophy, shield and token, the
## stat heads (heart, speed), the Rift Key and the Spark Dye drop.
extends Control

const Dot := preload("res://game/dot.gd")

const CritterArt := preload("res://game/ui/critter_art.gd")
const GOLD := Color("ffc23d")
const OFF := Color("3b3770")

var kind := "stars"
var count := 1
var of := 0 ## For stars: total slots drawn (dim ones after `count`).
var color := Color.WHITE


static func make(kind_: String, side: float, color_ := Color.WHITE, count_ := 1, of_ := 0) -> Control:
	var g = load("res://game/ui/glyph.gd").new()
	g.kind = kind_
	g.color = color_
	g.count = count_
	g.of = of_
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Drawn from its own height: a taller row must not blow the icon up.
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var slots: int = maxi(count_, of_) if kind_ == "stars" else 1
	g.custom_minimum_size = Vector2(side * slots * (.92 if kind_ == "stars" else 1.0), side)
	return g


func _draw() -> void:
	var s := size.y
	var c := Vector2(s / 2.0, s / 2.0)
	match kind:
		"stars":
			var slots := maxi(count, of)
			var step := custom_minimum_size.x / slots
			for i in slots:
				var p := Vector2(step * (i + .5), s / 2.0)
				Dot.poly(self, CritterArt.star_pts(p, s * .48, s * .2, 5), GOLD if i < count else OFF)
		"bolt":
			var pts := PackedVector2Array([Vector2(.58, .02), Vector2(.15, .58), Vector2(.47, .58), Vector2(.38, .98), Vector2(.85, .38), Vector2(.53, .38)])
			for i in pts.size():
				pts[i] = pts[i] * s
			Dot.poly(self, pts, color)
		"energy":
			# A charged cell: a blue disc with a darker rim and a sheen, and a
			# white-hot bolt with a dark edge.
			Dot.circle(self, c, s * .5, Color("2a9fd0"))
			Dot.circle(self, c + Vector2(0, -s * .03), s * .43, Color("5ce1ff"))
			Dot.circle(self, c + Vector2(-s * .14, -s * .2), s * .1, Color(1, 1, 1, .35))
			var pts := PackedVector2Array([Vector2(.58, .14), Vector2(.28, .56), Vector2(.48, .56), Vector2(.42, .86), Vector2(.72, .44), Vector2(.52, .44)])
			for i in pts.size():
				pts[i] = pts[i] * s
			var edge := PackedVector2Array()
			for q in pts:
				edge.append(c + (q - c) * 1.18)
			Dot.poly(self, edge, Color("0b3a55"))
			Dot.poly(self, pts, Color("f4fdff"))
		"coin":
			# A minted coin: a darker milled rim, a raised face with an inner
			# ring and a pressed star, and a glint top left.
			Dot.circle(self, c, s * .5, Color("c8901c"))
			Dot.circle(self, c + Vector2(0, -s * .02), s * .44, Color("ffd45c"))
			Dot.arc(self, c, s * .32, 0, TAU, 24, Color("d9a22e"), s * .05, true)
			Dot.poly(self, CritterArt.star_pts(c + Vector2(0, s * .01), s * .2, s * .09, 5), Color("d9a22e"))
			Dot.poly(self, CritterArt.star_pts(c, s * .2, s * .09, 5), Color("fff0b0"))
			Dot.circle(self, c + Vector2(-s * .2, -s * .2), s * .06, Color(1, 1, 1, .6))
		"medal_gold", "medal_silver", "medal_bronze":
			# Critter Plunge medals: a V ribbon over a milled disc with a
			# raised face, a pressed star and a glint.
			var tones: Array = {"medal_gold": ["c8901c", "ffd45c", "fff0b0"], "medal_silver": ["8a93a8", "dfe5f0", "ffffff"],
				"medal_bronze": ["8a4b1f", "d98a4a", "ffd0a8"]}[kind]
			var top := c + Vector2(0, -s * .5)
			Dot.poly(self, PackedVector2Array([top + Vector2(-s * .3, 0), top + Vector2(-s * .1, 0), c + Vector2(s * .06, -s * .02), c + Vector2(-s * .14, -s * .02)]), Color("3fa9f5"))
			Dot.poly(self, PackedVector2Array([top + Vector2(s * .3, 0), top + Vector2(s * .1, 0), c + Vector2(-s * .06, -s * .02), c + Vector2(s * .14, -s * .02)]), Color("ff5a7a"))
			var m := c + Vector2(0, s * .14)
			Dot.circle(self, m, s * .34, Color(tones[0]))
			Dot.circle(self, m + Vector2(0, -s * .015), s * .29, Color(tones[1]))
			Dot.poly(self, CritterArt.star_pts(m, s * .15, s * .065, 5), Color(tones[0]))
			Dot.circle(self, m + Vector2(-s * .13, -s * .13), s * .045, Color(tones[2], .8))
		"button":
			# Bounce Run's Buttons: a cream-gold sewing button with a teal rim,
			# a raised lip, four holes and a glint (tools/event_art/scenes/buttons_icon.mjs).
			Dot.circle(self, c, s * .5, Color("16827f"))
			Dot.circle(self, c, s * .43, Color("37d6c8"))
			Dot.circle(self, c, s * .36, Color("c99a3e"))
			Dot.circle(self, c + Vector2(0, -s * .015), s * .33, Color("f5dc98"))
			Dot.arc(self, c, s * .25, 0, TAU, 24, Color("d9b25c"), s * .04, true)
			for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				Dot.circle(self, c + q * s * .09, s * .055, Color("7a5418"))
			Dot.circle(self, c + Vector2(-s * .2, -s * .22), s * .05, Color(1, 1, 1, .6))
		"hammer":
			# A forge hammer, tilted: wooden handle, steel head with a hot face.
			var t := Transform2D(-PI / 5.0, c)
			draw_set_transform_matrix(t)
			Dot.rect(self, Rect2(Vector2(-.06, -.12) * s, Vector2(.12, .6) * s), Color("b07a45"))
			Dot.rect(self, Rect2(Vector2(-.34, -.42) * s, Vector2(.68, .3) * s), Color("aab4c8"))
			Dot.rect(self, Rect2(Vector2(-.34, -.42) * s, Vector2(.68, .08) * s), Color("e6ecf5"))
			Dot.rect(self, Rect2(Vector2(.24, -.42) * s, Vector2(.1, .3) * s), Color("ff8a3d"))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"key":
			# A Rift Key: a brass ring bow holding a glitch crystal (magenta
			# and cyan halves), a shaft and two teeth, tilted, with a glint.
			var t := Transform2D(-PI / 4.0, c)
			draw_set_transform_matrix(t)
			var brass := Color("e0a93a")
			Dot.rect(self, Rect2(Vector2(-.05, -.02) * s, Vector2(.1, .5) * s), brass.darkened(.35))
			Dot.rect(self, Rect2(Vector2(-.05, -.02) * s, Vector2(.05, .5) * s), brass)
			Dot.rect(self, Rect2(Vector2(.05, .3) * s, Vector2(.14, .07) * s), brass)
			Dot.rect(self, Rect2(Vector2(.05, .4) * s, Vector2(.1, .07) * s), brass)
			var bow := Vector2(0, -.22) * s
			Dot.circle(self, bow, s * .24, brass.darkened(.35))
			Dot.circle(self, bow + Vector2(-.01, -.01) * s, s * .21, brass)
			var gem := PackedVector2Array([bow + Vector2(0, -.14) * s, bow + Vector2(.12, 0) * s, bow + Vector2(0, .14) * s, bow + Vector2(-.12, 0) * s])
			Dot.poly(self, gem, Color("3ee6ff"))
			Dot.poly(self, PackedVector2Array([gem[0], gem[2], gem[3]]), Color("ff4fb8"))
			Dot.line(self, bow + Vector2(-.1, .03) * s, bow + Vector2(.06, .03) * s, Color(1, 1, 1, .7), s * .03)
			Dot.circle(self, bow + Vector2(-.04, -.06) * s, s * .03, Color(1, 1, 1, .9))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"dye":
			# A Spark Dye: a fat paint drop in `color`, a darker rim, a lighter
			# belly, a sparkle and a glint.
			var drop := PackedVector2Array()
			for i in 24:
				var a := -PI / 2.0 + i * TAU / 24.0
				var q := Vector2(cos(a), sin(a)) * .34
				if sin(a) < 0.0: # The top narrows to a point.
					q.x *= 1.0 + sin(a) * .85
					q.y *= 1.35
				drop.append(c + (q + Vector2(0, .1)) * s)
			Dot.poly(self, drop, color.darkened(.35))
			var inner := PackedVector2Array()
			for q in drop:
				inner.append(c + Vector2(0, .1) * s + (q - c - Vector2(0, .1) * s) * .82)
			Dot.poly(self, inner, color)
			Dot.circle(self, c + Vector2(.04, .2) * s, s * .14, color.lightened(.25))
			Dot.circle(self, c + Vector2(-.1, .02) * s, s * .05, Color(1, 1, 1, .75))
			Dot.poly(self, CritterArt.star_pts(c + Vector2(.3, -.28) * s, s * .13, s * .04, 4), Color("fff2b0"))
		"orb", "egg":
			# A Summon Egg (the currency): the summon screen's matte egg, a
			# bone shell with a violet tint and rim, speckles and a sheen.
			var shell := Color("ddd2bd").lerp(Color("c86bff"), .22).darkened(.1)
			var egg := PackedVector2Array()
			var lit := PackedVector2Array()
			for i in 20:
				var a := i * TAU / 20.0
				var q := Vector2(cos(a) * .38, sin(a) * (.5 if sin(a) < 0.0 else .44) + .03)
				egg.append(c + q * s)
				lit.append(c + (q * .88 + Vector2(-.03, -.04)) * s)
			Dot.poly(self, egg, shell.darkened(.3))
			Dot.poly(self, lit, shell)
			for p in [Vector2(-.12, -.2), Vector2(.14, -.04), Vector2(-.04, .22), Vector2(.18, .26)]:
				Dot.circle(self, c + p * s, s * .035, shell.darkened(.45))
			egg.append(egg[0])
			Dot.pline(self, egg, Color("a46be0"), s * .06, true)
			Dot.circle(self, c + Vector2(-.15, -.22) * s, s * .07, Color(1, 1, 1, .3))
		"gem":
			var pts := PackedVector2Array([Vector2(.5, .06), Vector2(.92, .4), Vector2(.5, .96), Vector2(.08, .4)])
			for i in pts.size():
				pts[i] = pts[i] * s
			# A cut gem: a table on top, crown facets light to dark round it and a
			# pavilion that darkens to the point.
			var mid := Vector2(.5, .4) * s
			Dot.poly(self, pts, Color("2fb6e8"))
			Dot.poly(self, PackedVector2Array([pts[3], mid, pts[2]]), Color("1f8fc0"))
			Dot.poly(self, PackedVector2Array([mid, pts[1], pts[2]]), Color("44c8f2"))
			Dot.poly(self, PackedVector2Array([pts[0], pts[1], mid]), Color("b8f4ff"))
			Dot.poly(self, PackedVector2Array([pts[3], pts[0], mid]), Color("e6fbff"))
			Dot.circle(self, Vector2(.36, .3) * s, s * .05, Color(1, 1, 1, .9))
		"pass":
			Dot.circle(self, c, s * .46, color)
			Dot.poly(self, CritterArt.star_pts(c, s * .3, s * .13, 5), Color("0b0a1f"))
		"lock":
			Dot.arc(self, c + Vector2(0, -s * .08), s * .2, PI, TAU, 12, color, s * .09, true)
			Dot.rect(self, Rect2(Vector2(s * .22, s * .38), Vector2(s * .56, s * .44)), color)
		"back":
			Dot.pline(self, PackedVector2Array([Vector2(.62, .22) * s, Vector2(.34, .5) * s, Vector2(.62, .78) * s]), color, s * .12, true)
		"critters":
			Dot.arc(self, c + Vector2(0, s * .04), s * .38, 0, TAU, 28, color, s * .08, true)
			Dot.circle(self, c + Vector2(-.13, -.02) * s, s * .06, color)
			Dot.circle(self, c + Vector2(.13, -.02) * s, s * .06, color)
			Dot.arc(self, c + Vector2(0, s * .08), s * .14, .2 * PI, .8 * PI, 8, color, s * .07, true)
		"bag":
			draw_rect(Rect2(Vector2(.14, .32) * s, Vector2(.72, .56) * s), color, false, s * .08)
			Dot.arc(self, c + Vector2(0, -s * .2), s * .15, PI, TAU, 10, color, s * .08, true)
			Dot.line(self, Vector2(.14, .56) * s, Vector2(.86, .56) * s, color, s * .07)
		"play":
			Dot.poly(self, PackedVector2Array([Vector2(.34, .2) * s, Vector2(.82, .5) * s, Vector2(.34, .8) * s]), color)
		"fuse":
			Dot.arc(self, Vector2(.3, .34) * s, s * .16, 0, TAU, 16, color, s * .08, true)
			Dot.arc(self, Vector2(.7, .34) * s, s * .16, 0, TAU, 16, color, s * .08, true)
			Dot.arc(self, Vector2(.5, .7) * s, s * .16, 0, TAU, 16, color, s * .08, true)
		"shell":
			Dot.circle(self, c, s * .4, Color("1b1842"))
			Dot.arc(self, c, s * .4, 0, TAU, 32, color, s * .08, true)
			for a in [0.0, PI / 3, 2 * PI / 3]:
				var d := Vector2(cos(a), sin(a)) * s * .36
				Dot.line(self, c - d, c + d, Color(color, .6), s * .04, true)
			Dot.circle(self, c, s * .15, color)
		"core":
			var hexa := PackedVector2Array()
			for i in 6:
				var a := -PI / 2 + i * TAU / 6
				hexa.append(c + Vector2(cos(a), sin(a)) * s * .42)
			Dot.poly(self, hexa, Color("1b1842"))
			hexa.append(hexa[0])
			Dot.pline(self, hexa, color, s * .08, true)
			Dot.circle(self, c, s * .17, color)
			Dot.circle(self, c + Vector2(-.05, -.05) * s, s * .06, Color(1, 1, 1, .8))
		"charm":
			Dot.arc(self, Vector2(.5, .22) * s, s * .14, PI, TAU, 12, color, s * .07, true)
			var diamond := PackedVector2Array([Vector2(.5, .26) * s, Vector2(.82, .6) * s, Vector2(.5, .96) * s, Vector2(.18, .6) * s])
			Dot.poly(self, diamond, Color("1b1842"))
			diamond.append(diamond[0])
			Dot.pline(self, diamond, color, s * .08, true)
			Dot.circle(self, Vector2(.5, .61) * s, s * .12, color)
		"gear":
			for i in 8:
				var a := i * TAU / 8
				var d := Vector2(cos(a), sin(a))
				Dot.line(self, c + d * s * .26, c + d * s * .46, color, s * .16)
			Dot.circle(self, c, s * .32, color)
			Dot.circle(self, c, s * .13, Color("0b0a1f"))
		"info":
			Dot.arc(self, c, s * .42, 0, TAU, 32, color, s * .08, true)
			Dot.circle(self, c + Vector2(0, -s * .2), s * .065, color)
			Dot.line(self, c + Vector2(0, -s * .06), c + Vector2(0, s * .24), color, s * .11)
		"summon":
			var e := CritterArt.ellipse_pts(c + Vector2(0, s * .1), s * .36, s * .26, 0.0, 0.0, TAU, 24)
			Dot.pline(self, e, color, s * .08, true)
			Dot.poly(self, CritterArt.star_pts(c + Vector2(0, -s * .18), s * .2, s * .07, 4), color)
		"target":
			Dot.arc(self, c, s * .42, 0, TAU, 32, color, s * .08, true)
			Dot.arc(self, c, s * .25, 0, TAU, 24, color, s * .08, true)
			Dot.circle(self, c, s * .09, color)
			Dot.line(self, Vector2(.9, .1) * s, Vector2(.56, .44) * s, Color.WHITE, s * .07, true)
			Dot.poly(self, PackedVector2Array([Vector2(.96, .04) * s, Vector2(.96, .2) * s, Vector2(.8, .04) * s]), Color.WHITE)
		"bounce":
			var arc := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				arc.append(Vector2(.06 + t * .62, .86 - sin(t * PI) * .62) * s)
			for i in range(0, 12, 2):
				Dot.line(self, arc[i], arc[i + 1], color, s * .08, true)
			Dot.line(self, Vector2(.04, .92) * s, Vector2(.96, .92) * s, Color(color, .5), s * .05)
			Dot.circle(self, Vector2(.76, .7) * s, s * .17, color)
			Dot.circle(self, Vector2(.71, .65) * s, s * .05, Color(1, 1, 1, .8))
		"tower":
			Dot.poly(self, PackedVector2Array([Vector2(.5, .02) * s, Vector2(.7, .3) * s, Vector2(.3, .3) * s]), color)
			Dot.poly(self, PackedVector2Array([Vector2(.32, .34) * s, Vector2(.68, .34) * s, Vector2(.8, .94) * s, Vector2(.2, .94) * s]), Color(color, .55))
			for y in [.5, .66, .82]:
				Dot.line(self, Vector2(.5 - y * .27, y) * s, Vector2(.5 + y * .27, y) * s, color, s * .05)
			Dot.rect(self, Rect2(Vector2(.43, .78) * s, Vector2(.14, .16) * s), color)
		"vault":
			Dot.rect(self, Rect2(Vector2(.08, .12) * s, Vector2(.84, .76) * s), Color(color, .25))
			draw_rect(Rect2(Vector2(.08, .12) * s, Vector2(.84, .76) * s), color, false, s * .07)
			var d := Vector2(.46, .5) * s
			Dot.arc(self, d, s * .2, 0, TAU, 24, color, s * .07, true)
			for i in 4:
				var a := i * TAU / 4 + PI / 4
				Dot.line(self, d, d + Vector2(cos(a), sin(a)) * s * .2, color, s * .05, true)
			Dot.rect(self, Rect2(Vector2(.8, .36) * s, Vector2(.06, .28) * s), color)
			Dot.line(self, Vector2(.2, .88) * s, Vector2(.2, .96) * s, color, s * .07)
			Dot.line(self, Vector2(.8, .88) * s, Vector2(.8, .96) * s, color, s * .07)
		"ghost":
			var body := PackedVector2Array()
			for i in 13:
				var a := PI + i * PI / 12
				body.append(Vector2(.5, .44) * s + Vector2(cos(a), sin(a)) * s * .36)
			for i in 7:
				var x := .86 - i * .12
				body.append(Vector2(x, .92 if i % 2 == 0 else .8) * s)
			Dot.poly(self, body, color)
			Dot.circle(self, Vector2(.38, .44) * s, s * .08, Color("0b0a1f"))
			Dot.circle(self, Vector2(.62, .44) * s, s * .08, Color("0b0a1f"))
			Dot.circle(self, Vector2(.36, .42) * s, s * .03, Color.WHITE)
			Dot.circle(self, Vector2(.6, .42) * s, s * .03, Color.WHITE)
		"friends":
			var back := Color(color, .5)
			Dot.circle(self, Vector2(.68, .34) * s, s * .14, back)
			Dot.poly(self, CritterArt.ellipse_pts(Vector2(.68, .8) * s, s * .24, s * .2, 0.0, PI, TAU, 16), back)
			Dot.circle(self, Vector2(.38, .4) * s, s * .17, color)
			Dot.poly(self, CritterArt.ellipse_pts(Vector2(.38, .94) * s, s * .3, s * .26, 0.0, PI, TAU, 16), color)
		"map":
			var pin := Vector2(.5, .38) * s
			var drop := PackedVector2Array()
			for i in 17:
				var a := PI * .7 + i * PI * 1.6 / 16
				drop.append(pin + Vector2(cos(a), sin(a)) * s * .3)
			drop.append(Vector2(.5, .96) * s)
			Dot.poly(self, drop, color)
			Dot.circle(self, pin, s * .12, Color("0b0a1f"))
		"swords":
			for side in [-1.0, 1.0]:
				var tip := Vector2(.5 - side * .38, .1) * s
				var hilt := Vector2(.5 + side * .26, .74) * s
				Dot.line(self, tip, hilt, color, s * .1, true)
				var n := (hilt - tip).normalized().orthogonal() * s * .14
				Dot.line(self, hilt - n, hilt + n, Color.WHITE, s * .08, true)
				Dot.line(self, hilt, hilt + (hilt - tip).normalized() * s * .2, Color.WHITE, s * .09, true)
		"sparkle":
			Dot.poly(self, CritterArt.star_pts(Vector2(.42, .56) * s, s * .38, s * .1, 4), color)
			Dot.poly(self, CritterArt.star_pts(Vector2(.8, .2) * s, s * .18, s * .05, 4), Color.WHITE)
			Dot.circle(self, Vector2(.84, .78) * s, s * .06, color)
		"points":
			# Arena Points (Trophy Room boosts): an up arrow in an amber badge.
			Dot.circle(self, c, s * .5, Color("ffb347"))
			Dot.poly(self, PackedVector2Array([Vector2(.5, .16) * s, Vector2(.8, .5) * s, Vector2(.6, .5) * s, Vector2(.6, .84) * s, Vector2(.4, .84) * s, Vector2(.4, .5) * s, Vector2(.2, .5) * s]), Color("0b0a1f"))
		"trophy":
			var cup := PackedVector2Array([Vector2(.24, .12) * s, Vector2(.76, .12) * s, Vector2(.7, .44) * s, Vector2(.56, .58) * s, Vector2(.44, .58) * s, Vector2(.3, .44) * s])
			Dot.poly(self, cup, color)
			Dot.arc(self, Vector2(.24, .28) * s, s * .12, PI * .5, PI * 1.5, 10, color, s * .07, true)
			Dot.arc(self, Vector2(.76, .28) * s, s * .12, -PI * .5, PI * .5, 10, color, s * .07, true)
			Dot.rect(self, Rect2(Vector2(.45, .56) * s, Vector2(.1, .18) * s), color)
			Dot.rect(self, Rect2(Vector2(.28, .74) * s, Vector2(.44, .12) * s), color)
			Dot.poly(self, CritterArt.star_pts(Vector2(.5, .3) * s, s * .1, s * .04, 5), Color("0b0a1f"))
		"shield":
			var sh := PackedVector2Array([Vector2(.5, .06) * s, Vector2(.86, .2) * s, Vector2(.8, .6) * s, Vector2(.5, .94) * s, Vector2(.2, .6) * s, Vector2(.14, .2) * s])
			Dot.poly(self, sh, Color("1b1842"))
			sh.append(sh[0])
			Dot.pline(self, sh, color, s * .08, true)
			Dot.line(self, Vector2(.5, .2) * s, Vector2(.5, .8) * s, Color(color, .7), s * .07)
			Dot.line(self, Vector2(.26, .4) * s, Vector2(.74, .4) * s, Color(color, .7), s * .07)
		"replay":
			Dot.arc(self, c, s * .34, -PI * .35, PI * 1.45, 24, color, s * .1, true)
			var tip := c + Vector2(cos(-PI * .35), sin(-PI * .35)) * s * .34
			Dot.poly(self, PackedVector2Array([tip + Vector2(-.2, -.08) * s, tip + Vector2(.1, -.16) * s, tip + Vector2(.04, .16) * s]), color)
		"share":
			Dot.pline(self, PackedVector2Array([Vector2(.34, .42) * s, Vector2(.18, .42) * s, Vector2(.18, .9) * s, Vector2(.82, .9) * s, Vector2(.82, .42) * s, Vector2(.66, .42) * s]), color, s * .08, true)
			Dot.line(self, Vector2(.5, .64) * s, Vector2(.5, .12) * s, color, s * .09, true)
			Dot.pline(self, PackedVector2Array([Vector2(.32, .28) * s, Vector2(.5, .1) * s, Vector2(.68, .28) * s]), color, s * .09, true)
		"film":
			Dot.rect(self, Rect2(Vector2(.08, .26) * s, Vector2(.6, .5) * s), color)
			Dot.poly(self, PackedVector2Array([Vector2(.7, .5) * s, Vector2(.94, .3) * s, Vector2(.94, .7) * s]), color)
			Dot.circle(self, Vector2(.38, .51) * s, s * .1, Color("0b0a1f"))
		"crown":
			# A cleared stage's mark: never a star, which means tier.
			var crown := PackedVector2Array([Vector2(.1, .3) * s, Vector2(.32, .52) * s, Vector2(.5, .16) * s, Vector2(.68, .52) * s,
				Vector2(.9, .3) * s, Vector2(.8, .82) * s, Vector2(.2, .82) * s])
			Dot.poly(self, crown, GOLD if count > 0 else OFF)
			for p in [Vector2(.1, .26), Vector2(.5, .12), Vector2(.9, .26)]:
				Dot.circle(self, p * s, s * .07, GOLD if count > 0 else OFF)
		"power":
			# Power: a burst, so it never reads as the energy bolt.
			Dot.poly(self, CritterArt.star_pts(c, s * .5, s * .3, 8), color)
			Dot.circle(self, c, s * .17, Color("0b0a1f"))
			Dot.circle(self, c, s * .09, color)
		"token":
			# The Arena's Token: a magenta hexagon with crossed swords, so it never
			# reads as the gold coin.
			var hexa := PackedVector2Array()
			for i in 6:
				var a := i * TAU / 6
				hexa.append(c + Vector2(cos(a), sin(a)) * s * .48)
			Dot.poly(self, hexa, Color("ff4fd8"))
			var inner := PackedVector2Array()
			for i in 6:
				var a := i * TAU / 6
				inner.append(c + Vector2(cos(a), sin(a)) * s * .36)
			Dot.poly(self, inner, Color("8a1f78"))
			for d in [1.0, -1.0]:
				Dot.line(self, c + Vector2(-.17 * d, -.17) * s, c + Vector2(.15 * d, .15) * s, Color("ffd1f5"), s * .08, true)
				Dot.line(self, c + Vector2(.06 * d, .16) * s, c + Vector2(.16 * d, .06) * s, Color("ffd1f5"), s * .07, true)
		"heart":
			Dot.circle(self, Vector2(.32, .36) * s, s * .2, color)
			Dot.circle(self, Vector2(.68, .36) * s, s * .2, color)
			Dot.poly(self, PackedVector2Array([Vector2(.13, .44) * s, Vector2(.87, .44) * s, Vector2(.5, .88) * s]), color)
		"speed":
			# Two chevrons with a trail: moves fast.
			for x in [.3, .58]:
				Dot.pline(self, PackedVector2Array([Vector2(x, .2) * s, Vector2(x + .24, .5) * s, Vector2(x, .8) * s]), color, s * .12, true)
			Dot.line(self, Vector2(.04, .5) * s, Vector2(.2, .5) * s, Color(color, .6), s * .1, true)
