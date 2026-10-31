## A Critter Plunge course: a 1000-wide shaft of big moving pieces, plus the
## collisions racers have with its still parts. There are 20 courses
## (COURSES), each in one arena's painted look. Under sliding bricks at the
## gate, a course is three of the shared moving pieces (sliding bricks, gap
## rings, rocking slabs, spinning crosses, bobbing bumpers, seesaws,
## pendulums; no two courses share a set), its hazard section and its own
## signature machine (a gumball globe, a sandworm, a scoop wheel...). The
## seed picks the course and varies each section's phases and speeds.
## The race itself is sim/plunge.gd.
##
## Moving pieces are `movers`: rows of circles that move as one (sliding,
## swinging on a hinge or turning round a hub) and are drawn as one thick
## line (their `group`). Still ramps only gather the field into a machine;
## ramps can be icy (no grip, they speed you up). Floors add wind and
## current bands, one-way portals and launch pads; there are gravity wells
## and pickups too.
##
## Course rules: pieces keep a racer-wide gap to the walls and to each other
## wherever they move, so nothing pins a racer, flat pieces are tilted or
## rocking so nobody rides one for good, and the seed mirrors each section.
## Nothing lets a racer skip course pieces (a peg-phasing shield won 2.4x
## its share).
##
## Only +, *, sqrt and sim/rng.gd, so every platform agrees.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const DMath := preload("res://sim/dmath.gd")

const WIDTH := 1000.0
const START_Y := 90.0
const CELL := 100.0 ## Collision grid cell size; more than a racer's reach.
const RAMP_THICK := 6.0
const KICKER_R := 34.0 ## The half-bumpers on the walls, one each side per peg row.
const WALL_BOUNCE := 0.55
const PEG_BOUNCE := 0.6
const RAMP_BOUNCE := 0.25
const RAMP_GRIP := 0.12
const BUMPER_KICK := 620.0 ## Minimum speed a bumper sends you away at.
## Below this speed into a ramp, a racer settles onto it instead of bouncing,
## so a roll is a smooth roll.
const REST_SPEED := 90.0
## The shared moving pieces (each course uses its own three), the hazard
## sections and each course's own signature machine.
const PIECES := ["bricks", "rings", "slabs", "crosses", "bobbers", "seesaws", "pendulums"]
const MACHINES := ["globe", "dipper", "sundial", "bridges", "orrery", "tumbler", "kelpwave", "doors", "blimps",
	"turbines", "bobsled", "pistons", "lavalamp", "traffic", "shuffle", "sandworm", "trapdoors", "stairs", "scoops",
	"plunger"]
## The hazard sections, one per course, in the arenas' own pieces: gravity
## wells, lava, goo and sliding bumpers. Each holds a pickup too (a power
## core, heal or shield). sim/plunge.gd runs them.
const HAZARDS := ["wells", "lava", "goo", "sliders"]
## The shared static set pieces (each course uses its own three): curved
## funnels, pop bumpers, hook slides that fling racers across, lanes, gem
## blocks and rooftops. Never rows of pins or plain slanted beams.
const STATICS := ["funnels", "poppers", "hooks", "lanes", "gems", "roofs"]
## Static set pieces are chunky like the moving ones: this thick (each
## side of the line) and drawn in the course's colour.
const SET_THICK := 16.0
const SET := {"thick": SET_THICK, "look": "set"}
const SECTIONS := PIECES + MACHINES + HAZARDS + STATICS
const WELL_ACCEL := 700.0 ## Under gravity even at full pull, so a well bends a drop but never holds it.
const GOO_DRAG := 2.2 ## Extra drag per second in goo.
const PICKUP_R := 34.0
const ICE_ACCEL := 320.0
const BELT_TOP := 300.0 ## Belts push racers along up to this speed. ## How hard an icy ramp speeds a racer along it.
## Movers stay under this speed where they bat racers (the arenas' rule: a
## part bats balls around but never pins one).
const MOVER_SPEED := 340.0
const BEAD := 1.9 ## Circles along a moving piece sit this many radii apart.
const KICK_EVERY := 260.0 ## Wall half-bumpers this far apart down the course.
## Sections whose pieces meet the walls themselves (no half-bumpers there).
const WALLED := ["funnels", "hooks", "lanes", "slabs", "globe", "bridges", "doors", "bobsled", "trapdoors", "scoops", "plunger"]

## Every course: its name, the arena whose painted look it wears (`art`, a
## map id in game/arena_art.gd; the race never reads it), the colour its
## moving pieces are painted (`tint`, render only) and the sections under
## the opener: its own three static set pieces, three moving pieces, its
## hazard and its machine, about half of it moving.
const COURSES := [
	{"id": "gumdrop", "name": "Gumdrop Drop", "art": "candy", "tint": "ff7eb6", "plan": ["funnels", "bricks", "goo", "poppers", "globe", "hooks", "crosses", "funnels", "bobbers"]},
	{"id": "honey", "name": "Honey Chute", "art": "hive", "tint": "f5b52e", "plan": ["gems", "slabs", "goo", "roofs", "dipper", "lanes", "seesaws", "gems", "pendulums"]},
	{"id": "sunstone", "name": "Sunstone Steps", "art": "temple", "tint": "e8c36a", "plan": ["gems", "bricks", "sliders", "funnels", "sundial", "lanes", "rings", "gems", "slabs"]},
	{"id": "vines", "name": "Vine Ruins", "art": "ruins", "tint": "7fd36b", "plan": ["poppers", "pendulums", "sliders", "hooks", "bridges", "roofs", "crosses", "poppers", "seesaws"]},
	{"id": "nebula", "name": "Nebula Fall", "art": "nebula", "tint": "b38cff", "plan": ["poppers", "rings", "wells", "roofs", "orrery", "funnels", "bobbers", "poppers", "crosses"]},
	{"id": "rocks", "name": "Rock Belt", "art": "asteroid", "tint": "a59a8e", "plan": ["gems", "bobbers", "wells", "hooks", "tumbler", "lanes", "bricks", "gems", "pendulums"]},
	{"id": "kelp", "name": "Kelp Forest", "art": "kelp", "tint": "4fd9a0", "plan": ["funnels", "pendulums", "wells", "gems", "kelpwave", "roofs", "rings", "funnels", "seesaws"]},
	{"id": "trench", "name": "Deep Trench", "art": "trench", "tint": "4aa8ff", "plan": ["lanes", "slabs", "wells", "roofs", "doors", "poppers", "crosses", "lanes", "bricks"]},
	{"id": "clouds", "name": "Cloud Hop", "art": "cloud", "tint": "f4f8ff", "plan": ["gems", "seesaws", "sliders", "funnels", "blimps", "hooks", "bobbers", "gems", "rings"]},
	{"id": "storm", "name": "Storm Front", "art": "storm", "tint": "9aa6ff", "plan": ["poppers", "crosses", "wells", "hooks", "turbines", "lanes", "pendulums", "poppers", "bricks"]},
	{"id": "icicles", "name": "Icicle Run", "art": "frost", "tint": "bfeaff", "plan": ["poppers", "slabs", "goo", "lanes", "bobsled", "funnels", "bobbers", "poppers", "rings"]},
	{"id": "crystal", "name": "Crystal Cave", "art": "prism", "tint": "8ff0ff", "plan": ["roofs", "crosses", "sliders", "hooks", "pistons", "gems", "rings", "roofs", "seesaws"]},
	{"id": "lava", "name": "Lava Tubes", "art": "magma", "tint": "ff8a3d", "plan": ["funnels", "bricks", "lava", "hooks", "lavalamp", "roofs", "bobbers", "funnels", "slabs"]},
	{"id": "sunset", "name": "Sunset Strip", "art": "sunset", "tint": "ff5fd2", "plan": ["lanes", "bricks", "sliders", "gems", "traffic", "poppers", "seesaws", "lanes", "crosses"]},
	{"id": "glitch", "name": "Glitch Grid", "art": "glitch", "tint": "5cf2ff", "plan": ["gems", "rings", "lava", "funnels", "shuffle", "poppers", "bricks", "gems", "bobbers"]},
	{"id": "dunes", "name": "Dune Slide", "art": "dunes", "tint": "e2b56f", "plan": ["hooks", "seesaws", "goo", "lanes", "sandworm", "roofs", "slabs", "hooks", "bricks"]},
	{"id": "graves", "name": "Grave Drop", "art": "graveyard", "tint": "9db0b8", "plan": ["lanes", "pendulums", "goo", "roofs", "trapdoors", "funnels", "slabs", "lanes", "crosses"]},
	{"id": "manor", "name": "Haunted Stairs", "art": "manor", "tint": "c58cff", "plan": ["roofs", "bobbers", "wells", "poppers", "stairs", "gems", "seesaws", "roofs", "pendulums"]},
	{"id": "toys", "name": "Toy Chest", "art": "toybox", "tint": "ffcf4d", "plan": ["funnels", "rings", "sliders", "hooks", "scoops", "lanes", "pendulums", "funnels", "crosses"]},
	{"id": "pinball", "name": "Pinball Plunge", "art": "pinball", "tint": "ff6fae", "plan": ["hooks", "bobbers", "sliders", "gems", "plunger", "poppers", "crosses", "hooks", "seesaws"]},
]

var pegs: Array = [] ## [{pos, r, bumper}]
var ramps: Array = [] ## [{a, b, down}] solid line segments, RAMP_THICK wide; `down` points downhill along it.
var sections: Array = [] ## [{kind, y0, y1}] for the renderer.
var finish_y := 0.0
var floors: Array = [] ## Arena floor pads: {kind "goo" or "lava", pos, radius}.
var wells: Array = [] ## Arena gravity wells: {pos, reach, accel, core}.
var cores: Array = [] ## Arena pickups: {pos, radius, kind "core" / "heal" / "shield"}.
var movers: Array = [] ## Moving parts, as arena obstacles (sim/arenas.gd): {pos, radius, kind, slide/period,
## orbit/pivot, bar/angle}, or `swing` (radians either way round `pivot`, over `period`, from `phase`).
var info: Dictionary ## This course's COURSES entry.
var _gid := 0 ## The last moving piece's group id (its circles share one).

var _cells := {} ## grid cell (CELL square) -> obstacle refs (peg index, or -1 - ramp index)
var _near := {} ## grid cell -> every ref in it and the 8 cells round it, once each
const _NONE: Array = []
var _peg_pos := PackedVector2Array()
var _peg_r := PackedFloat64Array()


## The course `course_id`, or one the seed picks when it's "".
func _init(seed_value: int, course_id := "") -> void:
	info = find(course_id) if course_id != "" else COURSES[Rng.new(seed_value * 17 + 5).range_int(0, COURSES.size() - 1)]
	_build(Rng.new(seed_value * 7919 + 1))


static func find(course_id: String) -> Dictionary:
	for c in COURSES:
		if c.id == course_id:
			return c
	return COURSES[0]


## Keeps a racer (anything with pos, vel and radius) inside the shaft and off
## the pieces, over `dt` seconds of grip. Returns the hardest hit as
## {speed, point, bumper, peg (its centre, or null)}, speed 0 when it touched
## nothing.
func collide(r, dt: float) -> Dictionary:
	var hit := {"speed": 0.0, "point": r.pos, "bumper": false, "peg": null}
	var rad: float = r.radius
	if r.pos.x < rad:
		_note(hit, absf(r.vel.x), Vector2(0.0, r.pos.y), false)
		r.pos.x = rad
		r.vel.x = absf(r.vel.x) * WALL_BOUNCE
	elif r.pos.x > WIDTH - rad:
		_note(hit, absf(r.vel.x), Vector2(WIDTH, r.pos.y), false)
		r.pos.x = WIDTH - rad
		r.vel.x = -absf(r.vel.x) * WALL_BOUNCE
	if r.pos.y < rad:
		r.pos.y = rad
		r.vel.y = absf(r.vel.y)
	for ref in _near.get(_cell(int(floorf(r.pos.x / CELL)), int(floorf(r.pos.y / CELL))), _NONE):
		if ref >= 0:
			# Most pegs in reach of the band are not touching: a cheap test first.
			var reach: float = rad + _peg_r[ref]
			var d: Vector2 = r.pos - _peg_pos[ref]
			if d.x >= reach or d.x <= -reach or d.y >= reach or d.y <= -reach:
				continue
			_hit_peg(r, pegs[ref], hit)
		else:
			_hit_ramp(r, ramps[-ref - 1], dt, hit)
	return hit


static func _note(hit: Dictionary, speed: float, point: Vector2, bumper: bool, peg = null) -> void:
	if speed > hit.speed:
		hit.speed = speed
		hit.point = point
		hit.bumper = bumper
		hit.peg = peg


func _hit_peg(r, p: Dictionary, hit: Dictionary) -> void:
	var d: Vector2 = r.pos - p.pos
	var reach: float = r.radius + p.r
	var dist2 := d.length_squared()
	if dist2 >= reach * reach or dist2 < 0.0001:
		return
	var dist := sqrt(dist2)
	var n := d / dist
	r.pos = p.pos + n * reach
	var vn: float = r.vel.dot(n)
	if vn >= 0.0:
		return
	_note(hit, -vn, p.pos + n * p.r, p.bumper, p.pos)
	if p.bumper:
		var out := maxf(-vn * PEG_BOUNCE, BUMPER_KICK)
		r.vel += n * (out - vn)
	else:
		r.vel -= n * vn * (1.0 + PEG_BOUNCE)


func _hit_ramp(r, s: Dictionary, dt: float, hit: Dictionary) -> void:
	var a: Vector2 = s.a
	var ab: Vector2 = s.b - a
	var t := clampf((r.pos - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var closest := a + ab * t
	var d: Vector2 = r.pos - closest
	var reach: float = r.radius + s.get("thick", RAMP_THICK)
	var dist2 := d.length_squared()
	if dist2 >= reach * reach or dist2 < 0.0001:
		return
	var dist := sqrt(dist2)
	var n := d / dist
	r.pos = closest + n * reach
	var vn: float = r.vel.dot(n)
	if vn < 0.0:
		_note(hit, -vn, closest, false)
		r.vel -= n * vn * (1.0 + (RAMP_BOUNCE if -vn > REST_SPEED else 0.0))
	hit.ramp = s # The race's Frost and Tech talents read it.
	if s.has("ice"):
		r.vel += s.down * ICE_ACCEL * dt
	else:
		var tangent: Vector2 = r.vel - n * r.vel.dot(n)
		r.vel -= tangent * minf(1.0, RAMP_GRIP * dt)
	if s.has("belt") and r.vel.dot(s.down) < BELT_TOP:
		r.vel += s.down * s.belt * dt


# --- Building ------------------------------------------------------------------

## Sliding bricks under the gate (they spread the field fairly), then the
## course's sections, each mirrored left-right on a coin flip.
func _build(crng: Rng) -> void:
	var y := START_Y + 120.0
	var first := [pegs.size(), ramps.size(), floors.size(), wells.size(), cores.size(), movers.size()]
	y = _section(crng, "opener", y)
	if crng.range_int(0, 1) == 1:
		_mirror(first)
	for kind in info.plan:
		var at := [pegs.size(), ramps.size(), floors.size(), wells.size(), cores.size(), movers.size()]
		y = _section(crng, kind, y)
		if crng.range_int(0, 1) == 1:
			_mirror(at)
	finish_y = y + 80.0
	# Half-bumpers down both walls wherever no piece comes near that wall,
	# so a gate by the wall can't free-fall past the pieces (and no piece
	# ever pinches a racer against one).
	var ky := START_Y + 300.0
	while ky < finish_y - 150.0:
		var open := sections.any(func(sec): return ky >= sec.y0 and ky < sec.y1 and not WALLED.has(sec.kind))
		if open:
			for x in [0.0, WIDTH]:
				if _wall_clear(x, ky):
					_peg(x, ky, KICKER_R, true)
		ky += KICK_EVERY
	for i in pegs.size():
		var p: Dictionary = pegs[i]
		_bucket(i, p.pos - Vector2.ONE * p.r, p.pos + Vector2.ONE * p.r)
		_peg_pos.append(p.pos)
		_peg_r.append(p.r)
	for i in ramps.size():
		var s: Dictionary = ramps[i]
		var d: Vector2 = s.b - s.a
		if d.y < 0.0:
			d = -d
		s.down = d / d.length() if d.length_squared() > 0.0 else Vector2.DOWN # Downhill along it (a flat one: a to b).
		var th: float = s.get("thick", RAMP_THICK)
		_bucket(-i - 1, Vector2(minf(s.a.x, s.b.x), minf(s.a.y, s.b.y)) - Vector2.ONE * th, Vector2(maxf(s.a.x, s.b.x), maxf(s.a.y, s.b.y)) + Vector2.ONE * th)
	# A racer touches what is within its radius (under CELL): one cell all round covers it.
	for key in _cells:
		var cx: int = key % 64 - 8
		var cy: int = key / 64
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var k := _cell(cx + dx, cy + dy)
				if not _near.has(k):
					_near[k] = []
				for ref in _cells[key]:
					if not _near[k].has(ref):
						_near[k].append(ref)


## Flips everything added since `at` (counts of pegs, ramps, floors, wells,
## cores, movers) left-right, so neither side of a section is the lucky one.
func _mirror(at: Array) -> void:
	for q in range(at[0], pegs.size()):
		pegs[q].pos.x = WIDTH - pegs[q].pos.x
	for q in range(at[1], ramps.size()):
		ramps[q].a.x = WIDTH - ramps[q].a.x
		ramps[q].b.x = WIDTH - ramps[q].b.x
	for q in range(at[2], floors.size()):
		var f: Dictionary = floors[q]
		if f.has("rect"):
			f.rect = Rect2(WIDTH - f.rect.end.x, f.rect.position.y, f.rect.size.x, f.rect.size.y)
		else:
			f.pos.x = WIDTH - f.pos.x
		if f.has("dir"):
			f.dir.x = -f.dir.x
		if f.has("kick"):
			f.kick.x = -f.kick.x
	for q in range(at[3], wells.size()):
		wells[q].pos.x = WIDTH - wells[q].pos.x
	for q in range(at[4], cores.size()):
		cores[q].pos.x = WIDTH - cores[q].pos.x
	for q in range(at[5], movers.size()):
		var o: Dictionary = movers[q]
		o.pos.x = WIDTH - o.pos.x
		if o.has("pivot"):
			o.pivot.x = WIDTH - o.pivot.x
		if o.has("slide"):
			o.slide.x = -o.slide.x
		for key in ["orbit", "swing"]:
			if o.has(key):
				o[key] = -o[key]
		if o.has("angle"):
			o.angle = 180.0 - o.angle


func _bucket(ref: int, lo: Vector2, hi: Vector2) -> void:
	for cy in range(int(floorf(lo.y / CELL)), int(floorf(hi.y / CELL)) + 1):
		for cx in range(int(floorf(lo.x / CELL)), int(floorf(hi.x / CELL)) + 1):
			var k := _cell(cx, cy)
			if not _cells.has(k):
				_cells[k] = []
			_cells[k].append(ref)


static func _cell(cx: int, cy: int) -> int:
	return cy * 64 + cx + 8


func _peg(x: float, y: float, r := 12.0, bumper := false) -> void:
	pegs.append({"pos": Vector2(x, y), "r": r, "bumper": bumper})


## Whether a half-bumper on the wall at `x` (0 or WIDTH), height `y`, stays
## a racer-wide gap clear of everything that can ever come near it: where a
## moving circle can go is taken as its slide, or its whole circle round its
## pivot.
func _wall_clear(x: float, y: float) -> bool:
	var keep := KICKER_R + 2.0 * 30.0 + 8.0
	for o in movers:
		var c: Vector2 = o.pos
		var reach: float = o.radius
		if o.has("pivot"):
			reach += c.distance_to(o.pivot)
			c = o.pivot
		var slide: Vector2 = o.get("slide", Vector2.ZERO)
		var lo_x := c.x - reach - absf(slide.x)
		var hi_x := c.x + reach + absf(slide.x)
		var lo_y := c.y - reach - absf(slide.y)
		var hi_y := c.y + reach + absf(slide.y)
		if y + keep < lo_y or y - keep > hi_y:
			continue
		if (x == 0.0 and lo_x < keep) or (x == WIDTH and hi_x > WIDTH - keep):
			return false
	for f in floors:
		if f.kind == "portal" or f.kind == "launch":
			if absf(f.pos.y - y) < keep + f.radius and absf(f.pos.x - x) < keep + f.radius:
				return false
	return true


## A ramp from `a` to `b` carrying `extra` (look, ice, belt).
func _seg(a: Vector2, b: Vector2, extra := {}) -> void:
	var s := {"a": a, "b": b}
	s.merge(extra)
	ramps.append(s)


## Point `t` (0..1) along the curve from `a` to `b` bent toward `c`.
static func _bez(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a * ((1.0 - t) * (1.0 - t)) + c * (2.0 * (1.0 - t) * t) + b * (t * t)


## A curved ramp from `a` to `b` bent toward `c`, as `n` short ramps.
func _curve(a: Vector2, c: Vector2, b: Vector2, extra := {}, n := 8) -> void:
	var prev := a
	for k in range(1, n + 1):
		var p := _bez(a, c, b, float(k) / n)
		_seg(prev, p, extra)
		prev = p


## A wind or current band: pushes everything in `rect` along `dir` at
## `accel`, reversing every `flip` seconds when set.
func _wind(rect: Rect2, dir: Vector2, accel: float, flip := 0.0) -> void:
	var f := {"kind": "wind", "rect": rect, "dir": dir, "accel": accel}
	if flip > 0.0:
		f.flip = flip
	floors.append(f)


## A one-way portal from `from` to `to`.
func _portal(from: Vector2, to: Vector2) -> void:
	floors.append({"kind": "portal", "pos": from, "radius": 52.0, "to": floors.size() + 1})
	floors.append({"kind": "portal", "pos": to, "radius": 52.0})


## A launch pad that throws a racer falling onto it along `kick`.
func _pad(at: Vector2, kick: Vector2) -> void:
	floors.append({"kind": "launch", "pos": at, "radius": 48.0, "kick": kick})


## A moving piece: circles BEAD radii apart along `pts`, all moving as one
## (`move`: orbit/pivot, slide/period/phase or swing/pivot/period/phase) and
## drawn as one thick line (`group`). `kind` "bumper" kicks.
func _chain(pts: Array, r: float, move: Dictionary, kind := "pillar") -> void:
	_gid += 1
	var tint: String = info.get("tint", "")
	var step := r * BEAD
	for k in range(pts.size() - 1):
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var n := maxi(1, int(ceil(a.distance_to(b) / step)))
		for j in range(0 if k == 0 else 1, n + 1):
			var o := {"pos": a.lerp(b, float(j) / n), "radius": r, "kind": kind, "group": _gid, "tint": tint}
			o.merge(move)
			movers.append(o)


## A straight rod from `a` to `b`.
func _rod(a: Vector2, b: Vector2, r: float, move: Dictionary) -> void:
	_chain([a, b], r, move)


## A rod `half` long either side of `c` at `deg` degrees.
func _rod_at(c: Vector2, half: float, deg: float, r: float, move: Dictionary) -> void:
	var d := Vector2(DMath.cos(deg_to_rad(deg)), DMath.sin(deg_to_rad(deg))) * half
	_rod(c - d, c + d, r, move)


## Swinging round `pivot` by `swing` radians either way.
static func _swinging(pivot: Vector2, swing: float, period: float, phase: float) -> Dictionary:
	return {"pivot": pivot, "swing": swing, "period": period, "phase": phase, "slide": Vector2.ZERO}


## Sliding by `by` (a sine over `period`), `phase` of the way through.
static func _sliding(by: Vector2, period: float, phase := 0.0) -> Dictionary:
	return {"slide": by, "period": period, "phase": phase}


## Turning round `pivot` at `spin` rad/s.
static func _turning(pivot: Vector2, spin: float) -> Dictionary:
	return {"pivot": pivot, "orbit": spin}


## A ring of radius `rad` round `c` turning at `spin`, with `gaps` openings
## each `gap` radians wide, the first centred at `start` radians.
func _ring(c: Vector2, rad: float, r: float, spin: float, gaps: int, gap: float, start: float) -> void:
	var arc := TAU / gaps - gap
	for g in gaps:
		var a0 := start + gap / 2.0 + g * TAU / gaps
		var pts := []
		var n := maxi(2, int(ceil(arc * rad / (r * BEAD))))
		for k in n + 1:
			var a := a0 + arc * k / n
			pts.append(c + Vector2(DMath.cos(a), DMath.sin(a)) * rad)
		# Every circle of the arc turns round the ring's centre.
		_gid += 1
		var tint: String = info.get("tint", "")
		for p in pts:
			movers.append({"pos": p, "radius": r, "kind": "pillar", "group": _gid, "tint": tint, "pivot": c, "orbit": spin})


## A number from `lo` to `hi` by the seed.
static func _jit(crng: Rng, lo: float, hi: float) -> float:
	return lo + (hi - lo) * crng.range_int(0, 100) / 100.0


## A V of still ramps from both walls down to a mouth `mouth` wide at `x`.
func _hopper(y: float, x: float, mouth: float, drop: float, extra := {}) -> void:
	_seg(Vector2(0.0, y), Vector2(x - mouth / 2.0, y + drop), extra)
	_seg(Vector2(WIDTH, y), Vector2(x + mouth / 2.0, y + drop), extra)


## Adds one section starting at `y0` and returns where the next one starts.
## Every section is moving pieces; still ramps only gather the field into a
## machine. The seed varies phases and speeds, and mirrors the section.
func _section(crng: Rng, kind: String, y0: float) -> float:
	var h := 0.0
	match kind:
		# --- The opener and the shared moving pieces -------------------------------
		"opener", "bricks":
			# Rounded bricks sliding across, tilted so nobody rides one for
			# good; rows of two short bricks and one long one, opposite ways.
			var rows := 3 if kind == "opener" else 5
			var period := _jit(crng, 3.4, 4.0)
			for row in rows:
				var ry := y0 + 70.0 + row * 160.0
				var tilt := 12.0 if row % 2 == 0 else -12.0
				var dir := 1.0 if row % 2 == 0 else -1.0
				var ph := row * 0.21
				if row % 2 == 0:
					for x in [300.0, 700.0]:
						_rod_at(Vector2(x, ry), 90.0, tilt, 18.0, _sliding(Vector2(110.0 * dir, 0.0), period, ph))
				else:
					_rod_at(Vector2(500.0, ry), 110.0, tilt, 18.0, _sliding(Vector2(150.0 * dir, 0.0), period, ph))
			h = rows * 160.0 + 60.0
		"rings":
			# Rings with three gaps turning both ways, close enough that the way
			# down is through them: drop in, ride round, fall out when a gap
			# comes by.
			# Two then one, big and few (battery: a ring is many circles).
			var spin := _jit(crng, 0.95, 1.2)
			for row in 2:
				var ry := y0 + 190.0 + row * 330.0
				var xs := [270.0, 730.0] if row == 0 else [500.0]
				for j in xs.size():
					_ring(Vector2(xs[j], ry), 150.0, 18.0, spin if (row + j) % 2 == 0 else -spin, 3, 0.75, _jit(crng, 0.0, TAU))
			h = 330.0 + 190.0 + 200.0
		"slabs":
			# Long slabs from alternate walls, flapping on their hinge like a
			# zigzag of see-saws, so no two drops off them are alike.
			var period := _jit(crng, 2.6, 3.0)
			for k in 4:
				var y := y0 + 60.0 + k * 240.0
				var left := k % 2 == 0
				var pivot := Vector2(0.0 if left else WIDTH, y)
				var a := deg_to_rad(15.0)
				var tip := pivot + Vector2(DMath.cos(a) * (1.0 if left else -1.0), DMath.sin(a)) * 620.0
				_rod(pivot, tip, 18.0, _swinging(pivot, 0.11 if left else -0.11, period, k * 0.3))
			h = 4 * 240.0 + 140.0
		"crosses":
			# Spinning crosses: two on one row, one on the next.
			var spin := _jit(crng, 1.2, 1.5)
			for row in 4:
				var ry := y0 + 150.0 + row * 250.0
				var xs := [270.0, 730.0] if row % 2 == 0 else [500.0]
				for j in xs.size():
					var c := Vector2(xs[j], ry)
					var s := spin if (row + j) % 2 == 0 else -spin
					var turn := _jit(crng, 0.0, 90.0)
					_rod_at(c, 125.0, turn, 17.0, _turning(c, s))
					_rod_at(c, 125.0, turn + 90.0, 17.0, _turning(c, s))
			h = 4 * 250.0 + 60.0
		"bobbers":
			# Big bumpers bobbing up and down, out of step.
			var period := _jit(crng, 2.0, 2.6)
			var at := [Vector2(250.0, 130.0), Vector2(750.0, 130.0), Vector2(500.0, 330.0), Vector2(200.0, 540.0),
				Vector2(800.0, 540.0), Vector2(500.0, 740.0)]
			for k in at.size():
				movers.append({"pos": Vector2(at[k].x, y0 + at[k].y), "radius": 52.0, "kind": "bumper",
					"slide": Vector2(0.0, 55.0), "period": period, "phase": k * 0.17})
			h = 880.0
		"seesaws":
			# Seesaws tipping racers off one end, then the other.
			var period := _jit(crng, 2.6, 3.2)
			for row in 4:
				var ry := y0 + 110.0 + row * 230.0
				var xs := [260.0, 740.0] if row % 2 == 0 else [500.0]
				for j in xs.size():
					var c := Vector2(xs[j], ry)
					# Tipped a little one way on average, so a racer always rolls off.
					var tip := 12.0 if (row + j) % 2 == 0 else -12.0
					_rod_at(c, 150.0 if xs.size() == 1 else 120.0, tip, 17.0, _swinging(c, 0.35, period, (row + j) * 0.25))
			h = 4 * 230.0 + 60.0
		"pendulums":
			# Heavy pendulums swinging across the drop, out of step.
			var period := _jit(crng, 2.6, 3.1)
			var at := [Vector2(260.0, 30.0), Vector2(740.0, 30.0), Vector2(500.0, 330.0), Vector2(260.0, 630.0), Vector2(740.0, 630.0)]
			for k in at.size():
				var pivot := Vector2(at[k].x, y0 + at[k].y)
				var swing := _swinging(pivot, 0.45, period + k * 0.15, k * 0.29)
				_rod(pivot, pivot + Vector2(0.0, 230.0), 16.0, swing)
				movers.append({"pos": pivot + Vector2(0.0, 240.0), "radius": 40.0, "kind": "pillar", "group": _gid,
					"tint": info.get("tint", "")}.merged(swing))
			h = 960.0
		# --- The hazards -----------------------------------------------------------
		"wells":
			# Two wells, each with a moon circling it; a pickup between them.
			h = 640.0
			var wx := _jit(crng, 250.0, 290.0)
			for x in [wx, WIDTH - wx]:
				var c := Vector2(x, y0 + 300.0)
				wells.append({"pos": c, "reach": 230.0, "accel": WELL_ACCEL, "core": 40.0})
				movers.append({"pos": c + Vector2(0.0, -150.0), "radius": 38.0, "kind": "pillar", "pivot": c,
					"orbit": 0.8 if x < WIDTH / 2.0 else -0.8, "tint": info.get("tint", "")})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 300.0))
		"lava":
			# Lava pools down the sides, sliding bumpers knocking racers at them;
			# the safe middle has a heal.
			h = 640.0
			var edge := _jit(crng, 260.0, 300.0)
			floors.append({"kind": "lava", "pos": Vector2(edge / 2.0, y0 + 300.0), "radius": edge / 2.0 + 10.0})
			floors.append({"kind": "lava", "pos": Vector2(WIDTH - edge / 2.0, y0 + 470.0), "radius": edge / 2.0 + 10.0})
			var period := _jit(crng, 4.5, 5.0)
			movers.append({"pos": Vector2(500.0, y0 + 150.0), "radius": 40.0, "kind": "bumper", "slide": Vector2(220.0, 0.0), "period": period})
			movers.append({"pos": Vector2(500.0, y0 + 330.0), "radius": 40.0, "kind": "bumper", "slide": Vector2(-220.0, 0.0), "period": period})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 520.0), "heal")
		"goo":
			# Goo puddles with a sweeping bar ploughing through them.
			h = 620.0
			var gx := _jit(crng, 220.0, 290.0)
			for x in [gx, WIDTH - gx]:
				floors.append({"kind": "goo", "pos": Vector2(x, y0 + 220.0), "radius": 110.0, "slow": 0.0})
			floors.append({"kind": "goo", "pos": Vector2(WIDTH / 2.0, y0 + 430.0), "radius": 100.0, "slow": 0.0})
			var period := _jit(crng, 3.4, 4.0)
			_rod_at(Vector2(500.0, y0 + 110.0), 150.0, 8.0, 18.0, _sliding(Vector2(170.0, 0.0), period))
			_rod_at(Vector2(500.0, y0 + 330.0), 150.0, -8.0, 18.0, _sliding(Vector2(-170.0, 0.0), period))
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 220.0), "shield")
		"sliders":
			# Rows of bumpers sliding across, out of step with each other.
			h = 640.0
			var period := _jit(crng, 2.6, 3.4)
			for row in 3:
				for x in [WIDTH / 3.0, WIDTH * 2.0 / 3.0]:
					var phase := 1.0 if row % 2 == 0 else -1.0
					movers.append({"pos": Vector2(x, y0 + 110.0 + row * 180.0), "radius": 34.0, "kind": "bumper",
						"slide": Vector2(130.0 * phase, 0.0), "period": period + row * 0.4})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 200.0))
		# --- The machines, one per course -------------------------------------------
		"globe":
			# Gumdrop: a hopper over a great turning gumball globe. Racers wait
			# in the hopper till a gap comes round, tumble inside, and drop out
			# the bottom into the coin chute.
			_hopper(y0, 500.0, 150.0, 210.0, {"look": "cane"})
			var c := Vector2(500.0, y0 + 520.0)
			_ring(c, 270.0, 20.0, 0.75, 2, 0.62, -PI / 2.0)
			_hopper(y0 + 760.0, 500.0, 160.0, 230.0, {"look": "cane"})
			h = 1100.0
		"dipper":
			# Honey: a giant honey dipper turning in the middle of the shaft,
			# its ridges out of step so racers corkscrew down it, goo either side.
			for k in 7:
				var c := Vector2(500.0, y0 + 90.0 + k * 125.0)
				var half := 150.0 if k % 2 == 0 else 120.0
				_rod_at(c, half, k * 26.0, 16.0, _turning(c, 0.9))
			for k in 2:
				floors.append({"kind": "goo", "pos": Vector2(140.0 if k == 0 else 860.0, y0 + 300.0 + k * 300.0), "radius": 90.0, "slow": 0.0})
			h = 1000.0
		"sundial":
			# Sunstone: a stone sun disc with four great spokes turning across
			# the shaft, two little discs under it.
			var c := Vector2(500.0, y0 + 380.0)
			movers.append({"pos": c, "radius": 70.0, "kind": "pillar", "tint": "ffd76a"})
			var turn := _jit(crng, 0.0, 90.0)
			for k in 4:
				var a := deg_to_rad(turn + k * 90.0)
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				_rod(c + d * 80.0, c + d * 370.0, 20.0, _turning(c, 0.5))
			for x in [230.0, 770.0]:
				var cc := Vector2(x, y0 + 860.0)
				_rod_at(cc, 120.0, 0.0, 16.0, _turning(cc, 1.3 if x < 500.0 else -1.3))
			h = 1040.0
		"bridges":
			# Vine Ruins: rope bridges whose planks flip down one after another.
			var period := _jit(crng, 2.8, 3.2)
			for row in 3:
				var ry := y0 + 120.0 + row * 300.0
				for k in 4:
					# Each plank hangs 35 degrees down and swings 35 either way:
					# shut (flat, a gap too narrow to pass) to wide open.
					var hinge := Vector2(40.0 + k * 245.0, ry)
					var a := deg_to_rad(35.0)
					_rod(hinge, hinge + Vector2(DMath.cos(a), DMath.sin(a)) * 205.0, 14.0, _swinging(hinge, -0.6, period, k * 0.18 + row * 0.5))
			h = 3 * 300.0 + 160.0
		"orrery":
			# Nebula: planets on long arms round a central well, each at its own
			# speed.
			var c := Vector2(500.0, y0 + 420.0)
			wells.append({"pos": c, "reach": 200.0, "accel": WELL_ACCEL, "core": 40.0})
			var arms := [[130.0, 0.9, 34.0], [230.0, -0.65, 42.0], [330.0, 0.48, 48.0]]
			for k in arms.size():
				var arm: Array = arms[k]
				var a := _jit(crng, 0.0, TAU)
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				_rod(c + d * 40.0, c + d * arm[0], 8.0, _turning(c, arm[1]))
				movers.append({"pos": c + d * arm[0], "radius": arm[2], "kind": "pillar", "pivot": c, "orbit": arm[1], "tint": "ffd27a"})
			# Wormholes from the top corners to the far bottom ones.
			_portal(Vector2(130.0, y0 + 90.0), Vector2(WIDTH - 130.0, y0 + 820.0))
			_portal(Vector2(WIDTH - 130.0, y0 + 90.0), Vector2(130.0, y0 + 820.0))
			h = 900.0
		"tumbler":
			# Rock Belt: one huge lumpy asteroid turning slowly; racers sit in
			# its craters until they roll off.
			var c := Vector2(500.0, y0 + 420.0)
			var lumps := [[0.0, 150.0, 95.0], [1.1, 170.0, 80.0], [2.0, 140.0, 100.0], [3.0, 175.0, 75.0], [4.1, 150.0, 90.0], [5.2, 165.0, 80.0]]
			movers.append({"pos": c, "radius": 120.0, "kind": "pillar", "pivot": c, "orbit": 0.35, "tint": info.get("tint", "")})
			for l in lumps:
				var d := Vector2(DMath.cos(l[0]), DMath.sin(l[0]))
				movers.append({"pos": c + d * l[1], "radius": l[2], "kind": "pillar", "pivot": c, "orbit": 0.35, "tint": info.get("tint", "")})
			h = 900.0
		"kelpwave":
			# Kelp: tall stalks swaying as one wave, bubble columns lifting
			# racers back up between them.
			var period := _jit(crng, 3.0, 3.6)
			for row in 2:
				var base := y0 + 470.0 + row * 460.0
				for k in 4:
					var root := Vector2(200.0 + k * 200.0, base)
					_rod(root, root - Vector2(0.0, 330.0), 14.0, _swinging(root, 0.25, period, k * 0.12 + row * 0.5))
				for x in [300.0, 700.0]:
					_wind(Rect2(x - 30.0, base - 380.0, 60.0, 330.0), Vector2.UP, 600.0)
			h = 1000.0
		"doors":
			# Deep Trench: pressure doors sliding shut from both walls on one
			# beat, tilted in so racers roll to the slot.
			var period := _jit(crng, 2.8, 3.2)
			for k in 4:
				var y := y0 + 100.0 + k * 230.0
				var a := deg_to_rad(9.0)
				for side in [-1.0, 1.0]:
					var c := Vector2(500.0 + side * 350.0, y)
					var d := Vector2(DMath.cos(a) * side, -DMath.sin(a))
					_rod(c - d * 230.0, c + d * 230.0, 20.0, _sliding(Vector2(-side * 60.0, 0.0), period, k * 0.08))
			h = 4 * 230.0 + 120.0
		"blimps":
			# Cloud Hop: two big blimps drifting across, their propeller wash
			# blowing racers the way they go.
			var period := _jit(crng, 6.0, 7.0)
			for k in 2:
				var y := y0 + 200.0 + k * 400.0
				var dir := 1.0 if k == 0 else -1.0
				_rod_at(Vector2(500.0, y), 150.0, 0.0, 52.0, _sliding(Vector2(220.0 * dir, 0.0), period))
				_wind(Rect2(60.0, y + 90.0, WIDTH - 120.0, 90.0), Vector2.RIGHT * dir, 500.0, period / 2.0)
			h = 900.0
		"turbines":
			# Storm Front: three-bladed wind turbines, a gust band between.
			var at := [Vector2(290.0, 210.0), Vector2(710.0, 480.0), Vector2(290.0, 750.0)]
			for k in at.size():
				var c := Vector2(at[k].x, y0 + at[k].y)
				var s := 1.3 if k % 2 == 0 else -1.3
				var turn := _jit(crng, 0.0, 120.0)
				for b in 3:
					var a := deg_to_rad(turn + b * 120.0)
					_rod(c, c + Vector2(DMath.cos(a), DMath.sin(a)) * 170.0, 15.0, _turning(c, s))
			_wind(Rect2(0.0, y0 + 330.0, WIDTH, 70.0), Vector2.RIGHT, 650.0, 1.6)
			_wind(Rect2(0.0, y0 + 600.0, WIDTH, 70.0), Vector2.LEFT, 650.0, 1.6)
			h = 960.0
		"bobsled":
			# Icicle Run: icy bobsled chutes, each running into a swinging
			# paddle that sends racers into the next.
			var drop := 260.0
			for t in 3:
				var ty := y0 + 40.0 + t * drop
				var a := Vector2(0.0, ty)
				var c := Vector2(380.0, ty + drop * 0.3)
				var b := Vector2(WIDTH - 220.0, ty + drop * 0.55)
				var sw := 1.0
				if t % 2 == 1:
					a.x = WIDTH
					c.x = WIDTH - c.x
					b.x = WIDTH - b.x
					sw = -1.0
				# The last bend is a snow run-out, not ice: it brakes the field.
				_curve(a, c, b, {"ice": true, "look": "ice"} if t < 2 else {})
				var pivot := Vector2(WIDTH - 90.0 if t % 2 == 0 else 90.0, ty - 20.0)
				_rod(pivot, pivot + Vector2(0.0, 150.0), 14.0, _swinging(pivot, 0.5 * sw, 1.8, t * 0.3))
			h = 3 * drop + 160.0
		"pistons":
			# Crystal Cave: a row of crystal pistons pounding down in turn like
			# piano keys; slip under one on its way up.
			var period := _jit(crng, 2.2, 2.6)
			for row in 2:
				var y := y0 + 140.0 + row * 420.0
				for k in 5:
					var x := 110.0 + k * 195.0 + (90.0 if row == 1 and k < 4 else 0.0)
					if row == 1 and k == 4:
						continue
					_rod(Vector2(x, y - 90.0), Vector2(x, y + 90.0), 26.0, _sliding(Vector2(0.0, 80.0), period, k * 0.2))
			h = 900.0
		"lavalamp":
			# Lava Tubes: blobs drifting up the tube against the racers.
			var period := _jit(crng, 4.8, 5.4)
			var at := [Vector2(250.0, 300.0), Vector2(750.0, 420.0), Vector2(500.0, 620.0), Vector2(220.0, 820.0), Vector2(780.0, 900.0)]
			for k in at.size():
				movers.append({"pos": Vector2(at[k].x, y0 + at[k].y), "radius": 62.0 - k * 3.0, "kind": "pillar",
					"slide": Vector2(0.0, 230.0), "period": period + k * 0.3, "phase": k * 0.23, "tint": "ff9f40"})
			h = 1160.0
		"traffic":
			# Sunset Strip: neon cars zooming across five lanes.
			var period := _jit(crng, 6.2, 7.0)
			for k in 5:
				var y := y0 + 100.0 + k * 170.0
				var dir := 1.0 if k % 2 == 0 else -1.0
				_rod_at(Vector2(500.0, y), 70.0, 0.0, 26.0, _sliding(Vector2(300.0 * dir, 0.0), period, k * 0.17))
			h = 5 * 170.0 + 80.0
		"shuffle":
			# Glitch Grid: a block field that flickers between two layouts
			# every couple of seconds.
			for row in 5:
				var y := y0 + 100.0 + row * 170.0
				for layout in 2:
					var xs := [200.0, 500.0, 800.0] if (row + layout) % 2 == 0 else [350.0, 650.0]
					for x in xs:
						movers.append({"pos": Vector2(x, y + layout * 40.0), "radius": 46.0, "kind": "pillar",
							"blink": 2.0, "blink_at": layout * 2.0, "tint": info.get("tint", "")})
			h = 5 * 170.0 + 100.0
		"sandworm":
			# Dune Slide: two sandworms sweeping across the slope in an S.
			var period := _jit(crng, 6.2, 6.8)
			for w in 2:
				var y := y0 + 250.0 + w * 450.0
				var dir := 1.0 if w == 0 else -1.0
				_gid += 1
				for k in 9:
					var x := 500.0 - dir * (k - 4) * 50.0
					movers.append({"pos": Vector2(x, y + 50.0 * DMath.sin(k * 0.8)), "radius": 46.0 - absf(k - 2) * 2.5, "kind": "pillar",
						"slide": Vector2(180.0 * dir, 0.0), "period": period, "phase": -k * 0.04, "group": _gid, "tint": "c9924d"})
			h = 1000.0
		"trapdoors":
			# Grave Drop: rows of coffin lids that flip open on a beat, a row
			# opening while the one below shuts.
			var period := _jit(crng, 3.0, 3.4)
			for row in 3:
				var ry := y0 + 100.0 + row * 300.0
				for pair in [[30.0, 1.0], [470.0, -1.0], [530.0, 1.0], [970.0, -1.0]]:
					var hinge := Vector2(pair[0], ry)
					var a := deg_to_rad(40.0)
					var dir: float = pair[1]
					var tip := hinge + Vector2(DMath.cos(a) * dir, DMath.sin(a)) * 210.0
					_rod(hinge, tip, 14.0, _swinging(hinge, -0.7 * dir, period, row * 0.5))
				if row < 2: # Thorns between the coffins snap out and back.
					movers.append({"pos": Vector2(500.0, ry + 170.0), "radius": 26.0, "kind": "spike", "retract": 1.4})
			h = 3 * 300.0 + 180.0
		"stairs":
			# Haunted Stairs: flights of stairs shifting between landings, and
			# the clock's pendulum in the middle.
			var period := _jit(crng, 4.0, 4.6)
			for k in 4:
				var c := Vector2(500.0, y0 + 120.0 + k * 230.0)
				_rod_at(c, 190.0, 25.0 if k % 2 == 0 else -25.0, 17.0, _sliding(Vector2(170.0 * (1.0 if k % 2 == 0 else -1.0), 0.0), period, k * 0.25))
			h = 4 * 230.0 + 100.0
		"scoops":
			# Toy Chest: a scoop wheel. A hopper drops racers into the middle;
			# cups at the bottom scoop them up and tip them out on the way round.
			_hopper(y0, 500.0, 170.0, 200.0)
			var c := Vector2(500.0, y0 + 600.0)
			movers.append({"pos": c, "radius": 46.0, "kind": "bumper", "tint": "ffcf4d"})
			for k in 6:
				var a := TAU * k / 6.0
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				var side := Vector2(-d.y, d.x)
				var rim := c + d * 260.0
				_rod(c + d * 60.0, rim, 7.0, _turning(c, 0.5))
				# A cup opening toward the hub: a back on the rim and two sides.
				_chain([rim - side * 55.0 - d * 70.0, rim - side * 55.0, rim + side * 55.0, rim + side * 55.0 - d * 70.0], 12.0, _turning(c, 0.5))
			h = 1000.0
		"plunger":
			# Pinball: a lane rolls racers off onto a big spring pad that fires
			# them back up past the spinners; flippers at the bottom.
			_seg(Vector2(0.0, y0 + 40.0), Vector2(500.0, y0 + 200.0))
			floors.append({"kind": "launch", "pos": Vector2(760.0, y0 + 400.0), "radius": 90.0, "kick": Vector2(-450.0, -850.0)})
			for at in [Vector2(250.0, 360.0), Vector2(520.0, 560.0), Vector2(800.0, 640.0)]:
				var cc := Vector2(at.x, y0 + at.y)
				_rod_at(cc, 80.0, 0.0, 15.0, _turning(cc, 2.1))
			var period := _jit(crng, 1.5, 1.8)
			var fy := y0 + 900.0
			_seg(Vector2(0.0, fy - 120.0), Vector2(250.0, fy))
			_seg(Vector2(WIDTH, fy - 120.0), Vector2(WIDTH - 250.0, fy))
			_rod(Vector2(250.0, fy), Vector2(410.0, fy + 60.0), 14.0, _swinging(Vector2(250.0, fy), 0.45, period, 0.0))
			_rod(Vector2(WIDTH - 250.0, fy), Vector2(WIDTH - 410.0, fy + 60.0), 14.0, _swinging(Vector2(WIDTH - 250.0, fy), -0.45, period, 0.0))
			h = 1060.0
		# --- The static set pieces -------------------------------------------------
		"funnels":
			# Curved funnels: one wall-to-wall funnel, then two side by side
			# round a peak, each with a racer-wide mouth.
			var ya := y0 + 60.0
			_curve(Vector2(0.0, ya), Vector2(260.0, ya + 40.0), Vector2(440.0, ya + 200.0), SET)
			_curve(Vector2(WIDTH, ya), Vector2(WIDTH - 260.0, ya + 40.0), Vector2(WIDTH - 440.0, ya + 200.0), SET)
			var yb := ya + 430.0
			_curve(Vector2(0.0, yb), Vector2(120.0, yb + 30.0), Vector2(190.0, yb + 170.0), SET)
			_curve(Vector2(WIDTH, yb), Vector2(WIDTH - 120.0, yb + 30.0), Vector2(WIDTH - 190.0, yb + 170.0), SET)
			_curve(Vector2(310.0, yb + 170.0), Vector2(400.0, yb + 10.0), Vector2(500.0, yb), SET)
			_curve(Vector2(500.0, yb), Vector2(600.0, yb + 10.0), Vector2(690.0, yb + 170.0), SET)
			h = 430.0 + 300.0
		"poppers":
			# Big pop bumpers in a honeycomb: racers ricochet between them.
			for row in 4:
				var ry := y0 + 110.0 + row * 185.0
				var xs := [250.0, 500.0, 750.0] if row % 2 == 0 else [375.0, 625.0]
				for x in xs:
					_peg(x + _jit(crng, -20.0, 20.0), ry, _jit(crng, 44.0, 54.0), true)
			h = 4 * 185.0 + 80.0
		"hooks":
			# Hook slides from alternate walls: a steep drop that levels out
			# and throws racers off its end across the shaft.
			for k in 3:
				var hy := y0 + 40.0 + k * 380.0
				var left := k % 2 == 0
				var a := Vector2(0.0 if left else WIDTH, hy)
				var c := Vector2(150.0 if left else WIDTH - 150.0, hy + 260.0)
				var b := Vector2(540.0 if left else WIDTH - 540.0, hy + 250.0)
				_curve(a, c, b, SET)
			h = 3 * 380.0 + 200.0
		"lanes":
			# Three lanes split by two walls, each lane with its own bumpers
			# zigzagging down it: which lane you drop into is your race.
			var top := y0 + 80.0
			var deep := 720.0
			for x in [WIDTH / 3.0, 2.0 * WIDTH / 3.0]:
				_seg(Vector2(x, top), Vector2(x, top + deep), SET)
			for lane in 3:
				var lx := lane * WIDTH / 3.0
				for k in 4:
					var x := lx + (75.0 if (k + lane) % 2 == 0 else WIDTH / 3.0 - 75.0)
					_peg(x, top + 110.0 + k * 160.0, 30.0, true)
			h = 80.0 + deep + 80.0
		"gems":
			# Big cut gems: diamonds racers glance off, two then one then two.
			var rad := 95.0
			for row in 3:
				var gy := y0 + 140.0 + row * 270.0
				var xs := [260.0, 740.0] if row % 2 == 0 else [500.0]
				for x in xs:
					var c := Vector2(x, gy)
					var pts := [c + Vector2(0.0, -rad), c + Vector2(rad, 0.0), c + Vector2(0.0, rad), c + Vector2(-rad, 0.0)]
					for q in 4:
						_seg(pts[q], pts[(q + 1) % 4], SET)
			h = 3 * 270.0 + 80.0
		"roofs":
			# Rooftops: peaked roofs in staggered rows; racers slide off the
			# eaves onto the next.
			for row in 4:
				var ry := y0 + 60.0 + row * 220.0
				var xs := [270.0, 730.0] if row % 2 == 0 else [500.0]
				for x in xs:
					var apex := Vector2(x, ry)
					_seg(apex, apex + Vector2(-130.0, 95.0), SET)
					_seg(apex, apex + Vector2(130.0, 95.0), SET)
			h = 4 * 220.0 + 60.0
	sections.append({"kind": kind, "y0": y0, "y1": y0 + h})
	return y0 + h


## A pickup at `at`: `kind`, or a power core, heal or shield by the seed.
func _pickup(crng: Rng, at: Vector2, kind := "") -> void:
	if kind == "":
		kind = ["core", "core", "heal", "shield"][crng.range_int(0, 3)]
	cores.append({"pos": at, "radius": PICKUP_R, "kind": kind})
