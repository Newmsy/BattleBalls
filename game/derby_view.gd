## Draws a Bounce Derby race (sim/derby.gd): the course, the racers, your
## pick, cheers and a progress rail. Holds no rules: everything comes from the
## sim's state and events, and effects use their own RNG, so watching (or
## cheering) can never change a race.
extends Node2D

const Derby := preload("res://sim/derby.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Roster := preload("res://game/ui/roster.gd")
const A11y := preload("res://game/a11y.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")

## Course colours per derby theme (liveops `derbies.theme`).
const THEMES := {
	"neon": {"bg": Color("0e0c2a"), "band": Color("151244"), "peg": Color("8f7bff"), "bumper": Color("ff4fd8"), "ramp": Color("27c8ff")},
	"spooky": {"bg": Color("120a1c"), "band": Color("1d1030"), "peg": Color("ff9a3d"), "bumper": Color("9cff57"), "ramp": Color("b366ff")},
	"frost": {"bg": Color("0a1630"), "band": Color("10224a"), "peg": Color("bfe9ff"), "bumper": Color("5ce1ff"), "ramp": Color("e3f6ff")},
	"festive": {"bg": Color("0f1a14"), "band": Color("142a1e"), "peg": Color("ffd36b"), "bumper": Color("ff5a5a"), "ramp": Color("45f5a6")},
}
const PICK_COLOR := Color("45f5a6")
const FLASH_LIFE := 0.3
const POP_LIFE := 0.9
const CHEER_LIFE := 1.4

var sim: Derby
var theme_id := "neon"
var pick := -1 ## Racer index the player called, or -1.
var view_scale := 0.68
var view_size := Vector2(680, 900)
var camera_y := 0.0 ## World y at the top of the view.
var follow := "leader" ## "leader" or "pick".

var _flashes := {} ## peg index -> seconds left
var _pops: Array = [] ## [{pos (world), text, color, age}]
var _cheers: Array = [] ## [{pos (world), vel, age, kind}]
var _peg_index := {} ## Vector2 -> peg index, to flash the peg an event names.
var _rng := RandomNumberGenerator.new()
var _clock := 0.0


func _init() -> void:
	_rng.seed = 12345


func set_sim(s: Derby) -> void:
	sim = s
	_peg_index.clear()
	for i in s.pegs.size():
		_peg_index[s.pegs[i].pos] = i
	_flashes.clear()
	_pops.clear()
	_cheers.clear()
	camera_y = 0.0


func consume_events(events: Array) -> void:
	for e in events:
		match e.type:
			"peg", "bumper":
				if _peg_index.has(e.pos):
					_flashes[_peg_index[e.pos]] = FLASH_LIFE
			"trick":
				var r: Derby.Racer = sim.racers[e.racer]
				_pops.append({"pos": r.pos, "text": Derby.TRICK_NAMES[e.trick] + "!", "color": Roster.get_critter(r.id).color.lightened(0.3), "age": 0.0})
			"finish":
				var names := ["1st!", "2nd", "3rd"]
				if e.place <= 3:
					_pops.append({"pos": e.pos, "text": names[e.place - 1], "color": Color("ffd36b"), "age": 0.0})


## A cheer: hearts and stars float up from your pick (or the leader).
func cheer() -> void:
	if sim == null:
		return
	var who := pick if pick >= 0 else sim.standings()[0]
	var r: Derby.Racer = sim.racers[who]
	var n := 3 if A11y.reduced_motion else 7
	for k in n:
		_cheers.append({"pos": r.pos + Vector2(_rng.randf_range(-30, 30), -20), "vel": Vector2(_rng.randf_range(-90, 90), _rng.randf_range(-320, -180)),
			"age": 0.0, "kind": k % 2})


func advance(delta: float) -> void:
	_clock += delta
	for k in _flashes.keys():
		_flashes[k] -= delta
		if _flashes[k] <= 0.0:
			_flashes.erase(k)
	for p in _pops:
		p.age += delta
	_pops = _pops.filter(func(p): return p.age < POP_LIFE)
	for c in _cheers:
		c.age += delta
		c.pos += c.vel * delta
	_cheers = _cheers.filter(func(c): return c.age < CHEER_LIFE)
	if sim != null:
		var target_y := _focus_y() - view_size.y / view_scale * 0.4
		target_y = clampf(target_y, 0.0, maxf(0.0, sim.finish_y + 160.0 - view_size.y / view_scale))
		var ease := 1.0 if A11y.reduced_motion else minf(1.0, delta * 4.0)
		camera_y = lerpf(camera_y, target_y, ease)
	queue_redraw()


func _focus_y() -> float:
	if follow == "pick" and pick >= 0:
		return sim.racers[pick].pos.y
	# The leader still racing, so the camera stays on the action after a win.
	for i in sim.standings():
		if sim.racers[i].place == 0:
			return sim.racers[i].pos.y
	return sim.finish_y


func to_screen(world: Vector2) -> Vector2:
	return Vector2(world.x, world.y - camera_y) * view_scale


func _draw() -> void:
	if sim == null:
		return
	var th: Dictionary = THEMES.get(theme_id, THEMES.neon)
	var s := view_scale
	draw_rect(Rect2(Vector2.ZERO, view_size), th.bg)
	var top := camera_y
	var bottom := camera_y + view_size.y / s
	# Alternate section bands so the course reads as stages.
	for i in sim.sections.size():
		var sec: Dictionary = sim.sections[i]
		if sec.y1 < top or sec.y0 > bottom or i % 2 == 0:
			continue
		var a := to_screen(Vector2(0, sec.y0))
		var b := to_screen(Vector2(Derby.WIDTH, sec.y1))
		draw_rect(Rect2(a, b - a), th.band)
	# Gate and finish.
	var gate := to_screen(Vector2(0, Derby.START_Y + Derby.RADIUS + 4))
	if sim.time() < Derby.GATE_SECONDS:
		draw_line(gate, gate + Vector2(view_size.x, 0), Color(th.ramp, 0.8), 4.0)
	var fy := to_screen(Vector2(0, sim.finish_y)).y
	if fy < view_size.y + 20:
		var sq := 20.0
		for k in int(view_size.x / sq) + 1:
			for row in 2:
				var col := Color.WHITE if (k + row) % 2 == 0 else Color("1a1530")
				draw_rect(Rect2(k * sq, fy + row * sq, sq, sq), col)
		draw_string(FONT, Vector2(12, fy - 12), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(26), Color.WHITE)
	# Ramps and pegs.
	for rp in sim.ramps:
		if maxf(rp.a.y, rp.b.y) < top - 20 or minf(rp.a.y, rp.b.y) > bottom + 20:
			continue
		draw_line(to_screen(rp.a), to_screen(rp.b), Color(th.ramp, 0.35), (Derby.RAMP_THICK * 2 + 10) * s)
		draw_line(to_screen(rp.a), to_screen(rp.b), th.ramp, Derby.RAMP_THICK * 2 * s)
	for i in sim.pegs.size():
		var p: Dictionary = sim.pegs[i]
		if p.pos.y < top - 60 or p.pos.y > bottom + 60:
			continue
		var c: Color = th.bumper if p.bumper else th.peg
		var flash: float = _flashes.get(i, 0.0) / FLASH_LIFE
		var at := to_screen(p.pos)
		if p.bumper:
			draw_circle(at, (p.r + 10.0 * flash) * s, Color(c, 0.25 + 0.4 * flash))
			draw_arc(at, p.r * s, 0, TAU, 28, c, 5.0 * s)
			draw_circle(at, p.r * 0.45 * s, c)
		else:
			draw_circle(at, (p.r + 6.0) * s, Color(c, 0.18 + 0.5 * flash))
			draw_circle(at, p.r * s, c.lerp(Color.WHITE, flash))
	# Racers, your pick last so it sits on top.
	var draw_order := range(sim.racers.size())
	if pick >= 0:
		draw_order.erase(pick)
		draw_order.append(pick)
	for i in draw_order:
		var r: Derby.Racer = sim.racers[i]
		var at := to_screen(r.pos)
		if at.y < -60 or at.y > view_size.y + 60:
			continue
		var rad := Derby.RADIUS * s
		if r.phase > 0.0:
			modulate_racer(at, rad, r, 0.45)
		else:
			modulate_racer(at, rad, r, 1.0)
		if i == pick:
			# A solid ring plus the word, never colour alone.
			draw_arc(at, rad + 6, 0, TAU, 32, PICK_COLOR, 4.0)
			draw_string(FONT, at + Vector2(-40, -rad - 12), "PICK", HORIZONTAL_ALIGNMENT_CENTER, 80, A11y.font(20), PICK_COLOR)
	for p in _pops:
		var at := to_screen(p.pos) + Vector2(0, -50 - 40 * p.age / POP_LIFE)
		draw_string(FONT, at - Vector2(60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, A11y.font(24), Color(p.color, 1.0 - p.age / POP_LIFE))
	for c in _cheers:
		var at := to_screen(c.pos)
		var a: float = 1.0 - c.age / CHEER_LIFE
		if c.kind == 0:
			_heart(at, 11.0, Color(1.0, 0.36, 0.6, a))
		else:
			draw_colored_polygon(CritterArt.star_pts(at, 12.0, 5.0, 5), Color(1.0, 0.85, 0.35, a))
	_draw_rail()


func modulate_racer(at: Vector2, rad: float, r: Derby.Racer, alpha: float) -> void:
	var look := r.vel.normalized() if r.vel.length() > 20.0 else Vector2.DOWN
	CritterArt.draw_critter(self, r.id, at, rad, {"t": _clock, "look": look})
	if alpha < 1.0:
		# Phasing: washed out, with a ghostly halo.
		var bg: Color = THEMES.get(theme_id, THEMES.neon).bg
		draw_circle(at, rad * 1.08, Color(bg, 1.0 - alpha))
		draw_arc(at, rad * 1.15, 0, TAU, 24, Color(0.9, 0.85, 1.0, 0.6), 2.0)


func _heart(at: Vector2, size: float, col: Color) -> void:
	draw_circle(at + Vector2(-size * 0.5, 0), size * 0.55, col)
	draw_circle(at + Vector2(size * 0.5, 0), size * 0.55, col)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-size * 1.05, size * 0.15), at + Vector2(size * 1.05, size * 0.15), at + Vector2(0, size * 1.2)]), col)


## The whole course as a thin rail on the right: where everyone is.
func _draw_rail() -> void:
	var x := view_size.x - 18.0
	var y0 := 20.0
	var y1 := view_size.y - 20.0
	draw_line(Vector2(x, y0), Vector2(x, y1), Color(1, 1, 1, 0.25), 6.0)
	draw_rect(Rect2(x - 10, y1 - 3, 20, 6), Color.WHITE)
	for i in sim.racers.size():
		var r: Derby.Racer = sim.racers[i]
		var y := lerpf(y0, y1, sim.progress(r))
		var col: Color = Roster.get_critter(r.id).color
		draw_circle(Vector2(x, y), 9.0 if i == pick else 6.0, col.lightened(0.2))
		if i == pick:
			draw_arc(Vector2(x, y), 12.0, 0, TAU, 16, PICK_COLOR, 3.0)
