## A Critter Plunge course: pegs, bumpers and ramps down a 1000-wide shaft,
## plus the collisions racers have with it. There are 20 courses (COURSES),
## each a fixed run of sections in one arena's painted look, built round its
## own set piece (a gumball spiral, a honeycomb, swinging vines, a pinball
## table...); the seed picks the course and varies each section's details.
## The race itself is sim/plunge.gd.
##
## Besides pegs and ramps (curved ones are runs of short ramps), sections
## lay down the arenas' own moving parts and pads, which the race runs:
## spinning, swinging and sliding bars and rocks (`movers`), wind and
## current bands, one-way portals and launch pads (`floors`), gravity wells
## and pickups. Ramps can be icy (no grip, they speed you up) or belts (they
## push you along).
##
## Course rules that keep the start fair: half-bumpers on the walls kick
## racers back in (a clear gutter let wall gates free-fall), peg rows are
## centred, and the seed mirrors each middle section. Nothing lets a racer
## skip course pieces (a peg-phasing shield won 2.4x its share).
##
## Only +, *, sqrt and sim/rng.gd, so every platform agrees.
extends RefCounted

const Rng := preload("res://sim/rng.gd")

const WIDTH := 1000.0
const START_Y := 90.0
const CELL := 100.0 ## Collision grid cell size; more than a racer's reach.
const RAMP_THICK := 6.0
const CLEAR := 100.0 ## Peg rows keep this far from the walls.
const KICKER_R := 34.0 ## The half-bumpers on the walls, one each side per peg row.
const WALL_BOUNCE := 0.55
const PEG_BOUNCE := 0.6
const RAMP_BOUNCE := 0.25
const RAMP_GRIP := 0.12
const BUMPER_KICK := 620.0 ## Minimum speed a bumper sends you away at.
## Below this speed into a ramp, a racer settles onto it instead of bouncing,
## so a roll is a smooth roll.
const REST_SPEED := 90.0
const SECTIONS := ["pegs", "bumpers", "wells", "lava", "goo", "sliders", "spiral", "canes", "comb", "flow",
	"highway", "train", "stair", "sundisc", "vines", "stumps", "orbits", "warps", "asteroids", "kelp", "currents",
	"trench", "trampolines", "gusts", "slalom", "mirrors", "spinners", "tubes", "blocks", "dunes", "tombs",
	"staircase", "bookcase", "tops", "jacks", "pops", "flippers"]
## The hazard sections, one per course, in the arenas' own pieces: gravity
## wells, lava, goo and sliding bumpers. Each holds a pickup too (a power
## core, heal or shield). sim/plunge.gd runs them.
const HAZARDS := ["wells", "lava", "goo", "sliders"]
const WELL_ACCEL := 700.0 ## Under gravity even at full pull, so a well bends a drop but never holds it.
const GOO_DRAG := 2.2 ## Extra drag per second in goo.
const PICKUP_R := 34.0
## Open sections (set pieces racers mostly fall past) end on a ledge.
const LEDGED := ["tombs", "vines", "stumps", "orbits", "warps", "asteroids", "kelp", "currents", "gusts", "spinners",
	"sundisc", "bookcase", "tops", "jacks", "pops"]
const LEDGE_SLOPE := 0.24
const ICE_ACCEL := 320.0
const BELT_TOP := 300.0 ## Belts push racers along up to this speed. ## How hard an icy ramp speeds a racer along it.
## Movers stay under this speed where they bat racers (the arenas' rule: a
## part bats balls around but never pins one).
const MOVER_SPEED := 340.0

## Every course: its name, the arena whose painted look it wears (`art`, a
## map id in game/arena_art.gd; the race never reads it) and the sections
## under the short peg field below the gate.
const COURSES := [
	{"id": "gumdrop", "name": "Gumdrop Drop", "art": "candy", "plan": ["spiral", "canes", "goo", "spiral", "canes"]},
	{"id": "honey", "name": "Honey Chute", "art": "hive", "plan": ["comb", "flow", "goo", "comb"]},
	{"id": "sunstone", "name": "Sunstone Steps", "art": "temple", "plan": ["stair", "sundisc", "sliders"]},
	{"id": "vines", "name": "Vine Ruins", "art": "ruins", "plan": ["vines", "stumps", "sliders", "vines", "stumps"]},
	{"id": "nebula", "name": "Nebula Fall", "art": "nebula", "plan": ["orbits", "warps", "wells", "orbits", "warps"]},
	{"id": "rocks", "name": "Rock Belt", "art": "asteroid", "plan": ["asteroids", "bumpers", "wells", "asteroids", "bumpers"]},
	{"id": "kelp", "name": "Kelp Forest", "art": "kelp", "plan": ["kelp", "currents", "wells", "kelp", "currents"]},
	{"id": "trench", "name": "Deep Trench", "art": "trench", "plan": ["trench", "wells", "trench", "bumpers"]},
	{"id": "clouds", "name": "Cloud Hop", "art": "cloud", "plan": ["trampolines", "sliders", "currents", "trampolines"]},
	{"id": "storm", "name": "Storm Front", "art": "storm", "plan": ["gusts", "bumpers", "wells", "gusts", "bumpers"]},
	{"id": "icicles", "name": "Icicle Run", "art": "frost", "plan": ["slalom", "goo", "mirrors"]},
	{"id": "crystal", "name": "Crystal Cave", "art": "prism", "plan": ["mirrors", "spinners", "sliders", "mirrors", "spinners"]},
	{"id": "lava", "name": "Lava Tubes", "art": "magma", "plan": ["tubes", "lava", "bumpers"]},
	{"id": "sunset", "name": "Sunset Strip", "art": "sunset", "plan": ["highway", "sliders", "highway"]},
	{"id": "glitch", "name": "Glitch Grid", "art": "glitch", "plan": ["blocks", "warps", "lava", "blocks", "warps"]},
	{"id": "dunes", "name": "Dune Slide", "art": "dunes", "plan": ["dunes", "goo", "stumps", "dunes"]},
	{"id": "graves", "name": "Grave Drop", "art": "graveyard", "plan": ["tombs", "goo", "tombs", "bookcase", "tombs"]},
	{"id": "manor", "name": "Haunted Stairs", "art": "manor", "plan": ["staircase", "bookcase", "wells", "staircase", "bookcase"]},
	{"id": "toys", "name": "Toy Chest", "art": "toybox", "plan": ["train", "tops", "sliders", "jacks"]},
	{"id": "pinball", "name": "Pinball Plunge", "art": "pinball", "plan": ["pops", "flippers", "sliders", "pops", "flippers"]},
]

var pegs: Array = [] ## [{pos, r, bumper}]
var ramps: Array = [] ## [{a, b}] solid line segments, RAMP_THICK wide.
var sections: Array = [] ## [{kind, y0, y1}] for the renderer.
var finish_y := 0.0
var floors: Array = [] ## Arena floor pads: {kind "goo" or "lava", pos, radius}.
var wells: Array = [] ## Arena gravity wells: {pos, reach, accel, core}.
var cores: Array = [] ## Arena pickups: {pos, radius, kind "core" / "heal" / "shield"}.
var movers: Array = [] ## Moving parts, as arena obstacles (sim/arenas.gd): {pos, radius, kind, slide/period,
## orbit/pivot, bar/angle}, or `swing` (radians either way round `pivot`, over `period`, from `phase`).
var info: Dictionary ## This course's COURSES entry.

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
	var reach: float = r.radius + RAMP_THICK
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
	if s.has("ice") or s.has("belt"):
		hit.ramp = s # The race's Frost talent reads it.
	if s.has("ice"):
		r.vel += s.down * ICE_ACCEL * dt
	else:
		var tangent: Vector2 = r.vel - n * r.vel.dot(n)
		r.vel -= tangent * minf(1.0, RAMP_GRIP * dt)
	if s.has("belt") and r.vel.dot(s.down) < BELT_TOP:
		r.vel += s.down * s.belt * dt


# --- Building ------------------------------------------------------------------

## A short peg field under the gate (it spreads the field fairly), then the
## course's sections, each mirrored left-right on a coin flip.
func _build(crng: Rng) -> void:
	var y := START_Y + 120.0
	y = _section(crng, "pegs", y)
	for kind in info.plan:
		var at := [pegs.size(), ramps.size(), floors.size(), wells.size(), cores.size(), movers.size()]
		y = _section(crng, kind, y)
		if crng.range_int(0, 1) == 1:
			_mirror(at)
	finish_y = y + 80.0
	for i in pegs.size():
		var p: Dictionary = pegs[i]
		_bucket(i, p.pos - Vector2.ONE * p.r, p.pos + Vector2.ONE * p.r)
		_peg_pos.append(p.pos)
		_peg_r.append(p.r)
	for i in ramps.size():
		var s: Dictionary = ramps[i]
		if s.has("ice") or s.has("belt"):
			var d: Vector2 = s.b - s.a
			if d.y < 0.0:
				d = -d
			s.down = d / d.length()
		_bucket(-i - 1, Vector2(minf(s.a.x, s.b.x), minf(s.a.y, s.b.y)) - Vector2.ONE * RAMP_THICK, Vector2(maxf(s.a.x, s.b.x), maxf(s.a.y, s.b.y)) + Vector2.ONE * RAMP_THICK)
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


## The half-bumpers on both walls at `y`.
func _kickers(y: float) -> void:
	_peg(0.0, y, KICKER_R, true)
	_peg(WIDTH, y, KICKER_R, true)


## A row of pegs `gap` apart between `lo` and `hi`, centred between them so
## both sides get the same gap; `half` rows sit half a gap over.
func _peg_row(lo: float, hi: float, y: float, gap: float, half: bool) -> void:
	var c := (lo + hi) / 2.0
	var m := 0.5 if half else 0.0
	var q := -int((hi - lo) / gap) - 1
	while q <= int((hi - lo) / gap) + 1:
		var x := c + (q + m) * gap
		if x >= lo and x <= hi:
			_peg(x, y)
		q += 1


func _ramp(ax: float, ay: float, bx: float, by: float) -> void:
	ramps.append({"a": Vector2(ax, ay), "b": Vector2(bx, by)})


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


## A closed shape of ramps through `pts`.
func _shape(pts: Array, extra := {}) -> void:
	for k in pts.size():
		_seg(pts[k], pts[(k + 1) % pts.size()], extra)


## A bar `half` long either side of `pos` at `angle` degrees, `radius` thick.
func _bar(pos: Vector2, half: float, angle: float, radius: float, extra: Dictionary) -> void:
	var o := {"pos": pos, "bar": half, "angle": angle, "radius": radius, "kind": "pillar"}
	o.merge(extra, true)
	movers.append(o)


## A pendulum hanging `length` from `pivot`, swinging `swing` radians either way.
func _pendulum(pivot: Vector2, length: float, radius: float, swing: float, period: float, phase: float) -> void:
	_bar(pivot + Vector2(0.0, length / 2.0), length / 2.0, 90.0, radius,
		{"pivot": pivot, "swing": swing, "period": period, "phase": phase, "slide": Vector2.ZERO})


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


## Ramps that switch back and forth from the walls (`turns` of them, `drop`
## apart), each reaching `reach` across and falling `fall` of `drop`.
func _switchbacks(y0: float, turns: int, drop: float, reach: float, fall: float, extra := {}) -> void:
	for t in turns:
		var ty := y0 + 40.0 + t * drop
		if t % 2 == 0:
			_seg(Vector2(0.0, ty), Vector2(reach, ty + drop * fall), extra)
		else:
			_seg(Vector2(WIDTH, ty), Vector2(WIDTH - reach, ty + drop * fall), extra)


## Adds one section starting at `y0` and returns where the next one starts.
func _section(crng: Rng, kind: String, y0: float) -> float:
	var h := 0.0
	match kind:
		"pegs":
			# Staggered rows, with a half-bumper on each wall per row.
			var rows := crng.range_int(5, 6)
			var gap := float(crng.range_int(110, 130))
			for row in rows:
				var ry := y0 + 40.0 + row * 96.0
				_peg_row(CLEAR, WIDTH - CLEAR, ry, gap, row % 2 == 1)
				_kickers(ry)
			h = rows * 96.0 + 40.0
			# A lip off each wall turns the outside lanes in, so no gate can
			# fall past whatever the first section starts with.
			_ramp(0.0, y0 + h + 30.0, 250.0, y0 + h + 120.0)
			_ramp(WIDTH, y0 + h + 30.0, WIDTH - 250.0, y0 + h + 120.0)
			h += 160.0
		"bumpers":
			# A garden of bumpers that fling racers about.
			var count := crng.range_int(5, 7)
			var placed: Array[Vector2] = []
			var tries := 0
			h = 640.0
			while placed.size() < count and tries < 200:
				tries += 1
				var p := Vector2(crng.range_int(110, 890), y0 + crng.range_int(90, int(h) - 90))
				if placed.all(func(q): return q.distance_to(p) >= 210.0):
					placed.append(p)
					_peg(p.x, p.y, 36.0, true)
		"wells":
			# Two wells either side of the drop, a pickup between them.
			h = 600.0
			var wx := float(crng.range_int(260, 300))
			var reach := float(crng.range_int(220, 250))
			for x in [wx, WIDTH - wx]:
				wells.append({"pos": Vector2(x, y0 + 260.0), "reach": reach, "accel": WELL_ACCEL, "core": 40.0})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 260.0))
			_peg_row(CLEAR, WIDTH - CLEAR, y0 + h - 70.0, 120.0, false)
		"lava":
			# Lava pools down the sides under a peg row that scatters racers
			# into them; the safe middle has a heal.
			h = 560.0
			var edge := float(crng.range_int(290, 330))
			_peg_row(CLEAR, WIDTH - CLEAR, y0 + 50.0, 115.0, false)
			_peg_row(CLEAR, WIDTH - CLEAR, y0 + 140.0, 115.0, true)
			# One pool each side, staggered, never stacked.
			floors.append({"kind": "lava", "pos": Vector2(edge / 2.0, y0 + 270.0), "radius": edge / 2.0 + 10.0})
			floors.append({"kind": "lava", "pos": Vector2(WIDTH - edge / 2.0, y0 + 420.0), "radius": edge / 2.0 + 10.0})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 400.0), "heal")
		"goo":
			# Peg rows over goo puddles, in mirrored pairs: pick a lucky lane.
			h = 560.0
			for row in 4:
				_peg_row(CLEAR, WIDTH - CLEAR, y0 + 60.0 + row * 120.0, 125.0, row % 2 == 1)
			var gx := float(crng.range_int(200, 300))
			var gy := y0 + float(crng.range_int(230, 260))
			for x in [gx, WIDTH - gx]:
				floors.append({"kind": "goo", "pos": Vector2(x, gy), "radius": 105.0, "slow": 0.0})
			floors.append({"kind": "goo", "pos": Vector2(WIDTH / 2.0, gy + 200.0), "radius": 95.0, "slow": 0.0})
			_pickup(crng, Vector2(WIDTH / 2.0, gy), "shield")
		"sliders":
			# Rows of bumpers sliding across, out of step with each other.
			h = 620.0
			var period := float(crng.range_int(26, 34)) / 10.0
			for row in 3:
				for x in [WIDTH / 3.0, WIDTH * 2.0 / 3.0]:
					var phase := 1.0 if row % 2 == 0 else -1.0
					movers.append({"pos": Vector2(x, y0 + 110.0 + row * 180.0), "radius": 34.0, "kind": "bumper",
						"slide": Vector2(130.0 * phase, 0.0), "period": period + row * 0.4})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 200.0))
		"spiral":
			# Gumdrop: curved shelves winding down round a column of gumball
			# jars, each shelf tipping racers past the next jar.
			var drop := 175.0
			for t in 4:
				var ty := y0 + 40.0 + t * drop
				var a := Vector2(0.0, ty)
				var b := Vector2(360.0, ty + 150.0)
				var c := Vector2(180.0, ty + 45.0)
				if t % 2 == 1:
					a.x = WIDTH
					b.x = WIDTH - b.x
					c.x = WIDTH - c.x
				_curve(a, c, b, {"look": "cane"})
				_peg(WIDTH / 2.0, ty + 165.0, 55.0)
			h = 4 * drop + 160.0
		"canes":
			# Candy canes: short slanted bars in staggered rows, a racer-wide
			# gap between one row's ends and the next's.
			for row in 5:
				var ry := y0 + 60.0 + row * 130.0
				var xs := [200.0, 500.0, 800.0] if row % 2 == 0 else [350.0, 650.0]
				for k in xs.size():
					var tilt := Vector2(48.0, 34.0) if (row + k) % 2 == 0 else Vector2(48.0, -34.0)
					_seg(Vector2(xs[k], ry) - tilt, Vector2(xs[k], ry) + tilt, {"look": "cane"})
				if row % 2 == 1:
					_kickers(ry)
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 255.0))
			h = 5 * 130.0 + 60.0
		"comb":
			# Honeycomb: solid hex cells in a honeycomb, racers rattling down
			# the gaps between them.
			for row in 4:
				var ry := y0 + 50.0 + row * 190.0
				var xs := [60.0, 280.0, 500.0, 720.0, 940.0] if row % 2 == 0 else [170.0, 390.0, 610.0, 830.0]
				for cx in xs:
					_shape([Vector2(cx, ry), Vector2(cx + 60.0, ry + 35.0), Vector2(cx + 60.0, ry + 105.0),
						Vector2(cx, ry + 140.0), Vector2(cx - 60.0, ry + 105.0), Vector2(cx - 60.0, ry + 35.0)], {"look": "comb"})
				if row % 2 == 1:
					_kickers(ry + 70.0)
				else:
					# The wall cells' tops slope into the wall: a kicker there
					# so nobody comes to rest in the corner.
					_kickers(ry)
			h = 4 * 190.0 + 40.0
		"flow":
			# Honey flows: switchback belts that carry racers along.
			_switchbacks(y0, 3, 160.0, WIDTH - 180.0, 0.65, {"belt": 330.0, "look": "belt"})
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 250.0), "heal")
			h = 3 * 160.0 + 120.0
		"highway":
			# The strip: long gentle switchbacks, fast belts, and a jump pad
			# off one road onto the next.
			_switchbacks(y0, 3, 200.0, WIDTH - 170.0, 0.7, {"belt": 360.0, "look": "belt"})
			_pad(Vector2(120.0, y0 + 40.0 + 200.0 + 120.0 + 70.0), Vector2(560.0, -140.0))
			h = 3 * 200.0 + 120.0
		"train":
			# The toy train: belts down switchback tracks.
			_switchbacks(y0, 3, 170.0, WIDTH - 180.0, 0.65, {"belt": 420.0, "look": "belt"})
			h = 3 * 170.0 + 120.0
		"stair":
			# The temple's grand stair: full-width steps, each with its gap
			# somewhere else.
			var gaps := [260.0, 740.0, 400.0, 600.0]
			for t in 4:
				var ty := y0 + 40.0 + t * 165.0
				var gx: float = gaps[t]
				_seg(Vector2(0.0, ty), Vector2(gx - 95.0, ty + 110.0), {"look": "stone"})
				_seg(Vector2(WIDTH, ty), Vector2(gx + 95.0, ty + 110.0), {"look": "stone"})
			h = 4 * 165.0 + 100.0
		"sundisc":
			# A great sun disc spinning in the middle, two small ones under it.
			_bar(Vector2(WIDTH / 2.0, y0 + 260.0), 190.0, 0.0, 18.0, {"orbit": 1.0})
			_bar(Vector2(190.0, y0 + 490.0), 80.0, 0.0, 16.0, {"orbit": -1.5})
			_bar(Vector2(WIDTH - 190.0, y0 + 490.0), 80.0, 0.0, 16.0, {"orbit": 1.5})
			_kickers(y0 + 260.0)
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 490.0))
			h = 620.0
		"vines":
			# Vines swinging across the drop, out of step with each other.
			_pendulum(Vector2(300.0, y0 + 30.0), 230.0, 15.0, 0.42, 2.6, 0.0)
			_pendulum(Vector2(700.0, y0 + 30.0), 230.0, 15.0, 0.42, 3.0, 0.5)
			_pendulum(Vector2(500.0, y0 + 340.0), 230.0, 15.0, 0.42, 2.8, 0.25)
			_kickers(y0 + 150.0)
			_kickers(y0 + 460.0)
			h = 640.0
		"stumps":
			# Fat pillar stumps, far apart: big shapes, not little pegs.
			var placed: Array[Vector2] = []
			var tries := 0
			h = 620.0
			while placed.size() < 5 and tries < 300:
				tries += 1
				var r := float(crng.range_int(48, 58))
				var p := Vector2(crng.range_int(int(r) + 70, int(WIDTH - r) - 70), y0 + crng.range_int(90, int(h) - 90))
				if placed.all(func(q): return q.distance_to(p) >= 240.0):
					placed.append(p)
					_peg(p.x, p.y, r)
			_kickers(y0 + 200.0)
			_kickers(y0 + 420.0)
		"orbits":
			# Planetoids circling one big well.
			var hub := Vector2(WIDTH / 2.0, y0 + 300.0)
			wells.append({"pos": hub, "reach": 320.0, "accel": WELL_ACCEL, "core": 40.0})
			for k in 3:
				var at: Vector2 = hub + [Vector2(190.0, 0.0), Vector2(-95.0, 164.5), Vector2(-95.0, -164.5)][k]
				movers.append({"pos": at, "radius": 42.0, "kind": "pillar", "orbit": 0.6, "pivot": hub})
			_kickers(y0 + 150.0)
			_kickers(y0 + 450.0)
			h = 640.0
		"warps":
			# Portals that warp racers across the shaft, between peg rows.
			for row in 3:
				_peg_row(CLEAR, WIDTH - CLEAR, y0 + 50.0 + row * 210.0, 125.0, row % 2 == 1)
				_kickers(y0 + 50.0 + row * 210.0)
			_portal(Vector2(230.0, y0 + 150.0), Vector2(WIDTH - 230.0, y0 + 360.0))
			_portal(Vector2(WIDTH - 230.0, y0 + 150.0), Vector2(230.0, y0 + 360.0))
			h = 560.0
		"asteroids":
			# Big rocks drifting slowly across, at their own speeds.
			for k in 6:
				var r := float(crng.range_int(40, 60))
				var x := float(crng.range_int(330, 670))
				var amp := minf(float(crng.range_int(170, 250)), minf(x - r - 70.0, WIDTH - x - r - 70.0))
				movers.append({"pos": Vector2(x, y0 + 80.0 + k * 105.0), "radius": r, "kind": "pillar",
					"slide": Vector2(amp if k % 2 == 0 else -amp, 0.0), "period": float(crng.range_int(40, 70)) / 10.0})
			_kickers(y0 + 200.0)
			_kickers(y0 + 500.0)
			h = 720.0
		"kelp":
			# Kelp stalks swaying side to side.
			for k in 3:
				_bar(Vector2(250.0 + k * 250.0, y0 + 220.0), 160.0, 90.0, 14.0,
					{"slide": Vector2(70.0 if k % 2 == 0 else -70.0, 0.0), "period": 3.2 + k * 0.4})
			for k in 2:
				_bar(Vector2(375.0 + k * 250.0, y0 + 590.0), 150.0, 90.0, 14.0,
					{"slide": Vector2(-70.0 if k == 0 else 70.0, 0.0), "period": 3.6 + k * 0.4})
			_kickers(y0 + 220.0)
			_kickers(y0 + 590.0)
			h = 780.0
		"currents":
			# Upward currents either side: floaty, slow-motion lanes, a quick
			# middle between them.
			_wind(Rect2(120.0, y0 + 40.0, 230.0, 520.0), Vector2.UP, 520.0)
			_wind(Rect2(WIDTH - 350.0, y0 + 40.0, 230.0, 520.0), Vector2.UP, 520.0)
			for k in 4:
				_peg(WIDTH / 2.0 + (40.0 if k % 2 == 0 else -40.0), y0 + 90.0 + k * 130.0)
			_kickers(y0 + 300.0)
			_pickup(crng, Vector2(235.0, y0 + 300.0))
			h = 600.0
		"trench":
			# The long dark shaft: a funnel into a narrow trench with
			# currents pushing across it.
			h = 1000.0
			_ramp(0.0, y0, 300.0, y0 + 180.0)
			_ramp(WIDTH, y0, WIDTH - 300.0, y0 + 180.0)
			_ramp(300.0, y0 + 180.0, 300.0, y0 + h - 60.0)
			_ramp(WIDTH - 300.0, y0 + 180.0, WIDTH - 300.0, y0 + h - 60.0)
			for k in 3:
				var by := y0 + 260.0 + k * 230.0
				_wind(Rect2(306.0, by, WIDTH - 612.0, 110.0), Vector2.RIGHT if k % 2 == 0 else Vector2.LEFT, 650.0, 1.8)
				if k % 2 == 0:
					_seg(Vector2(300.0, by + 140.0), Vector2(520.0, by + 200.0), {"look": "stone"})
				else:
					_seg(Vector2(WIDTH - 300.0, by + 140.0), Vector2(WIDTH - 520.0, by + 200.0), {"look": "stone"})
		"trampolines":
			# Cloud trampolines: puffy cups with a launch pad in the middle.
			var rows := [[270.0, 730.0], [500.0], [270.0, 730.0]]
			for row in 3:
				var ry := y0 + 80.0 + row * 230.0
				for x in rows[row]:
					_seg(Vector2(x - 130.0, ry), Vector2(x - 45.0, ry + 60.0), {"look": "cloud"})
					_seg(Vector2(x + 130.0, ry), Vector2(x + 45.0, ry + 60.0), {"look": "cloud"})
					var side := 1.0 if x < WIDTH / 2.0 else -1.0
					if x == WIDTH / 2.0:
						side = 1.0 if crng.range_int(0, 1) == 0 else -1.0
					_pad(Vector2(x, ry + 50.0), Vector2(260.0 * side, -720.0))
				_kickers(ry + 30.0)
			h = 3 * 230.0 + 100.0
		"gusts":
			# Gust bands that blow the field one way, then the other.
			for k in 3:
				var by := y0 + 50.0 + k * 210.0
				_wind(Rect2(0.0, by, WIDTH, 110.0), Vector2.RIGHT if k % 2 == 0 else Vector2.LEFT, 700.0, 1.5)
				_peg_row(CLEAR, WIDTH - CLEAR, by + 160.0, 170.0, k % 2 == 1)
				_kickers(by + 55.0)
			h = 3 * 210.0 + 80.0
		"slalom":
			# Ice slides: curved icy chutes that speed racers up.
			var drop := 220.0
			for t in 4:
				var ty := y0 + 40.0 + t * drop
				var a := Vector2(0.0, ty)
				var c := Vector2(415.0, ty + drop * 0.25)
				var b := Vector2(WIDTH - 170.0, ty + drop * 0.55)
				if t % 2 == 1:
					a.x = WIDTH
					c.x = WIDTH - c.x
					b.x = WIDTH - b.x
				_curve(a, c, b, {"ice": true, "look": "ice"})
			h = 4 * drop + 120.0
		"mirrors":
			# Crystal mirrors at 45 degrees in a diamond grid: ricochets, a
			# racer-wide gap between one row's ends and the next's.
			for row in 5:
				var ry := y0 + 60.0 + row * 140.0
				var xs := [170.0, 390.0, 610.0, 830.0] if row % 2 == 0 else [280.0, 500.0, 720.0]
				for k in xs.size():
					var tilt := Vector2(35.0, 35.0) if (row + k) % 2 == 0 else Vector2(35.0, -35.0)
					_seg(Vector2(xs[k], ry) - tilt, Vector2(xs[k], ry) + tilt, {"look": "crystal"})
				if row % 2 == 1:
					_kickers(ry)
			h = 5 * 140.0 + 60.0
		"spinners":
			# A crystal spinner in the middle, two quick little ones round it.
			_bar(Vector2(WIDTH / 2.0, y0 + 290.0), 150.0, 0.0, 16.0, {"orbit": 1.2})
			_bar(Vector2(210.0, y0 + 120.0), 80.0, 0.0, 15.0, {"orbit": -1.7})
			_bar(Vector2(WIDTH - 210.0, y0 + 460.0), 80.0, 0.0, 15.0, {"orbit": 1.7})
			_kickers(y0 + 290.0)
			_pickup(crng, Vector2(WIDTH - 210.0, y0 + 160.0))
			h = 580.0
		"tubes":
			# Lava tubes: curved pipes that carry racers back and forth.
			var drop := 240.0
			for t in 3:
				var ty := y0 + 40.0 + t * drop
				var a := Vector2(0.0, ty)
				var c := Vector2(300.0, ty + 180.0)
				var b := Vector2(WIDTH - 180.0, ty + drop * 0.85)
				if t % 2 == 1:
					a.x = WIDTH
					c.x = WIDTH - c.x
					b.x = WIDTH - b.x
				_curve(a, c, b, {"look": "pipe"})
				# The roof starts a racer-wide gap under the tube above.
				var prev := _bez(a, c, b, 0.55) - Vector2(0.0, 115.0)
				for k in range(5, 8):
					var p := _bez(a, c, b, k / 8.0) - Vector2(0.0, 115.0)
					_seg(prev, p, {"look": "pipe"})
					prev = p
			h = 3 * drop + 140.0
		"blocks":
			# Glitch blocks: a grid of diamonds.
			for row in 4:
				var ry := y0 + 70.0 + row * 170.0
				var xs := [180.0, 500.0, 820.0] if row % 2 == 0 else [340.0, 660.0]
				for x in xs:
					_shape([Vector2(x, ry - 55.0), Vector2(x + 55.0, ry), Vector2(x, ry + 55.0), Vector2(x - 55.0, ry)], {"look": "block"})
				if row % 2 == 1:
					_kickers(ry)
			_pickup(crng, Vector2(WIDTH / 2.0, y0 + 240.0))
			h = 4 * 170.0 + 60.0
		"dunes":
			# Rolling dunes: wavy slopes racers roll up and over, quicksand in
			# the dips.
			for t in 2:
				var ty := y0 + 40.0 + t * 300.0
				var prev := Vector2(0.0, ty)
				for k in 3:
					var nx := 280.0 * (k + 1)
					var nxt := Vector2(nx, ty + nx * 0.31)
					var c := Vector2((prev.x + nx) / 2.0, nxt.y - 15.0)
					var dip := _bez(prev, c, nxt, 0.9)
					if t % 2 == 1:
						_curve(Vector2(WIDTH - prev.x, prev.y), Vector2(WIDTH - c.x, c.y), Vector2(WIDTH - nxt.x, nxt.y), {"look": "sand"}, 6)
						dip.x = WIDTH - dip.x
					else:
						_curve(prev, c, nxt, {"look": "sand"}, 6)
					if k == 1:
						floors.append({"kind": "goo", "pos": dip - Vector2(0.0, 30.0), "radius": 60.0, "slow": 0.0})
					prev = nxt
			h = 2 * 300.0 + 120.0
		"tombs":
			# Tombstones in crooked rows, thorns that snap out between them; the
			# first row a racer-wide drop under the opening lips.
			for row in 5:
				var ry := y0 + 80.0 + row * 160.0
				var xs := [200.0, 500.0, 800.0] if row % 2 == 0 else [350.0, 650.0]
				for k in xs.size():
					var lean := 14.0 if (row + k) % 2 == 0 else -14.0
					_seg(Vector2(xs[k] - lean, ry - 50.0), Vector2(xs[k] + lean, ry + 50.0), {"look": "stone"})
				if row % 2 == 1:
					_kickers(ry)
					movers.append({"pos": Vector2(WIDTH / 2.0, ry + 10.0), "radius": 24.0, "kind": "spike", "retract": 1.4})
			h = 5 * 160.0 + 60.0
		"staircase":
			# The haunted staircase: shelves down both walls and a chandelier
			# swinging in the stairwell.
			for t in 5:
				var ty := y0 + 40.0 + t * 112.0
				if t % 2 == 0:
					_seg(Vector2(0.0, ty), Vector2(300.0, ty + 55.0), {"look": "stone"})
				else:
					_seg(Vector2(WIDTH, ty), Vector2(WIDTH - 300.0, ty + 55.0), {"look": "stone"})
			_pendulum(Vector2(WIDTH / 2.0, y0 + 20.0), 280.0, 18.0, 0.33, 3.2, 0.0)
			h = 5 * 112.0 + 140.0
		"bookcase":
			# A spinning bookcase and the secret passages either side of it.
			_bar(Vector2(WIDTH / 2.0, y0 + 260.0), 130.0, 90.0, 22.0, {"orbit": 0.9})
			_portal(Vector2(180.0, y0 + 110.0), Vector2(WIDTH - 180.0, y0 + 430.0))
			_portal(Vector2(WIDTH - 180.0, y0 + 110.0), Vector2(180.0, y0 + 430.0))
			_kickers(y0 + 260.0)
			h = 560.0
		"tops":
			# Spinning tops: little spinners all over.
			var tops := [[300.0, 120.0, -2.0], [700.0, 120.0, 2.0], [500.0, 330.0, 2.0], [250.0, 530.0, 2.2], [750.0, 530.0, -2.2]]
			for tp in tops:
				_bar(Vector2(tp[0], y0 + tp[1]), 72.0, 0.0, 15.0, {"orbit": tp[2]})
			_kickers(y0 + 330.0)
			h = 640.0
		"jacks":
			# Jack-in-the-box pads that throw racers up and across, bumpers
			# to land on.
			_pad(Vector2(250.0, y0 + 150.0), Vector2(300.0, -650.0))
			_pad(Vector2(WIDTH - 250.0, y0 + 150.0), Vector2(-300.0, -650.0))
			_pad(Vector2(WIDTH / 2.0, y0 + 420.0), Vector2(320.0 if crng.range_int(0, 1) == 0 else -320.0, -700.0))
			_peg(WIDTH / 2.0, y0 + 170.0, 36.0, true)
			_peg(200.0, y0 + 440.0, 36.0, true)
			_peg(WIDTH - 200.0, y0 + 440.0, 36.0, true)
			_kickers(y0 + 300.0)
			h = 600.0
		"pops":
			# Pop bumpers in clusters, pinball style.
			for at in [Vector2(500.0, 120.0), Vector2(425.0, 235.0), Vector2(575.0, 235.0), Vector2(220.0, 420.0), Vector2(780.0, 420.0), Vector2(500.0, 480.0)]:
				_peg(at.x, y0 + at.y, 38.0, true)
			_kickers(y0 + 200.0)
			_kickers(y0 + 480.0)
			h = 600.0
		"flippers":
			# Flippers: lanes guide racers onto two flippers that flick them
			# on, with the drain between them.
			_ramp(0.0, y0 + 40.0, 230.0, y0 + 220.0)
			_ramp(WIDTH, y0 + 40.0, WIDTH - 230.0, y0 + 220.0)
			var period := float(crng.range_int(14, 18)) / 10.0
			_bar(Vector2(250.0 + 78.0, y0 + 240.0 + 32.0), 85.0, 22.5, 14.0,
				{"pivot": Vector2(250.0, y0 + 240.0), "swing": 0.5, "period": period, "phase": 0.0, "slide": Vector2.ZERO})
			_bar(Vector2(WIDTH - 250.0 - 78.0, y0 + 240.0 + 32.0), 85.0, 157.5, 14.0,
				{"pivot": Vector2(WIDTH - 250.0, y0 + 240.0), "swing": -0.5, "period": period, "phase": 0.0, "slide": Vector2.ZERO})
			_peg(WIDTH / 2.0, y0 + 450.0, 38.0, true)
			_kickers(y0 + 450.0)
			h = 540.0
	if LEDGED.has(kind):
		h += _ledge(crng, y0 + h + 40.0) + 40.0
	sections.append({"kind": kind, "y0": y0, "y1": y0 + h})
	return y0 + h


## A ledge across the shaft under an open section: both sides slope to a
## gap somewhere along it, so the field gathers, rolls and jostles before it
## drops on. Returns its height.
func _ledge(crng: Rng, y: float) -> float:
	var gx := float(crng.range_int(330, 670))
	_seg(Vector2(0.0, y), Vector2(gx - 80.0, y + (gx - 80.0) * LEDGE_SLOPE))
	_seg(Vector2(WIDTH, y), Vector2(gx + 80.0, y + (WIDTH - gx - 80.0) * LEDGE_SLOPE))
	return maxf(gx - 80.0, WIDTH - gx - 80.0) * LEDGE_SLOPE + 110.0


## A pickup at `at`: `kind`, or a power core, heal or shield by the seed.
func _pickup(crng: Rng, at: Vector2, kind := "") -> void:
	if kind == "":
		kind = ["core", "core", "heal", "shield"][crng.range_int(0, 3)]
	cores.append({"pos": at, "radius": PICKUP_R, "kind": kind})
