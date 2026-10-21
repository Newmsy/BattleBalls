## The world map: the Neon Circuit's zones as glowing nodes on a winding path,
## from Glow Garden at the bottom up to Magma Core. Built zones are buttons
## that open their stage list; the rest are locked "coming soon" nodes. The
## path is lit up to the furthest zone you can play. Looks only.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Zones := preload("res://meta/zones.gd")

## Node centres as fractions of the map, zone 1 first (bottom).
const SPOTS := [Vector2(.25, .88), Vector2(.72, .75), Vector2(.3, .62), Vector2(.74, .49), Vector2(.28, .36), Vector2(.72, .23), Vector2(.34, .09)]
const OPEN_R := 62.0
const LOCKED_R := 42.0

var zones: Array = []
var open_count := 1 ## Zones you can play (the first open_count are lit).
var glitched := true ## Zone 1's boss isn't purified yet: the Glitch sits on it.
var nodes: Array[Control] = []
var _labels: Array[Control] = []
var _you: Control


static func make(zones_: Array, open_count_: int, glitched_: bool, height: float, on_zone: Callable, fighter: String, fighter_tier: int) -> Control:
	var m = load("res://game/ui/world_map.gd").new()
	m.zones = zones_
	m.open_count = open_count_
	m.glitched = glitched_
	m.custom_minimum_size = Vector2(0, height)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.mouse_filter = Control.MOUSE_FILTER_PASS
	for i in zones_.size():
		var z: Dictionary = zones_[i]
		var open := i < open_count_
		var r := OPEN_R if open else LOCKED_R
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(r, r) * 2.0
		var clear := StyleBoxEmpty.new()
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(st, clear)
		b.pressed.connect(on_zone.bind(i))
		var inner: Control
		if open:
			inner = CritterIcon.make(z.get("icon", "juggernaut"), 1, r * 1.5)
		else:
			inner = Glyph.make("lock", r * .8, Color(z.color).lerp(Kit.MUTED, .5))
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.size = inner.custom_minimum_size
		inner.position = (b.size - inner.size) / 2.0
		b.add_child(inner)
		m.add_child(b)
		m.nodes.append(b)
		var fmt := "1v1" if z.lineup == 1 else "%dv%d" % [z.lineup, z.lineup]
		var sub := ("Zone %d · %d stages · %s" % [i + 1, z.stages.size(), fmt]) if open else "Zone %d · Locked · %s" % [i + 1, fmt]
		var text := Kit.vbox(0, [Kit.caption(sub, Color(z.color) if open else Kit.MUTED),
			Kit.label(z.name, 30 if open else 24, Kit.FG if open else Kit.MUTED)])
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_child(text)
		m._labels.append(text)
	m._you = CritterIcon.make(fighter, fighter_tier, 72)
	m._you.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m._you.size = m._you.custom_minimum_size
	m.add_child(m._you)
	return m


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func center(i: int) -> Vector2:
	return SPOTS[i] * size


func _layout() -> void:
	for i in nodes.size():
		var c := center(i)
		var b := nodes[i]
		b.position = c - b.size / 2.0
		var t := _labels[i]
		t.size = t.get_combined_minimum_size()
		var r := b.size.x / 2.0
		# Labels sit on the open side of the node, never past the map's edge.
		if SPOTS[i].x < .5:
			t.position = Vector2(c.x + r + 16, c.y - t.size.y / 2.0)
		else:
			t.position = Vector2(c.x - r - 16 - t.size.x, c.y - t.size.y / 2.0)
		t.position.x = clampf(t.position.x, 0, maxf(0, size.x - t.size.x))
	# You stand next to the furthest zone you can play.
	var at := center(open_count - 1)
	# Opposite the zone's label so it never covers the text.
	var left: bool = SPOTS[open_count - 1].x < .5
	_you.position = Vector2(at.x - OPEN_R - _you.size.x + 18 if left else at.x + OPEN_R - 18, at.y - OPEN_R - 4)
	_you.position.x = clampf(_you.position.x, 0, maxf(0, size.x - _you.size.x))
	queue_redraw()


func _draw() -> void:
	# A quiet starfield and a synthwave horizon grid, seeded so it never jumps.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 70:
		var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
		draw_circle(p, rng.randf_range(1.0, 2.6), Color(Kit.FG, rng.randf_range(.08, .35)))
	var grid := Color(Kit.ACCENT, .1)
	for k in 6:
		var y := size.y * (.8 + k * k * .006)
		draw_line(Vector2(0, y), Vector2(size.x, y), grid, 2.0)
	for k in 9:
		var x := size.x * k / 8.0
		draw_line(Vector2(size.x / 2.0 + (x - size.x / 2.0) * .35, size.y * .8), Vector2(x, size.y), grid, 2.0)

	# The path, zone to zone. Lit up to the furthest open zone, dim after.
	for i in nodes.size() - 1:
		var pts := _curve(center(i), center(i + 1))
		var lit := i + 1 < open_count
		var col := Color(zones[i].color) if lit else Kit.LINE
		if lit:
			draw_polyline(pts, Color(col, .14), 22.0, true)
			draw_polyline(pts, Color(col, .4), 10.0, true)
			draw_polyline(pts, col.lightened(.3), 4.0, true)
		else:
			for k in range(0, pts.size() - 1, 2):
				draw_line(pts[k], pts[k + 1], Color(Kit.LINE, 1.0).lightened(.15), 6.0, true)

	# Nodes: a glowing disc in the zone's colour; locked ones are dim rings.
	for i in nodes.size():
		var c := center(i)
		var col := Color(zones[i].color)
		if i < open_count:
			for g in 4:
				draw_circle(c, OPEN_R + 6 + g * 7, Color(col, .1 - g * .02))
			draw_circle(c, OPEN_R, Kit.PANEL2)
			draw_arc(c, OPEN_R, 0, TAU, 64, col, 5.0, true)
			draw_arc(c, OPEN_R - 9, 0, TAU, 64, Color(col, .35), 2.0, true)
		else:
			draw_circle(c, LOCKED_R, Kit.PANEL)
			draw_arc(c, LOCKED_R, 0, TAU, 48, Color(col, .45), 3.0, true)
	# The Glitch peeks over the furthest open zone until its boss is purified (glitch.md).
	if glitched:
		var g := center(open_count - 1) + Vector2(OPEN_R * .55, OPEN_R * .62)
		var pink := Color("ff3fd8")
		for px in [Vector2(0, 0), Vector2(10, 0), Vector2(-10, 10), Vector2(0, 10), Vector2(10, 10), Vector2(20, 10), Vector2(0, 20), Vector2(10, 20)]:
			draw_rect(Rect2(g + px - Vector2(5, 5), Vector2(9, 9)), pink)
		draw_rect(Rect2(g + Vector2(-2, 7), Vector2(4, 4)), Kit.BG)
		draw_rect(Rect2(g + Vector2(8, 7), Vector2(4, 4)), Kit.BG)


## A gentle S-bend from a to b, as points.
static func _curve(a: Vector2, b: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var dy := (b.y - a.y) * .7
	var c0 := a + Vector2(0, dy)
	var c1 := b - Vector2(0, dy)
	for k in 25:
		var t := k / 24.0
		var u := 1.0 - t
		pts.append(a * u * u * u + c0 * 3.0 * u * u * t + c1 * 3.0 * u * t * t + b * t * t * t)
	return pts
