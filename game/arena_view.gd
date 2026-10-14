## Draws a MatchSim. Holds no game rules: everything it shows comes from the
## sim's state and the events of each step.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Modifiers := preload("res://sim/modifiers.gd")

const POPUP_LIFE := 0.9
## Side markers so mirror matches stay readable: index 0 is always the player.
const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const TEAM_TAGS := ["YOU", "FOE"]
const FLASH_LIFE := 0.12

var sim: MatchSim
var view_scale := 0.68
## Launch aim preview for the player's ball (world direction), or ZERO to hide.
var aim_dir := Vector2.ZERO
## Ball types to show before a sim exists (menu preview).
var preview_types: Array = ["vampire", "laser"]
var preview_modifier := Modifiers.NONE

var _popups: Array[Dictionary] = []
var _flash := [0.0, 0.0]
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - global_position) / view_scale


func clear_effects() -> void:
	_popups.clear()
	_flash = [0.0, 0.0]


## Turns the events of the latest sim step into visual effects.
func consume_events(events: Array[Dictionary]) -> void:
	for e in events:
		match e.type:
			"damage":
				_flash[e.target] = FLASH_LIFE
				_add_popup(e.pos, "-%d" % ceili(e.amount), Color(1, 0.35, 0.3) if e.kind == "contact" else Color(0.5, 0.95, 1))
			"heal":
				_add_popup(e.pos + Vector2(0, -30), "+%d" % ceili(e.amount), Color(0.4, 1, 0.5))


func advance_effects(delta: float) -> void:
	for p in _popups:
		p.age += delta
	_popups = _popups.filter(func(p): return p.age < POPUP_LIFE)
	for i in 2:
		_flash[i] = maxf(0.0, _flash[i] - delta)
	queue_redraw()


func _add_popup(pos: Vector2, text: String, color: Color) -> void:
	_popups.append({"pos": pos, "text": text, "color": color, "age": 0.0})


func _draw() -> void:
	var s := view_scale
	var full := Rect2(Vector2.ZERO, Vector2.ONE * MatchSim.ARENA_SIZE * s)
	draw_rect(full, Color(0.11, 0.12, 0.16))
	var arena := full
	var overtime := false
	if sim:
		var r := sim.arena_rect()
		arena = Rect2(r.position * s, r.size * s)
		overtime = sim.in_overtime()
	if overtime:
		draw_rect(full, Color(0.35, 0.05, 0.08, 0.5))
		draw_rect(arena, Color(0.13, 0.13, 0.18))
	_draw_grid(arena)
	draw_rect(arena, Color(1, 0.3, 0.3) if overtime else Color(0.85, 0.87, 0.95), false, 4.0)

	if sim == null:
		for i in 2:
			var def := Modifiers.apply_to_def(BallDefs.get_def(preview_types[i]), preview_modifier)
			_draw_ball(MatchSim.START_CORNERS[i] * s, def.radius * s, def, def.hp, 0.0, i)
		return

	for beam in sim.beams:
		var col: Color = sim.balls[beam.owner].def.color
		var k := beam.strength()
		draw_line(beam.a * s, beam.b * s, Color(col, 0.3 * k), 26.0 * s * k + 4.0)
		draw_line(beam.a * s, beam.b * s, Color(col.lightened(0.6), 0.6 + 0.4 * k), 8.0 * s * k + 2.0)

	if aim_dir != Vector2.ZERO:
		var b := sim.balls[0]
		var start := b.pos * s
		for i in 12:
			draw_circle(start + aim_dir * (b.radius + 30.0 + i * 38.0) * s, 5.0, Color(1, 1, 1, 1.0 - i / 12.0))

	for b in sim.balls:
		if b.alive():
			_draw_ball(b.pos * s, b.radius * s, b.def, b.hp, _flash[b.index] / FLASH_LIFE, b.index)

	for p in _popups:
		var t: float = p.age / POPUP_LIFE
		var pos: Vector2 = p.pos * s + Vector2(0, -50.0 * t)
		_draw_text_centered(pos, p.text, 30, Color(p.color, 1.0 - t * t), 6)


func _draw_grid(r: Rect2) -> void:
	var step := 100.0 * view_scale
	var x := r.position.x + step
	while x < r.end.x - 1.0:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(1, 1, 1, 0.04), 1.0)
		x += step
	var y := r.position.y + step
	while y < r.end.y - 1.0:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.04), 1.0)
		y += step


func _draw_ball(pos: Vector2, radius: float, def: Dictionary, hp: float, flash: float, team: int) -> void:
	var col: Color = def.color
	var team_col: Color = TEAM_COLORS[team]
	draw_circle(pos + Vector2(4, 6), radius, Color(0, 0, 0, 0.35))
	draw_arc(pos, radius + 7.0, 0, TAU, 56, Color(team_col, 0.25), 10.0, true)
	draw_arc(pos, radius + 5.0, 0, TAU, 56, team_col, 3.0, true)
	_draw_text_centered(pos + Vector2(0, radius + 24.0), TEAM_TAGS[team], 18, team_col, 4)
	draw_circle(pos, radius, col.lerp(Color.WHITE, flash * 0.7))
	draw_arc(pos, radius - 2.0, 0, TAU, 48, col.darkened(0.45), 4.0, true)
	match def.ability:
		"vampire":
			for side in [-1.0, 1.0]:
				var base := pos + Vector2(side * radius * 0.28, radius * 0.42)
				draw_colored_polygon(PackedVector2Array([
					base + Vector2(-radius * 0.1, 0), base + Vector2(radius * 0.1, 0), base + Vector2(0, radius * 0.25)]), Color.WHITE)
		"laser":
			draw_arc(pos, radius * 0.72, 0, TAU, 40, Color(1, 1, 1, 0.55), 3.0, true)
	_draw_text_centered(pos + Vector2(0, -radius * 0.05), str(ceili(hp)), int(radius * 0.75), Color.WHITE, 5)


func _draw_text_centered(pos: Vector2, text: String, size: int, color: Color, outline: int) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := pos + Vector2(-width / 2.0, size * 0.35)
	draw_string_outline(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0, 0, 0, color.a))
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
