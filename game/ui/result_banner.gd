## The banner behind a result's headline (YOU WIN!, Victory!, Defeated): a
## ribbon with notched tails in the headline's colour and, for a win, soft
## rays fanning out behind it and a sparkle at each end. Wrap the headline
## row in one; it draws once whenever the mood changes. Render-only.
extends MarginContainer

const Dot := preload("res://game/dot.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const A11y := preload("res://game/a11y.gd")
const OPEN_SECS := .32

var col := Color.WHITE
var win := false
var _open := 1.0 ## 0 rolled up in the middle, 1 unfurled.


static func wrap(row: Control) -> Node:
	var b = load("res://game/ui/result_banner.gd").new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_constant_override("margin_top", 6)
	b.add_theme_constant_override("margin_bottom", 6)
	b.add_child(row)
	return b


func set_mood(colour: Color, won: bool) -> void:
	col = colour
	win = won
	queue_redraw()
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	_unfurl()


## The ribbon stretches open from the middle, the win rays fan out once,
## then the headline drops in with a bounce. A tween, so it costs nothing
## once it has stopped.
func _unfurl() -> void:
	if A11y.motion() == 0.0:
		return
	_open = 0.0
	var row: Control = get_child(0) if get_child_count() > 0 else null
	if row != null:
		row.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		_open = t
		queue_redraw(), 0.0, 1.0, OPEN_SECS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(.08)
	if row == null:
		return
	tw.tween_callback(func():
		row.modulate.a = 1.0
		row.pivot_offset = row.size / 2.0
		row.scale = Vector2(1.35, 1.35))
	tw.tween_property(row, "scale", Vector2.ONE, .26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var c := size / 2.0
	var h := size.y
	var w := minf(size.x, h * 7.5) * lerpf(.12, 1.0, _open)
	if _open <= 0.0:
		return
	if win:
		# Rays behind everything, squashed wide so they stay inside the card.
		draw_set_transform(c, 0.0, Vector2(1.0, .42))
		for k in 14:
			var a := TAU * k / 14 + .11
			var tip := Vector2.from_angle(a) * w * .55
			var side := Vector2.from_angle(a + PI / 2) * w * .035
			Dot.poly(self, PackedVector2Array([Vector2.ZERO, tip - side, tip + side]), Color(col, .07 * _open))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		Dot.circle(self, c, h * .9, Color(col, .06))
	# The ribbon: a band with a fold and a notched tail at each end.
	var band := h * .62
	var half := w * .43
	var top := c.y - band / 2.0
	var ink := Color(col.darkened(.6), .42 if win else .3)
	for sgn in [-1.0, 1.0]:
		var x0: float = c.x + sgn * (half - h * .1)
		var x1: float = c.x + sgn * (half + h * .55)
		var drop := band * .22
		Dot.poly(self, PackedVector2Array([Vector2(x0, top + drop), Vector2(x1, top + drop), Vector2(x1 - sgn * h * .2, top + drop + band / 2.0),
			Vector2(x1, top + drop + band), Vector2(x0, top + drop + band)]), Color(ink.darkened(.3), ink.a))
		Dot.poly(self, PackedVector2Array([Vector2(x0, top + band), Vector2(x0 + sgn * h * .1, top + band), Vector2(x0, top + band + drop)]), Color(0, 0, 0, ink.a))
	Dot.poly(self, PackedVector2Array([Vector2(c.x - half, top), Vector2(c.x + half, top), Vector2(c.x + half, top + band), Vector2(c.x - half, top + band)]), ink)
	Dot.line(self, Vector2(c.x - half, top + 3), Vector2(c.x + half, top + 3), Color(col, .32 if win else .18), 2.0, true)
	Dot.line(self, Vector2(c.x - half, top + band - 3), Vector2(c.x + half, top + band - 3), Color(col, .2 if win else .1), 2.0, true)
	if win:
		for sgn in [-1.0, 1.0]:
			var p := Vector2(c.x + sgn * (half + h * .2), top - h * .08)
			Dot.poly(self, CritterArt.star_pts(p, h * .13, h * .045, 4), Color(col.lerp(Color.WHITE, .5), .85))
			Dot.poly(self, CritterArt.star_pts(p + Vector2(sgn * h * .2, h * .2), h * .07, h * .025, 4), Color(col.lerp(Color.WHITE, .5), .6))
