## The quick circle wipe between the menus and a fight: when one replaces
## the other, the new picture opens out of a circle from where you tapped
## (the Fight button), over 0.3s. It never takes a tap and frees itself.
## Off with Reduced motion. Render-only.
extends Control

const A11y := preload("res://game/a11y.gd")
const SECS := .3
const INK := Color("06051a")

var _at := Vector2.ZERO
var _r := 0.0


## Over `parent` (a node in the scene tree), opening from `at` (screen units).
static func open(parent: Node, at: Vector2) -> void:
	if A11y.reduced_motion or not parent.is_inside_tree():
		return
	var layer := CanvasLayer.new()
	layer.layer = 50
	parent.add_child(layer)
	var w = load("res://game/ui/wipe.gd").new()
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	w._at = at
	layer.add_child(w)
	var far: float = w.get_viewport_rect().size.length()
	var tw: Tween = w.create_tween()
	tw.tween_method(func(r: float) -> void:
		w._r = r
		w.queue_redraw(), 0.0, far, SECS).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(layer.queue_free)


func _draw() -> void:
	# Everything outside the circle: one very thick ring round it.
	var reach := get_viewport_rect().size.length() * 2.0
	draw_arc(_at, _r + reach / 2.0, 0.0, TAU, 72, INK, reach)
