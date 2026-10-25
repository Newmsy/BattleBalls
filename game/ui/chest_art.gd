## A painted Bounce Run chest (tools/event_art/scenes/bounce_chests.mjs): the
## box and its lid are two pictures on the same canvas, stacked, so the lid
## can swing open on its hinge (game/ui/bounce_chest_open.gd).
extends Control

const PATH := "res://game/bounce_run/art/chest_%s_%s.png"
const CANVAS := Vector2(400, 360) ## Both pictures' size.
const HINGE := Vector2(200, 180) ## Where the lid's back edge meets the box, on the canvas.

var base: TextureRect
var lid: TextureRect


## Chest `id` (BounceChest.TIERS[].id), `height` px tall.
static func make(id: String, height: float) -> Control:
	var c = load("res://game/ui/chest_art.gd").new()
	c._build(id, height)
	return c


func _build(id: String, height: float) -> void:
	var k := height / CANVAS.y
	custom_minimum_size = CANVAS * k
	size = custom_minimum_size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	base = _picture(PATH % [id, "base"], k)
	lid = _picture(PATH % [id, "lid"], k)
	lid.pivot_offset = HINGE * k


func _picture(path: String, k: float) -> TextureRect:
	var r := TextureRect.new()
	if ResourceLoader.exists(path):
		r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = CANVAS * k
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r
