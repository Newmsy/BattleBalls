## Draws a Critter Plunge race (sim/plunge.gd): the course, the racers with
## their HP rings, what their race verbs do, and the standings strip along
## the top. Holds no rules: everything comes from the sim's state and events,
## and effects use their own clock, so watching can never change a race.
## Cheap on purpose (battery): flat shapes only, nothing off screen is drawn,
## and every effect is a short-lived ring, line or pop.
extends Node2D

const Plunge := preload("res://sim/plunge.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Roster := preload("res://game/ui/roster.gd")
const A11y := preload("res://game/a11y.gd")
const Kit := preload("res://game/ui/ui_kit.gd")

const BG := Color("0e0c2a")
const BAND := Color("151244")
const PEG := Color("8f7bff")
const BUMPER := Color("ff4fd8")
const RAMP := Color("27c8ff")
const YOU := Color("45f5a6")
const HURT := Color("ff5a7a")
const VERB_COLORS := {"pulse": Color("ffd36b"), "shot": Color("5ce1ff"), "drop": Color("ff8a3d"), "ram": Color("ff5a7a"),
	"hook": Color("b366ff"), "shield": Color("8fd8ff"), "thorns": Color("45f5a6"), "drain": Color("ff4f8f")}
const FLASH_LIFE := 0.3
const POP_LIFE := 0.9
const RING_LIFE := 0.45
const HIT_LIFE := 0.35
const STRIP_H := 92.0 ## The standings strip at the top of the view.

var sim: Plunge
var you := 0 ## Your racer's index (-1 in a race you only watch).
var view_scale := 0.68
var view_size := Vector2(680, 900)
var camera_y := 0.0 ## World y at the top of the course view.

var _flashes := {} ## peg index -> seconds left
var _pops: Array = [] ## [{pos (world), text, color, age}]
var _rings: Array = [] ## Pulses: [{pos, radius, color, age}]
var _lines: Array = [] ## Hooks: [{a, b (racer indexes), age}]
var _hits := {} ## racer index -> seconds of hit flash left
var _peg_index := {} ## Vector2 -> peg index, to flash the peg an event names.
var _clock := 0.0


func set_sim(s: Plunge, your_index := 0) -> void:
	sim = s
	you = your_index
	_peg_index.clear()
	for i in s.pegs.size():
		_peg_index[s.pegs[i].pos] = i
	_flashes.clear()
	_pops.clear()
	_rings.clear()
	_lines.clear()
	_hits.clear()
	camera_y = 0.0


func consume_events(events: Array) -> void:
	for e in events:
		match e.type:
			"peg", "bumper":
				if _peg_index.has(e.pos):
					_flashes[_peg_index[e.pos]] = FLASH_LIFE
			"fire":
				match e.verb:
					"pulse":
						_rings.append({"pos": e.pos, "radius": e.radius, "color": VERB_COLORS.pulse, "age": 0.0})
					"hook":
						_lines.append({"a": e.racer, "b": e.target, "age": 0.0})
			"hit":
				_hits[e.racer] = HIT_LIFE
				if e.kind != "bump" or e.amount >= 6.0:
					_pops.append({"pos": e.pos, "text": "-%d" % ceili(e.amount), "color": HURT, "age": 0.0, "size": 20})
			"ko":
				_pops.append({"pos": e.pos, "text": "KO!", "color": HURT, "age": 0.0, "size": 30})
			"finish":
				var names := ["1st!", "2nd", "3rd"]
				if e.place <= 3:
					_pops.append({"pos": e.pos, "text": names[e.place - 1], "color": Color("ffd36b"), "age": 0.0, "size": 26})


func advance(delta: float) -> void:
	_clock += delta
	for k in _flashes.keys():
		_flashes[k] -= delta
		if _flashes[k] <= 0.0:
			_flashes.erase(k)
	for k in _hits.keys():
		_hits[k] -= delta
		if _hits[k] <= 0.0:
			_hits.erase(k)
	for list in [_pops, _rings, _lines]:
		for p in list:
			p.age += delta
	_pops = _pops.filter(func(p): return p.age < POP_LIFE)
	_rings = _rings.filter(func(p): return p.age < RING_LIFE)
	_lines = _lines.filter(func(p): return p.age < RING_LIFE)
	if sim != null:
		var course_h := (view_size.y - STRIP_H) / view_scale
		var target_y := _focus_y() - course_h * 0.4
		target_y = clampf(target_y, 0.0, maxf(0.0, sim.finish_y + 160.0 - course_h))
		var ease := 1.0 if A11y.reduced_motion else minf(1.0, delta * 4.0)
		camera_y = lerpf(camera_y, target_y, ease)
	queue_redraw()


## The camera follows the leader still racing, so it stays on the action
## after a win.
func _focus_y() -> float:
	for i in sim.standings():
		if sim.racers[i].racing():
			return sim.racers[i].pos.y
	return sim.finish_y


func to_screen(world: Vector2) -> Vector2:
	return Vector2(world.x * view_scale, STRIP_H + (world.y - camera_y) * view_scale)


func _draw() -> void:
	if sim == null:
		return
	var s := view_scale
	draw_rect(Rect2(Vector2.ZERO, view_size), BG)
	var top := camera_y
	var bottom := camera_y + (view_size.y - STRIP_H) / s
	for i in sim.sections.size():
		var sec: Dictionary = sim.sections[i]
		if sec.y1 < top or sec.y0 > bottom or i % 2 == 0:
			continue
		var a := to_screen(Vector2(0, sec.y0))
		var b := to_screen(Vector2(Plunge.WIDTH, sec.y1))
		draw_rect(Rect2(a, b - a), BAND)
	if sim.time() < Plunge.GATE_SECONDS:
		var gate := to_screen(Vector2(0, Plunge.START_Y + Plunge.RADIUS + 4))
		draw_line(gate, gate + Vector2(view_size.x, 0), Color(RAMP, 0.8), 4.0)
	var fy := to_screen(Vector2(0, sim.finish_y)).y
	if fy < view_size.y + 20:
		var sq := 20.0
		for k in int(view_size.x / sq) + 1:
			for row in 2:
				draw_rect(Rect2(k * sq, fy + row * sq, sq, sq), Color.WHITE if (k + row) % 2 == 0 else Color("1a1530"))
		draw_string(Kit.FONT, Vector2(12, fy - 12), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(26), Color.WHITE)
	for rp in sim.ramps:
		if maxf(rp.a.y, rp.b.y) < top - 20 or minf(rp.a.y, rp.b.y) > bottom + 20:
			continue
		draw_line(to_screen(rp.a), to_screen(rp.b), Color(RAMP, 0.35), (Plunge.RAMP_THICK * 2 + 10) * s)
		draw_line(to_screen(rp.a), to_screen(rp.b), RAMP, Plunge.RAMP_THICK * 2 * s)
	for i in sim.pegs.size():
		var p: Dictionary = sim.pegs[i]
		if p.pos.y < top - 60 or p.pos.y > bottom + 60:
			continue
		var flash: float = _flashes.get(i, 0.0) / FLASH_LIFE
		var at := to_screen(p.pos)
		if p.bumper:
			draw_circle(at, (p.r + 10.0 * flash) * s, Color(BUMPER, 0.25 + 0.4 * flash))
			draw_arc(at, p.r * s, 0, TAU, 28, BUMPER, 5.0 * s)
			draw_circle(at, p.r * 0.45 * s, BUMPER)
		else:
			draw_circle(at, (p.r + 6.0) * s, Color(PEG, 0.18 + 0.5 * flash))
			draw_circle(at, p.r * s, PEG.lerp(Color.WHITE, flash))
	for m in sim.mines:
		var at := to_screen(m.pos)
		if at.y > STRIP_H - 20 and at.y < view_size.y + 20:
			var blink := 0.6 + 0.4 * absf(sin(_clock * 6.0))
			draw_circle(at, 13.0 * s, Color(VERB_COLORS.drop, 0.3))
			draw_circle(at, 8.0 * s, Color(VERB_COLORS.drop, blink))
	for sh in sim.shots:
		var at := to_screen(sh.pos)
		var tail := to_screen(sh.pos - sh.vel * 0.05)
		draw_line(tail, at, Color(VERB_COLORS.shot, 0.5), 6.0 * s)
		draw_circle(at, 8.0 * s, VERB_COLORS.shot)
	for r in _rings:
		var k: float = r.age / RING_LIFE
		draw_arc(to_screen(r.pos), (r.radius * (0.4 + 0.6 * k)) * s, 0, TAU, 40, Color(r.color, 0.8 * (1.0 - k)), 6.0)
	for l in _lines:
		var a: Plunge.Racer = sim.racers[l.a]
		var b: Plunge.Racer = sim.racers[l.b]
		draw_line(to_screen(a.pos), to_screen(b.pos), Color(VERB_COLORS.hook, 0.8 * (1.0 - l.age / RING_LIFE)), 5.0)
	# Racers, yours last so it sits on top.
	var draw_order := range(sim.racers.size())
	if you >= 0:
		draw_order.erase(you)
		draw_order.append(you)
	for i in draw_order:
		var r: Plunge.Racer = sim.racers[i]
		if r.ko_tick >= 0:
			continue
		var at := to_screen(r.pos)
		if at.y < STRIP_H - 60 or at.y > view_size.y + 60:
			continue
		_draw_racer(i, at, Plunge.RADIUS * s)
	for p in _pops:
		var at := to_screen(p.pos) + Vector2(0, -40 - 40 * p.age / POP_LIFE)
		if at.y > STRIP_H:
			draw_string(Kit.FONT, at - Vector2(60, 0), p.text, HORIZONTAL_ALIGNMENT_CENTER, 120, A11y.font(p.size), Color(p.color, 1.0 - p.age / POP_LIFE))
	_draw_strip()


func _draw_racer(i: int, at: Vector2, rad: float) -> void:
	var r: Plunge.Racer = sim.racers[i]
	var look := r.vel.normalized() if r.vel.length() > 20.0 else Vector2.DOWN
	CritterArt.draw_critter(self, r.id, at, rad, {"t": _clock, "look": look, "hit": _hits.get(i, 0.0) / HIT_LIFE * 0.5})
	# HP as a ring round the racer: always on, so damage reads at a glance.
	var frac := clampf(r.hp / r.max_hp, 0.0, 1.0)
	draw_arc(at, rad + 5.0, 0, TAU, 32, Color(0, 0, 0, 0.45), 4.0)
	draw_arc(at, rad + 5.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 32, YOU if frac > 0.5 else (Color("ffd36b") if frac > 0.25 else HURT), 4.0)
	if r.shield > 0.0:
		draw_circle(at, rad + 12.0, Color(VERB_COLORS.shield, 0.18))
		draw_arc(at, rad + 12.0, 0, TAU, 32, Color(VERB_COLORS.shield, 0.8), 3.0)
	if i == you:
		# A solid ring plus the word, never colour alone.
		draw_arc(at, rad + 11.0, 0, TAU, 32, YOU, 3.0)
		draw_string(Kit.FONT, at + Vector2(-40, -rad - 16), "YOU", HORIZONTAL_ALIGNMENT_CENTER, 80, A11y.font(20), YOU)


## The standings along the top: every racer's face in race order with its
## place and an HP bar; knocked out racers are greyed with a cross.
func _draw_strip() -> void:
	draw_rect(Rect2(0, 0, view_size.x, STRIP_H), Color(BG, 0.94))
	draw_line(Vector2(0, STRIP_H), Vector2(view_size.x, STRIP_H), Color(PEG, 0.5), 2.0)
	var order := sim.standings()
	var n := order.size()
	var cell := view_size.x / n
	var face := minf(24.0, cell * 0.3)
	for k in n:
		var r: Plunge.Racer = sim.racers[order[k]]
		var cx := cell * (k + 0.5)
		var at := Vector2(cx, 38)
		var out := r.ko_tick >= 0
		CritterArt.draw_critter(self, r.id, at, face, {"t": _clock, "look": Vector2.DOWN, "grey": out, "ko": out})
		if order[k] == you:
			draw_arc(at, face + 4.0, 0, TAU, 28, YOU, 3.0)
		draw_string(Kit.FONT, Vector2(cx - cell / 2.0 + 4, 22), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(16), Kit.MUTED)
		var bar := Rect2(cx - cell * 0.36, 70, cell * 0.72, 7)
		draw_rect(bar, Color(0, 0, 0, 0.5))
		var frac := clampf(r.hp / r.max_hp, 0.0, 1.0)
		if not out:
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), YOU if order[k] == you else Color("cfc8ff"))
		else:
			draw_string(Kit.FONT, Vector2(cx - 30, 84), "OUT", HORIZONTAL_ALIGNMENT_CENTER, 60, A11y.font(14), HURT)
