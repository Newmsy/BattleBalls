## The world map: the Neon Circuit's zones as glowing nodes on a winding path,
## from Glow Garden at the bottom up to Magma Core. Built zones are buttons
## that open their stage list; the rest are locked "coming soon" nodes. The
## path is lit up to the furthest zone you can play. Looks only.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Zones := preload("res://meta/zones.gd")
const Dot := preload("res://game/dot.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Motion := preload("res://game/ui/motion.gd")

## Node centres as fractions of the map, zone 1 first (bottom).
const SPOTS := [Vector2(.25, .88), Vector2(.72, .75), Vector2(.3, .62), Vector2(.74, .49), Vector2(.28, .36), Vector2(.72, .23), Vector2(.34, .09)]
const OPEN_R := 62.0
const LOCKED_R := 42.0
## Painted art (tools/event_art/scenes/map_*.mjs): the sky behind the map and
## one floating island per zone, its node centred at ISLAND_NODE.
const ART := "res://game/ui/map_art/"
const ISLAND_NODE := Vector2(140, 92)
const LOCKED_TINT := Color(.4, .4, .55, .8)

var zones: Array = []
var open_count := 1 ## Zones you can play (the first open_count are lit).
var glitched := true ## Zone 1's boss isn't purified yet: the Glitch sits on it.
var nodes: Array[Control] = []
var _labels: Array[Control] = []
var _you: Control
## How many zones were open the last time the map was shown: newly opened
## ones get their moment (the light runs along the path, the node pops open,
## you hop over).
static var seen_open := -1
var _from_open := 0 ## Zones open before this showing (the reveal starts after them).
var _reveal := 1.0 ## 0..1 through the newly lit path.
var _sky: Control
var _islands: Array = [] ## Each zone's island painting, or null.
var _art_count := 0 ## Paintings added so far: they stay first, in order.
## How far the sky reaches past each side of the map (Shell.bleed()): the
## painting runs edge to edge while the zones stay inside the column.
var bleed := 0.0
var _fades: Array[TextureRect] = [] ## Soft top and bottom edges on the sky.
const FADE := 90.0


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
		var sub := "Zone %d · %s" % [i + 1, fmt]
		var text := Kit.vbox(0, [Kit.caption(sub, Color(z.color) if open else Kit.MUTED),
			Kit.label(z.name, 30 if open else 24, Kit.FG if open else Kit.MUTED)])
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		m.add_child(text)
		m._labels.append(text)
	m._you = CritterIcon.make(fighter, fighter_tier, 72)
	m._you.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m._you.size = m._you.custom_minimum_size
	m.add_child(m._you)
	m._add_art()
	m._from_open = open_count_
	if seen_open > 0 and seen_open < open_count_ and not Motion.calm():
		m._from_open = seen_open
		m._reveal = 0.0
		for i in range(seen_open, open_count_):
			m.nodes[i].modulate.a = 0.0
			m._labels[i].modulate.a = 0.0
	seen_open = open_count_
	return m


func _ready() -> void:
	if _reveal >= 1.0:
		return
	# The light runs on from the last zone you had to the new one; then it
	# pops open and you hop over to it.
	var tw := create_tween()
	tw.tween_interval(.35)
	tw.tween_method(func(t: float) -> void:
		_reveal = t
		queue_redraw(), 0.0, 1.0, .8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		for i in range(_from_open, open_count):
			nodes[i].modulate.a = 1.0
			Motion.pop(nodes[i], 0.0, .4)
			Motion.cascade([_labels[i]])
		var to := _you.position
		var from := _you_spot(_from_open - 1)
		_you.position = from
		var hop := create_tween()
		hop.tween_method(func(t: float) -> void:
			_you.position = from.lerp(to, t) - Vector2(0, sin(t * PI) * 60.0), 0.0, 1.0, .45).set_ease(Tween.EASE_IN_OUT))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func center(i: int) -> Vector2:
	return SPOTS[i] * size


func _layout() -> void:
	if _sky != null:
		_sky.position = Vector2(-bleed, 0)
		_sky.size = size + Vector2(bleed * 2.0, 0)
		for k in _fades.size():
			_fades[k].position = Vector2(-bleed, 0 if k == 0 else size.y - FADE)
			_fades[k].size = Vector2(size.x + bleed * 2.0, FADE)
	for i in _islands.size():
		if _islands[i] != null:
			var k := 1.0 if i < open_count else LOCKED_R / OPEN_R
			_islands[i].position = center(i) - ISLAND_NODE * k
			_islands[i].size = _islands[i].texture.get_size() * k
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
	# You stand next to the furthest zone you can play (the last one you had
	# while a new one is being revealed).
	_you.position = _you_spot(open_count - 1 if _reveal >= 1.0 else _from_open - 1)
	queue_redraw()


## Where you stand by zone i: opposite its label so you never cover the text.
func _you_spot(i: int) -> Vector2:
	var at := center(i)
	var left: bool = SPOTS[i].x < .5
	var p := Vector2(at.x - OPEN_R - _you.size.x + 18 if left else at.x + OPEN_R - 18, at.y - OPEN_R - 4)
	p.x = clampf(p.x, 0, maxf(0, size.x - _you.size.x))
	return p


## A painting from ART, or null when there isn't one (a zone not painted yet).
static func _art(name: String) -> Texture2D:
	var path := ART + name + ".png"
	return load(path) if ResourceLoader.exists(path) else null


## The paintings sit in their own canvas items behind the map's drawing
## (show_behind_parent): the sky, then each zone's island, dimmed while locked.
func _add_art() -> void:
	var sky := _art("map_sky")
	if sky != null:
		_sky = _picture(sky, Color.WHITE)
		_sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		# The sky melts into the screen at the top and bottom: no frame.
		for top in [true, false]:
			var g := Gradient.new()
			g.set_color(0, Color(Kit.BG, 1.0 if top else 0.0))
			g.set_color(1, Color(Kit.BG, 0.0 if top else 1.0))
			var gt := GradientTexture2D.new()
			gt.gradient = g
			gt.fill_from = Vector2(0, 0)
			gt.fill_to = Vector2(0, 1)
			gt.width = 4
			gt.height = 64
			_fades.append(_picture(gt, Color.WHITE))
	for i in zones.size():
		var island := _art("map_island_" + str(zones[i].get("id", "")))
		_islands.append(_picture(island, Color.WHITE if i < open_count else LOCKED_TINT) if island != null else null)


func _picture(tex: Texture2D, tint: Color) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.show_behind_parent = true
	t.self_modulate = tint
	add_child(t)
	move_child(t, _art_count)
	_art_count += 1
	return t


func _draw() -> void:
	if _sky == null:
		_draw_starfield()
	_draw_path()
	for i in nodes.size():
		if _islands[i] == null:
			_landmark(i, i < open_count)
	# A soft dark backing so each zone's name reads over the art.
	for t in _labels:
		var back := StyleBoxFlat.new()
		back.bg_color = Color(Kit.BG, .55)
		back.set_corner_radius_all(16)
		draw_style_box(back, Rect2(t.position, t.size).grow_individual(12, 4, 12, 4))
	_draw_nodes()


## The plain map behind zones with no painting: stars and a horizon grid.
func _draw_starfield() -> void:
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


func _draw_path() -> void:
	# The path, zone to zone. Lit up to the furthest open zone, dim after.
	# Newly opened segments light up one after another as _reveal runs.
	var fresh := maxi(1, open_count - _from_open)
	for i in nodes.size() - 1:
		var pts := _curve(center(i), center(i + 1))
		var lit := i + 1 < open_count
		var col := Color(zones[i].color) if lit else Kit.LINE
		if lit and i + 1 >= _from_open and _reveal < 1.0:
			# Dim underneath, the bright part growing along it.
			for k in range(0, pts.size() - 1, 2):
				draw_line(pts[k], pts[k + 1], Color(Kit.LINE, 1.0).lightened(.15), 6.0, true)
			var part := clampf(_reveal * fresh - (i + 1 - _from_open), 0.0, 1.0)
			var n := int(round(part * (pts.size() - 1)))
			if n >= 1:
				var head := pts.slice(0, n + 1)
				draw_polyline(head, Color(col, .4), 10.0, true)
				draw_polyline(head, col.lightened(.3), 4.0, true)
				Dot.circle(self, head[head.size() - 1], 9.0, col.lightened(.6))
			continue
		if lit:
			draw_polyline(pts, Color(col, .14), 22.0, true)
			draw_polyline(pts, Color(col, .4), 10.0, true)
			draw_polyline(pts, col.lightened(.3), 4.0, true)
		else:
			for k in range(0, pts.size() - 1, 2):
				draw_line(pts[k], pts[k + 1], Color(Kit.LINE, 1.0).lightened(.15), 6.0, true)



func _draw_nodes() -> void:
	# Nodes: a glowing disc in the zone's colour; locked ones are dim rings.
	for i in nodes.size():
		var c := center(i)
		var col := Color(zones[i].color)
		if i < open_count and (i < _from_open or _reveal >= 1.0):
			Dot.glow(self, c, OPEN_R + 30, Color(col, .3), OPEN_R / (OPEN_R + 30.0))
			draw_circle(c, OPEN_R, Kit.PANEL2)
			draw_arc(c, OPEN_R, 0, TAU, 64, col, 5.0, true)
			draw_arc(c, OPEN_R - 9, 0, TAU, 64, Color(col, .35), 2.0, true)
		else:
			draw_circle(c, LOCKED_R, Kit.PANEL)
			draw_arc(c, LOCKED_R, 0, TAU, 48, Color(col, .45), 3.0, true)
	# The Glitch peeks over the furthest open zone until its boss is purified (glitch.md).
	if glitched and _reveal >= 1.0:
		var g := center(open_count - 1) + Vector2(OPEN_R * .55, OPEN_R * .62)
		var pink := Color("ff3fd8")
		for px in [Vector2(0, 0), Vector2(10, 0), Vector2(-10, 10), Vector2(0, 10), Vector2(10, 10), Vector2(20, 10), Vector2(0, 20), Vector2(10, 20)]:
			draw_rect(Rect2(g + px - Vector2(5, 5), Vector2(9, 9)), pink)
		draw_rect(Rect2(g + Vector2(-2, 7), Vector2(4, 4)), Kit.BG)
		draw_rect(Rect2(g + Vector2(8, 7), Vector2(4, 4)), Kit.BG)


## The drawn stand-in for a zone with no painted island: a disc of ground
## under zone i's node and a landmark that says which zone it is: glowing mushrooms, chip towers, ice shards, thorny briars, an arcade
## cabinet, a falling star over a crater, a volcano.
func _landmark(i: int, open: bool) -> void:
	var c := center(i)
	var col := Color(zones[i].color)
	var r := OPEN_R if open else LOCKED_R
	var body := col.darkened(.55) if open else Color(col.darkened(.7), .55)
	var lit := col if open else Color(col.darkened(.4), .5)
	# The island: a flat disc of ground under the node.
	draw_set_transform(c + Vector2(0, r * .82), 0.0, Vector2(1.0, .3))
	Dot.circle(self, Vector2.ZERO, r * 1.55, Color(0, 0, 0, .25))
	Dot.circle(self, Vector2(0, -r * .2), r * 1.45, body.darkened(.3))
	draw_arc(Vector2(0, -r * .2), r * 1.45, PI * .1, PI * .9, 24, Color(lit, .3), 5.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# Props stand on the island's far side from the label.
	var s := -1.0 if SPOTS[i].x < .5 else 1.0
	var g := c + Vector2(s * r * 1.15, r * .78) # Ground point for the props.
	var k := 1.25 * r / OPEN_R
	match str(zones[i].get("id", "")):
		"glow_garden":
			for m in [[Vector2(0, 0), 1.0], [Vector2(s * 26, 6), .7]]:
				var at: Vector2 = g + m[0] * k
				var h: float = 34.0 * m[1] * k
				draw_rect(Rect2(at + Vector2(-4 * m[1] * k, -h), Vector2(8 * m[1] * k, h)), body.lightened(.25))
				var cap := PackedVector2Array()
				for q in 13:
					var a := PI + PI * q / 12.0
					cap.append(at + Vector2(0, -h) + Vector2(cos(a) * 20.0, sin(a) * 14.0) * m[1] * k)
				Dot.poly(self, cap, lit)
				Dot.circle(self, at + Vector2(-6.0 * m[1] * k, -h - 6.0 * m[1] * k), 3.0 * k, Color(1, 1, 1, .7 if open else .2))
		"circuit_lab":
			for t in [[Vector2(0, 0), 52.0, 22.0], [Vector2(s * 28, 4), 34.0, 18.0]]:
				var at: Vector2 = g + t[0] * k
				var rect := Rect2(at + Vector2(-t[2] / 2.0, -t[1]) * k, Vector2(t[2], t[1]) * k)
				draw_rect(rect, body.lightened(.15))
				for w in int(t[1] / 12.0):
					draw_rect(Rect2(rect.position + Vector2(5, 6 + w * 12) * k, Vector2(t[2] - 10, 4) * k), Color(lit, .8))
			draw_line(g + Vector2(0, -52) * k, g + Vector2(0, -66) * k, lit, 2.0)
			Dot.circle(self, g + Vector2(0, -68) * k, 3.5 * k, lit)
		"frostbite_caves":
			for sh in [[0.0, 54.0, 12.0], [s * 16.0, 36.0, 9.0], [-s * 14.0, 28.0, 8.0]]:
				var at: Vector2 = g + Vector2(sh[0], 0) * k
				Dot.poly(self, PackedVector2Array([at + Vector2(-sh[2], 0) * k, at + Vector2(0, -sh[1]) * k, at + Vector2(sh[2], 0) * k]), body.lightened(.3))
				Dot.poly(self, PackedVector2Array([at + Vector2(0, -sh[1]) * k, at + Vector2(sh[2], 0) * k, at + Vector2(sh[2] * .2, 0) * k]), Color(lit, .8))
		"bramble_hollow":
			for b in 3:
				var pts := PackedVector2Array()
				for q in 9:
					var u := q / 8.0
					pts.append(g + Vector2(s * (u * 40.0 - 8.0 + b * 6.0), -sin(u * PI) * (30.0 + b * 10.0)) * k)
				draw_polyline(pts, body.lightened(.2), 4.0 * k, true)
				for q in [2, 4, 6]:
					var p: Vector2 = pts[q]
					Dot.poly(self, PackedVector2Array([p + Vector2(-3, 0) * k, p + Vector2(0, -9) * k, p + Vector2(3, 0) * k]), lit)
		"haunted_arcade":
			var rect := Rect2(g + Vector2(-16, -56) * k, Vector2(32, 56) * k)
			draw_rect(rect, body.lightened(.15))
			draw_rect(Rect2(rect.position + Vector2(5, 8) * k, Vector2(22, 16) * k), Color(lit, .85))
			draw_rect(Rect2(rect.position + Vector2(6, 32) * k, Vector2(20, 5) * k), body.darkened(.2))
			Dot.circle(self, rect.position + Vector2(12, 34) * k, 3.0 * k, Color("ff5a7a") if open else body)
			var gh := g + Vector2(s * 34, -34) * k
			Dot.circle(self, gh, 11.0 * k, Color(1, 1, 1, .55 if open else .15))
			draw_rect(Rect2(gh + Vector2(-11, 0) * k, Vector2(22, 10) * k), Color(1, 1, 1, .55 if open else .15))
		"starfall_rim":
			draw_arc(g + Vector2(0, 2) * k, 24.0 * k, PI, TAU, 20, body.lightened(.3), 5.0 * k, true)
			var star := g + Vector2(s * 20, -54) * k
			draw_line(star, star + Vector2(-s * 34, -20) * k, Color(lit, .4), 4.0 * k, true)
			Dot.poly(self, CritterArt.star_pts(star, 11.0 * k, 4.5 * k, 5), lit)
		"magma_core":
			var v := PackedVector2Array([g + Vector2(-34, 0) * k, g + Vector2(-9, -46) * k, g + Vector2(9, -46) * k, g + Vector2(34, 0) * k])
			Dot.poly(self, v, body.lightened(.15))
			Dot.poly(self, PackedVector2Array([g + Vector2(-9, -46) * k, g + Vector2(9, -46) * k, g + Vector2(4, -30) * k, g + Vector2(-5, -24) * k]), lit)
			for e in 3:
				Dot.circle(self, g + Vector2(-6 + e * 7, -56 - e * 7) * k, (4.0 - e) * k, Color(lit, .7))


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
