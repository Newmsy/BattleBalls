## A new player's guided step (game/ui/intro.gd): the screen dims, the one
## control to tap stays lit inside a gold ring, and the step's hint sits right
## beside it (Newms, 2026-11-03: "the rest of the screen a bit dimmed and the
## thing you have to click on spotlighted"). Every tap passes straight through,
## so a player can never get stuck behind it. It follows its target while the
## screen slides or scrolls, but only redraws when the target has moved.
## While it is lit, `fallback` (the shell's usual hint pill) is see-through
## instead of hidden, so the layout under it never shifts.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Motion := preload("res://game/ui/motion.gd")
const A11y := preload("res://game/a11y.gd")

const DIM := Color(0.016, 0.012, 0.06, 0.62)
const RING := Color("ffd166")
const PAD := 12.0 ## Room between the target's edge and the ring.
const GAP := 18.0 ## Room between the ring and the hint.
## Below this line (the tab bar) the hint goes above its target instead.
const FLOOR := 210.0

var target: Control
var fallback: Control
var blocked := Callable() ## Returns true while something covers the screen (a sheet).
var _hole := Rect2()
var _hint: Label
var _lit := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hint = Kit.label("", 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	var st := Kit.box(Color("1c3a2e"), Kit.GOOD, 26, 2, 10)
	st.content_margin_left = 22
	st.content_margin_right = 22
	_hint.add_theme_stylebox_override("normal", st)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	visible = false
	set_process(false)


## Light `c` with `text` beside it; a null `c` turns the spotlight off.
func show_on(c: Control, text: String) -> void:
	var fresh := c != target or text != _hint.text
	target = c
	_hint.text = text
	_hint.visible = text != ""
	set_process(c != null)
	if c == null:
		_set_lit(false)
		return
	if fresh:
		_hole = Rect2()
	_follow()
	if fresh and _lit:
		Motion.pop(_hint, .85, .3)


## True while the dim and the ring are on screen.
func lit() -> bool:
	return _lit


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	var on: bool = is_instance_valid(target) and target.is_visible_in_tree() and not (blocked.is_valid() and blocked.call())
	var r := Rect2()
	if on:
		r = target.get_global_rect()
		r.position -= get_global_rect().position
		# A target scrolled out of sight (or not laid out yet) gets the usual hint instead.
		on = r.size.x > 4.0 and r.size.y > 4.0 and Rect2(Vector2.ZERO, size).encloses(r.grow(-2.0))
	_set_lit(on)
	if not on:
		return
	r = r.grow(PAD)
	if r.is_equal_approx(_hole):
		return
	_hole = r
	_place_hint()
	queue_redraw()


func _set_lit(on: bool) -> void:
	if on == _lit and visible == on:
		return
	_lit = on
	visible = on
	if fallback != null:
		fallback.modulate.a = 0.0 if on else 1.0


## Under the ring when there's room above the tab bar, otherwise over it;
## centred on the target and kept inside the screen.
func _place_hint() -> void:
	if not _hint.visible:
		return
	# Hints are one short line; a long one shrinks its font to fit the screen.
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint.custom_minimum_size = Vector2.ZERO
	var fs := A11y.font(24)
	_hint.add_theme_font_size_override("font_size", fs)
	var room := size.x - 64.0
	var wide := _hint.get_combined_minimum_size().x
	if wide > room:
		_hint.add_theme_font_size_override("font_size", maxi(14, floori(fs * room / wide)))
	_hint.size = _hint.get_combined_minimum_size()
	var h := _hint.size
	var y := _hole.end.y + GAP
	if y + h.y > size.y - FLOOR:
		y = _hole.position.y - GAP - h.y
	var x := clampf(_hole.get_center().x - h.x / 2.0, 32.0, size.x - 32.0 - h.x)
	_hint.position = Vector2(x, maxf(8.0, y))


func _draw() -> void:
	if not _lit:
		return
	var s := size
	var h := _hole
	# The dim, in four bands round the hole.
	draw_rect(Rect2(0, 0, s.x, h.position.y), DIM)
	draw_rect(Rect2(0, h.end.y, s.x, s.y - h.end.y), DIM)
	draw_rect(Rect2(0, h.position.y, h.position.x, h.size.y), DIM)
	draw_rect(Rect2(h.end.x, h.position.y, s.x - h.end.x, h.size.y), DIM)
	# Rounded corners: each square corner of the hole, less a quarter circle.
	var rad := minf(30.0, minf(h.size.x, h.size.y) / 2.0)
	for c in [[h.position, Vector2(1, 1)], [Vector2(h.end.x, h.position.y), Vector2(-1, 1)],
			[h.end, Vector2(-1, -1)], [Vector2(h.position.x, h.end.y), Vector2(1, -1)]]:
		var corner: Vector2 = c[0]
		var inward: Vector2 = c[1]
		var centre := corner + inward * rad
		var pts := PackedVector2Array([corner])
		for k in 9:
			var a := PI / 2.0 * k / 8.0
			pts.append(centre - Vector2(cos(a) * inward.x, sin(a) * inward.y) * rad)
		draw_colored_polygon(pts, DIM)
	var ring := StyleBoxFlat.new()
	ring.bg_color = Color(0, 0, 0, 0)
	ring.border_color = RING
	ring.set_border_width_all(5)
	ring.set_corner_radius_all(int(rad))
	ring.corner_detail = 12
	ring.shadow_color = Color(RING, .35)
	ring.shadow_size = 14
	draw_style_box(ring, h)
