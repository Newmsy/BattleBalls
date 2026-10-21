## Small drawn icons the font doesn't have: tier stars, power bolt, energy,
## coins, hammers, Summon Eggs, Glow Gems, the pass star, gear (slot icons shell, core,
## charm, plus one icon per gear type), locks, the back arrow, the info "i"
## the tab icons and the home mode icons (target, bounce, tower, vault, ghost,
## friends, map, swords, sparkle), the Arena's trophy, shield and token, and
## the stat heads (heart, speed).
extends Control

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
				draw_colored_polygon(CritterArt.star_pts(p, s * .48, s * .2, 5), GOLD if i < count else OFF)
		"bolt":
			var pts := PackedVector2Array([Vector2(.58, .02), Vector2(.15, .58), Vector2(.47, .58), Vector2(.38, .98), Vector2(.85, .38), Vector2(.53, .38)])
			for i in pts.size():
				pts[i] = pts[i] * s
			draw_colored_polygon(pts, color)
		"energy":
			draw_circle(c, s * .5, Color("5ce1ff"))
			var pts := PackedVector2Array([Vector2(.58, .14), Vector2(.28, .56), Vector2(.48, .56), Vector2(.42, .86), Vector2(.72, .44), Vector2(.52, .44)])
			for i in pts.size():
				pts[i] = pts[i] * s
			draw_colored_polygon(pts, Color("0b0a1f"))
		"coin":
			draw_circle(c, s * .5, Color("ffd45c"))
			draw_arc(c, s * .3, 0, TAU, 24, Color("b8860b"), s * .09, true)
		"hammer":
			# A forge hammer, tilted: wooden handle, steel head with a hot face.
			var t := Transform2D(-PI / 5.0, c)
			draw_set_transform_matrix(t)
			draw_rect(Rect2(Vector2(-.06, -.12) * s, Vector2(.12, .6) * s), Color("b07a45"))
			draw_rect(Rect2(Vector2(-.34, -.42) * s, Vector2(.68, .3) * s), Color("aab4c8"))
			draw_rect(Rect2(Vector2(-.34, -.42) * s, Vector2(.68, .08) * s), Color("e6ecf5"))
			draw_rect(Rect2(Vector2(.24, -.42) * s, Vector2(.1, .3) * s), Color("ff8a3d"))
			draw_set_transform_matrix(Transform2D.IDENTITY)
		"orb", "egg":
			# A Summon Egg (the currency): the summon eggs' shape, purple
			# shell, glowing rim and a star (game/ui/screens/summon_screen.gd).
			var egg := PackedVector2Array()
			for i in 20:
				var a := i * TAU / 20.0
				egg.append(c + Vector2(cos(a) * .38, sin(a) * (.5 if sin(a) < 0.0 else .44) + .03) * s)
			draw_colored_polygon(egg, Color("c86bff"))
			egg.append(egg[0])
			draw_polyline(egg, Color("e7b8ff"), s * .06, true)
			draw_colored_polygon(CritterArt.star_pts(c + Vector2(0, .06) * s, s * .17, s * .07, 5), Color("ffe9ff"))
			draw_circle(c + Vector2(-.15, -.22) * s, s * .07, Color.WHITE)
		"gem":
			var pts := PackedVector2Array([Vector2(.5, .06), Vector2(.92, .4), Vector2(.5, .96), Vector2(.08, .4)])
			for i in pts.size():
				pts[i] = pts[i] * s
			draw_colored_polygon(pts, Color("5ce1ff"))
			draw_colored_polygon(PackedVector2Array([pts[0], pts[1], Vector2(.5, .4) * s]), Color("b8f4ff"))
			draw_colored_polygon(PackedVector2Array([pts[3], pts[0], Vector2(.5, .4) * s]), Color("e6fbff"))
		"pass":
			draw_circle(c, s * .46, color)
			draw_colored_polygon(CritterArt.star_pts(c, s * .3, s * .13, 5), Color("0b0a1f"))
		"lock":
			draw_arc(c + Vector2(0, -s * .08), s * .2, PI, TAU, 12, color, s * .09, true)
			draw_rect(Rect2(Vector2(s * .22, s * .38), Vector2(s * .56, s * .44)), color)
		"back":
			draw_polyline(PackedVector2Array([Vector2(.62, .22) * s, Vector2(.34, .5) * s, Vector2(.62, .78) * s]), color, s * .12, true)
		"critters":
			draw_arc(c + Vector2(0, s * .04), s * .38, 0, TAU, 28, color, s * .08, true)
			draw_circle(c + Vector2(-.13, -.02) * s, s * .06, color)
			draw_circle(c + Vector2(.13, -.02) * s, s * .06, color)
			draw_arc(c + Vector2(0, s * .08), s * .14, .2 * PI, .8 * PI, 8, color, s * .07, true)
		"bag":
			draw_rect(Rect2(Vector2(.14, .32) * s, Vector2(.72, .56) * s), color, false, s * .08)
			draw_arc(c + Vector2(0, -s * .2), s * .15, PI, TAU, 10, color, s * .08, true)
			draw_line(Vector2(.14, .56) * s, Vector2(.86, .56) * s, color, s * .07)
		"play":
			draw_colored_polygon(PackedVector2Array([Vector2(.34, .2) * s, Vector2(.82, .5) * s, Vector2(.34, .8) * s]), color)
		"fuse":
			draw_arc(Vector2(.3, .34) * s, s * .16, 0, TAU, 16, color, s * .08, true)
			draw_arc(Vector2(.7, .34) * s, s * .16, 0, TAU, 16, color, s * .08, true)
			draw_arc(Vector2(.5, .7) * s, s * .16, 0, TAU, 16, color, s * .08, true)
		"shell":
			draw_circle(c, s * .4, Color("1b1842"))
			draw_arc(c, s * .4, 0, TAU, 32, color, s * .08, true)
			for a in [0.0, PI / 3, 2 * PI / 3]:
				var d := Vector2(cos(a), sin(a)) * s * .36
				draw_line(c - d, c + d, Color(color, .6), s * .04, true)
			draw_circle(c, s * .15, color)
		"core":
			var hexa := PackedVector2Array()
			for i in 6:
				var a := -PI / 2 + i * TAU / 6
				hexa.append(c + Vector2(cos(a), sin(a)) * s * .42)
			draw_colored_polygon(hexa, Color("1b1842"))
			hexa.append(hexa[0])
			draw_polyline(hexa, color, s * .08, true)
			draw_circle(c, s * .17, color)
			draw_circle(c + Vector2(-.05, -.05) * s, s * .06, Color(1, 1, 1, .8))
		"charm":
			draw_arc(Vector2(.5, .22) * s, s * .14, PI, TAU, 12, color, s * .07, true)
			var diamond := PackedVector2Array([Vector2(.5, .26) * s, Vector2(.82, .6) * s, Vector2(.5, .96) * s, Vector2(.18, .6) * s])
			draw_colored_polygon(diamond, Color("1b1842"))
			diamond.append(diamond[0])
			draw_polyline(diamond, color, s * .08, true)
			draw_circle(Vector2(.5, .61) * s, s * .12, color)
		# One icon per gear type (the gear type id, sim/gear.gd PIECES); colour = tier.
		"iron_shell":
			# Defense: a riveted iron shield with a cross band.
			var sh := PackedVector2Array([Vector2(.5, .06), Vector2(.86, .18), Vector2(.84, .52), Vector2(.5, .96), Vector2(.16, .52), Vector2(.14, .18)])
			for i in sh.size():
				sh[i] = sh[i] * s
			draw_colored_polygon(sh, Color("1b1842"))
			draw_colored_polygon(PackedVector2Array([sh[0], sh[1], sh[2], Vector2(.5, .52) * s]), Color(color, .35))
			sh.append(sh[0])
			draw_polyline(sh, color, s * .08, true)
			draw_line(Vector2(.5, .1) * s, Vector2(.5, .9) * s, color, s * .07)
			draw_line(Vector2(.16, .42) * s, Vector2(.84, .42) * s, color, s * .07)
			for p in [Vector2(.3, .26), Vector2(.7, .26), Vector2(.32, .62), Vector2(.68, .62)]:
				draw_circle(p * s, s * .045, Color(1, 1, 1, .85))
		"bubble_shell":
			# Health: a soap bubble with a heart inside and two little bubbles.
			draw_circle(c + Vector2(-.04, .04) * s, s * .36, Color(color, .18))
			draw_arc(c + Vector2(-.04, .04) * s, s * .36, 0, TAU, 32, color, s * .07, true)
			draw_arc(c + Vector2(-.04, .04) * s, s * .26, PI * 1.1, PI * 1.45, 8, Color(1, 1, 1, .85), s * .06, true)
			var h := c + Vector2(-.04, .08) * s
			draw_circle(h + Vector2(-.08, -.06) * s, s * .09, color)
			draw_circle(h + Vector2(.08, -.06) * s, s * .09, color)
			draw_colored_polygon(PackedVector2Array([h + Vector2(-.165, -.03) * s, h + Vector2(.165, -.03) * s, h + Vector2(0, .17) * s]), color)
			draw_arc(Vector2(.84, .2) * s, s * .09, 0, TAU, 14, color, s * .05, true)
			draw_arc(Vector2(.9, .44) * s, s * .05, 0, TAU, 10, color, s * .04, true)
		"spike_core":
			# Attack: a core studded with sharp spikes.
			draw_colored_polygon(CritterArt.star_pts(c, s * .5, s * .27, 8, -PI / 2), color)
			draw_circle(c, s * .25, Color("1b1842"))
			draw_arc(c, s * .25, 0, TAU, 24, color, s * .06, true)
			draw_colored_polygon(CritterArt.star_pts(c, s * .15, s * .06, 4, -PI / 4), Color(1, 1, 1, .9))
		"echo_core":
			# Crit: a core sending out echo ripples, sharpest on one side.
			draw_arc(c, s * .46, -PI * .3, PI * .3, 12, Color(color, .45), s * .06, true)
			draw_arc(c, s * .46, PI * .7, PI * 1.3, 12, Color(color, .45), s * .06, true)
			draw_arc(c, s * .34, -PI * .32, PI * .32, 10, Color(color, .75), s * .07, true)
			draw_arc(c, s * .34, PI * .68, PI * 1.32, 10, Color(color, .75), s * .07, true)
			var hexa := PackedVector2Array()
			for i in 6:
				var a := -PI / 2 + i * TAU / 6
				hexa.append(c + Vector2(cos(a), sin(a)) * s * .22)
			draw_colored_polygon(hexa, Color("1b1842"))
			hexa.append(hexa[0])
			draw_polyline(hexa, color, s * .06, true)
			draw_circle(c, s * .09, color)
			draw_circle(c + Vector2(-.03, -.03) * s, s * .035, Color(1, 1, 1, .85))
		"overclock_charm":
			# Ability speed: a stopwatch with its hand racing round.
			var w := c + Vector2(0, .06) * s
			draw_rect(Rect2(Vector2(.42, .02) * s, Vector2(.16, .1) * s), color)
			draw_line(Vector2(.78, .16) * s, Vector2(.86, .08) * s, color, s * .07)
			draw_circle(w, s * .38, Color("1b1842"))
			draw_colored_polygon(CritterArt.ellipse_pts(w, s * .38, s * .38, 0.0, -PI / 2, PI * .3, 14) + PackedVector2Array([w]), Color(color, .35))
			draw_arc(w, s * .38, 0, TAU, 32, color, s * .07, true)
			for i in 4:
				var a := i * TAU / 4
				draw_line(w + Vector2(cos(a), sin(a)) * s * .26, w + Vector2(cos(a), sin(a)) * s * .32, color, s * .05)
			draw_line(w, w + Vector2(cos(PI * .3), sin(PI * .3)) * s * .28, Color.WHITE, s * .07, true)
			draw_circle(w, s * .06, color)
		"jet_charm":
			# Move speed: a little rocket flying up-right on a flame.
			var t := Transform2D(PI / 4.0, c + Vector2(-.02, .02) * s)
			draw_set_transform_matrix(t)
			draw_colored_polygon(PackedVector2Array([Vector2(-.12, .3) * s, Vector2(0, .5) * s, Vector2(.12, .3) * s]), Color("ff8a3d"))
			draw_colored_polygon(PackedVector2Array([Vector2(-.06, .3) * s, Vector2(0, .42) * s, Vector2(.06, .3) * s]), Color("ffe08a"))
			draw_colored_polygon(PackedVector2Array([Vector2(-.13, .1) * s, Vector2(-.26, .32) * s, Vector2(-.13, .26) * s]), color)
			draw_colored_polygon(PackedVector2Array([Vector2(.13, .1) * s, Vector2(.26, .32) * s, Vector2(.13, .26) * s]), color)
			var body := CritterArt.ellipse_pts(Vector2(0, -.04) * s, s * .14, s * .36, 0.0, 0.0, TAU, 20)
			draw_colored_polygon(body, color)
			draw_circle(Vector2(0, -.1) * s, s * .07, Color("1b1842"))
			draw_circle(Vector2(-.02, -.12) * s, s * .025, Color.WHITE)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			for i in 2:
				draw_line(Vector2(.06, .66 + i * .14) * s, Vector2(.22 + i * .04, .66 + i * .14) * s, Color(color, .55), s * .045)
		"thorn_shell":
			# Thorns: a round shell ringed with sharp thorns that hit back.
			for i in 8:
				var a := i * TAU / 8 + PI / 8
				var d := Vector2(cos(a), sin(a))
				var side := d.orthogonal() * s * .07
				draw_colored_polygon(PackedVector2Array([c + d * s * .3 + side, c + d * s * .48, c + d * s * .3 - side]), color)
			draw_circle(c, s * .32, Color("1b1842"))
			draw_arc(c, s * .32, 0, TAU, 28, color, s * .07, true)
			draw_arc(c, s * .2, PI * .15, PI * 1.35, 12, Color(color, .7), s * .05, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(.13, -.09) * s, c + Vector2(.25, -.02) * s, c + Vector2(.13, .06) * s]), Color(color, .7))
		"spring_shell":
			# Mend: a coiled spring in a shell, with a green heal cross.
			draw_circle(c, s * .4, Color("1b1842"))
			draw_arc(c, s * .4, 0, TAU, 32, color, s * .07, true)
			var coil := PackedVector2Array()
			for i in 7:
				coil.append(Vector2(.34 if i % 2 == 0 else .62, .24 + i * .085) * s)
			draw_polyline(coil, color, s * .065, true)
			draw_line(Vector2(.3, .24) * s, Vector2(.66, .24) * s, color, s * .06)
			draw_line(Vector2(.3, .75) * s, Vector2(.66, .75) * s, color, s * .06)
			draw_line(Vector2(.78, .1) * s, Vector2(.78, .32) * s, Color("45f5a6"), s * .07)
			draw_line(Vector2(.67, .21) * s, Vector2(.89, .21) * s, Color("45f5a6"), s * .07)
		"leech_core":
			# Lifesteal: a core holding a drop it drank, two fangs above.
			var hexa := PackedVector2Array()
			for i in 6:
				var a := -PI / 2 + i * TAU / 6
				hexa.append(c + Vector2(cos(a), sin(a)) * s * .42)
			draw_colored_polygon(hexa, Color("1b1842"))
			hexa.append(hexa[0])
			draw_polyline(hexa, color, s * .07, true)
			var drop := c + Vector2(0, .1) * s
			draw_circle(drop, s * .14, color)
			draw_colored_polygon(PackedVector2Array([drop + Vector2(-.12, -.07) * s, drop + Vector2(0, -.3) * s, drop + Vector2(.12, -.07) * s]), color)
			draw_circle(drop + Vector2(-.05, .02) * s, s * .04, Color(1, 1, 1, .85))
			for x in [-.1, .1]:
				draw_colored_polygon(PackedVector2Array([Vector2(.5 + x - .05, .1) * s, Vector2(.5 + x + .05, .1) * s, Vector2(.5 + x, .24) * s]), Color.WHITE)
		"ricochet_core":
			# Bank shots: a core bouncing off a wall, the second leg glowing.
			draw_line(Vector2(.12, .1) * s, Vector2(.12, .9) * s, Color(color, .55), s * .08)
			draw_line(Vector2(.66, .2) * s, Vector2(.2, .5) * s, Color(color, .55), s * .06, true)
			draw_line(Vector2(.2, .5) * s, Vector2(.74, .8) * s, color, s * .09, true)
			draw_colored_polygon(PackedVector2Array([Vector2(.88, .88) * s, Vector2(.62, .86) * s, Vector2(.76, .66) * s]), color)
			draw_circle(Vector2(.7, .2) * s, s * .15, Color("1b1842"))
			draw_arc(Vector2(.7, .2) * s, s * .15, 0, TAU, 18, color, s * .06, true)
			draw_circle(Vector2(.7, .2) * s, s * .06, color)
			for d in [Vector2(-1, -1), Vector2(-1, 1), Vector2(-1.3, 0)]:
				draw_line(Vector2(.2, .5) * s + d * s * .03, Vector2(.2, .5) * s + d * s * .11, Color(1, 1, 1, .85), s * .035)
		"ward_charm":
			# Start shield: a charm inside a glowing bubble of shield.
			draw_circle(c, s * .46, Color(color, .14))
			draw_arc(c, s * .46, 0, TAU, 32, Color(color, .45), s * .05, true)
			draw_arc(c, s * .38, 0, TAU, 32, color, s * .06, true)
			var gem := PackedVector2Array([c + Vector2(0, -.2) * s, c + Vector2(.17, .02) * s, c + Vector2(0, .24) * s, c + Vector2(-.17, .02) * s])
			draw_colored_polygon(gem, Color("1b1842"))
			gem.append(gem[0])
			draw_polyline(gem, color, s * .06, true)
			draw_circle(c + Vector2(0, .02) * s, s * .07, color)
			draw_arc(c, s * .3, PI * 1.15, PI * 1.45, 8, Color(1, 1, 1, .85), s * .05, true)
		"phoenix_charm":
			# Revive: a fiery phoenix feather.
			var t := Transform2D(PI / 5.0, c)
			draw_set_transform_matrix(t)
			draw_colored_polygon(CritterArt.ellipse_pts(Vector2(0, -.06) * s, s * .17, s * .36, 0.0, 0.0, TAU, 22), color)
			draw_colored_polygon(CritterArt.ellipse_pts(Vector2(0, -.14) * s, s * .08, s * .2, 0.0, 0.0, TAU, 16), Color("ffe08a"))
			draw_line(Vector2(0, .44) * s, Vector2(0, -.3) * s, Color.WHITE, s * .045)
			for i in 3:
				var y := (.12 - i * .13) * s
				draw_line(Vector2(0, y), Vector2(-.13 * s, y - .07 * s), Color("1b1842"), s * .03)
				draw_line(Vector2(0, y), Vector2(.13 * s, y - .07 * s), Color("1b1842"), s * .03)
			draw_set_transform_matrix(Transform2D.IDENTITY)
			draw_circle(Vector2(.22, .8) * s, s * .05, Color("ff8a3d"))
			draw_circle(Vector2(.32, .9) * s, s * .035, Color("ffe08a"))
		"gear":
			for i in 8:
				var a := i * TAU / 8
				var d := Vector2(cos(a), sin(a))
				draw_line(c + d * s * .26, c + d * s * .46, color, s * .16)
			draw_circle(c, s * .32, color)
			draw_circle(c, s * .13, Color("0b0a1f"))
		"info":
			draw_arc(c, s * .42, 0, TAU, 32, color, s * .08, true)
			draw_circle(c + Vector2(0, -s * .2), s * .065, color)
			draw_line(c + Vector2(0, -s * .06), c + Vector2(0, s * .24), color, s * .11)
		"summon":
			var e := CritterArt.ellipse_pts(c + Vector2(0, s * .1), s * .36, s * .26, 0.0, 0.0, TAU, 24)
			draw_polyline(e, color, s * .08, true)
			draw_colored_polygon(CritterArt.star_pts(c + Vector2(0, -s * .18), s * .2, s * .07, 4), color)
		"target":
			draw_arc(c, s * .42, 0, TAU, 32, color, s * .08, true)
			draw_arc(c, s * .25, 0, TAU, 24, color, s * .08, true)
			draw_circle(c, s * .09, color)
			draw_line(Vector2(.9, .1) * s, Vector2(.56, .44) * s, Color.WHITE, s * .07, true)
			draw_colored_polygon(PackedVector2Array([Vector2(.96, .04) * s, Vector2(.96, .2) * s, Vector2(.8, .04) * s]), Color.WHITE)
		"bounce":
			var arc := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				arc.append(Vector2(.06 + t * .62, .86 - sin(t * PI) * .62) * s)
			for i in range(0, 12, 2):
				draw_line(arc[i], arc[i + 1], color, s * .08, true)
			draw_line(Vector2(.04, .92) * s, Vector2(.96, .92) * s, Color(color, .5), s * .05)
			draw_circle(Vector2(.76, .7) * s, s * .17, color)
			draw_circle(Vector2(.71, .65) * s, s * .05, Color(1, 1, 1, .8))
		"tower":
			draw_colored_polygon(PackedVector2Array([Vector2(.5, .02) * s, Vector2(.7, .3) * s, Vector2(.3, .3) * s]), color)
			draw_colored_polygon(PackedVector2Array([Vector2(.32, .34) * s, Vector2(.68, .34) * s, Vector2(.8, .94) * s, Vector2(.2, .94) * s]), Color(color, .55))
			for y in [.5, .66, .82]:
				draw_line(Vector2(.5 - y * .27, y) * s, Vector2(.5 + y * .27, y) * s, color, s * .05)
			draw_rect(Rect2(Vector2(.43, .78) * s, Vector2(.14, .16) * s), color)
		"vault":
			draw_rect(Rect2(Vector2(.08, .12) * s, Vector2(.84, .76) * s), Color(color, .25))
			draw_rect(Rect2(Vector2(.08, .12) * s, Vector2(.84, .76) * s), color, false, s * .07)
			var d := Vector2(.46, .5) * s
			draw_arc(d, s * .2, 0, TAU, 24, color, s * .07, true)
			for i in 4:
				var a := i * TAU / 4 + PI / 4
				draw_line(d, d + Vector2(cos(a), sin(a)) * s * .2, color, s * .05, true)
			draw_rect(Rect2(Vector2(.8, .36) * s, Vector2(.06, .28) * s), color)
			draw_line(Vector2(.2, .88) * s, Vector2(.2, .96) * s, color, s * .07)
			draw_line(Vector2(.8, .88) * s, Vector2(.8, .96) * s, color, s * .07)
		"ghost":
			var body := PackedVector2Array()
			for i in 13:
				var a := PI + i * PI / 12
				body.append(Vector2(.5, .44) * s + Vector2(cos(a), sin(a)) * s * .36)
			for i in 7:
				var x := .86 - i * .12
				body.append(Vector2(x, .92 if i % 2 == 0 else .8) * s)
			draw_colored_polygon(body, color)
			draw_circle(Vector2(.38, .44) * s, s * .08, Color("0b0a1f"))
			draw_circle(Vector2(.62, .44) * s, s * .08, Color("0b0a1f"))
			draw_circle(Vector2(.36, .42) * s, s * .03, Color.WHITE)
			draw_circle(Vector2(.6, .42) * s, s * .03, Color.WHITE)
		"friends":
			var back := Color(color, .5)
			draw_circle(Vector2(.68, .34) * s, s * .14, back)
			draw_colored_polygon(CritterArt.ellipse_pts(Vector2(.68, .8) * s, s * .24, s * .2, 0.0, PI, TAU, 16), back)
			draw_circle(Vector2(.38, .4) * s, s * .17, color)
			draw_colored_polygon(CritterArt.ellipse_pts(Vector2(.38, .94) * s, s * .3, s * .26, 0.0, PI, TAU, 16), color)
		"map":
			var pin := Vector2(.5, .38) * s
			var drop := PackedVector2Array()
			for i in 17:
				var a := PI * .7 + i * PI * 1.6 / 16
				drop.append(pin + Vector2(cos(a), sin(a)) * s * .3)
			drop.append(Vector2(.5, .96) * s)
			draw_colored_polygon(drop, color)
			draw_circle(pin, s * .12, Color("0b0a1f"))
		"swords":
			for side in [-1.0, 1.0]:
				var tip := Vector2(.5 - side * .38, .1) * s
				var hilt := Vector2(.5 + side * .26, .74) * s
				draw_line(tip, hilt, color, s * .1, true)
				var n := (hilt - tip).normalized().orthogonal() * s * .14
				draw_line(hilt - n, hilt + n, Color.WHITE, s * .08, true)
				draw_line(hilt, hilt + (hilt - tip).normalized() * s * .2, Color.WHITE, s * .09, true)
		"sparkle":
			draw_colored_polygon(CritterArt.star_pts(Vector2(.42, .56) * s, s * .38, s * .1, 4), color)
			draw_colored_polygon(CritterArt.star_pts(Vector2(.8, .2) * s, s * .18, s * .05, 4), Color.WHITE)
			draw_circle(Vector2(.84, .78) * s, s * .06, color)
		"points":
			# Arena Points (Trophy Room boosts): an up arrow in an amber badge.
			draw_circle(c, s * .5, Color("ffb347"))
			draw_colored_polygon(PackedVector2Array([Vector2(.5, .16) * s, Vector2(.8, .5) * s, Vector2(.6, .5) * s, Vector2(.6, .84) * s, Vector2(.4, .84) * s, Vector2(.4, .5) * s, Vector2(.2, .5) * s]), Color("0b0a1f"))
		"trophy":
			var cup := PackedVector2Array([Vector2(.24, .12) * s, Vector2(.76, .12) * s, Vector2(.7, .44) * s, Vector2(.56, .58) * s, Vector2(.44, .58) * s, Vector2(.3, .44) * s])
			draw_colored_polygon(cup, color)
			draw_arc(Vector2(.24, .28) * s, s * .12, PI * .5, PI * 1.5, 10, color, s * .07, true)
			draw_arc(Vector2(.76, .28) * s, s * .12, -PI * .5, PI * .5, 10, color, s * .07, true)
			draw_rect(Rect2(Vector2(.45, .56) * s, Vector2(.1, .18) * s), color)
			draw_rect(Rect2(Vector2(.28, .74) * s, Vector2(.44, .12) * s), color)
			draw_colored_polygon(CritterArt.star_pts(Vector2(.5, .3) * s, s * .1, s * .04, 5), Color("0b0a1f"))
		"shield":
			var sh := PackedVector2Array([Vector2(.5, .06) * s, Vector2(.86, .2) * s, Vector2(.8, .6) * s, Vector2(.5, .94) * s, Vector2(.2, .6) * s, Vector2(.14, .2) * s])
			draw_colored_polygon(sh, Color("1b1842"))
			sh.append(sh[0])
			draw_polyline(sh, color, s * .08, true)
			draw_line(Vector2(.5, .2) * s, Vector2(.5, .8) * s, Color(color, .7), s * .07)
			draw_line(Vector2(.26, .4) * s, Vector2(.74, .4) * s, Color(color, .7), s * .07)
		"replay":
			draw_arc(c, s * .34, -PI * .35, PI * 1.45, 24, color, s * .1, true)
			var tip := c + Vector2(cos(-PI * .35), sin(-PI * .35)) * s * .34
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-.2, -.08) * s, tip + Vector2(.1, -.16) * s, tip + Vector2(.04, .16) * s]), color)
		"share":
			draw_polyline(PackedVector2Array([Vector2(.34, .42) * s, Vector2(.18, .42) * s, Vector2(.18, .9) * s, Vector2(.82, .9) * s, Vector2(.82, .42) * s, Vector2(.66, .42) * s]), color, s * .08, true)
			draw_line(Vector2(.5, .64) * s, Vector2(.5, .12) * s, color, s * .09, true)
			draw_polyline(PackedVector2Array([Vector2(.32, .28) * s, Vector2(.5, .1) * s, Vector2(.68, .28) * s]), color, s * .09, true)
		"film":
			draw_rect(Rect2(Vector2(.08, .26) * s, Vector2(.6, .5) * s), color)
			draw_colored_polygon(PackedVector2Array([Vector2(.7, .5) * s, Vector2(.94, .3) * s, Vector2(.94, .7) * s]), color)
			draw_circle(Vector2(.38, .51) * s, s * .1, Color("0b0a1f"))
		"crown":
			# A cleared stage's mark: never a star, which means tier.
			var crown := PackedVector2Array([Vector2(.1, .3) * s, Vector2(.32, .52) * s, Vector2(.5, .16) * s, Vector2(.68, .52) * s,
				Vector2(.9, .3) * s, Vector2(.8, .82) * s, Vector2(.2, .82) * s])
			draw_colored_polygon(crown, GOLD if count > 0 else OFF)
			for p in [Vector2(.1, .26), Vector2(.5, .12), Vector2(.9, .26)]:
				draw_circle(p * s, s * .07, GOLD if count > 0 else OFF)
		"power":
			# Power: a burst, so it never reads as the energy bolt.
			draw_colored_polygon(CritterArt.star_pts(c, s * .5, s * .3, 8), color)
			draw_circle(c, s * .17, Color("0b0a1f"))
			draw_circle(c, s * .09, color)
		"token":
			# The Arena's Token: a magenta hexagon with crossed swords, so it never
			# reads as the gold coin.
			var hexa := PackedVector2Array()
			for i in 6:
				var a := i * TAU / 6
				hexa.append(c + Vector2(cos(a), sin(a)) * s * .48)
			draw_colored_polygon(hexa, Color("ff4fd8"))
			var inner := PackedVector2Array()
			for i in 6:
				var a := i * TAU / 6
				inner.append(c + Vector2(cos(a), sin(a)) * s * .36)
			draw_colored_polygon(inner, Color("8a1f78"))
			for d in [1.0, -1.0]:
				draw_line(c + Vector2(-.17 * d, -.17) * s, c + Vector2(.15 * d, .15) * s, Color("ffd1f5"), s * .08, true)
				draw_line(c + Vector2(.06 * d, .16) * s, c + Vector2(.16 * d, .06) * s, Color("ffd1f5"), s * .07, true)
		"heart":
			draw_circle(Vector2(.32, .36) * s, s * .2, color)
			draw_circle(Vector2(.68, .36) * s, s * .2, color)
			draw_colored_polygon(PackedVector2Array([Vector2(.13, .44) * s, Vector2(.87, .44) * s, Vector2(.5, .88) * s]), color)
		"speed":
			# Two chevrons with a trail: moves fast.
			for x in [.3, .58]:
				draw_polyline(PackedVector2Array([Vector2(x, .2) * s, Vector2(x + .24, .5) * s, Vector2(x, .8) * s]), color, s * .12, true)
			draw_line(Vector2(.04, .5) * s, Vector2(.2, .5) * s, Color(color, .6), s * .1, true)
