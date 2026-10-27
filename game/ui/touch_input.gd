## Phone-style touch handling for every screen, in one place:
## - a drag scrolls the ScrollContainer under the finger even when it starts on
##   a button or card (Godot's buttons swallow it otherwise), with a fling;
## - a swipe in from the left edge goes back, iOS style, where the current
##   screen says what Back means (set_back): when it also has a picture of
##   the screen underneath, the current screen follows the finger off to the
##   right over it (pictures only: nothing is rebuilt while dragging). Where
##   nothing says, it presses the Back (or Close) button on screen, so every
##   screen with a Back gets the swipe without wiring anything;
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
const PARALLAX := 0.3 ## The screen underneath starts this far (of the width) to the left.
const SHADE := 0.4 ## How dark the screen underneath starts.
const SETTLE_SECS := 0.2
const BACK_META := "swipe_back" ## mark_back(): the button a swipe presses.
const BACK_WORDS := ["BACK", "CLOSE"] ## Buttons that read like Back count anyway.
const QUIT_WINDOW_MS := 2000 ## Second Back within this leaves the game (Android).

const A11y := preload("res://game/a11y.gd")

enum Drag { NONE, PENDING, SCROLL, EDGE, IGNORE }

## owner -> Callable returning the back action (a Callable) or an empty Callable.
static var _back_sources := {}
## owner -> Callable returning {texture: a picture of the whole screen its
## back action returns to, rect: the part of the screen that slides}, or {}.
static var _back_previews := {}
static var _preview_source := Callable() ## The preview of the owner back_action() picked.
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
var _slide: Control ## The swipe-back pictures while dragging (null otherwise).
var _top: TextureRect ## The current screen, following the finger.
var _under: TextureRect ## The screen underneath.
var _shade: ColorRect
var _quit_armed := 0 ## Msec tick of a Back with nothing to go back to.
var _quit_hint: Label


## Adds the handler to the scene tree once; it survives scene changes.
static func ensure(from: Node) -> void:
	if is_instance_valid(_instance) or not from.is_inside_tree():
		return
	_instance = new()
	_instance.name = "TouchInput"
	from.get_tree().root.add_child.call_deferred(_instance)


## Says what a left-edge swipe does while `owner` is alive: `source` returns the
## action to run (a Callable), or an empty Callable when Back means nothing now.
## `preview` returns a picture of the screen it goes back to (or null), so the
## swipe can slide the current screen off over it.
static func set_back(owner: Object, source: Callable, preview := Callable()) -> void:
	_back_sources[owner] = source
	if preview.is_valid():
		_back_previews[owner] = preview


static func clear_back(owner: Object) -> void:
	_back_sources.erase(owner)
	_back_previews.erase(owner)


## A picture of what's on screen now (the last frame drawn), or null where
## pictures aren't wanted: reduced motion, or no screen at all (headless).
static func snapshot(from: Node) -> Texture2D:
	if A11y.reduced_motion or DisplayServer.get_name() == "headless" or not from.is_inside_tree():
		return null
	var img := from.get_viewport().get_texture().get_image()
	return ImageTexture.create_from_image(img) if img != null and not img.is_empty() else null


## True while a finger drags a list or a fling is still moving it. Busy
## animations (the live critter icons) hold still meanwhile so scrolling stays smooth.
## True while the edge swipe's pictures are up (the screen change it ends
## with has already been animated).
static func sliding() -> bool:
	return is_instance_valid(_instance) and is_instance_valid(_instance._slide)


static func scrolling() -> bool:
	return is_instance_valid(_instance) and (_instance._drag == Drag.SCROLL or is_instance_valid(_instance._fling))


## Makes `b` the button a left-edge swipe presses when it is on screen and
## nothing covers it. Buttons that read BACK or CLOSE count without this.
static func mark_back(b: BaseButton) -> BaseButton:
	b.set_meta(BACK_META, true)
	return b


## What a left-edge swipe would do right now (an empty Callable for nothing):
## what the newest set_back() owner says, else the Back button on screen.
static func back_action() -> Callable:
	for owner in _back_sources.keys():
		if not is_instance_valid(owner) or (owner is Node and not owner.is_inside_tree()):
			_back_sources.erase(owner)
	var keys := _back_sources.keys()
	for i in range(keys.size() - 1, -1, -1):
		var action: Callable = _back_sources[keys[i]].call()
		if action.is_valid():
			_preview_source = _back_previews.get(keys[i], Callable())
			return action
	_preview_source = Callable()
	if not is_instance_valid(_instance):
		return Callable()
	var button := back_button_on_screen(_instance.get_tree().root)
	return Callable(button, "emit_signal").bind("pressed") if button != null else Callable()


## The Back button a tap could reach right now: a marked (mark_back) or
## BACK / CLOSE button that is shown, enabled and not under anything else
## (a popup over a page covers the page's Back). The topmost one wins.
static func back_button_on_screen(root: Node) -> BaseButton:
	var found: Array = []
	_collect_backs(root, found)
	for i in range(found.size() - 1, -1, -1):
		var b: BaseButton = found[i]
		var hit := find_control(root, b.get_global_transform_with_canvas() * (b.size / 2.0))
		if hit == b or (hit != null and b.is_ancestor_of(hit)):
			return b
	return null


static func _collect_backs(node: Node, out: Array) -> void:
	for child in node.get_children():
		if (child is CanvasItem or child is CanvasLayer) and not child.visible:
			continue
		if child is BaseButton and not child.disabled \
				and (child.has_meta(BACK_META) or (child is Button and child.text.strip_edges().to_upper() in BACK_WORDS)):
			out.append(child)
		_collect_backs(child, out)


## Lets go of whatever the finger is pressing without tapping it (a long
## press that opened something instead).
static func cancel_press() -> void:
	if is_instance_valid(_instance):
		_instance._drag = Drag.IGNORE
		_instance._cancel_press()


func _ready() -> void:
	process_priority = -100
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_hint = BackHint.new()
	_hint.visible = false
	layer.add_child(_hint)


## Android's Back gesture / button (application/config/quit_on_go_back is off,
## so the game decides): it does what a left-edge swipe would. With nothing to
## go back to, a second Back within QUIT_WINDOW_MS leaves the game.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or _drag == Drag.EDGE or _slide != null:
		return
	var action := back_action()
	if action.is_valid():
		_quit_armed = 0
		action.call()
		return
	var now := Time.get_ticks_msec()
	if _quit_armed > 0 and now - _quit_armed < QUIT_WINDOW_MS:
		get_tree().quit()
		return
	_quit_armed = now
	_show_quit_hint()


func _show_quit_hint() -> void:
	if _quit_hint == null:
		_quit_hint = Label.new()
		_quit_hint.text = "Press Back again to leave"
		_quit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_quit_hint.add_theme_font_size_override("font_size", A11y.font(24))
		_quit_hint.add_theme_color_override("font_color", Color.WHITE)
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.08, 0.07, 0.2, 0.92)
		st.set_corner_radius_all(24)
		st.set_content_margin_all(16)
		_quit_hint.add_theme_stylebox_override("normal", st)
		_quit_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_quit_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_quit_hint.position.y -= 220
		_hint.get_parent().add_child(_quit_hint)
	_quit_hint.visible = true
	_quit_hint.modulate.a = 1.0
	var tw := _quit_hint.create_tween()
	tw.tween_interval(QUIT_WINDOW_MS / 1000.0 - 0.3)
	tw.tween_property(_quit_hint, "modulate:a", 0.0, 0.3)


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
				_start_slide()
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
			var go := (moved.x > width * (BACK_DISTANCE if _slide == null else 1.0 / 3.0) or flick) and _back_action.is_valid()
			if _slide != null:
				_settle(go, _back_action)
			elif go:
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
	if _slide != null:
		_place_slide(clampf(pos.x - _start.x, 0.0, width) / width)
		return
	_hint.visible = true
	_hint.progress = clampf((pos.x - _start.x) / (width * BACK_DISTANCE), 0.0, 1.0)
	_hint.y = pos.y
	_hint.queue_redraw()


## The iOS-style swipe: when the back action has a picture of the screen it
## returns to, cover everything with that picture (dimmed, a little to the
## left) and a picture of the current screen on top, which then follows the
## finger. Two textures moving: no screen is built or redrawn meanwhile.
func _start_slide() -> void:
	_end_slide()
	if not _preview_source.is_valid() or A11y.reduced_motion:
		return
	var preview: Dictionary = _preview_source.call()
	if not preview.get("texture") is Texture2D:
		return
	var top := snapshot(self)
	if top == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var rect: Rect2 = preview.get("rect", Rect2(Vector2.ZERO, screen))
	var size := rect.size
	_slide = Control.new()
	_slide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slide.position = rect.position
	_slide.size = size
	_slide.clip_contents = true
	_under = _picture(_crop(preview.texture, rect, screen), size)
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, SHADE)
	_shade.size = size
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top = _picture(_crop(top, rect, screen), size)
	var shadow := _Shadow.new()
	shadow.size = Vector2(28.0, size.y)
	shadow.position = Vector2(-28.0, 0.0)
	_top.add_child(shadow)
	for c in [_under, _shade, _top]:
		_slide.add_child(c)
	_hint.get_parent().add_child(_slide)
	_place_slide(0.0)


## The part of a whole-screen picture under `rect` (in screen units).
func _crop(tex: Texture2D, rect: Rect2, screen: Vector2) -> Texture2D:
	var k := Vector2(tex.get_size()) / screen
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(rect.position * k, rect.size * k)
	return a


func _picture(tex: Texture2D, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## `t`: 0 with the current screen in place, 1 with it gone off the right edge.
func _place_slide(t: float) -> void:
	var w := _slide.size.x
	_top.position.x = w * t
	_under.position.x = -w * PARALLAX * (1.0 - t)
	_shade.color.a = SHADE * (1.0 - t)


## Let go: slide the rest of the way and go back, or slide back into place.
## Going back runs once the current screen is off, then the pictures stay up
## a couple of frames while the screen underneath is rebuilt for real.
func _settle(go: bool, action: Callable) -> void:
	var slide := _slide
	var from := _top.position.x / slide.size.x
	var tw := create_tween()
	var move := func(t: float) -> void:
		if is_instance_valid(slide) and slide == _slide:
			_place_slide(t)
	tw.tween_method(move, from, 1.0 if go else 0.0, SETTLE_SECS * ((1.0 - from) if go else from) + .05) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.finished.connect(func():
		if go:
			action.call()
			await get_tree().process_frame
			await get_tree().process_frame
		if slide == _slide:
			_end_slide())


func _end_slide() -> void:
	if is_instance_valid(_slide):
		_slide.queue_free()
	_slide = null


## The soft shadow down the left edge of the sliding screen.
class _Shadow extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var cols := PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, .35), Color(0, 0, 0, .35), Color(0, 0, 0, 0)])
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, size.y), Vector2(0, size.y)]), cols)


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
