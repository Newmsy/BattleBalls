## The standings along the top of a Critter Plunge race: every racer's face
## in race order with its place and an HP bar; knocked out racers are greyed
## with OUT; a bar flashes red on a hit. A tap on a face follows that racer
## (`picked`); the followed racer wears a white ring. Render only: it redraws
## when the standings or HP change, at most 15 times a second, and stops once
## the race is over (battery). The race keeps it in its own SubViewport that
## only renders on those redraws, so the rest of the time it costs the frame
## one texture (game/plunge.gd); taps come in through tap().
extends Control

signal picked(racer: int)

const Plunge := preload("res://sim/plunge.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const A11y := preload("res://game/a11y.gd")
const Kit := preload("res://game/ui/ui_kit.gd")

const HEIGHT := 92.0
const BG := Color("0e0c2a")
const LINE := Color("8f7bff")
const YOU := Color("45f5a6")
const HURT := Color("ff5a7a")
const TICK := 1.0 / 15.0
const HIT_FLASH := 0.3

var sim: Plunge
var you := 0
var follow := -1 ## The racer the camera follows instead of yours (-1: yours).
var _clock := 0.0
var _wait := 0.0
var _seen := [] ## What the last redraw showed: order, HP and KOs.
var _hp := [] ## Racer HP at the last check, for the hit flash.
var _flash := {} ## racer -> seconds of red left
var _over := false


func _process(delta: float) -> void:
	_clock += delta
	_wait -= delta
	if _over or sim == null or _wait > 0.0:
		return
	_wait = TICK
	for i in _flash.keys():
		_flash[i] -= TICK
		if _flash[i] <= 0.0:
			_flash.erase(i)
	var hp := []
	for i in sim.starters:
		hp.append(roundi(sim.balls[i].hp))
		if i < _hp.size() and hp[i] < _hp[i]:
			_flash[i] = HIT_FLASH
	_hp = hp
	var now := [sim.standings(), hp, sim.kos.size(), follow, _flash.keys()]
	if now != _seen or not _flash.is_empty():
		_seen = now
		refresh()
	_over = sim.finished


## Redraws, and renders its SubViewport once with the new drawing.
func refresh() -> void:
	queue_redraw()
	var vp := get_viewport()
	if vp is SubViewport:
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE


## A tap on a face picks that racer (mouse only: touches arrive as mouse
## too); true when it was one.
func tap(event: InputEvent) -> bool:
	if sim == null or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	var order := sim.standings()
	var k := clampi(int(event.position.x / (size.x / order.size())), 0, order.size() - 1)
	picked.emit(order[k])
	return true


func _gui_input(event: InputEvent) -> void:
	if tap(event):
		accept_event()


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
		if i == follow and i != you:
			draw_arc(at, face + 4.0, 0, TAU, 28, Color.WHITE, 3.0)
		draw_string(Kit.FONT, Vector2(cx - cell / 2.0 + 4, 22), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(16), Kit.MUTED)
		var bar := Rect2(cx - cell * 0.36, 70, cell * 0.72, 7)
		draw_rect(bar, Color(0, 0, 0, 0.5))
		if not out:
			var frac: float = clampf(b.hp / b.max_hp, 0.0, 1.0)
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), HURT if _flash.has(i) else (YOU if i == you else Color("cfc8ff")))
		else:
			draw_string(Kit.FONT, Vector2(cx - 30, 84), "OUT", HORIZONTAL_ALIGNMENT_CENTER, 60, A11y.font(14), HURT)
