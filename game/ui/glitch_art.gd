## The Glitch (design/glitch.md): a magenta ball that didn't finish loading.
## Drawn as a pixel staircase with a cyan/magenta split, one square eye, one
## loading-spinner eye and a "missing texture" checker on its cheek. It
## stutters instead of sliding. Redraws about 12 times a second, and holds
## still with reduced motion on.
extends Control

const A11y := preload("res://game/a11y.gd")

const PINK := Color("ff2bd6")
const PURPLE := Color("7a1cff")
const CYAN := Color("00e5ff")
const STEP := 1.0 / 12.0

var _t := 0.0
var _acc := 0.0
var _jump := Vector2.ZERO


static func make(side: float) -> Control:
	var g = load("res://game/ui/glitch_art.gd").new()
	g.custom_minimum_size = Vector2(side, side)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g


func _process(delta: float) -> void:
	if A11y.reduced_motion or not is_visible_in_tree():
		return
	_t += delta
	_acc += delta
	if _acc < STEP:
		return
	_acc = 0.0
	# Dropped frames: mostly still, now and then a hop of a few pixels.
	_jump = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * size.x * .03 if randf() < .12 else Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y)
	var r := side * .36
	var c := size / 2.0 + _jump
	var px := maxf(2.0, roundf(r / 6.0))
	var split := px * (.6 + .4 * sin(_t * 3.0))
	_ball(c - Vector2(split, 0), r, px, Color(CYAN, .45), Color(CYAN, .45))
	_ball(c + Vector2(split, 0), r, px, Color(PINK, .45), Color(PINK, .45))
	_ball(c, r, px, PINK, PURPLE)
	# Scanlines.
	var y := c.y - r + fmod(_t * px * 2.0, px * 2.0)
	while y < c.y + r:
		var half := sqrt(maxf(0.0, r * r - (y - c.y) * (y - c.y)))
		draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), Color(0, 0, 0, .14), 1.0)
		y += px * 2.0
	# The square eye, looking around.
	var eye := c + Vector2(-r * .36, -r * .18)
	var e := px * 2.4
	draw_rect(Rect2(eye - Vector2(e, e) / 2.0, Vector2(e, e)), Color.WHITE)
	var look := Vector2(cos(_t * .8), sin(_t * 1.3)) * e * .2
	draw_rect(Rect2(eye + look - Vector2(e, e) / 4.0, Vector2(e, e) / 2.0), Color("140a2a"))
	# The loading-spinner eye: 8 dots, one bright.
	var spin := c + Vector2(r * .36, -r * .18)
	var lead := int(_t * 10.0) % 8
	for k in 8:
		var a := TAU * k / 8.0
		var fade := float((k - lead + 8) % 8) / 8.0
		draw_rect(Rect2(spin + Vector2(cos(a), sin(a)) * e * .55 - Vector2(px, px) * .35, Vector2(px, px) * .7), Color(1, 1, 1, 1.0 - fade * .85))
	# A jagged grin with one tooth-pixel missing.
	for k in 6:
		if k == 4:
			continue
		var gx := c.x - px * 3.0 + k * px
		var gy := c.y + r * .32 + (px * .5 if k % 2 == 0 else 0.0)
		draw_rect(Rect2(Vector2(gx, gy), Vector2(px * .9, px * .9)), Color("140a2a"))
	# Missing-texture checker on the cheek.
	var ch := c + Vector2(r * .3, r * .12)
	for i in 2:
		for j in 2:
			draw_rect(Rect2(ch + Vector2(i, j) * px * .7, Vector2(px, px) * .7), Color.BLACK if (i + j) % 2 == 0 else PINK.lightened(.3))
	# Loose pixels drifting up off its head.
	for k in 4:
		var f := fmod(_t * .5 + k * .25, 1.0)
		var at := c + Vector2((k - 1.5) * r * .4, -r - f * r * .6)
		draw_rect(Rect2(at, Vector2(px, px) * .8), Color(PINK.lightened(.3), 1.0 - f))


## A round ball made of square cells, shaded top to bottom.
func _ball(c: Vector2, r: float, px: float, top: Color, bottom: Color) -> void:
	var n := int(ceil(r / px))
	for j in range(-n, n):
		for i in range(-n, n):
			var cell := Vector2(i + .5, j + .5) * px
			if cell.length() <= r:
				draw_rect(Rect2(c + Vector2(i, j) * px, Vector2(px, px)), top.lerp(bottom, (j + n) / (2.0 * n)))
