## The standings along the top of a Critter Plunge race: every racer's face
## in race order with its place and an HP bar; knocked out racers are greyed
## with OUT. Render only (game/plunge.gd redraws it each frame).
extends Control

const Plunge := preload("res://sim/plunge.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const A11y := preload("res://game/a11y.gd")
const Kit := preload("res://game/ui/ui_kit.gd")

const HEIGHT := 92.0
const BG := Color("0e0c2a")
const LINE := Color("8f7bff")
const YOU := Color("45f5a6")
const HURT := Color("ff5a7a")

var sim: Plunge
var you := 0
var _clock := 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(BG, 0.94))
	draw_line(Vector2(0, size.y), Vector2(size.x, size.y), Color(LINE, 0.5), 2.0)
	if sim == null:
		return
	var order := sim.standings()
	var n := order.size()
	var cell := size.x / n
	var face := minf(24.0, cell * 0.3)
	for k in n:
		var i: int = order[k]
		var b = sim.balls[i]
		var cx := cell * (k + 0.5)
		var at := Vector2(cx, 38)
		var out: bool = sim.ko_ticks[i] >= 0
		CritterArt.draw_critter(self, b.type_id, at, face, {"t": _clock, "look": Vector2.DOWN, "grey": out, "ko": out})
		if i == you:
			draw_arc(at, face + 4.0, 0, TAU, 28, YOU, 3.0)
		draw_string(Kit.FONT, Vector2(cx - cell / 2.0 + 4, 22), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(16), Kit.MUTED)
		var bar := Rect2(cx - cell * 0.36, 70, cell * 0.72, 7)
		draw_rect(bar, Color(0, 0, 0, 0.5))
		if not out:
			var frac: float = clampf(b.hp / b.max_hp, 0.0, 1.0)
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), YOU if i == you else Color("cfc8ff"))
		else:
			draw_string(Kit.FONT, Vector2(cx - 30, 84), "OUT", HORIZONTAL_ALIGNMENT_CENTER, 60, A11y.font(14), HURT)
