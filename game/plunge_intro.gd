## The start of a Critter Plunge race: the course's name and hazard slide
## in below the gate, a ring and a banner in your racer's rarity colour call
## it out, then a 3, 2, 1, GO! countdown pops up over the gate and the gate
## drops on GO (`go` fires; game/plunge.gd only starts the race then). A
## race run again goes straight to GO. A tap anywhere jumps straight to GO.
## Render only: the race is the same whenever it starts.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const ArenaTheme := preload("res://game/arena_theme.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")

signal go

const HAZARD_NAMES := {"wells": "Gravity wells", "lava": "Lava pools", "goo": "Sticky goo", "sliders": "Sliding bumpers"}
const BANNER_SECS := 1.3 ## The course banner holds this long before the count.
const BEAT := 0.7 ## Seconds between 3, 2, 1 and GO.
const COUNT_COLORS := [Color("ff6b8a"), Color("ffd166"), Color("7cf5d0")]
const GO_COLOR := Color("45f5a6")

var sfx ## game/audio/sfx.gd, for the beeps (null in tests).
var you_at := Callable() ## Returns your racer's spot on screen, or null.
var gate_at := Callable() ## Returns the gate's height on screen, or null.
var you_color := GO_COLOR ## Your racer's rarity colour, for its banner.

var _banner: Control
var _count: Label
var _ring := 0.0 ## 0..1 pulse of the ring round your racer.
var _clock := 0.0
var _gone := false
var _tween: Tween
var _pop: Tween ## The current beat's pop and fade; killed by the next beat.
var _laid_for := Vector2.ZERO


## Builds the overlay for `course` (a PlungeCourse) with `n` racers; `quick`
## (a race run again) is just GO!.
func start(course: PlungeCourse, n: int, quick := false) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var col := Color(ArenaTheme.get_theme(course.info.art).border)
	var hazard := ""
	for kind in course.info.plan:
		if HAZARD_NAMES.has(kind):
			hazard = HAZARD_NAMES[kind]
	var lines := Kit.vbox(4, [
		Kit.label("%d RACERS" % n, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label(course.info.name.to_upper(), 48, col, HORIZONTAL_ALIGNMENT_CENTER)])
	if hazard != "":
		lines.add_child(Kit.label(hazard, 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
	_banner = Kit.panel(lines, Kit.box(Color(Kit.BG, 0.88), Color(col, 0.7), 26, 3, 18))
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	_count = Kit.label("", 150, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	_count.add_theme_constant_override("outline_size", 18)
	_count.add_theme_color_override("font_outline_color", Color(Kit.BG, 0.9))
	_count.visible = false
	add_child(_count)
	if quick:
		_banner.visible = false
		_tween = create_tween()
		_tween.tween_interval(0.35)
		_tween.tween_callback(_beat.bind("GO!", GO_COLOR, true))
		_tween.tween_interval(0.6)
		_tween.tween_callback(queue_free)
		return
	_banner.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_banner, "modulate:a", 1.0, 0.25)
	if sfx != null:
		sfx.play("whoosh", -6.0)
	_tween.tween_interval(BANNER_SECS)
	_tween.tween_property(_banner, "modulate:a", 0.0, 0.25)
	for k in 3:
		_tween.tween_callback(_beat.bind(str(3 - k), COUNT_COLORS[k], false))
		_tween.tween_interval(BEAT)
	_tween.tween_callback(_beat.bind("GO!", GO_COLOR, true))
	_tween.tween_interval(0.6)
	_tween.tween_callback(queue_free)


## Lays the banner and the count out for the screen, whenever its size changes.
func _place() -> void:
	var screen := get_viewport_rect().size
	if screen == _laid_for:
		return
	_laid_for = screen
	position = Vector2.ZERO
	size = screen
	var w := minf(size.x - 40.0, 620.0)
	_banner.custom_minimum_size.x = w
	_banner.reset_size()
	_banner.position = Vector2((size.x - _banner.size.x) / 2.0, size.y * 0.45)
	_count.size = Vector2(size.x, 220)
	var gate = gate_at.call() if gate_at.is_valid() else null
	var gy: float = gate if gate != null else size.y * 0.25
	_count.position = Vector2(0, maxf(0.0, gy - 110.0))
	_count.pivot_offset = _count.size / 2.0


## One beat of the count: `text` pops in (GO! starts the race).
func _beat(text: String, col: Color, is_go: bool) -> void:
	_count.text = text
	_count.add_theme_color_override("font_color", col)
	_count.visible = true
	_count.modulate.a = 1.0
	if _pop != null:
		_pop.kill() # Its fade would otherwise carry on into this beat.
	var pop := create_tween()
	_pop = pop
	if A11y.reduced_motion:
		_count.scale = Vector2.ONE
	else:
		_count.scale = Vector2.ONE * 1.8
		pop.tween_property(_count, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_count, "modulate:a", 0.0, BEAT * 0.55).set_delay(BEAT * 0.2)
	_ring = 1.0
	if sfx != null:
		if is_go:
			sfx.play("go")
		else:
			sfx.play("ot_tick", -4.0, 0.9 + 0.1 * (3 - int(text))) # A little higher each beat.
	if is_go:
		_release()


func _release() -> void:
	if _gone:
		return
	_gone = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	go.emit()


## Straight to GO.
func skip() -> void:
	if _gone:
		return
	if _tween != null:
		_tween.kill()
	_banner.visible = false
	_beat("GO!", GO_COLOR, true)
	var out := create_tween()
	out.tween_interval(0.6)
	out.tween_callback(queue_free)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		skip()
		accept_event()


func _process(delta: float) -> void:
	_place()
	_clock += delta
	_ring = maxf(0.0, _ring - delta * 2.0)
	queue_redraw()


## A ring that pulses round your racer in the gate on every beat, under a
## YOU banner in its rarity colour.
func _draw() -> void:
	if _gone or not you_at.is_valid():
		return
	var at = you_at.call()
	if at == null:
		return
	var r := 46.0 + 6.0 * (0.5 + 0.5 * sin(_clock * 6.0)) + 20.0 * _ring
	draw_arc(at, r, 0, TAU, 48, Color(GO_COLOR, 0.85), 4.0, true)
	var fs := A11y.font(24)
	var w: float = Kit.FONT.get_string_size("YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28.0
	var h := fs * 1.5
	var tag := Rect2(at + Vector2(-w / 2.0, -r - 10.0 - h), Vector2(w, h))
	draw_rect(tag, you_color)
	draw_rect(tag, Color(Kit.BG, 0.6), false, 2.0)
	draw_string(Kit.FONT, Vector2(tag.position.x, tag.position.y + h / 2.0 + fs * 0.36), "YOU", HORIZONTAL_ALIGNMENT_CENTER, w, fs, Kit.BG)
