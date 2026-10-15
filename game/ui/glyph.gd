## Small drawn icons the font doesn't have: tier stars, power bolt, energy,
## coins, orbs, Glow Gems, the pass star, gear (shell, core, charm), locks, the back arrow, the info "i"
## and the tab icons.
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
		"orb":
			draw_circle(c, s * .5, Color("c86bff"))
			draw_circle(c + Vector2(-.12, -.12) * s, s * .3, Color("e7b8ff"))
			draw_circle(c + Vector2(-.18, -.18) * s, s * .12, Color.WHITE)
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
