## The Bounce Run map: FLOORS rows of nodes from the bottom (floor 1) to the
## Champion on top, the links between them, the route you took lit, and the
## nodes you can step to now ringed and bigger. Tap one to select it. Drawn
## once per change (no per-frame redraw), so it costs nothing while you think.
extends Control

const BounceRun := preload("res://sim/bounce_run.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Dot := preload("res://game/dot.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")

const COLORS := {
	"fight": Color("3ee6ff"), "elite": Color("ff4fb8"), "mystery": Color("b88cff"), "shop": Color("ffd34e"),
	"rest": Color("5cff9a"), "chest": Color("ff9f43"), "boss": Color("ff5a6e"), "event": Color("b88cff"),
}
const NAMES := {
	"fight": "Fight", "elite": "Elite", "mystery": "Mystery", "shop": "Shop", "rest": "Charge Pad",
	"chest": "Glow Chest", "boss": "Champion", "event": "Event",
}

var setup: Dictionary
var run: Dictionary
var selected := -1
var on_select: Callable ## Called with the node id a tap picks.
var _reach: Array = []
var _route: Array = []


func show_run(setup_: Dictionary, run_: Dictionary, selected_ := -1) -> void:
	setup = setup_
	run = run_
	selected = selected_
	_reach = BounceRun.next_nodes(setup, run)
	_route = run.log.filter(func(e): return e.t == "go").map(func(e): return int(e.n))
	queue_redraw()


## What a node shows: its type, or a mystery node's contents once a Star Map
## revealed them.
func shown_type(id: int) -> String:
	var n: Dictionary = setup.nodes[id]
	if n.type == "mystery" and (run.get("revealed", false) or id in _route):
		return n.get("holds", "event") if n.get("holds", "") != "event" else "event"
	return n.type


func node_pos(id: int) -> Vector2:
	var n: Dictionary = setup.nodes[id]
	var pad := Vector2(70.0, _r() * 1.6)
	var y: float = size.y - pad.y - (size.y - 2.0 * pad.y) * n.row / float(BounceRun.FLOORS - 1)
	if n.col < 0:
		return Vector2(size.x / 2.0, y)
	return Vector2(pad.x + (size.x - 2.0 * pad.x) * n.col / float(BounceRun.COLS - 1), y)


## A node's radius: as big as the row spacing allows.
func _r() -> float:
	return clampf(size.y / BounceRun.FLOORS * 0.36, 9.0, 24.0)


func _gui_input(event: InputEvent) -> void:
	var at := Vector2.INF
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventScreenTouch and event.pressed:
		at = event.position
	if at == Vector2.INF or _reach.is_empty():
		return
	var best := -1
	var best_d := INF
	for id in _reach:
		var d := node_pos(id).distance_to(at)
		if d < best_d:
			best_d = d
			best = id
	# Generous: only the reachable nodes take taps, so a near miss still counts.
	if best >= 0 and best_d < maxf(70.0, _r() * 3.0):
		accept_event()
		if on_select.is_valid():
			on_select.call(best)


func _draw() -> void:
	if setup.is_empty():
		return
	var r := _r()
	var walked := {}
	for i in range(1, _route.size()):
		walked["%d-%d" % [_route[i - 1], _route[i]]] = true
	# Links first, under the nodes.
	for id in setup.nodes:
		var a := node_pos(id)
		for k in setup.nodes[id].kids:
			var b := node_pos(k)
			var key := "%d-%d" % [id, k]
			if walked.has(key):
				draw_line(a, b, Kit.GOOD, 5.0, true)
			elif id == run.at and k in _reach and run.done:
				draw_line(a, b, Color(Kit.FG, .75), 3.0, true)
			else:
				_dashed(a, b, Color(Kit.LINE, .9), 2.0)
	if run.at >= 0 and run.get("dash", false):
		for k in _reach:
			_dashed(node_pos(run.at), node_pos(k), Color(COLORS.chest, .8), 3.0)
	for id in setup.nodes:
		var n: Dictionary = setup.nodes[id]
		var p := node_pos(id)
		var t := shown_type(id)
		var col: Color = COLORS[t]
		var rr := r * (1.55 if t == "boss" else 1.0)
		if id in _reach:
			rr *= 1.3
			Dot.circle(self, p, rr * 1.75, Color(col, .14))
			Dot.circle(self, p, rr * 1.4, Color(col, .22))
		if id in _route:
			Dot.circle(self, p, rr, col)
			_icon(t, p, rr * .62, Kit.BG)
		else:
			var dim: bool = n.row < run.floor or (not id in _reach and n.row <= run.floor)
			Dot.circle(self, p, rr, Kit.PANEL if not dim else Kit.BG)
			draw_arc(p, rr, 0.0, TAU, 32, Color(col, .35 if dim else (1.0 if id in _reach else .6)), 3.0 if id in _reach else 2.0, true)
			_icon(t, p, rr * .62, Color(col, .35 if dim else (1.0 if id in _reach else .75)))
		if id == selected:
			draw_arc(p, rr + 7.0, 0.0, TAU, 40, Kit.FG, 4.0, true)
		if id == run.at and not run.done:
			draw_arc(p, rr + 6.0, 0.0, TAU, 40, Kit.FG, 3.0, true)


func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var d := a.distance_to(b)
	var steps := maxi(1, int(d / 12.0))
	for i in steps:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / steps), a.lerp(b, minf(1.0, float(i + 1) / steps)), col, w, true)


## The node type's mark, `s` its half-size.
func _icon(t: String, p: Vector2, s: float, col: Color) -> void:
	var w := maxf(2.0, s * .22)
	match t:
		"fight":
			draw_arc(p + Vector2(-s * .3, s * .1), s * .55, 0.0, TAU, 24, col, w, true)
			Dot.circle(self, p + Vector2(s * .5, -s * .2), s * .38, col)
		"elite":
			Dot.circle(self, p, s * .48, col)
			for k in 8:
				var d := Vector2.from_angle(k * TAU / 8.0)
				draw_line(p + d * s * .55, p + d * s * 1.0, col, w, true)
		"mystery", "event":
			var fs := maxi(10, roundi(s * 1.9))
			var tw := Kit.FONT.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(Kit.FONT, p + Vector2(-tw / 2.0, fs * .36), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		"shop": # A Button, the shop's currency.
			draw_arc(p, s * .8, 0.0, TAU, 24, col, w, true)
			for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				Dot.circle(self, p + q * s * .26, s * .17, col)
		"rest":
			draw_rect(Rect2(p + Vector2(-.22, -.8) * s, Vector2(.44, 1.6) * s), col)
			draw_rect(Rect2(p + Vector2(-.8, -.22) * s, Vector2(1.6, .44) * s), col)
		"chest":
			draw_rect(Rect2(p + Vector2(-.8, -.2) * s, Vector2(1.6, 1.0) * s), col)
			Dot.poly(self, PackedVector2Array([p + Vector2(-.8, -.3) * s, p + Vector2(-.6, -.8) * s, p + Vector2(.6, -.8) * s, p + Vector2(.8, -.3) * s]), col)
		"boss":
			Dot.poly(self, PackedVector2Array([p + Vector2(-.9, .6) * s, p + Vector2(-.9, -.4) * s, p + Vector2(-.45, .05) * s, p + Vector2(0, -.75) * s,
				p + Vector2(.45, .05) * s, p + Vector2(.9, -.4) * s, p + Vector2(.9, .6) * s]), col)
