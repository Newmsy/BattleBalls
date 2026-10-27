## The Quick fight wait while the live server looks for a foe: a little
## side-scroller where your fighter and a shadowy stranger run in, bash into
## each other, bounce apart and go again (no damage). Every few bonks the
## stranger's shape changes, like the search trying faces. Cheap: a few
## shapes, two critter icons and one redraw per frame while it's on screen.
extends Control

const CritterIcon := preload("res://game/ui/critter_icon.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

const LOOP := 1.7 ## Seconds per run-in, bonk and bounce back.
const BONK_AT := 0.55 ## Fraction of the loop where they meet.
const SKY_TOP := Color("120d2e")
const SKY_LOW := Color("2a1a55")
const HILLS_FAR := Color("231a4d")
const HILLS_NEAR := Color("2f2366")
const GROUND := Color("3b2c7a")
const GROUND_EDGE := Color("8f7bff")
const SPARK := Color("ffd36b")

var _t := 0.0
var _scroll := 0.0
var _you: Control
var _foe: Control
var _you_id := ""
var _foe_ids: Array = []
var _bonks := 0
var _last_phase := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()


## Your fighter on the left; the stranger on the right is any other critter.
func setup(you_id: String, tier: int) -> void:
	_you_id = you_id
	_foe_ids = BallDefs.PLAYABLE.filter(func(id): return id != you_id)
	if _you != null:
		_you.queue_free()
	_you = CritterIcon.make(you_id, tier, 10.0)
	add_child(_you)
	_new_foe()
	_t = 0.0
	_bonks = 0


func _new_foe() -> void:
	if _foe != null:
		_foe.queue_free()
	var id: String = _foe_ids[_rng.randi_range(0, _foe_ids.size() - 1)] if not _foe_ids.is_empty() else "laser"
	_foe = CritterIcon.make(id, 1, 10.0, false, true)
	add_child(_foe)


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _you == null:
		return
	_t += delta
	var phase := fmod(_t, LOOP) / LOOP
	var running := phase < BONK_AT
	_scroll += delta * (220.0 if running else 60.0)
	if _last_phase < BONK_AT and phase >= BONK_AT:
		_you.poke()
		_foe.poke()
		_bonks += 1
	elif phase < _last_phase and _bonks % 3 == 0 and _bonks > 0:
		_new_foe() # A new loop after every third bonk: try another face.
	_last_phase = phase
	_place(phase)
	queue_redraw()


## Where each critter is: running in with a hop, then knocked back in an arc.
func _place(phase: float) -> void:
	var w := size.x
	var side := minf(size.y * 0.34, size.x * 0.3)
	var ground := _ground_y()
	var x_off := 0.0
	var lift := 0.0
	if phase < BONK_AT:
		var k := phase / BONK_AT
		k = k * k * (3.0 - 2.0 * k)
		x_off = lerpf(w * 0.36, side * 0.3, k)
		lift = absf(sin(phase * TAU * 4.0)) * side * 0.12 # Running hops.
	else:
		var k := (phase - BONK_AT) / (1.0 - BONK_AT)
		x_off = lerpf(side * 0.3, w * 0.36, 1.0 - pow(1.0 - k, 2.0))
		lift = sin(k * PI) * side * 0.55 # Knocked back in an arc.
	for i in 2:
		var c: Control = [_you, _foe][i]
		c.size = Vector2(side, side)
		c.pivot_offset = c.size / 2.0
		var cx := w / 2.0 + (x_off if i == 1 else -x_off)
		c.position = Vector2(cx - side / 2.0, ground - side - lift)
		c.rotation = (-1.0 if i == 0 else 1.0) * (0.25 * sin(clampf((phase - BONK_AT) / (1.0 - BONK_AT), 0.0, 1.0) * PI) if phase >= BONK_AT else 0.0)


func _ground_y() -> float:
	return size.y * 0.78


func _draw() -> void:
	var w := size.x
	var h := size.y
	var ground := _ground_y()
	# Sky in soft bands from night to dusk, a few slow stars.
	for i in 6:
		draw_rect(Rect2(0, ground * i / 6.0, w, ground / 6.0 + 1.0), SKY_TOP.lerp(SKY_LOW, i / 5.0))
	for i in 14:
		var sx := fposmod(i * 197.0 - _scroll * 0.05, w)
		draw_circle(Vector2(sx, (i * 53) % int(maxf(1.0, ground * 0.5)) + 8.0), 1.5 + (i % 3) * 0.6, Color(1, 1, 1, 0.35 + 0.1 * (i % 3)))
	# Two layers of hills that slide at different speeds (parallax).
	_hills(ground, h * 0.16, 260.0, _scroll * 0.2, HILLS_FAR)
	_hills(ground, h * 0.09, 170.0, _scroll * 0.5, HILLS_NEAR)
	# The ground with tiles that scroll past while they run.
	draw_rect(Rect2(0, ground, w, h - ground), GROUND)
	draw_line(Vector2(0, ground), Vector2(w, ground), GROUND_EDGE, 3.0)
	var tile := 64.0
	var x := -fposmod(_scroll, tile)
	while x < w:
		draw_line(Vector2(x, ground + 6), Vector2(x - 18, h), Color(GROUND_EDGE, 0.25), 2.0)
		x += tile
	# A faint glow behind the stranger, so its shadowy shape reads.
	if _foe != null:
		draw_circle(_foe.position + _foe.size / 2.0, _foe.size.x * 0.4, Color(GROUND_EDGE, 0.14))
	# Shadows under the two critters.
	if _you != null:
		for c in [_you, _foe]:
			var cx: float = c.position.x + c.size.x / 2.0
			var lift: float = ground - (c.position.y + c.size.y)
			var r: float = c.size.x * 0.34 * (1.0 - clampf(lift / c.size.x, 0.0, 0.6))
			draw_set_transform(Vector2(cx, ground + 4), 0.0, Vector2(1.0, 0.3))
			draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.35))
			draw_set_transform(Vector2.ZERO)
	# The bonk: a burst of sparks where they met, fading fast.
	var phase := fmod(_t, LOOP) / LOOP
	var since := (phase - BONK_AT) * LOOP
	if since >= 0.0 and since < 0.35:
		var a := 1.0 - since / 0.35
		var c := Vector2(w / 2.0, ground - size.y * 0.15)
		for i in 8:
			var dir := Vector2.RIGHT.rotated(i * TAU / 8.0 + 0.3)
			draw_line(c + dir * (10.0 + since * 120.0), c + dir * (26.0 + since * 220.0), Color(SPARK, a), 4.0)
		draw_circle(c, 14.0 * a + 4.0, Color(1, 1, 1, a * 0.8))


## A rolling row of round hills, repeating every `span` pixels.
func _hills(base: float, height: float, span: float, shift: float, color: Color) -> void:
	var pts := PackedVector2Array([Vector2(0, base)])
	var x := -fposmod(shift, span)
	while x <= size.x + span:
		for s in 9:
			var px := x + span * s / 8.0
			pts.append(Vector2(px, base - height * (0.55 + 0.45 * sin(s / 8.0 * PI)) * (0.7 + 0.3 * absf(sin(floorf((x + shift) / span) * 1.7)))))
		x += span
	pts.append(Vector2(size.x + span, base))
	draw_colored_polygon(pts, color)
