## Draws a Critter Plunge race (sim/plunge.gd). It is the fight view
## (game/arena_view.gd) with the course in place of the arena: every ability
## looks exactly as it does in a fight. The camera follows the leader down
## the shaft. Holds no rules: everything comes from the sim's state and
## events, so watching can never change a race. Each course wears one
## arena's painted art (game/arena_art.gd): its floor is baked once, like a
## fight's, and laid down the shaft a square at a time, with the pegs and
## bumpers as that arena's pillar and bumper sprites. Only what is on screen
## is drawn (battery).
extends "res://game/arena_view.gd"

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const ArenaKit := preload("res://game/arena_art/kit.gd")
const Backdrops := preload("res://game/plunge_backdrops.gd")

const FLASH_LIFE := 0.3
const EDGE_TRIM := 0.08 ## Share of the baked square cut off its top and bottom.
## Ramp colours by look (PlungeCourse ramps); others wear the theme's border.
const RAMP_LOOKS := {"ice": Color("9fe6ff"), "belt": Color("ffb347"), "cane": Color("fff4f4"), "comb": Color("f5b52e"),
	"cloud": Color("e8f4ff"), "crystal": Color("c9a6ff"), "pipe": Color("ff7a3d"), "block": Color("39ffb6"),
	"sand": Color("e8c27a"), "stone": Color("c9c0b0")}

var you := 0 ## Your racer's index (-1 in a race you only watch).
var view_size := Vector2(680, 900)
var top_pad := 0.0 ## Screen pixels above the course (the standings strip).
var camera_y := 0.0 ## World y at the top of the view.

var _peg_flash := {} ## peg index -> seconds left
var _peg_at := {} ## Vector2 -> peg index, to flash the peg a bounce names.


func set_race(s: Plunge, your_index := 0) -> void:
	sim = s
	you = your_index
	team_tags = ["YOU", ""] # Only your racer is tagged; the field is everyone else.
	_peg_at.clear()
	for i in s.course.pegs.size():
		_peg_at[s.course.pegs[i].pos] = i
	_peg_flash.clear()
	clear_effects()
	camera_y = 0.0


func _side(i: int) -> int:
	return 0 if i == you else 1


func consume_events(events: Array[Dictionary]) -> void:
	super.consume_events(events)
	for e in events:
		if e.type == "course_hit" and _peg_at.has(e.peg):
			_peg_flash[_peg_at[e.peg]] = FLASH_LIFE
		elif e.type == "finish" and e.place <= 3:
			_add_popup(e.pos, ["1ST!", "2ND", "3RD"][e.place - 1], Color("ffd36b"), 1.4)
		elif e.type == "race_ko":
			_add_popup(e.pos, "KO!", POP_DAMAGE, 1.4)


func advance(delta: float) -> void:
	advance_effects(delta)
	for k in _peg_flash.keys():
		_peg_flash[k] -= delta
		if _peg_flash[k] <= 0.0:
			_peg_flash.erase(k)
	if sim != null:
		var course_h := (view_size.y - top_pad) / view_scale
		var target_y := _focus_y() - course_h * 0.4
		target_y = clampf(target_y, 0.0, maxf(0.0, sim.finish_y + 220.0 - course_h))
		var ease := 1.0 if A11y.reduced_motion else minf(1.0, delta * 4.0)
		camera_y = lerpf(camera_y, target_y, ease)
	position = Vector2(0.0, top_pad - camera_y * view_scale)
	queue_redraw()


## The camera follows the leader still racing, so it stays on the action
## after a win.
func _focus_y() -> float:
	for i in sim.standings():
		if sim.racing(i):
			return sim.balls[i].pos.y
	return sim.finish_y


func to_world(screen_pos: Vector2) -> Vector2:
	return (get_global_transform().affine_inverse() * screen_pos) / view_scale


## The course where the arena would be: the painted floor, the gate, ramps,
## pegs and bumpers, and the finish line. World y runs down the shaft.
func _draw_stage(_shape, s: float, shake: Vector2) -> void:
	var c: PlungeCourse = sim.course
	var top := camera_y - 80.0
	var bottom := camera_y + (view_size.y - top_pad) / s + 80.0
	var art: String = c.info.art
	var theme := ArenaTheme.get_theme(art)
	_bake_art_if_needed(art)
	if _art_ctx != null and _bake != null:
		_draw_floor_tiles(top, bottom, s, shake)
	else:
		draw_rect(Rect2(0.0, top * s, Plunge.WIDTH * s, (bottom - top) * s), Color(theme.fill))
	if sim.time() < Plunge.GATE_SECONDS:
		var gy := (PlungeCourse.START_Y + Plunge.RADIUS + 4.0) * s
		draw_line(Vector2(0.0, gy), Vector2(Plunge.WIDTH * s, gy), Color(theme.border), 4.0)
	var fy: float = sim.finish_y * s
	if sim.finish_y < bottom:
		var sq := 20.0
		for k in int(Plunge.WIDTH * s / sq) + 1:
			for row in 2:
				draw_rect(Rect2(k * sq, fy + row * sq, sq, sq), Color.WHITE if (k + row) % 2 == 0 else INK)
		draw_string(Kit.FONT, Vector2(12.0, fy - 12.0), "FINISH", HORIZONTAL_ALIGNMENT_LEFT, -1, A11y.font(26), Color.WHITE)
	var seen := func(y: float, r: float) -> bool: return y + r >= top and y - r <= bottom
	var pads: Array[Dictionary] = []
	for f in sim.floors():
		if f.kind == "wind":
			if seen.call(f.rect.get_center().y, f.rect.size.y / 2.0):
				_draw_wind(f, s)
		elif seen.call(f.pos.y, f.radius):
			pads.append(f)
	_draw_floors(pads)
	_draw_wells(sim.wells())
	_draw_cores(sim)
	var rail := Color(theme.border)
	var w := PlungeCourse.RAMP_THICK * 2.0 * s
	for rp in c.ramps:
		if maxf(rp.a.y, rp.b.y) < top or minf(rp.a.y, rp.b.y) > bottom:
			continue
		var look: String = rp.get("look", "")
		var col: Color = RAMP_LOOKS.get(look, rail)
		draw_line(rp.a * s, rp.b * s, Color(0, 0, 0, 0.45), w + 10.0 * s)
		draw_line(rp.a * s, rp.b * s, col, w)
		draw_circle(rp.b * s, w / 2.0, col) # Rounds the joints of curves and shapes.
		match look:
			"ice": # A glint along the ice.
				draw_line(rp.a * s, rp.b * s, Color(1, 1, 1, 0.55), w * 0.3)
			"belt": # Chevrons running downhill along the belt.
				var d: Vector2 = rp.down
				var n := Vector2(-d.y, d.x) * 7.0 * s
				var span: float = rp.a.distance_to(rp.b)
				var start: Vector2 = rp.a if (rp.b - rp.a).dot(d) > 0.0 else rp.b
				var k := fmod(_time * 90.0, 46.0)
				while k < span - 8.0:
					var p: Vector2 = (start + d * k) * s
					draw_polyline(PackedVector2Array([p - d * 6.0 * s + n, p, p - d * 6.0 * s - n]), Color(INK, 0.8), 2.5 * s)
					k += 46.0
			"cane": # Candy stripes.
				var span: float = rp.a.distance_to(rp.b)
				var d: Vector2 = (rp.b - rp.a) / span
				var k := 8.0
				while k < span - 8.0:
					draw_line((rp.a + d * k) * s, (rp.a + d * (k + 10.0)) * s, Color("ff4d6d"), w)
					k += 26.0
			"cloud": # Puffs along the cloud's edge.
				for t in [0.15, 0.5, 0.85]:
					draw_circle(rp.a.lerp(rp.b, t) * s, w * 1.3, Color(1, 1, 1, 0.9))
	var sprites := _art_ctx != null and _bake != null
	var art_bumper := sprites and ArenaArt.has_bumper(art)
	for i in c.pegs.size():
		var p: Dictionary = c.pegs[i]
		if p.pos.y < top or p.pos.y > bottom:
			continue
		var flash: float = _peg_flash.get(i, 0.0) / FLASH_LIFE
		var at: Vector2 = p.pos * s
		var r: float = p.r * s
		if p.bumper and art_bumper:
			_sprite(1, at, r)
			if flash > 0.0:
				draw_circle(at, r, Color(1, 1, 1, 0.5 * flash))
		elif p.bumper:
			draw_circle(at, r + 10.0 * flash * s, Color(BUMPER, 0.25 + 0.4 * flash))
			draw_arc(at, r, 0, TAU, 28, BUMPER, 5.0 * s)
			draw_circle(at, r * 0.45, BUMPER)
		elif sprites:
			_sprite(0, at, r)
			if flash > 0.0:
				draw_circle(at, r, Color(1, 1, 1, 0.6 * flash))
		else:
			draw_circle(at, r, Color(theme.pillar).lerp(Color.WHITE, flash))
	var parts: Array[Dictionary] = []
	for o in sim.obstacles(): # A margin a bar long, so a bar is drawn whole.
		if seen.call(o.pos.y, o.radius + 300.0):
			parts.append(o)
	_draw_obstacles(parts)


## A wind or current band: a faint tint with streaks blowing along it.
func _draw_wind(f: Dictionary, s: float) -> void:
	var r: Rect2 = f.rect
	var rr := Rect2(r.position * s, r.size * s)
	draw_rect(rr, Color(1, 1, 1, 0.09))
	var d: Vector2 = f.dir
	var along := absf(d.x) > 0.5
	var span := r.size.x if along else r.size.y
	var cross := r.size.y if along else r.size.x
	var flipping: bool = f.get("flip_in", 99.0) < 0.6
	var col := Color(1.0, 0.5, 0.4, 0.7) if flipping else Color(1, 1, 1, 0.55)
	for k in 6:
		var u := fmod(_time * 260.0 + k * 197.0, span + 80.0) - 40.0
		var v := cross * (k + 0.5) / 6.0
		var p := Vector2(u, v) if along else Vector2(v, u)
		if (d.x < 0.0 and along) or (d.y < 0.0 and not along):
			p = Vector2(r.size.x - p.x, p.y) if along else Vector2(p.x, r.size.y - p.y)
		var a := (r.position + p) * s
		draw_line(a, a - d * 70.0 * s, col, 4.0 * s)


## The baked floor, one arena-sized square after another down the shaft;
## every other square is flipped so the joins match. The wall band from the
## arena's sides runs down both edges.
func _draw_floor_tiles(top: float, bottom: float, s: float, shake: Vector2) -> void:
	var tex := _bake.get_texture()
	var m := frame_margin()
	var side := Plunge.WIDTH * s
	# The square's top and bottom edges are shaded like walls: leave them out.
	var trim := side * EDGE_TRIM
	var src := Rect2(Vector2(m, m + trim) * _art_k, Vector2(side, side - 2.0 * trim) * _art_k)
	var wall := _art_ctx.wall
	var left_wall := Rect2(Vector2(m - wall, m + trim) * _art_k, Vector2(wall, side - 2.0 * trim) * _art_k)
	var right_wall := Rect2(Vector2(m + side, m + trim) * _art_k, Vector2(wall, side - 2.0 * trim) * _art_k)
	var band := wall * 0.5
	for k in range(int(floorf(top / Plunge.WIDTH)), int(floorf(bottom / Plunge.WIDTH)) + 1):
		if k % 2 == 0:
			draw_set_transform(shake + Vector2(0.0, k * side))
		else:
			draw_set_transform(shake + Vector2(0.0, (k + 1) * side), 0.0, Vector2(1.0, -1.0))
		draw_texture_rect_region(tex, Rect2(0.0, 0.0, side, side), src)
		draw_texture_rect_region(tex, Rect2(0.0, 0.0, band, side), left_wall)
		draw_texture_rect_region(tex, Rect2(side - band, 0.0, band, side), right_wall)
	draw_set_transform(shake)


## Sprite `slot` (0 pillar, 1 bumper) from the baked art, radius `r` at `at`.
func _sprite(slot: int, at: Vector2, r: float) -> void:
	var e := r * ArenaArt.SPRITE_EXTENT
	draw_texture_rect_region(_bake.get_texture(), Rect2(at - Vector2(e, e), Vector2(e, e) * 2.0), _art_src(slot))


## The course's arena art over a plain square: no walls but the shaft's
## sides, nothing on the floor, so it tiles.
func _make_art_ctx(id: String, margin: float) -> ArenaKit.Ctx:
	var ctx := ArenaArt.make_ctx(id, view_scale, margin)
	ctx.outline = PackedVector2Array([ctx.full.position, Vector2(ctx.full.end.x, ctx.full.position.y), ctx.full.end, Vector2(ctx.full.position.x, ctx.full.end.y)])
	ctx.centre = ctx.full.get_center()
	ctx.obstacles = []
	ctx.floors = []
	return ctx


## The arena's painting, then this course's own wash and motif over it.
func _paint_art(cv: CanvasItem) -> void:
	super._paint_art(cv)
	if _art_ctx != null and sim != null:
		Backdrops.paint(cv, _art_ctx, sim.course.info.id)


func _art_tracks() -> bool:
	return false


## Sprites are baked at bumper size; pegs shrink them.
func _art_sprite_r(_id: String) -> float:
	return 36.0 * view_scale


## Tags sit under each racer; the fight's square-arena clamping doesn't apply.
func _place_tags(s: float, _ko_ball: int) -> void:
	_tag_at.clear()
	for b in sim.balls:
		if b.alive():
			_tag_at[b.index] = ball_pos(b) * s + Vector2(0, b.radius * s + 22.0)


## Only your racer carries a ring, tag and HP badge: eight would bury the
## race, and the strip up top has everyone's HP.
func _draw_overlay(i: int, def: Dictionary, pos: Vector2, r: float, hp: float, max_hp: float, shake: Vector2) -> void:
	if i == you:
		super._draw_overlay(i, def, pos, r, hp, max_hp, shake)


## No 1v1 matchup card over a race.
func _draw_matchup(_full: Rect2) -> void:
	pass
