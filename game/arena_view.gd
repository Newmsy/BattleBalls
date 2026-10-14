## Draws a MatchSim in the Neon Critters style (design/critters.md). Holds no
## game rules: everything it shows comes from the sim's state and the events
## of each step. Effects use their own RNG and never feed back into the sim.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Roster := preload("res://game/ui/roster.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")

const INK := Color("1a1530")
const ARENA_FILL := Color("120f33")
const GRID := Color(120 / 255.0, 110 / 255.0, 1.0, 0.08)
const BORDER := Color("8f7bff")
const OVERTIME_BORDER := Color("ff5a7a")
const BEAM := Color("27c8ff")
const BURST := Color("ffe28a")
const POP_DAMAGE := Color("ff5a7a")
const POP_HEAL := Color("45f5a6")
const POP_BEAM := Color("7cc4ff")
const RARITY_COLORS := Roster.RARITY_COLORS
## Side markers so mirror matches stay readable: index 0 is always the player.
const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const TEAM_TAGS := ["YOU", "FOE"]

const POPUP_LIFE := 0.9
const HIT_LIFE := 0.35
const BURST_LIFE := 0.35
const BLINK_PERIOD := 4.3

var sim: MatchSim
var team_tags: Array = TEAM_TAGS ## Labels under each ball; a shared replay uses P1/P2.
var view_scale := 0.68
## Launch aim preview for the player's ball (world direction), or ZERO to hide.
var aim_dir := Vector2.ZERO
## Ball types to show before a sim exists (menu preview).
var preview_types: Array = ["vampire", "laser"]
## Tier of each ball (stars on the badge, how big its feature grows).
var tiers: Array = [1, 1]

var _time := 0.0
var _shake := 0.0
var _popups: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _bursts: Array[Dictionary] = []
var _wisps: Array[Dictionary] = []
var _look: Array[Vector2] = [Vector2(1, -1).normalized(), Vector2(-1, 1).normalized()]
var _hit := [0.0, 0.0]
var _squash := [0.0, 0.0]
var _eye_flash := [0.0, 0.0]
var _fx_rng := RandomNumberGenerator.new()


func to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - global_position) / view_scale


func clear_effects() -> void:
	_popups.clear()
	_particles.clear()
	_bursts.clear()
	_wisps.clear()
	_shake = 0.0
	_hit = [0.0, 0.0]
	_squash = [0.0, 0.0]
	_eye_flash = [0.0, 0.0]
	if sim:
		for b in sim.balls:
			_look[b.index] = b.vel.normalized()


## Turns the events of the latest sim step into visual effects.
func consume_events(events: Array[Dictionary]) -> void:
	for e in events:
		match e.type:
			"damage":
				_hit[e.target] = HIT_LIFE
				var col := POP_DAMAGE if e.kind == "contact" else POP_BEAM
				var t := sim.balls[e.target]
				_add_popup(t.pos + Vector2(28, -t.radius - 10), "-%d" % ceili(e.amount), col)
			"heal":
				var b := sim.balls[e.target]
				_add_popup(b.pos + Vector2(48, -b.radius - 40), "+%d" % ceili(e.amount), POP_HEAL)
				var victim := sim.balls[1 - e.target]
				for i in 8:
					_wisps.append({"from": victim.pos + _rand_dir() * victim.radius * 0.5, "to": e.target, "age": -i * 0.03, "life": 0.45})
			"collide":
				_squash[e.a] = 0.2
				_squash[e.b] = 0.2
				_shake = maxf(_shake, 5.0)
				_bursts.append({"pos": e.pos, "age": 0.0})
				_spawn_particles(e.pos, 10)
			"bounce":
				_squash[e.ball] = maxf(_squash[e.ball], 0.15)
				_eye_flash[e.ball] = 0.3
			"end":
				for b in sim.balls:
					if not b.alive():
						_spawn_particles(b.pos, 36)
						_shake = 10.0


func advance_effects(delta: float) -> void:
	_time += delta
	_shake = maxf(0.0, _shake - delta * 30.0)
	for i in 2:
		_hit[i] = maxf(0.0, _hit[i] - delta)
		_squash[i] = maxf(0.0, _squash[i] - delta)
		_eye_flash[i] = maxf(0.0, _eye_flash[i] - delta)
	if sim:
		for b in sim.balls:
			if b.vel.length() > 0.001:
				_look[b.index] = _look[b.index].lerp(b.vel.normalized(), clampf(delta * 9.0, 0.0, 1.0)).normalized()
	for p in _popups:
		p.age += delta
	_popups = _popups.filter(func(p): return p.age < POPUP_LIFE)
	for p in _particles:
		p.age += delta
		p.pos += p.vel * delta
		p.vel *= pow(0.96, delta * 60.0)
	_particles = _particles.filter(func(p): return p.age < p.life)
	for k in _bursts:
		k.age += delta
	_bursts = _bursts.filter(func(k): return k.age < BURST_LIFE)
	for w in _wisps:
		w.age += delta
	_wisps = _wisps.filter(func(w): return w.age < w.life)
	queue_redraw()


func _add_popup(pos: Vector2, text: String, color: Color) -> void:
	_popups.append({"pos": pos, "text": text, "color": color, "age": 0.0})


func _spawn_particles(pos: Vector2, count: int) -> void:
	for i in count:
		_particles.append({"pos": pos, "vel": _rand_dir() * _fx_rng.randf_range(120.0, 460.0), "age": 0.0, "life": _fx_rng.randf_range(0.5, 1.1)})


func _rand_dir() -> Vector2:
	return Vector2.from_angle(_fx_rng.randf() * TAU)


# --- Drawing ----------------------------------------------------------------

func _draw() -> void:
	var s := view_scale
	var shake := Vector2(_fx_rng.randf_range(-1, 1), _fx_rng.randf_range(-1, 1)) * _shake if _shake > 0.0 else Vector2.ZERO
	draw_set_transform(shake)
	var full := Rect2(Vector2.ZERO, Vector2.ONE * MatchSim.ARENA_SIZE * s)
	var arena := full
	var overtime := false
	if sim:
		var r := sim.arena_rect()
		arena = Rect2(r.position * s, r.size * s)
		overtime = sim.in_overtime()
	if overtime:
		_rounded_rect(full, 14.0, Color(0.35, 0.05, 0.12, 0.35))
	_rounded_rect(arena, 14.0, ARENA_FILL)
	_draw_grid(arena)
	var border := OVERTIME_BORDER if overtime else BORDER
	for i in 4:
		_rounded_rect_outline(arena.grow(i * 2.0), 14.0 + i * 2.0, Color(border, 0.22 - i * 0.05), 4.0)
	_rounded_rect_outline(arena, 14.0, border, 2.5)

	if sim == null:
		for i in 2:
			var def := BallDefs.get_def(preview_types[i])
			_draw_critter(i, def, MatchSim.START_CORNERS[i] * s, def.radius * s, def.hp, def.hp, shake)
		return

	for beam in sim.beams:
		var k := beam.strength()
		var a: Vector2 = beam.a * s
		var b: Vector2 = beam.b * s
		draw_line(a, b, Color(BEAM, 0.18 * k), 14.0, true)
		draw_line(a, b, Color(BEAM, 0.35 * k), 7.0, true)
		draw_line(a, b, Color(BEAM, 0.9 * k), 3.5, true)
		draw_line(a, b, Color("e6f7ff", k), 1.4, true)

	for k in _bursts:
		var t: float = k.age / BURST_LIFE
		_star(k.pos * s, 10.0 + t * 70.0, 5.0 + t * 30.0, 8, Color(BURST, 1.0 - t))

	if aim_dir != Vector2.ZERO:
		var b := sim.balls[0]
		for i in 12:
			draw_circle(b.pos * s + aim_dir * (b.radius + 40.0 + i * 38.0) * s, 5.0, Color(TEAM_COLORS[0], 1.0 - i / 12.0))

	for w in _wisps:
		if w.age < 0.0:
			continue
		var t: float = w.age / w.life
		var target: Vector2 = sim.balls[w.to].pos
		var p: Vector2 = w.from.lerp(target, t * t)
		draw_circle(p * s, 6.0 * (1.0 - t) + 2.0, Color(1.0, 0.2, 0.35, 0.8 * (1.0 - t)))

	for b in sim.balls:
		if b.alive():
			_draw_critter(b.index, b.def, b.pos * s, b.radius * s, b.hp, b.max_hp, shake)

	for p in _particles:
		var a: float = 1.0 - p.age / p.life
		draw_circle(p.pos * s, 4.0, Color(1, 1, 1, a * 0.3))
		draw_circle(p.pos * s, 2.0, Color(1, 1, 1, a))

	for p in _popups:
		var t: float = p.age / POPUP_LIFE
		var pos: Vector2 = p.pos * s + Vector2(0, -40.0 * t)
		_text_centered(pos, p.text, 26, Color(p.color, 1.0 - t * t), 6)


func _draw_grid(r: Rect2) -> void:
	var step := 80.0 * view_scale
	var x := r.position.x + step
	while x < r.end.x - 1.0:
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), GRID, 1.0)
		x += step
	var y := r.position.y + step
	while y < r.end.y - 1.0:
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), GRID, 1.0)
		y += step


## One critter at `pos` (screen space) with radius `r`. Squash, wince, blink
## and eye direction come from the per-ball effect state.
func _draw_critter(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2) -> void:
	var look: Vector2 = _look[i]
	var team_col: Color = TEAM_COLORS[i]
	# Team ring and tag sit outside the squash so they stay steady.
	draw_set_transform(shake)
	draw_arc(pos, r + 9.0, 0, TAU, 64, Color(team_col, 0.18), 9.0, true)
	draw_arc(pos, r + 7.0, 0, TAU, 64, Color(team_col, 0.85), 2.5, true)
	_text_centered(pos + Vector2(0, r + 26.0), team_tags[i], 17, team_col, 4)

	var ang := look.angle()
	var sq: float = _squash[i] * 1.6
	var squash := Transform2D(Vector2(1.0 - sq * 0.6, 0), Vector2(0, 1.0 + sq * 0.5), Vector2.ZERO)
	draw_set_transform_matrix(Transform2D(0, pos + shake) * Transform2D(ang, Vector2.ZERO) * squash * Transform2D(-ang, Vector2.ZERO))

	draw_circle(Vector2(r * 0.08, r * 0.14), r, Color(0, 0, 0, 0.35))
	var phase := fmod(_time + i * 1.7, BLINK_PERIOD)
	var blink := sin(phase / 0.12 * PI) if phase < 0.12 else 0.0
	CritterArt.draw_critter(self, def.id, Vector2.ZERO, r, {"t": _time, "tier": tiers[i], "look": look, "blink": blink,
		"hit": _hit[i], "eye_flash": _eye_flash[i], "hp_frac": hp / max_hp})

	draw_set_transform(shake)
	_hp_badge(def, pos, r, hp)


func _hp_badge(def: Dictionary, pos: Vector2, r: float, hp: float) -> void:
	var rarity: String = def.get("rarity", "common")
	var rim: Color = RARITY_COLORS[rarity]
	var top: float = def.get("badge_top", 1.15) * r
	var fs := maxi(14, roundi(r * 0.42))
	var text := str(maxi(0, ceili(hp)))
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tier := 1
	var star_w := fs * 0.62
	var w := fs * 0.55 + tw + fs * 0.35 + tier * star_w + fs * 0.45
	var h := fs * 1.45
	var rect := Rect2(pos.x - w / 2.0, pos.y - top - h - 4.0, w, h)
	if rarity != "common":
		_rounded_rect(rect.grow(3.0), h / 2.0 + 3.0, Color(rim, 0.25))
	_rounded_rect(rect, h / 2.0, Color(10 / 255.0, 8 / 255.0, 30 / 255.0, 0.88))
	_rounded_rect_outline(rect, h / 2.0, rim, 1.0 if rarity == "common" else 2.0)
	draw_string(FONT, Vector2(rect.position.x + fs * 0.55, rect.position.y + h / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	for k in tier:
		_star(Vector2(rect.position.x + fs * 0.9 + tw + star_w * 0.5 + k * star_w, rect.position.y + h / 2.0), fs * 0.3, fs * 0.13, 5, rim)


# --- Shape helpers ------------------------------------------------------------

func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _star(c: Vector2, r_out: float, r_in: float, points: int, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in points * 2:
		var rr := r_in if k % 2 == 1 else r_out
		var a := k * PI / points - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)


func _rounded_rect_points(r: Rect2, radius: float) -> PackedVector2Array:
	var rad := minf(radius, minf(r.size.x, r.size.y) / 2.0)
	var pts := PackedVector2Array()
	var corners := [
		[r.end - Vector2(rad, rad), 0.0], [Vector2(r.position.x + rad, r.end.y - rad), PI / 2.0],
		[r.position + Vector2(rad, rad), PI], [Vector2(r.end.x - rad, r.position.y + rad), PI * 1.5]]
	for c in corners:
		for k in 7:
			var a: float = c[1] + (PI / 2.0) * k / 6.0
			var q: Vector2 = c[0] + Vector2(cos(a), sin(a)) * rad
			# Pills have zero-length straight edges; duplicate points break triangulation.
			if pts.is_empty() or pts[pts.size() - 1].distance_to(q) > 0.01:
				pts.append(q)
	if pts.size() > 1 and pts[0].distance_to(pts[pts.size() - 1]) <= 0.01:
		pts.remove_at(pts.size() - 1)
	return pts


func _rounded_rect(r: Rect2, radius: float, col: Color) -> void:
	draw_colored_polygon(_rounded_rect_points(r, radius), col)


func _rounded_rect_outline(r: Rect2, radius: float, col: Color, width: float) -> void:
	var pts := _rounded_rect_points(r, radius)
	pts.append(pts[0])
	draw_polyline(pts, col, width, true)


func _text_centered(pos: Vector2, text: String, size: int, color: Color, outline: int) -> void:
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var baseline := pos + Vector2(-width / 2.0, size * 0.35)
	draw_string_outline(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(Color("0b0a1f"), color.a))
	draw_string(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
