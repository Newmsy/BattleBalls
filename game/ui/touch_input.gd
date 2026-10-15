## Phone-style touch handling for every screen, in one place:
## - a drag scrolls the ScrollContainer under the finger even when it starts on
##   a button or card (Godot's buttons swallow it otherwise), with a fling;
## - a swipe in from the left edge goes back, iOS style, where the current
##   screen says what Back means (set_back);
## - a tap is still a tap: a press only becomes a scroll or swipe once it moves
##   past a small dead zone, and then the button under it is let go untapped.
## Works on the emulated mouse events (touch on phones, the mouse on desktop),
## before the GUI sees them. Render/UI only; never touches the sim.
extends Node

const DEAD_ZONE := 18.0 ## Design pixels a press can wander and still be a tap.
const EDGE := 36.0 ## Presses this close to the left edge can swipe back.
const BACK_DISTANCE := 0.22 ## Fraction of the width a swipe must cover to go back...
const BACK_FLICK := 900.0 ## ...or a flick at least this fast (px/s) over 60 px.
const FLING_DECAY := 4.5 ## Per second; higher stops a fling sooner.
const NOT_BUILT_IN := 1 << 20 ## Dead zone that keeps Godot's own touch drag out of the way.

enum Drag { NONE, PENDING, SCROLL, EDGE, IGNORE }

## owner -> Callable returning the back action (a Callable) or an empty Callable.
static var _back_sources := {}
static var _instance: Node

var _drag := Drag.NONE
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _last_time := 0
var _velocity := Vector2.ZERO
var _scrolls: Array = [] ## ScrollContainers under the press, innermost first.
var _scroll: ScrollContainer
var _axis := 1 ## 0 = horizontal, 1 = vertical.
var _from := 0.0 ## Scroll value when the drag took over.
var _anchor := 0.0 ## Pointer position (on _axis) when the drag took over.
var _back_action := Callable()
var _fling: ScrollContainer
var _fling_axis := 1
var _fling_speed := 0.0
var _hint: Control ## The edge-swipe arrow.


## Adds the handler to the scene tree once; it survives scene changes.
static func ensure(from: Node) -> void:
	if is_instance_valid(_instance) or not from.is_inside_tree():
		return
	_instance = new()
	_instance.name = "TouchInput"
	from.get_tree().root.add_child.call_deferred(_instance)


## Says what a left-edge swipe does while `owner` is alive: `source` returns the
## action to run (a Callable), or an empty Callable when Back means nothing now.
static func set_back(owner: Object, source: Callable) -> void:
	_back_sources[owner] = source


static func clear_back(owner: Object) -> void:
	_back_sources.erase(owner)


## True while a finger drags a list or a fling is still moving it. Busy
## animations (the live critter icons) hold still meanwhile so scrolling stays smooth.
static func scrolling() -> bool:
	return is_instance_valid(_instance) and (_instance._drag == Drag.SCROLL or is_instance_valid(_instance._fling))


## What a left-edge swipe would do right now (an empty Callable for nothing).
static func back_action() -> Callable:
	for owner in _back_sources.keys():
		if not is_instance_valid(owner) or (owner is Node and not owner.is_inside_tree()):
			_back_sources.erase(owner)
	var keys := _back_sources.keys()
	for i in range(keys.size() - 1, -1, -1):
		var action: Callable = _back_sources[keys[i]].call()
		if action.is_valid():
			return action
	return Callable()


func _ready() -> void:
	process_priority = -100
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_hint = BackHint.new()
	_hint.visible = false
	layer.add_child(_hint)


func _input(event: InputEvent) -> void:
	if event.has_meta("touch_input_cancel"):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(event.position)
		else:
			_release()
	elif event is InputEventMouseMotion and _drag != Drag.NONE and _drag != Drag.IGNORE:
		_move(event.position)


func _press(pos: Vector2) -> void:
	_fling = null
	_drag = Drag.PENDING
	_start = pos
	_last = pos
	_last_time = Time.get_ticks_msec()
	_velocity = Vector2.ZERO
	_scrolls = []
	var hit := find_control(get_tree().root, pos)
	var node: Node = hit
	while node != null:
		if node is ScrollContainer and node.is_visible_in_tree():
			_scrolls.append(node)
			# Our drag replaces Godot's own touch drag, which would fight it.
			node.scroll_deadzone = NOT_BUILT_IN
		node = node.get_parent()
	_back_action = back_action() if pos.x <= EDGE else Callable()


func _move(pos: Vector2) -> void:
	var now := Time.get_ticks_msec()
	var dt := maxf(0.001, (now - _last_time) / 1000.0)
	_velocity = _velocity.lerp((pos - _last) / dt, 0.5)
	_last = pos
	_last_time = now
	var moved := pos - _start
	match _drag:
		Drag.PENDING:
			if moved.length() < DEAD_ZONE:
				return
			if _back_action.is_valid() and moved.x > 0.0 and moved.x > absf(moved.y) * 1.2:
				_drag = Drag.EDGE
				_cancel_press()
				_update_hint(pos)
			else:
				_axis = 0 if absf(moved.x) > absf(moved.y) else 1
				_scroll = _scrollable(_axis)
				if _scroll == null:
					_drag = Drag.IGNORE ## Not ours: aiming, sliders and so on.
					return
				_drag = Drag.SCROLL
				_from = _value(_scroll, _axis)
				_anchor = pos[_axis]
				_cancel_press()
			get_viewport().set_input_as_handled()
		Drag.SCROLL:
			if is_instance_valid(_scroll):
				_set_value(_scroll, _axis, _from - (pos[_axis] - _anchor))
			get_viewport().set_input_as_handled()
		Drag.EDGE:
			_update_hint(pos)
			get_viewport().set_input_as_handled()


func _release() -> void:
	match _drag:
		Drag.SCROLL:
			if is_instance_valid(_scroll) and Time.get_ticks_msec() - _last_time < 80:
				_fling = _scroll
				_fling_axis = _axis
				_fling_speed = -_velocity[_axis]
			get_viewport().set_input_as_handled()
		Drag.EDGE:
			_hint.visible = false
			var moved := _last - _start
			var width := get_viewport().get_visible_rect().size.x
			var flick := _velocity.x > BACK_FLICK and moved.x > 60.0
			if (moved.x > width * BACK_DISTANCE or flick) and _back_action.is_valid():
				_back_action.call_deferred()
			get_viewport().set_input_as_handled()
	_drag = Drag.NONE
	_scroll = null
	_back_action = Callable()


func _process(delta: float) -> void:
	if not is_instance_valid(_fling) or absf(_fling_speed) < 20.0:
		_fling = null
		return
	var before := _value(_fling, _fling_axis)
	_set_value(_fling, _fling_axis, before + _fling_speed * delta)
	if is_equal_approx(before, _value(_fling, _fling_axis)):
		_fling = null ## Hit an end.
		return
	_fling_speed *= exp(-FLING_DECAY * delta)


## The innermost scroll area under the press that can move along `axis`.
func _scrollable(axis: int) -> ScrollContainer:
	for s in _scrolls:
		if not is_instance_valid(s):
			continue
		var mode: int = s.horizontal_scroll_mode if axis == 0 else s.vertical_scroll_mode
		var bar: ScrollBar = s.get_h_scroll_bar() if axis == 0 else s.get_v_scroll_bar()
		if mode != ScrollContainer.SCROLL_MODE_DISABLED and bar.max_value - bar.page > 0.5:
			return s
	return null


func _value(s: ScrollContainer, axis: int) -> float:
	return float(s.scroll_horizontal if axis == 0 else s.scroll_vertical)


func _set_value(s: ScrollContainer, axis: int, v: float) -> void:
	var bar: ScrollBar = s.get_h_scroll_bar() if axis == 0 else s.get_v_scroll_bar()
	bar.value = clampf(v, 0.0, maxf(0.0, bar.max_value - bar.page))


## Lets go of the button under the finger without tapping it: the GUI sees the
## pointer leave and lift far off screen, so the press doesn't count.
func _cancel_press() -> void:
	var away := Vector2(-100000, -100000)
	var motion := InputEventMouseMotion.new()
	motion.position = away
	motion.global_position = away
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.set_meta("touch_input_cancel", true)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = away
	up.global_position = away
	up.set_meta("touch_input_cancel", true)
	get_viewport().push_input.call_deferred(motion, true)
	get_viewport().push_input.call_deferred(up, true)


func _update_hint(pos: Vector2) -> void:
	var width := get_viewport().get_visible_rect().size.x
	_hint.visible = true
	_hint.progress = clampf((pos.x - _start.x) / (width * BACK_DISTANCE), 0.0, 1.0)
	_hint.y = pos.y
	_hint.queue_redraw()


## The control a press at `pos` lands on, the way the GUI picks it: the top
## canvas layer first, later siblings over earlier ones, skipping hidden and
## click-through (MOUSE_FILTER_IGNORE) controls.
static func find_control(root: Node, pos: Vector2) -> Control:
	var tops: Array = []
	_collect_tops(root, 0, true, tops)
	tops.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for i in range(tops.size() - 1, -1, -1):
		var hit := _hit(tops[i][2], pos)
		if hit != null:
			return hit
	return null


static func _collect_tops(node: Node, layer: int, shown: bool, out: Array) -> void:
	for child in node.get_children():
		if child is CanvasLayer:
			_collect_tops(child, child.layer, shown and child.visible, out)
		elif child is Control:
			if shown:
				out.append([layer, out.size(), child])
		elif child is CanvasItem:
			_collect_tops(child, layer, shown and child.visible, out)
		else:
			_collect_tops(child, layer, shown, out)


static func _hit(c: Control, pos: Vector2) -> Control:
	if not c.visible:
		return null
	var local := c.get_global_transform_with_canvas().affine_inverse() * pos
	var inside := Rect2(Vector2.ZERO, c.size).has_point(local)
	if c.clip_contents and not inside:
		return null
	for i in range(c.get_child_count() - 1, -1, -1):
		var child := c.get_child(i)
		if child is Control and not child.top_level:
			var hit := _hit(child, pos)
			if hit != null:
				return hit
	if inside and c.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return c
	return null


## A round arrow that slides in from the left edge and lights up once letting
## go would go back.
class BackHint extends Control:
	const Kit := preload("res://game/ui/ui_kit.gd")
	var progress := 0.0
	var y := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		var armed := progress >= 1.0
		var c := Vector2(-30.0 + 90.0 * progress, y)
		draw_circle(c, 40.0, Kit.ACCENT if armed else Kit.PANEL2)
		draw_arc(c, 40.0, 0.0, TAU, 40, Kit.ACCENT, 3.0, true)
		var ink := Kit.BG if armed else Kit.FG
		draw_polyline(PackedVector2Array([c + Vector2(8, -16), c + Vector2(-8, 0), c + Vector2(8, 16)]), ink, 7.0, true)
