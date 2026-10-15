## The words around a clip, in its 720x1280 frame: a "Who wins?" title card,
## the matchup and HP while it plays, and the result with the game's address
## at the end. The arena itself is drawn by ArenaView, placed at ARENA_POS.
extends Node2D

const ArenaView := preload("res://game/arena_view.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")

const SIZE := Vector2(720, 1280)
const ARENA_POS := Vector2(20, 290)
const ARENA_SIDE := 680.0
const TITLE_TIME := 2.6 ## Seconds of title card before the fight starts.
const GO_TIME := 2.0 ## When the title card flashes "FIGHT!".
const END_TIME := 2.8 ## Seconds of result card at the end.
const YELLOW := Color("ffe28a")
const MUTED := Color("a29fc9")
const BACK := Color("0b0a1f")
const HOME_TEXT := "battleballs.vercel.app"

var phase := "title" ## title, fight or end.
var t := 0.0 ## Seconds into the current phase.
var names: Array = ["", ""]
var sim ## The fight being shown, for HP and the winner.


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func set_phase(p: String) -> void:
	phase = p
	t = 0.0
	queue_redraw()


func _draw() -> void:
	# Opaque frame around the arena (drawn under this card) so the clip records cleanly.
	var hole := Rect2(ARENA_POS, Vector2.ONE * ARENA_SIDE).grow(28.0)
	draw_rect(Rect2(0, 0, SIZE.x, hole.position.y), BACK)
	draw_rect(Rect2(0, hole.end.y, SIZE.x, SIZE.y - hole.end.y), BACK)
	draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), BACK)
	draw_rect(Rect2(hole.end.x, hole.position.y, SIZE.x - hole.end.x, hole.size.y), BACK)
	var cols: Array = ArenaView.TEAM_COLORS
	match phase:
		"title":
			var pop := minf(1.0, t / 0.25)
			_text(Vector2(360, 140), "WHO WINS?", roundi(lerpf(130, 96, pop)), Color(YELLOW, pop), 16)
			_matchup(Vector2(360, 236), cols)
			_text(Vector2(360, 1040), "Comment your pick!", 40, Color.WHITE, 8)
		"fight":
			_text(Vector2(360, 130), "WHO WINS?", 72, YELLOW, 12)
			_matchup(Vector2(360, 226), cols)
			if sim:
				var hp := "%d   |   %.0fs   |   %d" % [maxi(0, ceili(sim.balls[0].hp)), sim.time(), maxi(0, ceili(sim.balls[1].hp))]
				_text(Vector2(360, 1036), hp, 36, MUTED, 6)
		"end":
			var pop := minf(1.0, t / 0.2)
			var w: int = sim.winner if sim else -1
			var line := "DRAW!" if w < 0 else "%s WINS!" % str(names[w]).to_upper()
			var size := 84 if line.length() <= 13 else 64
			_text(Vector2(360, 140), line, roundi(lerpf(size * 1.3, size, pop)), Color(YELLOW if w < 0 else cols[w], pop), 14)
			_text(Vector2(360, 236), "Did you call it?", 44, Color.WHITE, 8)
			_text(Vector2(360, 1040), "Can your ball beat it?", 40, Color.WHITE, 8)
	_text(Vector2(360, 1140), "BATTLE BALLS", 52, Color.WHITE, 12)
	_text(Vector2(360, 1204), HOME_TEXT, 30, MUTED, 6)
	if phase == "title" and t >= GO_TIME:
		var k := (t - GO_TIME) / (TITLE_TIME - GO_TIME)
		_text(ARENA_POS + Vector2(ARENA_SIDE, ARENA_SIDE) / 2.0, "FIGHT!", roundi(lerpf(150, 110, minf(1.0, k * 3.0))), Color(YELLOW, 1.0 - k * k), 18)


## "Vampire vs Laser", each name in its side's colour.
func _matchup(centre: Vector2, cols: Array) -> void:
	var size := 44
	var vs := "  vs  "
	var widths := [_width(names[0], size), _width(vs, size), _width(names[1], size)]
	var x: float = centre.x - (widths[0] + widths[1] + widths[2]) / 2.0
	_text_at(Vector2(x, centre.y), names[0], size, cols[0])
	_text_at(Vector2(x + widths[0], centre.y), vs, size, MUTED)
	_text_at(Vector2(x + widths[0] + widths[1], centre.y), names[1], size, cols[1])


func _width(text: String, size: int) -> float:
	return FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _text(centre: Vector2, text: String, size: int, color: Color, outline: int) -> void:
	_text_at(centre - Vector2(_width(text, size) / 2.0, 0), text, size, color, outline)


func _text_at(left: Vector2, text: String, size: int, color: Color, outline := 6) -> void:
	var baseline := left + Vector2(0, size * 0.35)
	draw_string_outline(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(BACK, color.a))
	draw_string(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
