## The shop's try-on preview: your critter wearing a cosmetic, bouncing around
## a small arena and bumping a dummy, which pops after four seconds; then it
## loops. Pure animation: no sim, no rules, so it can't disagree with a fight.
extends Control

const CritterArt := preload("res://game/ui/critter_art.gd")
const CosmeticArt := preload("res://game/glow/cosmetic_art.gd")
const Catalog := preload("res://game/glow/catalog.gd")

const LOOP := 5.4
const POP_AT := 4.0
const YOU := Color("45f5a6")
const TRAIL_LEN := 22
const DUMMY_INK := Color("1a1530")

var critter_id := "vampire"
var tier := 1
var loadout := {} ## slot -> cosmetic id

var _t := 0.0
var _pos := Vector2(.3, .4)
var _vel := Vector2(.52, .37)
var _trail: Array = []
var _sparks: Array = [] ## {p, age, seed}
var _hits := 0


static func make(id: String, tier_: int, loadout_: Dictionary, height := 300.0) -> Control:
	var v = load("res://game/glow/try_on.gd").new()
	v.critter_id = id
	v.tier = tier_
	v.loadout = loadout_
	v.custom_minimum_size = Vector2(0, height)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


func _process(delta: float) -> void:
	if not is_visible_in_tree() or size.x <= 0.0:
		return
	_t += delta
	if _t >= LOOP:
		_t = 0.0
		_pos = Vector2(.3, .4)
		_vel = Vector2(.52, .37)
		_trail.clear()
		_hits += 1
	var asp := size.x / size.y
	_pos += _vel * delta
	var rr := _r_frac()
	for ax in 2:
		var lim := (asp if ax == 0 else 1.0)
		if _pos[ax] < rr:
			_pos[ax] = rr
			_vel[ax] = absf(_vel[ax])
		elif _pos[ax] > lim - rr:
			_pos[ax] = lim - rr
			_vel[ax] = -absf(_vel[ax])
	var dummy := _dummy_pos()
	if _t < POP_AT and _pos.distance_to(dummy) < rr * 2.0:
		var n := (_pos - dummy).normalized()
		_pos = dummy + n * rr * 2.0
		_vel = _vel.bounce(n)
		_sparks.append({"p": dummy + n * rr, "age": 0.0, "seed": float(_hits * 7 + _sparks.size())})
	_trail.append(_pos)
	while _trail.size() > TRAIL_LEN:
		_trail.pop_front()
	for s in _sparks:
		s.age += delta
	_sparks = _sparks.filter(func(s): return s.age < CosmeticArt.SPARK_LIFE)
	queue_redraw()


func _r_frac() -> float:
	return .12


func _dummy_pos() -> Vector2:
	return Vector2(size.x / size.y * .68, .55)


func _draw() -> void:
	var h := size.y
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("120f33"))
	for i in range(1, int(size.x / 40.0) + 1):
		draw_line(Vector2(i * 40.0, 0), Vector2(i * 40.0, h), Color(.47, .43, 1, .07), 1.0)
	for i in range(1, int(h / 40.0) + 1):
		draw_line(Vector2(0, i * 40.0), Vector2(size.x, i * 40.0), Color(.47, .43, 1, .07), 1.0)
	draw_rect(rect, Color("8f7bff"), false, 2.0)
	var r := _r_frac() * h
	var trail := Catalog.item(str(loadout.get("trail", "")))
	if not trail.is_empty():
		CosmeticArt.draw_trail(self, trail, _trail.map(func(p): return p * h), r, _t)
	# The dummy: a grey practice ball, popped by your KO effect.
	var dp := _dummy_pos() * h
	if _t < POP_AT:
		draw_circle(dp, r, Color("4a4772"))
		draw_arc(dp, r, 0, TAU, 32, Color("6d6aa0"), 3.0, true)
		draw_line(dp + Vector2(-r * .3, -r * .1), dp + Vector2(-r * .1, -r * .1), DUMMY_INK, 3.0)
		draw_line(dp + Vector2(r * .1, -r * .1), dp + Vector2(r * .3, -r * .1), DUMMY_INK, 3.0)
	else:
		var ko := Catalog.item(str(loadout.get("ko", "")))
		var k := (_t - POP_AT) / CosmeticArt.KO_LIFE
		if k < 1.0:
			if ko.is_empty():
				for i in 12:
					draw_circle(dp + Vector2.from_angle(i * TAU / 12.0) * r * (1.0 + 2.0 * k), 3.0, Color(1, 1, 1, 1.0 - k))
			else:
				CosmeticArt.draw_ko(self, ko, dp, r, k, float(_hits))
	var c := _pos * h
	var look := _vel.normalized()
	CritterArt.draw_critter(self, critter_id, c, r, {"t": _t, "tier": tier, "look": look})
	var hat := Catalog.item(str(loadout.get("hat", "")))
	if not hat.is_empty():
		CosmeticArt.draw_hat(self, hat, c, r, _t)
	var spark := Catalog.item(str(loadout.get("spark", "")))
	for s in _sparks:
		var k: float = s.age / CosmeticArt.SPARK_LIFE
		if spark.is_empty():
			draw_colored_polygon(CritterArt.star_pts(s.p * h, 8.0 + 40.0 * k, 4.0 + 18.0 * k, 8), Color(1, .89, .54, 1.0 - k))
		else:
			CosmeticArt.draw_spark(self, spark, s.p * h, k, .7, s.seed)
	# The YOU ring always goes on top, as in a real fight.
	draw_arc(c, r + 6.0, 0, TAU, 48, Color(YOU, .85), 2.5, true)
	var fs := 15
	var w := CosmeticArt.FONT.get_string_size("YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(CosmeticArt.FONT, c + Vector2(-w / 2.0, r + 24.0), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, YOU)
