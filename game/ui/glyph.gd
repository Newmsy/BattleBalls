## Small drawn icons the font doesn't have: tier stars, power bolt, energy,
## coins, orbs, locks, the back arrow and the tab icons.
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
		"summon":
			var e := CritterArt.ellipse_pts(c + Vector2(0, s * .1), s * .36, s * .26, 0.0, 0.0, TAU, 24)
			draw_polyline(e, color, s * .08, true)
			draw_colored_polygon(CritterArt.star_pts(c + Vector2(0, -s * .18), s * .2, s * .07, 4), color)
