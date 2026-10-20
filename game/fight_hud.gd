extends Control
## Health bars for both sides, drawn above the arena so the critters
## themselves stay uncluttered. YOU on the left (solid frame), FOE on the
## right (dashed frame): shape as well as colour tells the sides apart.
## A pale "chip" trails each bar so a big hit reads at a glance.
## In a 2v2 each side gets two thinner bars, one per critter, under its tag.
## Render-only: reads the sim, never changes it.

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const A11y := preload("res://game/a11y.gd")

const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const SHIELD := Color("9fd8ff")
const TRACK := Color(10 / 255.0, 8 / 255.0, 30 / 255.0, 0.9)
const CHIP := Color("fff3c4")
const LOW := Color("ff5a7a")
const LOW_SHARE := 0.35
const CHIP_DELAY := 0.35 ## Seconds the chip holds before it drains.
const CHIP_RATE := 1.4 ## Share of the bar the chip drains per second.
const CENTER_W := 0.22 ## Share of the width kept for the clock between the bars.

var tags: Array = ["YOU", "FOE"]
## A small line under each 1v1 bar, like "T5 · Lv25 · 5,481 power" (empty: none).
var stats: Array = ["", ""]
var center_text := ""
var _hp := [0.0, 0.0, 0.0, 0.0]
var _max := [1.0, 1.0, 1.0, 1.0]
var _shield := [0.0, 0.0, 0.0, 0.0]
var _names := ["", "", "", ""]
var _chip := [1.0, 1.0, 1.0, 1.0]
var _chip_hold := [0.0, 0.0, 0.0, 0.0]
var _count := 2 ## Bars: 2, or 4 in a 2v2 (index 2 is YOU's mate, 3 the foe's).
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
	_count = 4 if sim.get("starters") == 4 and sim.balls.size() >= 4 else 2
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
	if not _live:
		if center_text != "":
			_text(Vector2(size.x / 2.0, size.y * 0.62), center_text, A11y.font(26), Color("f0eeff"))
		return
	if _count == 4:
		_draw_teams()
		return
	var fs := A11y.font(20)
	var gap := size.x * CENTER_W
	var bar_w := (size.x - gap) / 2.0
	var sfs := A11y.font(15)
	var stats_h := sfs + 6.0 if stats[0] != "" or stats[1] != "" else 0.0
	var bar_h := maxf(20.0, minf(size.y * 0.4, 25.0))
	var bar_y := size.y - bar_h - 4.0 - stats_h
	for i in 2:
		var x := 0.0 if i == 0 else size.x - bar_w
		_bar(i, Rect2(x, bar_y, bar_w, bar_h), fs)
		var label := "%s · %s" % [tags[i], _names[i]] if i == 0 else "%s · %s" % [_names[i], tags[i]]
		var align := HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		draw_string_outline(FONT, Vector2(x, bar_y - 8.0), label, align, bar_w, fs, 4, Color(0, 0, 0, 0.6))
		draw_string(FONT, Vector2(x, bar_y - 8.0), label, align, bar_w, fs, TEAM_COLORS[i])
		if stats_h > 0.0 and stats[i] != "":
			draw_string(FONT, Vector2(x, bar_y + bar_h + sfs + 2.0), stats[i], align, bar_w, sfs, Color(TEAM_COLORS[i].lerp(Color("f0eeff"), 0.55), 0.85))
	if center_text != "":
		var col := LOW if center_text.begins_with("OVERTIME") else Color("f0eeff")
		var text := center_text.replace("OVERTIME ", "OT ") # The arena banner says OVERTIME in full.
		var cfs := A11y.font(22) if text.length() <= 5 else A11y.font(16)
		_text(Vector2(size.x / 2.0, bar_y + bar_h / 2.0), text, cfs, col)


## 2v2: each side's tag, then its two critters' bars stacked under it, each
## bar carrying the critter's name and HP inside.
func _draw_teams() -> void:
	var gap := size.x * CENTER_W
	var bar_w := (size.x - gap) / 2.0
	var tag_h := A11y.font(18) + 4.0
	var bar_h := maxf(16.0, (size.y - tag_h - 8.0) / 2.0)
	var fs := mini(A11y.font(18), int(bar_h * 0.62))
	for side in 2:
		var x := 0.0 if side == 0 else size.x - bar_w
		var align := HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		draw_string_outline(FONT, Vector2(x, tag_h - 4.0), tags[side], align, bar_w, A11y.font(18), 4, Color(0, 0, 0, 0.6))
		draw_string(FONT, Vector2(x, tag_h - 4.0), tags[side], align, bar_w, A11y.font(18), TEAM_COLORS[side])
		for k in 2:
			var i := side + 2 * k
			_bar(i, Rect2(x, tag_h + 4.0 + k * (bar_h + 4.0), bar_w, bar_h), fs, _names[i] + "  ")
	if center_text != "":
		var col := LOW if center_text.begins_with("OVERTIME") else Color("f0eeff")
		var text := center_text.replace("OVERTIME ", "OT ")
		var cfs := A11y.font(22) if text.length() <= 5 else A11y.font(16)
		_text(Vector2(size.x / 2.0, size.y * 0.6), text, cfs, col)


## One bar: the fill drains toward the arena centre (YOU from the right end,
## FOE from the left), like a fighting game. `i` is a ball; its side is i % 2.
## `prefix` (2v2) puts the critter's name before the HP inside the bar.
func _bar(ball: int, r: Rect2, fs: int, prefix := "") -> void:
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
	var text := prefix + str(ceili(_hp[ball]))
	if _shield[ball] > 0.0:
		text += " +%d" % ceili(_shield[ball])
	var align := HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	var base := Vector2(r.position.x + rad + 6.0, r.position.y + r.size.y / 2.0 + fs * 0.36)
	draw_string_outline(FONT, base, text, align, r.size.x - rad * 2.0 - 12.0, fs, 5, Color(0, 0, 0, 0.75))
	draw_string(FONT, base, text, align, r.size.x - rad * 2.0 - 12.0, fs, Color.WHITE)


func _fill(i: int, r: Rect2, frac: float, col: Color) -> void:
	if frac <= 0.0:
		return
	var w := r.size.x * frac
	var x := r.position.x + (r.size.x - w if i == 0 else 0.0)
	_round(Rect2(x, r.position.y, w, r.size.y), minf(r.size.y / 2.0, w / 2.0), col)


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
