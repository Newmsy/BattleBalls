## A Bounce Run boon's badge: a disc tinted by the boon's rarity with its
## icon drawn on top and the rarity's shape (game/ui/rarity_mark.gd) in the
## corner, so rarity never relies on colour alone. Render-only.
extends Control

const Dot := preload("res://game/dot.gd")

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
	Dot.circle(self, c, s * .48, col.darkened(.55))
	Dot.arc(self, c, s * .45, 0, TAU, 32, col, maxf(2.0, s * (.09 if rarity == "legendary" else .06)), true)
	_glyph(c, s * .62, col.lightened(.25))
	# The rarity's shape in the corner, on a dark chip so it reads on any tint.
	var m := Vector2(s * .8, s * .8)
	Dot.circle(self, m, s * .2, INK)
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
				Dot.arc(self, c, h * .95, -PI * .9, -PI * .1, 12, col, maxf(2.0, s * .08), true)
				Dot.arc(self, c, h * .95, PI * .1, PI * .9, 12, col, maxf(2.0, s * .08), true)
		"heart":
			Dot.circle(self, c + Vector2(-.42, -.25) * h, h * .45, col)
			Dot.circle(self, c + Vector2(.42, -.25) * h, h * .45, col)
			_poly(c, h, [Vector2(-.86, -.1), Vector2(.86, -.1), Vector2(0, .9)], col)
		"bubble":
			Dot.arc(self, c, h * .85, 0, TAU, 28, col, maxf(2.0, s * .1), true)
			Dot.circle(self, c + Vector2(-.32, -.32) * h, h * .2, col)
		"fang":
			_poly(c, h, [Vector2(-.9, -.7), Vector2(.9, -.7), Vector2(.9, -.35), Vector2(.45, -.35), Vector2(.25, .9), Vector2(.05, -.35), Vector2(-.05, -.35), Vector2(-.25, .9), Vector2(-.45, -.35), Vector2(-.9, -.35)], col)
		"bank":
			Dot.arc(self, c + Vector2(0, .2) * h, h * .7, PI, TAU, 16, col, maxf(2.0, s * .12), true)
			_poly(c, h, [Vector2(.95, -.15), Vector2(.4, -.55), Vector2(.45, .15)], col)
			Dot.line(self, c + Vector2(-1, .55) * h, c + Vector2(1, .55) * h, col, maxf(2.0, s * .1))
		"guard":
			Dot.arc(self, c, h * .8, -PI * .85, -PI * .15, 16, col, maxf(2.0, s * .16), true)
			Dot.arc(self, c, h * .8, PI * .15, PI * .85, 16, col, maxf(2.0, s * .16), true)
			Dot.circle(self, c, h * .28, col)
		"beam":
			Dot.line(self, c + Vector2(-1, .6) * h, c + Vector2(1, -.6) * h, col, maxf(2.0, s * .16))
			Dot.circle(self, c + Vector2(-1, .6) * h, h * .25, col)
		"feather": # Phoenix Feather.
			_poly(c, h, [Vector2(.7, -1), Vector2(.35, .1), Vector2(-.5, .75), Vector2(-.2, -.1)], col)
			Dot.line(self, c + Vector2(.7, -1) * h, c + Vector2(-.8, 1) * h, INK, maxf(1.5, s * .06))
		"thorns": # Thorn Crown.
			_poly(c, h, [Vector2(-1, .7), Vector2(-1, -.6), Vector2(-.5, -.05), Vector2(0, -.95), Vector2(.5, -.05), Vector2(1, -.6), Vector2(1, .7)], col)
			for x in [-.6, 0.0, .6]:
				Dot.circle(self, c + Vector2(x, .35) * h, h * .13, INK)
		"drop": # Vampire Kiss.
			Dot.circle(self, c + Vector2(0, .3) * h, h * .62, col)
			_poly(c, h, [Vector2(0, -1), Vector2(.58, .1), Vector2(-.58, .1)], col)
		"flame": # Ember Rim.
			_poly(c, h, [Vector2(0, -1), Vector2(.55, -.15), Vector2(.7, .45), Vector2(.3, .95), Vector2(-.3, .95), Vector2(-.7, .45), Vector2(-.45, -.25), Vector2(-.2, .05)], col)
			_poly(c, h, [Vector2(0, -.1), Vector2(.3, .45), Vector2(.15, .8), Vector2(-.15, .8), Vector2(-.3, .45)], INK)
		"snow": # Frost Rim.
			for k in 3:
				var d := Vector2.from_angle(k * PI / 3.0 + PI / 2.0) * h * .9
				Dot.line(self, c - d, c + d, col, maxf(2.0, s * .1))
				for e in [d, -d]:
					var t: Vector2 = c + e * .6
					Dot.line(self, t, t + e.rotated(.8) * .3, col, maxf(1.5, s * .07))
					Dot.line(self, t, t + e.rotated(-.8) * .3, col, maxf(1.5, s * .07))
		"rebound": # Rebound Bolt: a spark bouncing off a wall.
			Dot.line(self, c + Vector2(-.9, -1) * h, c + Vector2(-.9, 1) * h, col, maxf(2.0, s * .1))
			Dot.pline(self, PackedVector2Array([c + Vector2(.1, -.9) * h, c + Vector2(-.75, 0) * h, c + Vector2(.4, .55) * h]), col, maxf(2.0, s * .08), true)
			_poly(c + Vector2(.55, .6) * h, h * .45, [Vector2(0, -1), Vector2(.3, -.3), Vector2(1, 0), Vector2(.3, .3), Vector2(0, 1), Vector2(-.3, .3), Vector2(-1, 0), Vector2(-.3, -.3)], col)
		"pinball": # Pinball: a ball knocked into a wall.
			Dot.line(self, c + Vector2(.95, -1) * h, c + Vector2(.95, 1) * h, col, maxf(2.0, s * .12))
			Dot.circle(self, c + Vector2(.3, 0) * h, h * .48, col)
			for y in [-.5, 0.0, .5]:
				Dot.line(self, c + Vector2(-1, y) * h, c + Vector2(-.4, y) * h, col, maxf(1.5, s * .07))
		"mine": # Bounce Mine.
			for k in 8:
				var d := Vector2.from_angle(k * TAU / 8.0)
				Dot.line(self, c + d * h * .4, c + d * h * .95, col, maxf(2.0, s * .08))
			Dot.circle(self, c, h * .58, col)
			Dot.circle(self, c, h * .2, INK)
		"fist": # Payback: two arrows trading blows.
			_poly(c, h, [Vector2(-1, -.35), Vector2(.2, -.35), Vector2(.2, -.7), Vector2(.8, -.1), Vector2(-1, -.1)], col)
			_poly(c, h, [Vector2(1, .35), Vector2(-.2, .35), Vector2(-.2, .7), Vector2(-.8, .1), Vector2(1, .1)], col)
		"collar": # Zap Collar: a ring with a bolt on it.
			Dot.arc(self, c, h * .8, 0, TAU, 28, col, maxf(2.0, s * .1), true)
			_poly(c, h * .7, [Vector2(.2, -1), Vector2(-.6, .15), Vector2(-.05, .15), Vector2(-.25, 1), Vector2(.65, -.25), Vector2(.1, -.25)], col)
		"wind": # Second Wind: gust lines.
			Dot.arc(self, c + Vector2(.25, -.45) * h, h * .32, PI * .9, TAU + PI * .5, 14, col, maxf(2.0, s * .09), true)
			Dot.line(self, c + Vector2(-1, -.13) * h, c + Vector2(.25, -.13) * h, col, maxf(2.0, s * .09))
			Dot.line(self, c + Vector2(-.8, .25) * h, c + Vector2(.85, .25) * h, col, maxf(2.0, s * .09))
			Dot.arc(self, c + Vector2(.45, .6) * h, h * .35, -PI * .5, PI * .9, 14, col, maxf(2.0, s * .09), true)
		"thermo": # Fever: a thermometer.
			Dot.line(self, c + Vector2(0, -.85) * h, c + Vector2(0, .35) * h, col, maxf(3.0, s * .2))
			Dot.circle(self, c + Vector2(0, .6) * h, h * .36, col)
			Dot.line(self, c + Vector2(0, -.1) * h, c + Vector2(0, .5) * h, INK, maxf(1.5, s * .07))
			for y in [-.6, -.3]:
				Dot.line(self, c + Vector2(.2, y) * h, c + Vector2(.45, y) * h, col, maxf(1.5, s * .06))
		"storm": # Storm Heart: a cloud with lightning.
			Dot.circle(self, c + Vector2(-.4, -.3) * h, h * .38, col)
			Dot.circle(self, c + Vector2(.15, -.5) * h, h * .45, col)
			Dot.circle(self, c + Vector2(.55, -.2) * h, h * .32, col)
			Dot.rect(self, Rect2(c + Vector2(-.75, -.3) * h, Vector2(1.6, .35) * h), col)
			_poly(c + Vector2(0, .5) * h, h * .55, [Vector2(.2, -1), Vector2(-.6, .15), Vector2(-.05, .15), Vector2(-.25, 1), Vector2(.65, -.25), Vector2(.1, -.25)], col)
		"titan": # Titan Belt: a big ball with a buckled belt.
			Dot.circle(self, c, h * .92, col)
			Dot.rect(self, Rect2(c + Vector2(-.92, -.16) * h, Vector2(1.84, .32) * h), INK)
			Dot.rect(self, Rect2(c + Vector2(-.24, -.3) * h, Vector2(.48, .6) * h), col.lightened(.3))
			Dot.rect(self, Rect2(c + Vector2(-.12, -.16) * h, Vector2(.24, .32) * h), INK)
		_:
			Dot.circle(self, c, h * .6, col)


func _poly(c: Vector2, h: float, pts: Array, col: Color) -> void:
	var out := PackedVector2Array()
	for p in pts:
		out.append(c + p * h)
	Dot.poly(self, out, col)
