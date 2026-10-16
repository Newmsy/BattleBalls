## A Bounce Run boon's badge: a disc tinted by the boon's rarity with its
## icon drawn on top and the rarity's shape (game/ui/rarity_mark.gd) in the
## corner, so rarity never relies on colour alone. Render-only.
extends Control

const RarityMark := preload("res://game/ui/rarity_mark.gd")
const Roster := preload("res://game/ui/roster.gd")
const INK := Color("0b0a1f")

var icon := "shield"
var rarity := "common"


static func make(icon_: String, rarity_: String, side: float) -> Control:
	var g = load("res://game/ui/boon_icon.gd").new()
	g.icon = icon_
	g.rarity = rarity_
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.custom_minimum_size = Vector2(side, side)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return g


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(s, s) / 2.0
	var col: Color = Roster.RARITY_COLORS.get(rarity, Roster.RARITY_COLORS.common)
	draw_circle(c, s * .48, col.darkened(.55))
	draw_arc(c, s * .45, 0, TAU, 32, col, maxf(2.0, s * (.09 if rarity == "legendary" else .06)), true)
	_glyph(c, s * .62, col.lightened(.25))
	# The rarity's shape in the corner, on a dark chip so it reads on any tint.
	var m := Vector2(s * .8, s * .8)
	draw_circle(m, s * .2, INK)
	RarityMark.draw(self, rarity, m, s * .26, col)


func _glyph(c: Vector2, s: float, col: Color) -> void:
	var h := s / 2.0
	match icon:
		"shield":
			_poly(c, h, [Vector2(-.8, -.8), Vector2(.8, -.8), Vector2(.8, .05), Vector2(0, .95), Vector2(-.8, .05)], col)
		"spike":
			_poly(c, h, [Vector2(0, -1), Vector2(.3, -.3), Vector2(1, 0), Vector2(.3, .3), Vector2(0, 1), Vector2(-.3, .3), Vector2(-1, 0), Vector2(-.3, -.3)], col)
		"bolt", "zap":
			_poly(c, h, [Vector2(.2, -1), Vector2(-.6, .15), Vector2(-.05, .15), Vector2(-.25, 1), Vector2(.65, -.25), Vector2(.1, -.25)], col)
			if icon == "zap": # Overcharge: a double bolt.
				draw_arc(c, h * .95, -PI * .9, -PI * .1, 12, col, maxf(2.0, s * .08), true)
				draw_arc(c, h * .95, PI * .1, PI * .9, 12, col, maxf(2.0, s * .08), true)
		"heart":
			draw_circle(c + Vector2(-.42, -.25) * h, h * .45, col)
			draw_circle(c + Vector2(.42, -.25) * h, h * .45, col)
			_poly(c, h, [Vector2(-.86, -.1), Vector2(.86, -.1), Vector2(0, .9)], col)
		"bubble":
			draw_arc(c, h * .85, 0, TAU, 28, col, maxf(2.0, s * .1), true)
			draw_circle(c + Vector2(-.32, -.32) * h, h * .2, col)
		"fang":
			_poly(c, h, [Vector2(-.9, -.7), Vector2(.9, -.7), Vector2(.9, -.35), Vector2(.45, -.35), Vector2(.25, .9), Vector2(.05, -.35), Vector2(-.05, -.35), Vector2(-.25, .9), Vector2(-.45, -.35), Vector2(-.9, -.35)], col)
		"bank":
			draw_arc(c + Vector2(0, .2) * h, h * .7, PI, TAU, 16, col, maxf(2.0, s * .12), true)
			_poly(c, h, [Vector2(.95, -.15), Vector2(.4, -.55), Vector2(.45, .15)], col)
			draw_line(c + Vector2(-1, .55) * h, c + Vector2(1, .55) * h, col, maxf(2.0, s * .1))
		"guard":
			draw_arc(c, h * .8, -PI * .85, -PI * .15, 16, col, maxf(2.0, s * .16), true)
			draw_arc(c, h * .8, PI * .15, PI * .85, 16, col, maxf(2.0, s * .16), true)
			draw_circle(c, h * .28, col)
		"beam":
			draw_line(c + Vector2(-1, .6) * h, c + Vector2(1, -.6) * h, col, maxf(2.0, s * .16))
			draw_circle(c + Vector2(-1, .6) * h, h * .25, col)
		"feather": # Phoenix Feather.
			_poly(c, h, [Vector2(.7, -1), Vector2(.35, .1), Vector2(-.5, .75), Vector2(-.2, -.1)], col)
			draw_line(c + Vector2(.7, -1) * h, c + Vector2(-.8, 1) * h, INK, maxf(1.5, s * .06))
		"thorns": # Thorn Crown.
			_poly(c, h, [Vector2(-1, .7), Vector2(-1, -.6), Vector2(-.5, -.05), Vector2(0, -.95), Vector2(.5, -.05), Vector2(1, -.6), Vector2(1, .7)], col)
			for x in [-.6, 0.0, .6]:
				draw_circle(c + Vector2(x, .35) * h, h * .13, INK)
		"drop": # Vampire Kiss.
			draw_circle(c + Vector2(0, .3) * h, h * .62, col)
			_poly(c, h, [Vector2(0, -1), Vector2(.58, .1), Vector2(-.58, .1)], col)
		_:
			draw_circle(c, h * .6, col)


func _poly(c: Vector2, h: float, pts: Array, col: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p * h)
	draw_colored_polygon(out, col)
