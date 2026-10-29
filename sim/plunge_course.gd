## A Critter Plunge course: pegs, bumpers and ramps down a 1000-wide shaft,
## plus the collisions racers have with it. There are 20 courses (COURSES),
## each a fixed run of sections in one arena's painted look; the seed picks
## the course and varies each section's details. The race itself is
## sim/plunge.gd.
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
const SECTIONS := ["pegs", "funnel", "zigzag", "bumpers", "split", "cups", "chutes", "steps", "gauntlet",
	"wells", "lava", "goo", "sliders"]
## The hazard sections, one per course, in the arenas' own pieces: gravity
## wells, lava, goo and sliding bumpers. Each holds a pickup too (a power
## core, heal or shield). sim/plunge.gd runs them.
const HAZARDS := ["wells", "lava", "goo", "sliders"]
const WELL_ACCEL := 700.0 ## Under gravity even at full pull, so a well bends a drop but never holds it.
const GOO_DRAG := 2.2 ## Extra drag per second in goo.
const PICKUP_R := 34.0
const CUP_GAP := 130.0 ## The hole in a cup's bottom: two racers wide.

## Every course: its name, the arena whose painted look it wears (`art`, a
## map id in game/arena_art.gd; the race never reads it) and the sections
## between the peg fields at the top and bottom.
const COURSES := [
	{"id": "gumdrop", "name": "Gumdrop Drop", "art": "candy", "plan": ["bumpers", "cups", "goo", "gauntlet", "bumpers"]},
	{"id": "honey", "name": "Honey Chute", "art": "hive", "plan": ["chutes", "zigzag", "goo", "funnel", "steps"]},
	{"id": "sunstone", "name": "Sunstone Steps", "art": "temple", "plan": ["steps", "funnel", "sliders", "steps", "cups"]},
	{"id": "vines", "name": "Vine Ruins", "art": "ruins", "plan": ["split", "gauntlet", "sliders", "chutes", "funnel"]},
	{"id": "nebula", "name": "Nebula Fall", "art": "nebula", "plan": ["bumpers", "gauntlet", "wells", "split", "funnel"]},
	{"id": "rocks", "name": "Rock Belt", "art": "asteroid", "plan": ["gauntlet", "bumpers", "wells", "bumpers", "zigzag"]},
	{"id": "kelp", "name": "Kelp Forest", "art": "kelp", "plan": ["chutes", "gauntlet", "wells", "chutes", "funnel"]},
	{"id": "trench", "name": "Deep Trench", "art": "trench", "plan": ["funnel", "zigzag", "wells", "cups", "funnel"]},
	{"id": "clouds", "name": "Cloud Hop", "art": "cloud", "plan": ["cups", "bumpers", "sliders", "steps", "bumpers"]},
	{"id": "storm", "name": "Storm Front", "art": "storm", "plan": ["zigzag", "bumpers", "wells", "split", "funnel"]},
	{"id": "icicles", "name": "Icicle Run", "art": "frost", "plan": ["zigzag", "steps", "goo", "funnel", "split"]},
	{"id": "crystal", "name": "Crystal Cave", "art": "prism", "plan": ["gauntlet", "split", "sliders", "gauntlet", "steps"]},
	{"id": "lava", "name": "Lava Tubes", "art": "magma", "plan": ["funnel", "chutes", "lava", "bumpers", "zigzag"]},
	{"id": "sunset", "name": "Sunset Strip", "art": "sunset", "plan": ["split", "zigzag", "sliders", "steps", "split"]},
	{"id": "glitch", "name": "Glitch Grid", "art": "glitch", "plan": ["chutes", "bumpers", "lava", "gauntlet", "cups"]},
	{"id": "dunes", "name": "Dune Slide", "art": "dunes", "plan": ["steps", "zigzag", "goo", "split", "funnel"]},
	{"id": "graves", "name": "Grave Drop", "art": "graveyard", "plan": ["gauntlet", "funnel", "goo", "split", "bumpers"]},
	{"id": "manor", "name": "Haunted Stairs", "art": "manor", "plan": ["steps", "cups", "wells", "gauntlet", "split"]},
	{"id": "toys", "name": "Toy Chest", "art": "toybox", "plan": ["bumpers", "chutes", "sliders", "zigzag", "steps"]},
	{"id": "pinball", "name": "Pinball Plunge", "art": "pinball", "plan": ["bumpers", "split", "sliders", "zigzag", "bumpers"]},
]

var pegs: Array = [] ## [{pos, r, bumper}]
var ramps: Array = [] ## [{a, b}] solid line segments, RAMP_THICK wide.
var sections: Array = [] ## [{kind, y0, y1}] for the renderer.
var finish_y := 0.0
var floors: Array = [] ## Arena floor pads: {kind "goo" or "lava", pos, radius}.
var wells: Array = [] ## Arena gravity wells: {pos, reach, accel, core}.
var cores: Array = [] ## Arena pickups: {pos, radius, kind "core" / "heal" / "shield"}.
var movers: Array = [] ## Sliding bumpers, as arena obstacles: {pos, radius, kind, slide, period}.
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
	var tangent: Vector2 = r.vel - n * r.vel.dot(n)
	r.vel -= tangent * minf(1.0, RAMP_GRIP * dt)


# --- Building ------------------------------------------------------------------

## A peg field under the gate, the course's sections (each mirrored
## left-right on a coin flip) and a peg field before the finish.
func _build(crng: Rng) -> void:
	var y := START_Y + 120.0
	y = _section(crng, "pegs", y)
	for kind in info.plan:
		var p0 := pegs.size()
		var r0 := ramps.size()
		y = _section(crng, kind, y)
		if crng.range_int(0, 1) == 1:
			for q in range(p0, pegs.size()):
				pegs[q].pos = Vector2(WIDTH - pegs[q].pos.x, pegs[q].pos.y)
			for q in range(r0, ramps.size()):
				ramps[q].a = Vector2(WIDTH - ramps[q].a.x, ramps[q].a.y)
				ramps[q].b = Vector2(WIDTH - ramps[q].b.x, ramps[q].b.y)
	y = _section(crng, "pegs", y)
	finish_y = y + 80.0
	for i in pegs.size():
		var p: Dictionary = pegs[i]
		_bucket(i, p.pos - Vector2.ONE * p.r, p.pos + Vector2.ONE * p.r)
		_peg_pos.append(p.pos)
		_peg_r.append(p.r)
	for i in ramps.size():
		var s: Dictionary = ramps[i]
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


## Adds one section starting at `y0` and returns where the next one starts.
func _section(crng: Rng, kind: String, y0: float) -> float:
	var h := 0.0
	match kind:
		"pegs":
			# Staggered rows, with a half-bumper on each wall per row.
			var rows := crng.range_int(5, 7)
			var gap := float(crng.range_int(110, 130))
			for row in rows:
				var ry := y0 + 40.0 + row * 96.0
				_peg_row(CLEAR, WIDTH - CLEAR, ry, gap, row % 2 == 1)
				_peg(0.0, ry, KICKER_R, true)
				_peg(WIDTH, ry, KICKER_R, true)
			h = rows * 96.0 + 40.0
		"funnel":
			# Two walls squeeze everyone through one gap: jams and shoves.
			var mouth := float(crng.range_int(150, 190))
			var cx := float(crng.range_int(380, 620))
			var depth := float(crng.range_int(300, 380))
			_ramp(0.0, y0, cx - mouth / 2.0, y0 + depth)
			_ramp(WIDTH, y0, cx + mouth / 2.0, y0 + depth)
			_peg(cx, y0 + depth + 130.0, 20.0, true)
			h = depth + 230.0
		"zigzag":
			# Switchback ramps: long rolls where the lead can change.
			var turns := crng.range_int(3, 4)
			var drop := float(crng.range_int(150, 175))
			for t in turns:
				var ty := y0 + 40.0 + t * drop
				if t % 2 == 0:
					_ramp(0.0, ty, WIDTH - 190.0, ty + drop * 0.7)
				else:
					_ramp(WIDTH, ty, 190.0, ty + drop * 0.7)
			h = turns * drop + 120.0
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
		"split":
			# A divider: a quick peg lane on one side, a long ramp on the other.
			var left_fast := crng.range_int(0, 1) == 0
			h = 640.0
			_ramp(WIDTH / 2.0, y0 + 40.0, WIDTH / 2.0, y0 + h - 60.0)
			var lo := 0.0 if left_fast else WIDTH / 2.0
			for row in 5:
				_peg_row(lo + CLEAR, lo + WIDTH / 2.0 - CLEAR, y0 + 110.0 + row * 100.0, 105.0, row % 2 == 1)
			if left_fast:
				_ramp(WIDTH, y0 + 140.0, WIDTH / 2.0 + 120.0, y0 + 300.0)
				_ramp(WIDTH / 2.0, y0 + 420.0, WIDTH - 120.0, y0 + 560.0)
			else:
				_ramp(0.0, y0 + 140.0, WIDTH / 2.0 - 120.0, y0 + 300.0)
				_ramp(WIDTH / 2.0, y0 + 420.0, 120.0, y0 + 560.0)
		"cups":
			# Two rows of V cups with a hole in each: drop in, roll out the bottom.
			# The lower row sits half a cup over, with kickers in its wall gaps.
			var deep := float(crng.range_int(100, 130))
			for row in 2:
				var ry := y0 + 60.0 + row * (deep + 170.0)
				var n := 3 if row == 0 else 2
				var w := WIDTH / 3.0
				var left := 0.0 if row == 0 else w / 2.0
				for c in n:
					var cx := left + w * (c + 0.5)
					_ramp(cx - w / 2.0 + 6.0, ry, cx - CUP_GAP / 2.0, ry + deep)
					_ramp(cx + w / 2.0 - 6.0, ry, cx + CUP_GAP / 2.0, ry + deep)
				if row == 1:
					_peg(0.0, ry + deep / 2.0, KICKER_R, true)
					_peg(WIDTH, ry + deep / 2.0, KICKER_R, true)
			h = 60.0 + 2.0 * deep + 170.0 + 150.0
		"chutes":
			# Three lanes split by walls, each with its own peg rows.
			h = float(crng.range_int(560, 660))
			var w := WIDTH / 3.0
			_ramp(w, y0 + 50.0, w, y0 + h - 70.0)
			_ramp(2.0 * w, y0 + 50.0, 2.0 * w, y0 + h - 70.0)
			_peg(w, y0 + 50.0, 14.0, true)
			_peg(2.0 * w, y0 + 50.0, 14.0, true)
			var rows := int((h - 160.0) / 100.0)
			for row in rows:
				for lane in 3:
					_peg_row(lane * w + 70.0, (lane + 1) * w - 70.0, y0 + 120.0 + row * 100.0, 110.0, (row + lane) % 2 == 1)
		"steps":
			# Short shelves from alternate walls: hop, hop, hop down.
			var shelves := crng.range_int(5, 6)
			var drop := float(crng.range_int(105, 120))
			var reach := float(crng.range_int(400, 440))
			for t in shelves:
				var ty := y0 + 40.0 + t * drop
				if t % 2 == 0:
					_ramp(0.0, ty, reach, ty + 55.0)
				else:
					_ramp(WIDTH, ty, WIDTH - reach, ty + 55.0)
			h = shelves * drop + 140.0
		"gauntlet":
			# Tight peg rows: a slow, jostling squeeze.
			var rows := crng.range_int(6, 7)
			for row in rows:
				var ry := y0 + 40.0 + row * 80.0
				_peg_row(CLEAR, WIDTH - CLEAR, ry, 98.0, row % 2 == 1)
				if row % 2 == 0:
					_peg(0.0, ry, KICKER_R, true)
					_peg(WIDTH, ry, KICKER_R, true)
			h = rows * 80.0 + 60.0
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
			# Lava down both sides under a peg row that scatters racers into
			# it; the safe middle has a heal.
			h = 560.0
			var edge := float(crng.range_int(290, 330))
			_peg_row(CLEAR, WIDTH - CLEAR, y0 + 50.0, 115.0, false)
			_peg_row(CLEAR, WIDTH - CLEAR, y0 + 140.0, 115.0, true)
			for x in [edge / 2.0, WIDTH - edge / 2.0]:
				for k in 2:
					floors.append({"kind": "lava", "pos": Vector2(x, y0 + 250.0 + k * 150.0), "radius": edge / 2.0 + 10.0})
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
	sections.append({"kind": kind, "y0": y0, "y1": y0 + h})
	return y0 + h


## A pickup at `at`: `kind`, or a power core, heal or shield by the seed.
func _pickup(crng: Rng, at: Vector2, kind := "") -> void:
	if kind == "":
		kind = ["core", "core", "heal", "shield"][crng.range_int(0, 3)]
	cores.append({"pos": at, "radius": PICKUP_R, "kind": kind})


func _ramp(ax: float, ay: float, bx: float, by: float) -> void:
	ramps.append({"a": Vector2(ax, ay), "b": Vector2(bx, by)})
