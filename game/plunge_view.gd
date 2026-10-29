## Draws a Critter Plunge race (sim/plunge.gd). It is the fight view
## (game/arena_view.gd) with the course in place of the arena: every ability
## looks exactly as it does in a fight. The camera follows the leader down
## the shaft. Holds no rules: everything comes from the sim's state and
## events, so watching can never change a race. The course is flat shapes,
## and only what is on screen is drawn (battery).
extends "res://game/arena_view.gd"

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const Kit := preload("res://game/ui/ui_kit.gd")

const BG := Color("0e0c2a")
const BAND := Color("151244")
const PEG := Color("8f7bff")
const RAMP := Color("27c8ff")
const FLASH_LIFE := 0.3

var you := 0 ## Your racer's index (-1 in a race you only watch).
var view_size := Vector2(680, 900)
var top_pad := 0.0 ## Screen pixels above the course (the standings strip).
var camera_y := 0.0 ## World y at the top of the view.

var _peg_flash := {} ## peg index -> seconds left
var _peg_at := {} ## Vector2 -> peg index, to flash the peg a bounce names.


func set_race(s: Plunge, your_index := 0) -> void:
	sim = s
	you = your_index
	team_tags = ["YOU", ""] # Only your racer is tagged; the field is everyone else.
	_peg_at.clear()
	for i in s.course.pegs.size():
		_peg_at[s.course.pegs[i].pos] = i
	_peg_flash.clear()
	clear_effects()
	camera_y = 0.0


func _side(i: int) -> int:
	return 0 if i == you else 1


func consume_events(events: Array[Dictionary]) -> void:
	super.consume_events(events)
	for e in events:
		if e.type == "course_hit" and _peg_at.has(e.peg):
			_peg_flash[_peg_at[e.peg]] = FLASH_LIFE
		elif e.type == "finish" and e.place <= 3:
			_add_popup(e.pos, ["1ST!", "2ND", "3RD"][e.place - 1], Color("ffd36b"), 1.4)
		elif e.type == "race_ko":
			_add_popup(e.pos, "KO!", POP_DAMAGE, 1.4)


func advance(delta: float) -> void:
	advance_effects(delta)
	for k in _peg_flash.keys():
		_peg_flash[k] -= delta
		if _peg_flash[k] <= 0.0:
			_peg_flash.erase(k)
	if sim != null:
		var course_h := (view_size.y - top_pad) / view_scale
		var target_y := _focus_y() - course_h * 0.4
		target_y = clampf(target_y, 0.0, maxf(0.0, sim.finish_y + 220.0 - course_h))
		var ease := 1.0 if A11y.reduced_motion else minf(1.0, delta * 4.0)
		camera_y = lerpf(camera_y, target_y, ease)
	position = Vector2(0.0, top_pad - camera_y * view_scale)
	queue_redraw()


## The camera follows the leader still racing, so it stays on the action
## after a win.
func _focus_y() -> float:
	for i in sim.standings():
		if sim.racing(i):
			return sim.balls[i].pos.y
	return sim.finish_y


func to_world(screen_pos: Vector2) -> Vector2:
	return (get_global_transform().affine_inverse() * screen_pos) / view_scale


## The course where the arena would be: section bands, the gate, ramps, pegs
## and bumpers, and the finish line. World y runs down the shaft.
func _draw_stage(_shape, s: float, _shake: Vector2) -> void:
	var c: PlungeCourse = sim.course
	var top := camera_y - 80.0
	var bottom := camera_y + (view_size.y - top_pad) / s + 80.0
	draw_rect(Rect2(0.0, top * s, Plunge.WIDTH * s, (bottom - top) * s), BG)
	for i in c.sections.size():
		var sec: Dictionary = c.sections[i]
		if sec.y1 < top or sec.y0 > bottom or i % 2 == 0:
			continue
		draw_rect(Rect2(0.0, sec.y0 * s, Plunge.WIDTH * s, (sec.y1 - sec.y0) * s), BAND)
	if sim.time() < Plunge.GATE_SECONDS:
		var gy := (PlungeCourse.START_Y + Plunge.RADIUS + 4.0) * s
		draw_line(Vector2(0.0, gy), Vector2(Plunge.WIDTH * s, gy), Color(RAMP, 0.8), 4.0)
	var fy: float = sim.finish_y * s
	if sim.finish_y < bottom:
		var sq := 20.0
		for k in int(Plunge.WIDTH * s / sq) + 1:
			for row in 2:
				draw_rect(Rect2(k * sq, fy + row * sq, sq, sq), Color.WHITE if (k + row) % 2 == 0 else INK)
		draw_string(Kit.FONT, Vector2(12.0, fy - 12.0), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(26), Color.WHITE)
	for rp in c.ramps:
		if maxf(rp.a.y, rp.b.y) < top or minf(rp.a.y, rp.b.y) > bottom:
			continue
		draw_line(rp.a * s, rp.b * s, Color(RAMP, 0.35), (PlungeCourse.RAMP_THICK * 2.0 + 10.0) * s)
		draw_line(rp.a * s, rp.b * s, RAMP, PlungeCourse.RAMP_THICK * 2.0 * s)
	for i in c.pegs.size():
		var p: Dictionary = c.pegs[i]
		if p.pos.y < top or p.pos.y > bottom:
			continue
		var flash: float = _peg_flash.get(i, 0.0) / FLASH_LIFE
		var at: Vector2 = p.pos * s
		if p.bumper:
			draw_circle(at, (p.r + 10.0 * flash) * s, Color(BUMPER, 0.25 + 0.4 * flash))
			draw_arc(at, p.r * s, 0, TAU, 28, BUMPER, 5.0 * s)
			draw_circle(at, p.r * 0.45 * s, BUMPER)
		else:
			draw_circle(at, (p.r + 6.0) * s, Color(PEG, 0.18 + 0.5 * flash))
			draw_circle(at, p.r * s, PEG.lerp(Color.WHITE, flash))


## Tags sit under each racer; the fight's square-arena clamping doesn't apply.
func _place_tags(s: float, _ko_ball: int) -> void:
	_tag_at.clear()
	for b in sim.balls:
		if b.alive():
			_tag_at[b.index] = ball_pos(b) * s + Vector2(0, b.radius * s + 22.0)


## Only your racer carries a ring, tag and HP badge: eight would bury the
## race, and the strip up top has everyone's HP.
func _draw_overlay(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2) -> void:
	if i == you:
		super._draw_overlay(i, def, pos, r, hp, max_hp, shake)


## No 1v1 matchup card over a race.
func _draw_matchup(_full: Rect2) -> void:
	pass
