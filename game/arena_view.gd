## Draws a MatchSim in the Neon Critters style (design/critters.md). Holds no
## game rules: everything it shows comes from the sim's state and the events
## of each step. Effects use their own RNG and never feed back into the sim.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const A11y := preload("res://game/a11y.gd")
const RarityMark := preload("res://game/ui/rarity_mark.gd")

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
const RARITY_COLORS := {"common": Color("c9d3e0"), "uncommon": Color("5ee08a"), "rare": Color("3d9bff"), "epic": Color("b366ff"), "legendary": Color("ffc23d")}
## Side markers so mirror matches stay readable: index 0 is always the player.
## Colour is never the only cue: the player's ring is solid, the foe's is
## dashed with four spikes, so red-green colourblind players can tell them apart.
const TEAM_COLORS := [Color("45f5a6"), Color("ff5a7a")]
const TEAM_TAGS := ["YOU", "FOE"]

const POPUP_LIFE := 0.9
const HIT_LIFE := 0.35
const BURST_LIFE := 0.35
const BLINK_PERIOD := 4.3
const PILLAR := Color("6d79b8")
const BUMPER := Color("ff6fae")
const BUMPER_FLASH_LIFE := 0.2
const BANNER_LIFE := 1.6
## HP share under which the badge turns red (matches the heartbeat sound).
const LOW_HP_SHARE := 0.35

var sim: MatchSim
var team_tags: Array = TEAM_TAGS ## Labels under each ball; a shared replay uses P1/P2.
var view_scale := 0.68
## Launch aim preview for the player's ball (world direction), or ZERO to hide.
var aim_dir := Vector2.ZERO
## Ball types to show before a sim exists (menu preview).
var preview_types: Array = ["vampire", "laser"]
## Arena to show before a sim exists (menu preview).
var preview_arena := "square"

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
var _bumper_flash := 0.0
var _fx_rng := RandomNumberGenerator.new()
var _banner := 0.0 ## Seconds left on the OVERTIME banner.
var _was_overtime := false


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
	_bumper_flash = 0.0
	_banner = 0.0
	_was_overtime = false
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
				_shake = maxf(_shake, 5.0 * A11y.motion())
				_bursts.append({"pos": e.pos, "age": 0.0})
				_spawn_particles(e.pos, 10)
			"bounce":
				_squash[e.ball] = maxf(_squash[e.ball], 0.15)
				if sim.balls[e.ball].def.ability == "laser" and not A11y.reduced_motion:
					_eye_flash[e.ball] = 0.3
			"bumper":
				_bumper_flash = BUMPER_FLASH_LIFE
				_spawn_particles(e.pos, 6)
			"end":
				for b in sim.balls:
					if not b.alive():
						_spawn_particles(b.pos, 36)
						_shake = 10.0 * A11y.motion()


func advance_effects(delta: float) -> void:
	_time += delta
	_shake = maxf(0.0, _shake - delta * 30.0)
	_banner = maxf(0.0, _banner - delta)
	if sim:
		# Visual twin of the overtime sound cue.
		var ot := sim.in_overtime()
		if ot and not _was_overtime and A11y.sound_cues:
			_banner = BANNER_LIFE
		_was_overtime = ot
	for i in 2:
		_hit[i] = maxf(0.0, _hit[i] - delta)
		_squash[i] = maxf(0.0, _squash[i] - delta)
		_eye_flash[i] = maxf(0.0, _eye_flash[i] - delta)
	_bumper_flash = maxf(0.0, _bumper_flash - delta)
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
	# The menu has no fight yet; a fresh sim gives the arena's starting shape.
	var shape: MatchSim = sim if sim else MatchSim.new({"arena": preview_arena})
	var r := shape.arena_rect()
	var arena := Rect2(r.position * s, r.size * s)
	var overtime := shape.in_overtime()
	if overtime:
		_rounded_rect(full, 14.0, Color(0.35, 0.05, 0.12, 0.35))
	var border := OVERTIME_BORDER if overtime else BORDER
	var outline := shape.arena_outline()
	if outline.size() == 4:
		_rounded_rect(arena, 14.0, ARENA_FILL)
		_draw_grid(arena)
		for i in 4:
			_rounded_rect_outline(arena.grow(i * 2.0), 14.0 + i * 2.0, Color(border, 0.22 - i * 0.05), 4.0)
		_rounded_rect_outline(arena, 14.0, border, 2.5)
	else:
		for i in outline.size():
			outline[i] *= s
		draw_colored_polygon(outline, ARENA_FILL)
		_draw_grid(arena, outline)
		var closed := outline.duplicate()
		closed.append(outline[0])
		for i in 4:
			draw_polyline(closed, Color(border, 0.22 - i * 0.05), 4.0 + i * 4.0, true)
		draw_polyline(closed, border, 2.5, true)
	_draw_obstacles(shape.obstacles())

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
		var grow := 70.0 if not A11y.reduced_motion else 25.0
		_star(k.pos * s, 10.0 + t * grow, 5.0 + t * grow * 0.43, 8, Color(BURST, 1.0 - t))

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
		var rise := 40.0 if not A11y.reduced_motion else 16.0
		_text_centered(pos + Vector2(0, (40.0 - rise) * t), p.text, A11y.font(26), Color(p.color, 1.0 - t * t), 6)

	if _banner > 0.0:
		_draw_banner(full)


## OVERTIME call-out across the arena, so the cue reads with the sound off.
func _draw_banner(full: Rect2) -> void:
	var t := 1.0 - _banner / BANNER_LIFE
	var a := clampf(_banner / 0.4, 0.0, 1.0)
	var pop := 1.0 if A11y.reduced_motion else 1.0 + 0.25 * maxf(0.0, 1.0 - t * 5.0)
	var c := full.get_center() - Vector2(0, full.size.y * 0.3)
	var h := 64.0 * pop
	_rounded_rect(Rect2(c.x - full.size.x * 0.36, c.y - h / 2.0, full.size.x * 0.72, h), h / 2.0, Color(0.1, 0.02, 0.08, 0.8 * a))
	_text_centered(c, "OVERTIME!", roundi(A11y.font(36) * pop), Color(OVERTIME_BORDER, a), 6)


## Grid lines across `r`, clipped to the convex `clip` outline when given.
func _draw_grid(r: Rect2, clip := PackedVector2Array()) -> void:
	var step := 80.0 * view_scale
	var x := r.position.x + step
	while x < r.end.x - 1.0:
		_grid_line(Vector2(x, r.position.y), Vector2(x, r.end.y), clip)
		x += step
	var y := r.position.y + step
	while y < r.end.y - 1.0:
		_grid_line(Vector2(r.position.x, y), Vector2(r.end.x, y), clip)
		y += step


func _grid_line(a: Vector2, b: Vector2, clip: PackedVector2Array) -> void:
	if clip.is_empty():
		draw_line(a, b, GRID, 1.0)
		return
	var hits := Geometry2D.clip_polyline_with_polygon(PackedVector2Array([a, b]), clip)
	for part in hits:
		if part.size() >= 2:
			draw_line(part[0], part[part.size() - 1], GRID, 1.0)


func _draw_obstacles(obstacles: Array[Dictionary]) -> void:
	var s := view_scale
	for o in obstacles:
		var p: Vector2 = o.pos * s
		var rad: float = o.radius * s
		if o.kind == "bumper":
			var k := _bumper_flash / BUMPER_FLASH_LIFE
			var col := BUMPER.lerp(Color.WHITE, k * 0.7)
			draw_circle(p, rad, Color(BUMPER, 0.16 + 0.3 * k))
			for i in 3:
				draw_arc(p, rad + i * 3.0, 0, TAU, 56, Color(col, 0.3 - i * 0.08), 4.0 + i * 3.0, true)
			draw_arc(p, rad, 0, TAU, 56, col, 2.5, true)
			draw_circle(p, rad * 0.42, col)
		else:
			draw_circle(p + Vector2(3, 5), rad, Color(0, 0, 0, 0.35))
			draw_circle(p, rad, PILLAR.darkened(0.6))
			draw_circle(p + Vector2(-0.25, -0.3) * rad, rad * 0.45, Color(PILLAR, 0.25))
			draw_arc(p, rad + 3.0, 0, TAU, 56, Color(BORDER, 0.2), 6.0, true)
			draw_arc(p, rad, 0, TAU, 56, PILLAR.lightened(0.2), 2.5, true)


## One critter at `pos` (screen space) with radius `r`. Squash, wince, blink
## and eye direction come from the per-ball effect state.
func _draw_critter(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2) -> void:
	var look: Vector2 = _look[i]
	var team_col: Color = TEAM_COLORS[i]
	# Team ring and tag sit outside the squash so they stay steady.
	draw_set_transform(shake)
	_team_ring(i, pos, r, team_col)
	_text_centered(pos + Vector2(0, r + 30.0), team_tags[i], A11y.font(20), team_col, 5)

	var ang := look.angle()
	var sq: float = _squash[i] * 1.6
	var squash := Transform2D(Vector2(1.0 - sq * 0.6, 0), Vector2(0, 1.0 + sq * 0.5), Vector2.ZERO)
	draw_set_transform_matrix(Transform2D(0, pos + shake) * Transform2D(ang, Vector2.ZERO) * squash * Transform2D(-ang, Vector2.ZERO))

	var col: Color = def.color
	match def.ability:
		"vampire":
			_vampire_collar(r, col)
		"laser":
			_laser_antenna(r, col)
	_body(r, col)
	var hit: float = _hit[i]
	if hit > 0.0:
		var flash_cap := 0.3 if A11y.reduced_motion else 0.85
		draw_circle(Vector2.ZERO, r, Color(1, 1, 1, minf(flash_cap, hit * 2.4)))
	_face(def, r, look, hp / max_hp, hit, i)

	draw_set_transform(shake)
	_hp_badge(def, pos, r, hp, max_hp)


## Solid ring for the player (index 0); dashed ring with four outward spikes
## for the foe. Shape, not just hue, tells the sides apart.
func _team_ring(i: int, pos: Vector2, r: float, col: Color) -> void:
	draw_arc(pos, r + 9.0, 0, TAU, 64, Color(col, 0.18), 9.0, true)
	if i == 0:
		draw_arc(pos, r + 7.0, 0, TAU, 64, Color(col, 0.9), 3.5, true)
		return
	var dashes := 16
	var gap := TAU / dashes
	for k in dashes:
		draw_arc(pos, r + 7.0, k * gap, k * gap + gap * 0.55, 6, Color(col, 0.9), 3.5, true)
	for k in 4:
		var d := Vector2.from_angle(PI / 4.0 + k * PI / 2.0)
		var side := d.orthogonal()
		var base := pos + d * (r + 6.0)
		draw_colored_polygon(PackedVector2Array([base + side * 6.0, base + d * 14.0, base - side * 6.0]), Color(col, 0.9))


func _body(r: float, col: Color) -> void:
	draw_circle(Vector2(r * 0.08, r * 0.14), r, Color(0, 0, 0, 0.35))
	# Radial gradient: shrinking discs drifting toward the top-left highlight.
	var dark := col.darkened(0.2)
	var light := col.lightened(0.45)
	var steps := 12
	for k in steps:
		var t := float(k) / (steps - 1)
		var rad := r * (1.0 - t * 0.88)
		var centre := Vector2(-0.35, -0.4) * r * t * 0.85
		draw_circle(centre, rad, dark.lerp(light, t * t))
	draw_arc(Vector2.ZERO, r, 0, TAU, 64, col.darkened(0.5), maxf(1.5, r * 0.07), true)


func _vampire_collar(r: float, col: Color) -> void:
	var cape := col.darkened(0.55)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * r * 0.25, -r * 0.9), Vector2(side * r * 1.12, -r * 1.13), Vector2(side * r * 0.95, -r * 0.15)]), cape)


func _laser_antenna(r: float, col: Color) -> void:
	var tip := Vector2(0, -r * 1.45)
	draw_line(Vector2(0, -r * 0.8), tip, col.darkened(0.5), maxf(1.5, r * 0.07), true)
	var on := sin(_time * 5.0) > -0.2
	if on:
		draw_circle(tip, r * 0.2, Color("7fe6ff", 0.3))
	draw_circle(tip, r * 0.1, Color("bff4ff") if on else Color("3b6f80"))


func _face(def: Dictionary, r: float, look: Vector2, hp_frac: float, hit: float, i: int) -> void:
	var e := look * r * 0.2 + Vector2(0, -r * 0.08)
	if hit > 0.0:
		_wince(r, e)
		return
	var phase := fmod(_time + i * 1.7, BLINK_PERIOD)
	var blink := sin(phase / 0.12 * PI) if phase < 0.12 else 0.0
	var open := maxf(0.08, 1.0 - blink)
	match def.ability:
		"laser":
			_eye(e, r * 0.4, r * 0.4 * open, r * 0.16, look, Color("0a7bb0"), Color("7fe6ff"), 0.0, def.color, _eye_flash[i])
		"vampire":
			for k in [-1.0, 1.0]:
				_eye(e + Vector2(k * r * 0.3, 0), r * 0.19, r * 0.22 * open, r * 0.1, look, Color.TRANSPARENT, Color.TRANSPARENT, 0.45, def.color, 0.0)
				_brow(e + Vector2(k * r * 0.3, 0), r * 0.19, r * 0.22, k, r * 0.12, r)
			_mouth(e + Vector2(0, r * 0.34), r, "fangs", hp_frac)
		_:
			for k in [-1.0, 1.0]:
				_eye(e + Vector2(k * r * 0.3, 0), r * 0.2, r * 0.24 * open, r * 0.1, look, Color.TRANSPARENT, Color.TRANSPARENT, 0.0, def.color, 0.0)
			_mouth(e + Vector2(0, r * 0.34), r, "smile", hp_frac)


func _eye(c: Vector2, w: float, h: float, pupil: float, look: Vector2, iris: Color, glow: Color, lid: float, body: Color, flash: float) -> void:
	if glow.a > 0.0:
		var g := 0.25 + flash * 1.5
		for k in 3:
			_ellipse(c, w * (1.25 + k * 0.18), h * (1.25 + k * 0.18), Color(glow, g / (k + 2)))
	_ellipse(c, w, h, Color.WHITE)
	var p := c + Vector2(look.x * w, look.y * h) * 0.45
	# Keep the pupil inside the (possibly blinking) eye.
	var ph := minf(pupil, h * 0.95)
	if iris.a > 0.0:
		_ellipse(p, minf(pupil * 1.7, w * 0.95), minf(pupil * 1.7, h * 0.95), iris)
	_ellipse(p, pupil, ph, INK)
	if ph > pupil * 0.5:
		draw_circle(p - Vector2(pupil, pupil) * 0.4, pupil * 0.35, Color.WHITE)
	if lid > 0.0:
		# Sleepy upper lid in body colour, with a darker edge.
		var y := c.y - h + h * 2.0 * lid
		# Arc of the eye above the lid line; the chord closes the polygon.
		var d := clampf((y - c.y) / (h * 1.04), -0.99, 0.99)
		var a0 := PI - asin(d)
		var a1 := TAU + asin(d)
		var pts := PackedVector2Array()
		for k in 17:
			var a := lerpf(a0, a1, k / 16.0)
			pts.append(c + Vector2(cos(a) * w * 1.04, sin(a) * h * 1.04))
		draw_colored_polygon(pts, body.lightened(0.05))
		draw_line(Vector2(c.x - w, y), Vector2(c.x + w, y), body.darkened(0.45), maxf(1.0, w * 0.25), true)


func _brow(c: Vector2, w: float, h: float, side: float, slant: float, r: float) -> void:
	var top := c.y - h - r * 0.08
	draw_line(Vector2(c.x + side * w * 1.1, top - slant * 0.5), Vector2(c.x - side * w * 0.9, top + slant * 0.5), INK, maxf(1.6, r * 0.08), true)


func _wince(r: float, e: Vector2) -> void:
	var lw := maxf(1.6, r * 0.08)
	for k in [-1.0, 1.0]:
		var c := e + Vector2(k * r * 0.3, 0)
		draw_polyline(PackedVector2Array([
			c + Vector2(-k * r * 0.12, -r * 0.1), c + Vector2(k * r * 0.08, 0), c + Vector2(-k * r * 0.12, r * 0.1)]), INK, lw, true)
	_ellipse(e + Vector2(0, r * 0.38), r * 0.12, r * 0.09, INK)


func _mouth(m: Vector2, r: float, kind: String, hp_frac: float) -> void:
	var lw := maxf(1.4, r * 0.065)
	if hp_frac < 0.35:
		var pts := PackedVector2Array()
		for k in 5:
			pts.append(m + Vector2(-r * 0.16 + k * r * 0.08, -r * 0.05 if k % 2 == 1 else 0.0))
		draw_polyline(pts, INK, lw, true)
		return
	draw_arc(m + Vector2(0, -r * 0.07), r * 0.14, 0.2 * PI, 0.8 * PI, 16, INK, lw, true)
	if kind == "fangs":
		for k in [-1.0, 1.0]:
			var x: float = m.x + k * r * 0.1
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - r * 0.035, m.y + r * 0.03), Vector2(x + r * 0.035, m.y + r * 0.03), Vector2(x, m.y + r * 0.15)]), Color.WHITE)


func _hp_badge(def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float) -> void:
	var rarity: String = def.get("rarity", "common")
	var rim: Color = RARITY_COLORS.get(rarity, RARITY_COLORS.common)
	var top: float = def.get("badge_top", 1.15) * r
	var fs := A11y.font(roundi(r * 0.42))
	var text := str(maxi(0, ceili(hp)))
	var tw := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tier := 1
	var star_w := fs * 0.62
	var mark_w := fs * 0.8 ## Rarity shape before the HP number.
	var w := fs * 0.45 + mark_w + tw + fs * 0.35 + tier * star_w + fs * 0.45
	var h := fs * 1.45
	var rect := Rect2(pos.x - w / 2.0, pos.y - top - h - 4.0, w, h)
	if rarity != "common":
		_rounded_rect(rect.grow(3.0), h / 2.0 + 3.0, Color(rim, 0.25))
	_rounded_rect(rect, h / 2.0, Color(10 / 255.0, 8 / 255.0, 30 / 255.0, 0.88))
	_rounded_rect_outline(rect, h / 2.0, rim, 1.0 if rarity == "common" else 2.0)
	var low := hp > 0.0 and hp < max_hp * LOW_HP_SHARE
	if low:
		# Visual twin of the low-HP heartbeat: a red pulse (steady with reduced motion).
		var beat := 1.0 if A11y.reduced_motion else 0.55 + 0.45 * absf(sin(_time * PI / 0.85))
		_rounded_rect_outline(rect.grow(4.0), h / 2.0 + 4.0, Color(POP_DAMAGE, beat), 3.0)
	var x := rect.position.x + fs * 0.45
	RarityMark.draw(self, rarity, Vector2(x + mark_w * 0.45, rect.position.y + h / 2.0), fs * 0.62, rim)
	x += mark_w
	draw_string(FONT, Vector2(x, rect.position.y + h / 2.0 + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, POP_DAMAGE.lightened(0.25) if low else Color.WHITE)
	for k in tier:
		_star(Vector2(x + tw + fs * 0.35 + star_w * 0.5 + k * star_w, rect.position.y + h / 2.0), fs * 0.3, fs * 0.13, 5, rim)


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
