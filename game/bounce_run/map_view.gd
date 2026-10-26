## The Bounce Run map: FLOORS rows of nodes from the bottom (floor 1) to the
## Champion on top, the links between them, the route you took lit, and the
## nodes you can step to now ringed and bigger. It is taller than the screen
## (row_h per floor) and sits in a ScrollContainer; tap a reachable node to go
## there. Drawn once per change (no per-frame redraw), so it costs nothing
## while you think.
extends Control

const BounceRun := preload("res://sim/bounce_run.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Dot := preload("res://game/dot.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")

const COLORS := {
	"fight": Color("3ee6ff"), "elite": Color("ff4fb8"), "mystery": Color("b88cff"), "shop": Color("ffd34e"),
	"rest": Color("5cff9a"), "chest": Color("ff9f43"), "boss": Color("ff5a6e"), "event": Color("b88cff"),
}
const ART := "res://game/bounce_run/art/%s.png"
const PAD := 52.0 ## Side margin to the outer lanes (room for the glow).
const SPREAD := 0.7 ## How far each floor is stretched to the full width.
const NAMES := {
	"fight": "Fight", "elite": "Elite", "mystery": "Mystery", "shop": "Shop", "rest": "Charge Pad",
	"chest": "Glow Chest", "boss": "Champion", "event": "Event",
}

var setup: Dictionary
var run: Dictionary
var selected := -1
var row_h := 120.0 ## Pixels between floors.
var on_select: Callable ## Called with the node id a tap picks.
var _press := Vector2.INF
var _spans := {} ## Row -> its leftmost and rightmost lane.
static var _textures := {}
var _reach: Array = []
var _route: Array = []


func show_run(setup_: Dictionary, run_: Dictionary, selected_ := -1) -> void:
	setup = setup_
	run = run_
	selected = selected_
	_reach = BounceRun.next_nodes(setup, run)
	_route = run.log.filter(func(e): return e.t == "go").map(func(e): return int(e.n))
	_spans = {}
	for id in setup.nodes:
		var n: Dictionary = setup.nodes[id]
		if n.col >= 0:
			var sp: Vector2i = _spans.get(n.row, Vector2i(n.col, n.col))
			_spans[n.row] = Vector2i(mini(sp.x, n.col), maxi(sp.y, n.col))
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
	var y: float = size.y - row_h * (n.row + 0.6)
	if n.col < 0:
		return Vector2(size.x / 2.0, y - row_h * 0.15)
	# A little seeded wobble, so the lanes don't read as a grid (render only).
	var h := hash([setup.get("seed", 0), setup.day, id])
	var lane := (size.x - 2.0 * PAD) / float(BounceRun.COLS - 1)
	var wob := Vector2(((h & 255) / 255.0 - 0.5) * lane * 0.3, (((h >> 8) & 255) / 255.0 - 0.5) * row_h * 0.2)
	# Each floor is stretched most of the way to both edges (its order kept,
	# so links still never cross): the map fills the width like StS's.
	var f: float = n.col / float(BounceRun.COLS - 1)
	var sp: Vector2i = _spans.get(n.row, Vector2i(0, BounceRun.COLS - 1))
	if sp.y > sp.x:
		f = lerpf(f, (n.col - sp.x) / float(sp.y - sp.x), SPREAD)
	return Vector2(PAD + (size.x - 2.0 * PAD) * f, y) + wob


## The map's full height for rows `row_h` apart.
static func height_for(row_h_: float) -> float:
	return row_h_ * (BounceRun.FLOORS + 0.3)


## Where to scroll so the floor you pick next sits low on screen, with the
## floors ahead above it.
func scroll_for(view_h: float) -> float:
	var row: int = mini(int(run.floor), BounceRun.FLOORS - 1)
	var y := size.y - row_h * (row + 0.6)
	return clampf(y - view_h * 0.72, 0.0, maxf(0.0, size.y - view_h))


## A node's radius: big enough to tap with a thumb.
func _r() -> float:
	return clampf(minf(row_h * 0.26, (size.x - 2.0 * PAD) / float(BounceRun.COLS - 1) * 0.36), 14.0, 34.0)


func _gui_input(event: InputEvent) -> void:
	# Taps go on release, and only when the finger stayed put, so a drag
	# scrolls the map instead of picking a node.
	var at := Vector2.INF
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press = event.position
			return
		if _press != Vector2.INF and event.position.distance_to(_press) < 24.0:
			at = event.position
		_press = Vector2.INF
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
	if best >= 0 and best_d < maxf(60.0, _r() * 2.2):
		accept_event()
		if on_select.is_valid():
			on_select.call(best)


func _draw() -> void:
	if setup.is_empty():
		return
	var r := _r()
	var back := _tex("map_backdrop")
	if back:
		# Cover the map without squashing the painting: scale to fill, crop the sides.
		var k := maxf(size.x / back.get_width(), size.y / back.get_height())
		var art := Vector2(back.get_width(), back.get_height()) * k
		draw_texture_rect(back, Rect2(Vector2((size.x - art.x) / 2.0, size.y - art.y), art), false)
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
				draw_line(a, b, Kit.GOOD, 6.0, true)
			elif id == run.at and k in _reach and run.done:
				draw_line(a, b, Color(Kit.FG, .75), 3.0, true)
			else:
				_dashed(a, b, Color(Kit.MUTED, .55), 3.0)
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
			rr *= 1.15
			Dot.glow(self, p, rr * 1.6, Color(col, .36), .6)
		var token := _tex("map_node_" + t)
		if token:
			# The painted token (a 150 px badge in a 160 px square): past and
			# out-of-reach nodes fade back, the route stays lit.
			var dim: bool = not id in _route and (n.row < run.floor or (not id in _reach and n.row <= run.floor))
			var tint := Color(.45, .45, .55, .55) if dim else (Color.WHITE if id in _reach or id in _route else Color(.8, .8, .88, .92))
			draw_texture_rect(token, Rect2(p - Vector2.ONE * rr * 160.0 / 150.0, Vector2.ONE * rr * 320.0 / 150.0), false, tint)
			if t == "event" and n.type == "mystery":
				_event_face(n.get("event", ""), p, rr * 0.86, tint)
			if id in _route:
				draw_arc(p, rr + 2.0, 0.0, TAU, 40, Kit.GOOD, 4.0, true)
		elif id in _route:
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


## A painted map texture (game/bounce_run/art), or null when it isn't there.
static func _tex(name: String) -> Texture2D:
	if not _textures.has(name):
		var path := ART % name
		_textures[name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[name]


func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var d := a.distance_to(b)
	var steps := maxi(1, int(d / 12.0))
	for i in steps:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / steps), a.lerp(b, minf(1.0, float(i + 1) / steps)), col, w, true)


## A revealed event shows its own painting inside the token, so a Star Map
## or the Ghost Lantern visibly tells you which event waits there.
func _event_face(ev: String, p: Vector2, r: float, tint: Color) -> void:
	var art := _tex(ev)
	if art == null:
		return
	var side := minf(art.get_width(), art.get_height())
	var corner := (Vector2(art.get_width(), art.get_height()) - Vector2.ONE * side) / 2.0
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for k in 24:
		var d := Vector2.from_angle(k * TAU / 24.0)
		pts.append(p + d * r)
		uvs.append((corner + (d * 0.5 + Vector2.ONE * 0.5) * side) / Vector2(art.get_width(), art.get_height()))
	draw_colored_polygon(pts, tint, uvs, art)
	draw_arc(p, r, 0.0, TAU, 32, Color(COLORS.event, tint.a), 3.0, true)


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
