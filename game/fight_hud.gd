extends Control
## Health bars for every fighter, each along the bottom of its plate
## (game/fight_layout.gd: the foe's plates above the arena, yours below), and
## the clock notched into the arena's top edge. YOU bars have a solid frame,
## FOE bars a dashed one: shape as well as colour tells the sides apart.
## A pale "chip" trails each bar so a big hit reads at a glance.
## It covers the whole screen and draws only where the layout says.
## Render-only: reads the sim, never changes it.

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const A11y := preload("res://game/a11y.gd")
const FightLayout := preload("res://game/fight_layout.gd")

const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const SHIELD := Color("9fd8ff")
const TRACK := Color(10 / 255.0, 8 / 255.0, 30 / 255.0, 0.9)
const CHIP := Color("fff3c4")
const LOW := Color("ff5a7a")
const LOW_SHARE := 0.35
const CHIP_DELAY := 0.35 ## Seconds the chip holds before it drains.
const CHIP_RATE := 1.4 ## Share of the bar the chip drains per second.

## Where things go: FightLayout.rects() for this screen (FightLayout.place_plates).
var layout := {}
## False draws only the clock (aiming, between relay legs): the plates' room
## below the arena holds the screen's controls then.
var plates := true:
	set(v):
		if v != plates:
			plates = v
			queue_redraw()
## Only the foe's bars (aiming: the room under the arena holds the controls).
var foe_only := false
var tags: Array = ["YOU", "FOE"]
## A team fight's power per side (viewer's first; empty: none), small in the
## arena's corners by each side's plates.
var power: Array = ["", ""]
## Under the clock: the fight's twist (Chaos Weekend rule), or the overtime damage.
var caption := ""
var center_text := ""
var _hp := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _max := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
var _shield := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _names := ["", "", "", "", "", ""]
var _chip := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
var _chip_hold := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _count := 2 ## Bars: 2, or 4 in a 2v2 (index 2 is YOU's mate, 3 the foe's), or 6 in a 3v3.
var _time := 0.0
var _live := false
## The sim side the viewer plays (a live match can put you on side 1): its
## balls fill the YOU bars on the left.
var you_side := 0


## Shows the fight `sim` (balls 0 and 1, plus 2 and 3 in a 2v2). Pass null
## to hide the bars.
func show_fight(sim, center := "") -> void:
	center_text = center
	if sim == null or sim.balls.size() < 2:
		if _live:
			_live = false
			queue_redraw()
		return
	var n: int = sim.get("starters") if sim.get("starters") != null else 2
	_count = n if n in [4, 6] and sim.balls.size() >= n else 2
	for i in _count:
		var b = sim.balls[i ^ you_side]
		var frac := clampf(b.hp / maxf(1.0, b.max_hp), 0.0, 1.0)
		# A new ball (relay, next leg) resets the chip instead of draining from the last one.
		if not _live or _names[i] != str(b.def.get("display_name", b.def.get("name", ""))) or frac > _chip[i]:
			_chip[i] = frac
		elif frac < _hp[i] / maxf(1.0, _max[i]) - 0.001:
			_chip_hold[i] = CHIP_DELAY
		_hp[i] = maxf(0.0, b.hp)
		_max[i] = maxf(1.0, b.max_hp)
		_shield[i] = maxf(0.0, b.shield)
		_names[i] = str(b.def.get("display_name", b.def.get("name", "")))
	_live = true
	queue_redraw()


func _process(delta: float) -> void:
	if not _live:
		return
	_time += delta
	for i in _count:
		var frac: float = _hp[i] / _max[i]
		if _chip_hold[i] > 0.0:
			_chip_hold[i] -= delta
		elif _chip[i] > frac:
			_chip[i] = maxf(frac, _chip[i] - CHIP_RATE * delta)
	queue_redraw()


func _draw() -> void:
	if layout.is_empty():
		return
	var arena: Rect2 = layout.arena
	var clock := Vector2(arena.get_center().x, arena.position.y)
	if not _live:
		if center_text != "":
			_text(clock, center_text, A11y.font(26), Color("f0eeff"))
		return
	if plates:
		for i in _count:
			var p := FightLayout.plate(layout, i, _count)
			if p.size.y < 60.0 or (foe_only and i % 2 == 0):
				continue
			var r := FightLayout.plate_bar(p, _count)
			_bar(i, r, mini(A11y.font(22), int(r.size.y * 0.72)), tags[i] if i < 2 and _count < 6 else "")
	_draw_clock(clock, minf(260.0, arena.size.x * 0.5))
	if plates:
		var pfs := A11y.font(18)
		for side in 2:
			if str(power[side]) == "":
				continue
			var text := "Power %s" % power[side]
			var y := arena.end.y - 14.0 if side == 0 else arena.position.y + 14.0 + pfs
			var align := HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
			var at := Vector2(arena.position.x + 14.0, y)
			draw_string_outline(FONT, at, text, align, arena.size.x - 28.0, pfs, 5, Color(0, 0, 0, 0.75))
			draw_string(FONT, at, text, align, arena.size.x - 28.0, pfs, TEAM_COLORS[side].lerp(Color.WHITE, 0.4))
	if caption != "":
		var fs := A11y.font(20)
		_text(clock + Vector2(0, fs + 24.0), caption, fs, Color("c9c3ff"))


## The clock as a pill on the arena's top edge; in overtime it turns into a
## red OVERTIME badge that pulses (steady with reduced motion).
func _draw_clock(c: Vector2, max_w: float) -> void:
	if center_text == "":
		return
	var over := center_text.begins_with("OVERTIME")
	var text := "OVERTIME" if over else center_text
	var fs := A11y.font(20) if over else A11y.font(24)
	var w := minf(max_w, FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 28.0)
	var h := fs + 14.0
	var r := Rect2(c.x - w / 2.0, c.y - h / 2.0, w, h)
	if over:
		var beat := 1.0 if A11y.reduced_motion else 0.7 + 0.3 * absf(sin(_time * PI / 0.6))
		_round(r.grow(3.0 * beat), h / 2.0 + 3.0, Color(LOW, 0.3 * beat))
		_round(r, h / 2.0, Color(LOW.darkened(0.35), 0.95))
		_round_outline(r, h / 2.0, Color(LOW.lightened(0.3), beat), 2.0)
	else:
		_round(r, h / 2.0, Color(13 / 255.0, 11 / 255.0, 38 / 255.0))
		_round_outline(r, h / 2.0, Color(1, 1, 1, 0.25), 2.0)
	_text(c, text, fs, Color.WHITE)


## One bar: the fill drains from the right, the HP number at its left end and
## the side's tag (`tag`, YOU / FOE) at its right. `ball` is a plate; its side
## is ball % 2.
func _bar(ball: int, r: Rect2, fs: int, tag := "") -> void:
	var i := ball % 2
	var col: Color = TEAM_COLORS[i]
	var frac: float = _hp[ball] / _max[ball]
	var low := frac > 0.0 and frac < LOW_SHARE
	var rad := r.size.y / 2.0
	_round(r, rad, TRACK)
	var inner := r.grow(-3.0)
	_fill(i, inner, _chip[ball], CHIP)
	_fill(i, inner, frac, LOW if low else col)
	if _shield[ball] > 0.0:
		_fill(i, inner, minf(1.0, _shield[ball] / _max[ball]), Color(SHIELD, 0.75))
	var beat := 1.0 if A11y.reduced_motion or not low else 0.6 + 0.4 * absf(sin(_time * PI / 0.85))
	if i == 0:
		_round_outline(r, rad, Color(col, beat), 2.0)
	else:
		_dashed_outline(r, Color(col, beat), 2.0)
	var text := str(ceili(_hp[ball]))
	if _shield[ball] > 0.0:
		text += " +%d" % ceili(_shield[ball])
	var base := Vector2(r.position.x + rad * 0.6 + 6.0, r.position.y + r.size.y / 2.0 + fs * 0.36)
	var room := r.size.x - rad * 1.2 - 12.0
	draw_string_outline(FONT, base, text, HORIZONTAL_ALIGNMENT_LEFT, room, fs, 5, Color(0, 0, 0, 0.75))
	draw_string(FONT, base, text, HORIZONTAL_ALIGNMENT_LEFT, room, fs, Color.WHITE)
	if tag != "":
		var tfs := mini(fs, A11y.font(18))
		draw_string_outline(FONT, base, tag, HORIZONTAL_ALIGNMENT_RIGHT, room, tfs, 5, Color(0, 0, 0, 0.75))
		draw_string(FONT, base, tag, HORIZONTAL_ALIGNMENT_RIGHT, room, tfs, Color(1, 1, 1, 0.8))


func _fill(_side: int, r: Rect2, frac: float, col: Color) -> void:
	if frac <= 0.0:
		return
	var w := r.size.x * frac
	_round(Rect2(r.position.x, r.position.y, w, r.size.y), minf(r.size.y / 2.0, w / 2.0), col)


func _text(c: Vector2, text: String, fs: int, col: Color) -> void:
	var w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var p := Vector2(c.x - w / 2.0, c.y + fs * 0.36)
	draw_string_outline(FONT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, 0.7))
	draw_string(FONT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _round(r: Rect2, rad: float, col: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = col
	box.set_corner_radius_all(int(rad))
	box.anti_aliasing = true
	draw_style_box(box, r)


func _round_outline(r: Rect2, rad: float, col: Color, w: float) -> void:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = col
	box.set_border_width_all(int(w))
	box.set_corner_radius_all(int(rad))
	box.anti_aliasing = true
	draw_style_box(box, r)


## The foe's frame: dashes along a stadium shape.
func _dashed_outline(r: Rect2, col: Color, w: float) -> void:
	var rad := r.size.y / 2.0
	var pts := PackedVector2Array()
	var left := Vector2(r.position.x + rad, r.position.y + rad)
	var right := Vector2(r.end.x - rad, r.position.y + rad)
	for k in 13:
		pts.append(right + Vector2.from_angle(-PI / 2.0 + PI * k / 12.0) * rad)
	for k in 13:
		pts.append(left + Vector2.from_angle(PI / 2.0 + PI * k / 12.0) * rad)
	pts.append(pts[0])
	var dash := 10.0
	var on := true
	var left_over := dash
	for k in pts.size() - 1:
		var a := pts[k]
		var b := pts[k + 1]
		var seg := a.distance_to(b)
		var t := 0.0
		while t < seg:
			var step := minf(left_over, seg - t)
			if on:
				draw_line(a.lerp(b, t / seg), a.lerp(b, (t + step) / seg), col, w, true)
			t += step
			left_over -= step
			if left_over <= 0.0:
				on = not on
				left_over = dash if on else dash * 0.6
