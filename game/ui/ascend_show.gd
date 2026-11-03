## The Ascension reveal (Newms 2026-11-02): a critter ascending gets its own
## evolution moment, styled by its family. Three beats over about 3 seconds:
##   gather  the family's things close in (leaves, bubbles, circuit traces...)
##           while the ball pulses brighter and brighter
##   flash   a white-violet burst hides the ball for a blink
##   burst   the family's things fly out, the ball is back with a purple halo
## then the title, the new purple star and the boon's new numbers pop in.
## Render-only and cheap: one Control draws everything with plain shapes,
## a few dozen at most, and stops redrawing once the burst has settled.
## Reduced motion skips straight to the end card.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Motion := preload("res://game/ui/motion.gd")
const Families := preload("res://sim/families.gd")
const Boons := preload("res://sim/boons.gd")
const Painted := preload("res://game/ui/painted.gd")

const GATHER := 1.4
const FLASH := 0.3
const BURST := 1.1
const END := GATHER + FLASH + BURST
const BALL := 230.0
const RADIUS := .38 ## The ball's radius as a share of BALL.
const N := 28 ## Particles per family effect.

var family := "nature"
var col := Color.WHITE
var t := 0.0
var _parts: Array = [] ## [angle, distance, size, spin, delay] per particle.
var _icon: Control
var _card: Control
var _fx: Control
var _front: Control
var _home: Control ## The family's home painting (the Critters screen's), fading in after the pop.
var _done := false


## Plays the reveal for `cid` reaching Ascension `level` over the shell.
## `on_close` runs when Continue closes it.
static func play(shell, cid: String, level: int, on_close := Callable()) -> void:
	var show = load("res://game/ui/ascend_show.gd").new()
	show.setup(shell, cid, level, on_close)
	shell.overlay(show, "ascend")
	print("ASCEND_SHOW %s %s A%d" % [show.family, cid, level])
	if shell.sfx != null:
		shell.sfx.play("summon_charge", 0.0, 1.1)


## Builds the layers; also used by the preview (?ascendshow=fire).
func setup(shell, cid: String, level: int, on_close := Callable()) -> void:
	family = Families.of(cid)
	col = Color(Families.info(family).get("color", "b46cff"))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new() # Render-only: its own generator, never the fight's.
	rng.seed = hash([cid, level])
	for i in N:
		_parts.append([rng.randf_range(0.0, TAU), rng.randf_range(.55, 1.0), rng.randf_range(.6, 1.2), rng.randf_range(-1.0, 1.0), rng.randf_range(0.0, .35)])
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.08, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Newms 2026-11-03: the critter's family home (the same painting as its
	# critter screen) fades in behind it once the flash pops, the ball on its lit stage.
	var home := Painted.habitat(cid)
	if home != "":
		_home = Painted.make(home, {"focus": Vector2(200, 340), "at": Vector2(0.5, 0.36), "bottom_dark": 0.75})
		_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_home.modulate.a = 0.0
		add_child(_home)
	var fx := Control.new() # Draws behind the ball.
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.draw.connect(func(): _draw_fx(fx, false))
	add_child(fx)
	_fx = fx
	_icon = CritterIcon.make(cid, 5, BALL, true)
	_icon.radius_frac = RADIUS
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	var front := Control.new() # Flash and the closing shell sit over the ball.
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	front.draw.connect(func(): _draw_fx(front, true))
	add_child(front)
	_front = front
	_card = _end_card(shell, cid, level, on_close)
	add_child(_card)
	_card.modulate.a = 0.0
	resized.connect(_layout)
	if Motion.calm():
		t = END
	set_process(true)


func _layout() -> void:
	_icon.size = Vector2(BALL, BALL)
	_icon.position = _centre() - _icon.size / 2.0
	_icon.pivot_offset = _icon.size / 2.0
	_card.custom_minimum_size.x = minf(size.x - 48.0, 640.0)
	_card.size = Vector2(_card.custom_minimum_size.x, 0)
	_card.position = Vector2((size.x - _card.size.x) / 2.0, _centre().y + BALL * .62)


func _centre() -> Vector2:
	return Vector2(size.x / 2.0, size.y * .36)


func _process(delta: float) -> void:
	t = minf(END, t + delta)
	_layout()
	# The ball: pulses faster and brighter while gathering, hidden in the flash, springs back.
	var glow := 1.0
	var sc := 1.0
	if t < GATHER:
		var k := t / GATHER
		glow = 1.0 + 1.6 * k * k * (.6 + .4 * absf(sin(t * (6.0 + 18.0 * k))))
		sc = 1.0 + .05 * sin(t * (6.0 + 18.0 * k)) * k
	elif t < GATHER + FLASH:
		glow = 3.0
		sc = .85
	else:
		var k := (t - GATHER - FLASH) / BURST
		glow = lerpf(2.4, 1.0, minf(1.0, k * 2.0))
		sc = 1.0 + .18 * exp(-6.0 * k) * cos(k * 18.0)
	_icon.modulate = Color(glow, glow, glow)
	_icon.scale = Vector2(sc, sc)
	if _home != null and t >= GATHER + FLASH * .6 and _home.modulate.a == 0.0:
		_home.modulate.a = 0.01
		_home.create_tween().tween_property(_home, "modulate:a", 1.0, .7).set_ease(Tween.EASE_OUT)
	if t >= GATHER + FLASH + .5 and _card.modulate.a == 0.0:
		_card.create_tween().tween_property(_card, "modulate:a", 1.0, .3)
	_fx.queue_redraw()
	_front.queue_redraw()
	if t >= END and not _done:
		_done = true
		_card.modulate.a = 1.0
		if _home != null:
			_home.modulate.a = 1.0
		set_process(false) # Settled: nothing redraws until it closes.


## Ease helpers: 0..1 progress of the gather and burst beats.
func _g() -> float:
	return clampf(t / GATHER, 0.0, 1.0)


func _b() -> float:
	return clampf((t - GATHER - FLASH) / BURST, 0.0, 1.0)


func _draw_fx(ci: CanvasItem, front: bool) -> void:
	var c := _centre()
	var r := BALL * RADIUS
	if front:
		# The flash: a soft white-violet bloom swelling over the ball, then gone.
		if t >= GATHER - .1 and t < GATHER + FLASH + .25:
			var k := clampf((t - GATHER + .1) / (FLASH + .35), 0.0, 1.0)
			var a := sin(k * PI)
			_glow(ci, c, r * (2.2 + 3.0 * k), Color(Glyph.PURPLE.lerp(Color.WHITE, .5), a))
			_glow(ci, c, r * (1.4 + 1.2 * k), Color(1, 1, 1, a))
		if family == "frost" and t < GATHER + .05:
			_frost_shell(ci, c, r)
		return
	# The charge: a soft glow in the family's colour that swells while gathering.
	if t < GATHER + FLASH:
		_glow(ci, c, r * (1.6 + 1.6 * _g()), Color(col, .25 + .45 * _g()))
	# The halo the ball keeps once it's ascended.
	if t >= GATHER + FLASH:
		var k := _b()
		var rr := r * (1.25 + .1 * exp(-4.0 * k))
		ci.draw_arc(c, rr, 0.0, TAU, 64, Color(Glyph.PURPLE, .35 * minf(1.0, k * 3.0)), 14.0, true)
		ci.draw_arc(c, rr, t * .6, t * .6 + TAU * .8, 48, Color(Glyph.PURPLE.lightened(.3), minf(1.0, k * 3.0)), 4.0, true)
	match family:
		"nature": _nature(ci, c, r)
		"sea": _sea(ci, c, r)
		"tech": _tech(ci, c, r)
		"sweet": _sweet(ci, c, r)
		"frost": _frost(ci, c, r)
		"toybox": _toybox(ci, c, r)
		"spooky": _spooky(ci, c, r)
		"fire": _fire(ci, c, r)
		_: _cosmic(ci, c, r)


## Where particle `p` sits while gathering: far out, spiralling in by `twist`.
func _in(c: Vector2, r: float, p: Array, twist: float) -> Vector2:
	var k := clampf((_g() - p[4]) / (1.0 - p[4]), 0.0, 1.0)
	var d: float = lerpf(r * 3.2 * p[1] + r, r * .9, k * k)
	var a: float = p[0] + twist * k
	return c + Vector2(cos(a), sin(a)) * d


## Where particle `p` sits while bursting out.
func _out(c: Vector2, r: float, p: Array, reach := 3.0) -> Vector2:
	var k := 1.0 - pow(1.0 - _b(), 3.0)
	return c + Vector2(cos(p[0]), sin(p[0])) * lerpf(r * 1.1, r * reach * p[1] + r, k)


func _fade_in() -> float:
	return clampf(_g() * 4.0, 0.0, 1.0)


func _fade_out() -> float:
	return 1.0 - _b()


func _gathering() -> bool:
	return t < GATHER + FLASH * .5


func _bursting() -> bool:
	return t >= GATHER + FLASH * .5 and t < END


static func _leaf(ci: CanvasItem, p: Vector2, s: float, a: float, c: Color) -> void:
	var d := Vector2(cos(a), sin(a))
	var n := Vector2(-d.y, d.x)
	ci.draw_colored_polygon(PackedVector2Array([p - d * s, p + n * s * .45, p + d * s, p - n * s * .45]), c)
	ci.draw_line(p - d * s, p + d * s, c.darkened(.35), 1.5, true)


## Nature: leaves spiral in; a ring of petals blooms open.
func _nature(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _gathering():
		for p in _parts:
			var q := _in(c, r, p, 2.2)
			_leaf(ci, q, 14.0 * p[2], p[0] + t * 3.0 * p[3], Color(col, _fade_in()))
	elif _bursting():
		var k := _b()
		for i in 10:
			var a := TAU * i / 10.0 + k * 1.2
			var q := c + Vector2(cos(a), sin(a)) * r * (1.0 + 1.1 * k)
			_leaf(ci, q, 34.0 * (1.0 - k * .5), a, Color(Color("ff8fc8") if i % 2 == 0 else col, _fade_out()))
		for p in _parts:
			_leaf(ci, _out(c, r, p, 3.4), 10.0 * p[2], p[0] + t * 4.0, Color(col.lightened(.3), _fade_out()))


## Sea: bubbles rise and gather; a wobbling wave ring and arcing droplets.
func _sea(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _gathering():
		for p in _parts:
			var q := _in(c, r, p, .6) + Vector2(sin(t * 5.0 + p[0] * 3.0) * 8.0, 0)
			var s: float = 7.0 * p[2]
			ci.draw_arc(q, s, 0.0, TAU, 16, Color(col.lightened(.4), _fade_in()), 2.0, true)
			ci.draw_circle(q + Vector2(-s * .35, -s * .35), s * .25, Color(1, 1, 1, .7 * _fade_in()))
	elif _bursting():
		var k := _b()
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48.0
			pts.append(c + Vector2(cos(a), sin(a)) * (r * (1.1 + 1.8 * k) + sin(a * 8.0 + t * 9.0) * 8.0))
		ci.draw_polyline(pts, Color(col.lightened(.3), _fade_out()), 6.0, true)
		for p in _parts:
			var q := _out(c, r, p, 2.6) + Vector2(0, 260.0 * k * k * p[1]) # Droplets fall back.
			ci.draw_circle(q, 6.0 * p[2] * (1.0 - k * .5), Color(col, _fade_out()))


## Tech: circuit traces run in at right angles; scan rings and spark lines out.
func _tech(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _gathering():
		for i in 12:
			var p: Array = _parts[i]
			var k := clampf(_g() * 1.3 - p[4], 0.0, 1.0)
			var a: float = PI / 2.0 * (i % 4) + .3 * p[3]
			var far := c + Vector2(cos(a), sin(a)) * r * 3.4
			var knee := Vector2(far.x, lerpf(far.y, c.y, .5)) if i % 2 == 0 else Vector2(lerpf(far.x, c.x, .5), far.y)
			var path := [far, knee, c + (knee - c).normalized() * r * .95]
			var head: Vector2 = path[0].lerp(path[1], minf(1.0, k * 2.0)) if k < .5 else path[1].lerp(path[2], (k - .5) * 2.0)
			ci.draw_line(path[0], head if k < .5 else path[1], Color(col.lightened(.3), .8), 3.0, true)
			if k >= .5:
				ci.draw_line(path[1], head, Color(col.lightened(.3), .8), 3.0, true)
			ci.draw_circle(head, 5.0, Color("5ce1ff"))
	elif _bursting():
		var k := _b()
		for j in 3:
			var kk := clampf(k * 1.4 - j * .2, 0.0, 1.0)
			if kk > 0.0:
				var pts := PackedVector2Array()
				for i in 7:
					var a := TAU * i / 6.0 + PI / 6.0
					pts.append(c + Vector2(cos(a), sin(a)) * r * (1.1 + 2.0 * kk))
				ci.draw_polyline(pts, Color("5ce1ff", (1.0 - kk) * .9), 4.0, true)
		for p in _parts:
			var q := _out(c, r, p, 3.0)
			ci.draw_line(q, q + (q - c).normalized() * 18.0, Color(1, 1, 1, _fade_out()), 2.5, true)


## Sweet: rainbow sprinkles swirl in; a candy-stripe ring pops and confetti falls.
func _sweet(ci: CanvasItem, c: Vector2, r: float) -> void:
	var tints := [Color("ff7ac8"), Color("ffd166"), Color("7ee8fa"), Color("a3f07c"), Color.WHITE]
	if _gathering():
		for i in _parts.size():
			var p: Array = _parts[i]
			var q := _in(c, r, p, 3.0)
			var a: float = p[0] + t * 6.0 * p[3]
			var d := Vector2(cos(a), sin(a)) * 7.0
			ci.draw_line(q - d, q + d, Color(tints[i % tints.size()], _fade_in()), 5.0, true)
	elif _bursting():
		var k := _b()
		for i in 16:
			var a0 := TAU * i / 16.0 + k * 2.0
			ci.draw_arc(c, r * (1.15 + 1.2 * k), a0, a0 + TAU / 16.0, 6, Color(tints[0] if i % 2 == 0 else Color.WHITE, _fade_out()), 16.0 * (1.0 - k * .6), true)
		for i in _parts.size():
			var p: Array = _parts[i]
			var q := _out(c, r, p, 3.0) + Vector2(0, 180.0 * k * k)
			var a: float = t * 8.0 * p[3]
			var d := Vector2(cos(a), sin(a)) * 6.0
			ci.draw_line(q - d, q + d, Color(tints[i % tints.size()], _fade_out()), 6.0, true)


## Frost: ice shards close into a crystal shell (drawn over the ball, see
## _frost_shell); it shatters and snowflakes drift out.
func _frost(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _bursting():
		var k := _b()
		for p in _parts:
			var q := _out(c, r, p, 3.2)
			var a: float = p[0] + k * 5.0 * p[3]
			var s: float = 16.0 * p[2] * (1.0 - k * .4)
			ci.draw_colored_polygon(PackedVector2Array([q + Vector2(cos(a), sin(a)) * s, q + Vector2(cos(a + 2.4), sin(a + 2.4)) * s * .5, q + Vector2(cos(a - 2.4), sin(a - 2.4)) * s * .5]), Color(col.lightened(.4), _fade_out()))
		for i in 6:
			var q := c + Vector2(cos(TAU * i / 6.0 + .5), sin(TAU * i / 6.0 + .5)) * r * (1.4 + 1.4 * k)
			for j in 3:
				var a := PI / 3.0 * j + k * 2.0
				var d := Vector2(cos(a), sin(a)) * 14.0
				ci.draw_line(q - d, q + d, Color(1, 1, 1, _fade_out()), 2.5, true)


func _frost_shell(ci: CanvasItem, c: Vector2, r: float) -> void:
	for i in 12:
		var p: Array = _parts[i]
		var k := clampf(_g() * 1.25 - p[4] * .5, 0.0, 1.0)
		var a := TAU * i / 12.0
		var d := lerpf(r * 3.0, r * 1.02, k * k)
		var q := c + Vector2(cos(a), sin(a)) * d
		var tang := Vector2(-sin(a), cos(a)) * r * .3
		var out := Vector2(cos(a), sin(a)) * r * .2
		ci.draw_colored_polygon(PackedVector2Array([q - tang, q + out, q + tang, q - out * 1.6]), Color(col.lightened(.5), .55 * k + .2))


## Toybox: wooden blocks hop in; springy stars bounce out.
func _toybox(ci: CanvasItem, c: Vector2, r: float) -> void:
	var tints := [Color("ff5a5a"), Color("ffc93c"), Color("3fa9f5"), Color("5fd068")]
	if _gathering():
		for i in 16:
			var p: Array = _parts[i]
			var q := _in(c, r, p, 0.0) - Vector2(0, absf(sin(t * 7.0 + p[0] * 2.0)) * 26.0 * (1.0 - _g()))
			var s: float = 13.0 * p[2]
			ci.draw_rect(Rect2(q - Vector2(s, s), Vector2(s, s) * 2.0), Color(tints[i % 4], _fade_in()))
			ci.draw_rect(Rect2(q - Vector2(s, s), Vector2(s, s) * 2.0), Color(0, 0, 0, .3 * _fade_in()), false, 2.0)
	elif _bursting():
		var k := _b()
		for i in 14:
			var p: Array = _parts[i]
			var q := _out(c, r, p, 2.8) - Vector2(0, absf(sin(k * 9.0 + i)) * 40.0 * (1.0 - k))
			ci.draw_colored_polygon(_star(q, 18.0 * p[2], 5, t * 3.0 * p[3]), Color(tints[i % 4], _fade_out()))


## Spooky: wisps circle in as the room goes dark; they scatter as ghost flames.
func _spooky(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _gathering():
		ci.draw_circle(c, r * 6.0, Color(0, 0, 0, .35 * _g()))
		for p in _parts.slice(0, 14):
			for j in 4: # A head and a fading tail.
				var back := t - j * .05
				var k := clampf((back / GATHER - p[4]) / (1.0 - p[4]), 0.0, 1.0)
				var a: float = p[0] + 4.0 * k
				var q := c + Vector2(cos(a), sin(a)) * lerpf(r * 3.0 * p[1] + r, r * .9, k)
				ci.draw_circle(q, (9.0 - j * 2.0) * p[2], Color(col.lightened(.3), (1.0 - j * .25) * _fade_in()))
	elif _bursting():
		var k := _b()
		for p in _parts.slice(0, 18):
			var q := _out(c, r, p, 2.6) + Vector2(sin(t * 6.0 + p[0]) * 10.0, -60.0 * k)
			var s: float = 16.0 * p[2] * (1.0 - k * .5)
			ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-s * .6, 0), q + Vector2(0, -s * 1.6), q + Vector2(s * .6, 0), q + Vector2(0, s * .5)]), Color(col, .8 * _fade_out()))


## Fire: flame tongues lick up round the ball; embers rise from a fire ring.
func _fire(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _gathering():
		var g := _g()
		for i in 14:
			var a := TAU * i / 14.0
			var base := c + Vector2(cos(a), sin(a)) * r * lerpf(2.4, 1.0, g)
			var h := (24.0 + 20.0 * sin(t * 12.0 + i * 1.7)) * (.5 + g)
			var w := 12.0
			ci.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, -h), base + Vector2(w, 0)]), Color(Color("ffb02e") if i % 2 == 0 else col, _fade_in()))
	elif _bursting():
		var k := _b()
		ci.draw_arc(c, r * (1.15 + 1.4 * k), 0.0, TAU, 48, Color(col, _fade_out()), 18.0 * (1.0 - k), true)
		for p in _parts:
			var q := _out(c, r, p, 2.4) - Vector2(0, 160.0 * k * p[1])
			ci.draw_circle(q, 5.0 * p[2] * (1.0 - k * .6), Color(Color("ffd166").lerp(col, k), _fade_out()))


## Cosmic: stars streak in from deep space; a nova ring and orbiting motes.
func _cosmic(ci: CanvasItem, c: Vector2, r: float) -> void:
	if _gathering():
		for p in _parts:
			var q := _in(c, r, p, 0.0)
			var d := (c - q).normalized() * 22.0 * _g()
			ci.draw_line(q - d, q, Color(col.lightened(.5), _fade_in() * .7), 2.0, true)
			ci.draw_colored_polygon(_star(q, 6.0 * p[2], 4, 0.0), Color(1, 1, 1, _fade_in()))
	elif _bursting():
		var k := _b()
		ci.draw_arc(c, r * (1.1 + 2.4 * k), 0.0, TAU, 64, Color(col.lightened(.4), _fade_out()), 8.0, true)
		ci.draw_arc(c, r * (1.1 + 1.5 * k), 0.0, TAU, 64, Color(Glyph.PURPLE, _fade_out()), 4.0, true)
		for i in 5:
			var a := TAU * i / 5.0 + t * 2.0
			ci.draw_circle(c + Vector2(cos(a), sin(a) * .4) * r * 1.7, 7.0, Color(col.lightened(.5), _fade_out()))


static var _soft: Texture2D


## A smooth radial glow (one gradient texture, no stacked circles), `c.a` at the middle.
static func _glow(ci: CanvasItem, p: Vector2, radius: float, c: Color) -> void:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(.45, Color(1, 1, 1, .45))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(.5, .5)
		tex.fill_to = Vector2(1, .5)
		tex.width = 128
		tex.height = 128
		_soft = tex
	ci.draw_texture_rect(_soft, Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, c)


static func _star(p: Vector2, s: float, points: int, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points * 2:
		var a := rot - PI / 2.0 + PI * i / points
		out.append(p + Vector2(cos(a), sin(a)) * (s if i % 2 == 0 else s * .42))
	return out


## Title, stars with the new one purple, the boon's numbers now, Continue.
func _end_card(shell, cid: String, level: int, on_close: Callable) -> Control:
	var c := Roster.get_critter(cid)
	var title := Kit.label("Ascension %d!" % level, 44, Glyph.PURPLE, HORIZONTAL_ALIGNMENT_CENTER)
	var stars := Glyph.tier_stars(40, 5, level, 5)
	var sc := CenterContainer.new()
	sc.add_child(stars)
	var boon := Boons.ascended(cid, level)
	var text := Kit.label("%s · %s" % [Boons.get_def(Boons.for_critter(cid)).get("name", ""), boon.get("text", "")], 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	var ok := Kit.button("Continue", func():
		if shell != null:
			shell.close_overlay()
		if on_close.is_valid():
			on_close.call(), "go", 28, 88)
	if shell != null:
		shell.mark("ascend_done", ok)
	var v := Kit.vbox(14, [title, Kit.label(c.name, 28, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), sc, text, ok])
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	return v
