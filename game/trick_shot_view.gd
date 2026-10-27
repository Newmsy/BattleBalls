## Arena for Daily Trick Shot: the normal arena plus the called walls, the
## aims of earlier tries, the current shot's trail and the solving window.
extends "res://game/arena_view.gd"

const RESULT_COLORS := {
	"solved": Color("45f5a6"),
	"wrong_walls": Color("ffd25a"),
	"miss": Color("ff5a7a"),
}
const CALL_COLOR := Color("ffd25a")
const TrickShot := preload("res://sim/trick_shot.gd")

## Called walls in order, e.g. ["right", "top"].
var called_walls: Array = []
## Earlier tries this day: [{ aim: int (degrees), result: String }].
var ghosts: Array = []
## Your ball's path during the current shot, in arena units.
var trail: PackedVector2Array = PackedVector2Array()
## Solving aims to reveal when the day is over (degrees), or empty.
var solutions: Array = []


func _draw() -> void:
	super._draw()
	var s := view_scale
	var size := MatchSim.ARENA_SIZE * s
	var ends := {
		"left": [Vector2(0, 0), Vector2(0, size)],
		"right": [Vector2(size, 0), Vector2(size, size)],
		"top": [Vector2(0, 0), Vector2(size, 0)],
		"bottom": [Vector2(0, size), Vector2(size, size)],
	}
	var numbers := {}
	for i in called_walls.size():
		var w: String = called_walls[i]
		numbers[w] = (numbers.get(w, "") + " " + str(i + 1)).strip_edges()
	for w in numbers:
		var a: Vector2 = ends[w][0]
		var b: Vector2 = ends[w][1]
		draw_line(a, b, Color(CALL_COLOR, 0.35), 18.0)
		draw_line(a, b, CALL_COLOR, 6.0)
		var mid := (a + b) / 2.0
		var inward := (Vector2(size, size) / 2.0 - mid).normalized()
		draw_circle(mid + inward * 34.0, 26.0, Color(0.07, 0.08, 0.11, 0.9))
		draw_arc(mid + inward * 34.0, 26.0, 0, TAU, 32, CALL_COLOR, 3.0, true)
		_badge_text(mid + inward * 34.0, numbers[w], 24 if numbers[w].length() < 2 else 18)

	if sim == null:
		return
	var start := sim.balls[0].pos * s if trail.is_empty() else trail[0] * s
	var r := 520.0 * s
	for w in TrickShot.windows(solutions):
		var first := deg_to_rad(float(w[0]) - 0.5)
		var last := deg_to_rad(float(w[1]) + 0.5)
		var wedge := PackedVector2Array([start])
		for i in 9:
			wedge.append(start + Vector2.from_angle(lerpf(first, last, i / 8.0)) * r)
		draw_colored_polygon(wedge, Color(RESULT_COLORS.solved, 0.25))
	for g in ghosts:
		var dir := Vector2.from_angle(deg_to_rad(float(g.aim)))
		var col: Color = RESULT_COLORS.get(g.result, Color.WHITE)
		draw_line(start + dir * 40.0 * s, start + dir * 560.0 * s, Color(col, 0.55), 3.0, true)
	if trail.size() >= 2:
		var pts := PackedVector2Array()
		for p in trail:
			pts.append(p * s)
		draw_polyline(pts, Color(TEAM_COLORS[0], 0.6), 4.0, true)


func _badge_text(pos: Vector2, text: String, size: int) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(FONT, pos + Vector2(-width / 2.0, size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, CALL_COLOR)
