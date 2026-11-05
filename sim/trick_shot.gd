## Daily Trick Shot: one called bank shot per day, built from the day number
## alone so every device gets the same puzzle without a server.
##
## Both balls are placed and the foe sits still. The player picks a launch
## angle (whole degrees) that bounces off the called walls, in order, and then
## hits the foe within TIME_LIMIT seconds. Pillars and bumpers on the floor
## deflect the shot for free (a bumper also speeds it up for a moment); only
## the arena's walls are called. Only the flight before the first contact
## matters, so the outcome changes smoothly with the aim (a full fight is
## chaotic: one degree flips the winner).
##
## Three puzzles a day (Newms 2026-11-05), one per star level:
##   1 star: the plain floor with pillars and bumpers, one called wall.
##   2 stars: a painted map (maps()), whatever is on it (bumpers, portals,
##     wells, goo, moving parts), two called walls.
##   3 stars: the shooter's ability is on and bends the shot
##     (flight_critters(): dashes, swerves, pulls), two or three called
##     walls; it must solve at aims that miss without the ability.
## Levels 2 and 3 are judged with the real sim, which is slow, so the export
## writes the coming days to BUNDLED (tools/trick_shot_days.gd); daily()
## reads them there and generates on the device only for a day it lacks.
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const DMath := preload("res://sim/dmath.gd")
const Arenas := preload("res://sim/arenas.gd")

const EPOCH := {"year": 2026, "month": 10, "day": 14} ## Trick Shot #1.
const TRIES := 3
const TIME_LIMIT := 8.0
## A puzzle is kept when this many whole-degree aims (of 360) solve it.
const MIN_SOLUTIONS := 4
const MAX_SOLUTIONS := 12
const MAX_CANDIDATES := 40
const EDGE_MARGIN := 140.0
const MIN_START_GAP := 300.0
const WALLS := ["left", "top", "right", "bottom"]
## The sim's id for a Trick Shot layout: not a picker map, so it draws plain.
const ARENA_ID := "trickshot"
## Floor pieces per puzzle, and how big. Whole numbers, so the sim's overtime
## scaling of obstacle positions leaves them exact.
const MAX_OBSTACLES := 4
const OBSTACLE_RADII := [40, 70]
const OBSTACLE_AREA := [190, 810]
## Room kept round each start (beyond both radii) and between pieces, so
## nothing starts touching and a ball can always pass between two pieces.
const START_CLEARANCE := 110.0
const GAP := 130.0
const BUMPER_SHARE := 0.4
## Percent of candidates calling 1 and 2 walls (the rest call 3). Long calls
## fail the fairness check more often, so they're drawn more.
const WALL_ODDS := [20, 45]

const LEVELS := 3
## Written at export time by tools/trick_shot_days.gd (not in git).
const BUNDLED := "res://liveops/trick_shots.json"
## Called walls per level: [fewest, most].
const LEVEL_WALLS := [[1, 1], [2, 2], [2, 3]]
## Room kept round each start from anything on a map's floor.
const MAP_CLEARANCE := 70.0
## How far (arena units) an ability must move the shot off its straight
## path within FLIGHT_TIME for a critter to set 3-star puzzles.
const FLIGHT_SHIFT := 40.0
const FLIGHT_TIME := TIME_LIMIT
## Share of a 3-star puzzle's solving aims that must miss without the ability.
const ABILITY_SHARE := 0.5

const SOLVED := "solved"
const WRONG_WALLS := "wrong_walls" ## Hit the foe before banking off every called wall.
const MISS := "miss"

## {critter id: {radius, speed}} as the sim builds them, for fast_judge().
static var _stats := {}
static var _flight: Array = []
static var _bundled = null


## 1 on EPOCH, counting up one per calendar day. `date` has year, month, day.
static func day_number(date: Dictionary) -> int:
	var d := {"year": date.year, "month": date.month, "day": date.day}
	return int(floor((Time.get_unix_time_from_datetime_dict(d) - Time.get_unix_time_from_datetime_dict(EPOCH)) / 86400.0)) + 1


## Setup number `k` for a day. Generation tries k = 0, 1, 2... until one has a
## fair number of solutions. `shooter` forces your ball and makes a different
## puzzle from the day's main one. Both critters come from the whole live
## roster (abilities are off in a trick shot, so any of them flies straight).
static func candidate(day: int, k: int, shooter := "", level := 1) -> Dictionary:
	if level > 1:
		return _candidate_hard(day, k, shooter, level)
	var rng := Rng.new(day * 7919 + k * 104729 + (17 if shooter == "" else 31337 + shooter.hash() % 9973))
	var pool := critters()
	var p1: String = pool[rng.range_int(0, pool.size() - 1)]
	if shooter != "":
		p1 = shooter
	var p2: String = pool[rng.range_int(0, pool.size() - 1)]
	while p2 == p1 and pool.size() > 1:
		p2 = pool[rng.range_int(0, pool.size() - 1)]
	var starts: Array[Vector2] = []
	while starts.size() < 2:
		var p := Vector2(_coord(rng), _coord(rng))
		if starts.is_empty() or p.distance_to(starts[0]) >= MIN_START_GAP:
			starts.append(p)
	var obstacles: Array = []
	for i in rng.range_int(1, MAX_OBSTACLES):
		var o := _obstacle(rng, starts, obstacles)
		if not o.is_empty():
			obstacles.append(o)
	return {"day": day, "p1": p1, "p2": p2, "starts": starts, "walls": _walls(rng, 1), "obstacles": obstacles, "level": 1}


## A called-wall list for `level` (LEVEL_WALLS), no wall twice in a row.
static func _walls(rng: Rng, level: int) -> Array:
	var span: Array = LEVEL_WALLS[level - 1]
	var walls: Array[String] = []
	for i in rng.range_int(span[0], span[1]):
		var w: String = WALLS[rng.range_int(0, 3)]
		while not walls.is_empty() and w == walls[-1]:
			w = WALLS[rng.range_int(0, 3)]
		walls.append(w)
	return walls


## Square-walled painted maps (no cut corners or extra sides, so the four
## walls are the ones called), in a fixed order.
static func maps() -> Array:
	return Arenas.RANDOM_POOL.filter(func(id):
		var d: Dictionary = Arenas.DEFS[id]
		return float(d.get("corner_cut", 0.0)) == 0.0 and not d.has("sides") and float(d.get("start_scale", 1.0)) == 1.0)


## Critters whose ability bends their own flight (a 3-star shooter), found
## by flying each one with and without its ability.
static func flight_critters() -> Array:
	if _flight.is_empty():
		for id in critters():
			if _bends(id):
				_flight.append(id)
	return _flight


static func _bends(id: String) -> bool:
	for aim in [20, 160]:
		var paths := []
		for on in [true, false]:
			var sim := MatchSim.new({"seed": 1, "p1": id, "p2": "plain", "starts": [Vector2(200, 500), Vector2(860, 140)], "angles": [aim * 10, 0],
				"arena": ARENA_ID, "arena_def": arena_def({}), "abilities": [on, false], "fields": on, "seek": 0.0})
			sim.balls[1].vel = Vector2.ZERO
			var pts := []
			while sim.time() < FLIGHT_TIME and not sim.finished:
				sim.step()
				if sim.tick % 10 == 0:
					pts.append([sim.balls[0].pos, sim.balls[1].pos]) # Your path, and the foe's spot (pulls move it).
			paths.append(pts)
		for i in mini(paths[0].size(), paths[1].size()):
			for b in 2:
				if paths[0][i][b].distance_to(paths[1][i][b]) > FLIGHT_SHIFT:
					return true
	return false


## A 2-star (painted map) or 3-star (ability) setup, or {} when the starts
## don't fit.
static func _candidate_hard(day: int, k: int, shooter: String, level: int) -> Dictionary:
	var rng := Rng.new(day * 6271 + k * 92821 + level * 15485863 + (0 if shooter == "" else shooter.hash() % 9973))
	var pool := critters()
	var shooters: Array = flight_critters() if level == 3 else pool
	var p1: String = shooter if shooter != "" else shooters[rng.range_int(0, shooters.size() - 1)]
	var p2: String = pool[rng.range_int(0, pool.size() - 1)]
	while p2 == p1 and pool.size() > 1:
		p2 = pool[rng.range_int(0, pool.size() - 1)]
	var puzzle := {"day": day, "p1": p1, "p2": p2, "level": level, "obstacles": []}
	var def := {}
	if level == 2:
		var all := maps()
		puzzle.arena = all[rng.range_int(0, all.size() - 1)]
		def = Arenas.get_def(puzzle.arena)
	else:
		puzzle.abilities = true
	var starts: Array[Vector2] = []
	var tries := 0
	while starts.size() < 2 and tries < 200:
		tries += 1
		var p := Vector2(_coord(rng), _coord(rng))
		if (starts.is_empty() or p.distance_to(starts[0]) >= MIN_START_GAP) and _clear_of(def, p):
			starts.append(p)
	if starts.size() < 2:
		return {}
	puzzle.starts = starts
	if level == 3:
		for i in rng.range_int(1, MAX_OBSTACLES - 1):
			var o := _obstacle(rng, starts, puzzle.obstacles)
			if not o.is_empty():
				puzzle.obstacles.append(o)
	puzzle.walls = _walls(rng, level)
	return puzzle


## True when a ball can start at `p` on map `def`: clear of its pieces,
## pads, wells and cores (moving parts measured from where they start, and
## an orbiting piece's whole ring).
static func _clear_of(def: Dictionary, p: Vector2) -> bool:
	var things: Array = []
	for key in ["obstacles", "floors", "wells", "cores"]:
		things.append_array(def.get(key, []))
	for t in things:
		if not t is Dictionary:
			continue
		var keep := float(t.get("radius", 60.0)) + MAP_CLEARANCE + 60.0
		if t.has("pos"):
			if p.distance_to(t.pos) < keep + float(t.get("bar", 0.0)) + float(t.get("reach", 0.0)) * 0.5 + absf(float(t.get("slide", Vector2.ZERO).length() if t.get("slide") is Vector2 else 0.0)):
				return false
			if t.has("orbit") and not t.has("bar"):
				var pivot: Vector2 = t.get("pivot", Vector2(500, 500))
				if absf(p.distance_to(pivot) - pivot.distance_to(t.pos)) < keep:
					return false
		elif t.has("rect"):
			if (t.rect as Rect2).grow(MAP_CLEARANCE + 60.0).has_point(p):
				return false
	return true


## Every critter a puzzle may use, in a fixed order.
static func critters() -> Array:
	var ids: Array = BallDefs.PLAYABLE.duplicate()
	ids.sort()
	return ids


## A pillar or bumper clear of both starts and the pieces already placed, or
## {} after a few tries.
static func _obstacle(rng: Rng, starts: Array, placed: Array) -> Dictionary:
	for attempt in 12:
		var r: int = rng.range_int(OBSTACLE_RADII[0], OBSTACLE_RADII[1])
		var pos := Vector2(rng.range_int(OBSTACLE_AREA[0], OBSTACLE_AREA[1]), rng.range_int(OBSTACLE_AREA[0], OBSTACLE_AREA[1]))
		var kind := "bumper" if rng.range_int(0, 99) < int(BUMPER_SHARE * 100) else "pillar"
		var ok := true
		for s in starts:
			if pos.distance_to(s) < r + START_CLEARANCE + 60.0:
				ok = false
		for o in placed:
			if pos.distance_to(o.pos) < r + o.radius + GAP:
				ok = false
		if ok:
			return {"pos": pos, "radius": float(r), "kind": kind}
	return {}


## The puzzle's layout as a sim arena: the plain square plus its pieces.
static func arena_def(puzzle: Dictionary) -> Dictionary:
	return {"display_name": "Trick Shot", "corner_cut": 0.0, "obstacles": puzzle.get("obstacles", [])}


static func _coord(rng) -> float:
	return EDGE_MARGIN + float(rng.range_int(0, int(MatchSim.ARENA_SIZE - 2.0 * EDGE_MARGIN)))


## The real sim for a shot: the foe waits until it is hit.
static func make_sim(puzzle: Dictionary, aim_deg: int) -> MatchSim:
	var cfg := {"seed": 1, "p1": puzzle.p1, "p2": puzzle.p2, "starts": puzzle.starts, "angles": [aim_deg * 10, 0],
		"arena": ARENA_ID, "arena_def": arena_def(puzzle), "abilities": false, "fields": false, "seek": 0.0} # An aim puzzle: no pull.
	if puzzle.has("arena"): # A painted map, as it is.
		cfg.arena = puzzle.arena
		cfg.erase("arena_def")
	if puzzle.get("abilities", false): # Yours bends the shot; the foe's stays off.
		cfg.abilities = [true, false]
		cfg.fields = true
	var sim := MatchSim.new(cfg)
	sim.balls[1].vel = Vector2.ZERO
	return sim


## Plays a shot with the real sim until it is decided: a contact, a bounce
## off an uncalled wall, or TIME_LIMIT. Returns { result, walls, time, pos }:
## result is SOLVED, WRONG_WALLS (hit before banking off every called wall) or
## MISS; walls the walls your ball bounced off; pos where the balls touched.
static func judge(puzzle: Dictionary, aim_deg: int) -> Dictionary:
	var sim := make_sim(puzzle, aim_deg)
	var shot := {"result": "", "walls": []}
	while shot.result == "":
		step_shot(sim, puzzle, shot)
	return shot


## Advances `shot` (start it as {result = "", walls = []}) by one tick of `sim`.
## Sets shot.result once the shot is decided.
static func step_shot(sim: MatchSim, puzzle: Dictionary, shot: Dictionary) -> void:
	sim.step()
	shot.time = sim.time()
	for e in sim.events:
		if e.type == "bounce" and e.ball == 0:
			var wall := _wall_at(e.pos)
			if wall == "":
				continue # A pillar or bumper: free.
			shot.walls.append(wall)
			# Off an uncalled wall: the shot can no longer be solved.
			if shot.walls.size() > puzzle.walls.size() or shot.walls[-1] != puzzle.walls[shot.walls.size() - 1]:
				shot.result = MISS
				return
		elif e.type == "collide" and ((e.a == 0 and e.b == 1) or (e.a == 1 and e.b == 0)):
			shot.result = SOLVED if shot.walls == puzzle.walls else WRONG_WALLS
			shot.pos = e.pos
			return
	if sim.time() >= TIME_LIMIT or sim.finished:
		shot.result = MISS


## The arena wall a bounce point is on, or "" for a point inside (a pillar).
static func _wall_at(pos: Vector2) -> String:
	if pos.x <= 0.0:
		return "left"
	if pos.x >= MatchSim.ARENA_SIZE:
		return "right"
	if pos.y <= 0.0:
		return "top"
	return "bottom" if pos.y >= MatchSim.ARENA_SIZE else ""


## {radius, speed} of critter `id` as the sim builds it.
static func ball_stats(id: String) -> Dictionary:
	if not _stats.has(id):
		var b = MatchSim.new({"p1": id, "p2": id, "abilities": false}).balls[0]
		_stats[id] = {"radius": b.radius, "speed": b.speed}
	return _stats[id]


## judge().result without a MatchSim: until the first contact the balls only
## fly straight and bounce off the walls, so this replays just that with the
## sim's own arithmetic, many times faster. Tests check it agrees with judge()
## on every aim.
static func fast_judge(puzzle: Dictionary, aim_deg: int) -> String:
	var me := ball_stats(puzzle.p1)
	var r0: float = me.radius
	var r1: float = ball_stats(puzzle.p2).radius
	var min_dist := r0 + r1
	var p: Vector2 = puzzle.starts[0]
	var target: Vector2 = puzzle.starts[1]
	var speed: float = me.speed
	var v := DMath.from_angle(deg_to_rad(aim_deg * 10 / 10.0)) * speed
	var hi := MatchSim.ARENA_SIZE
	var called: Array = puzzle.walls
	var obstacles: Array = puzzle.get("obstacles", [])
	var boost_for := int(round(MatchSim.BUMPER_BOOST_TIME * MatchSim.TICK_RATE))
	var boost := 0
	var walls := 0
	for t in int(TIME_LIMIT * MatchSim.TICK_RATE):
		if boost > 0:
			boost -= 1
			if boost == 0:
				v = v.normalized() * speed
		p += v * MatchSim.DT
		var hit := ""
		if p.x - r0 < 0.0:
			p.x = r0
			if v.x < 0.0:
				v.x = -v.x
				hit = "left"
		elif p.x + r0 > hi:
			p.x = hi - r0
			if v.x > 0.0:
				v.x = -v.x
				hit = "right"
		if hit != "":
			if walls >= called.size() or called[walls] != hit:
				return MISS
			walls += 1
			hit = ""
		if p.y - r0 < 0.0:
			p.y = r0
			if v.y < 0.0:
				v.y = -v.y
				hit = "top"
		elif p.y + r0 > hi:
			p.y = hi - r0
			if v.y > 0.0:
				v.y = -v.y
				hit = "bottom"
		if hit != "":
			if walls >= called.size() or called[walls] != hit:
				return MISS
			walls += 1
		for o in obstacles:
			var away: Vector2 = p - o.pos
			var reach: float = r0 + o.radius
			var d := away.length()
			if d >= reach:
				continue
			var on := away / d if d > 0.0001 else Vector2.UP
			p = o.pos + on * reach
			if v.dot(on) < 0.0:
				v -= 2.0 * v.dot(on) * on
				if o.kind == "bumper":
					boost = boost_for
					v = v.normalized() * (speed * MatchSim.BUMPER_BOOST)
		var delta := target - p
		var dist := delta.length()
		if dist < min_dist:
			var n := delta / dist if dist > 0.0001 else Vector2.RIGHT
			if v.dot(n) > 0.0:
				return SOLVED if walls == called.size() else WRONG_WALLS
			# A graze while already moving apart: the sim only separates them.
			var ma := r0 * r0
			var mb := r1 * r1
			var overlap := min_dist - dist
			p -= n * overlap * (mb / (ma + mb))
			target += n * overlap * (ma / (ma + mb))
	return MISS


## Solving aims as runs of whole degrees, [[from, to], ...]: pieces on the
## floor can split a day's solutions into more than one window.
static func windows(solutions: Array) -> Array:
	var out: Array = []
	for a in solutions:
		if not out.is_empty() and int(a) == int(out[-1][1]) + 1:
			out[-1][1] = int(a)
		else:
			out.append([int(a), int(a)])
	return out


## The aim straight at the foe, which a puzzle must never accept.
static func direct_aim(puzzle: Dictionary) -> int:
	var to_foe: Vector2 = puzzle.starts[1] - puzzle.starts[0]
	return posmod(roundi(rad_to_deg(DMath.angle(to_foe))), 360)


## Every solving whole-degree aim, stopping past MAX_SOLUTIONS. The real
## sim (levels 2 and 3) is slow, so it tries every other degree and then the
## neighbours of each hit: a fair window is always 2+ degrees wide.
static func _solve(puzzle: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if int(puzzle.get("level", 1)) == 1:
		for aim in 360:
			if fast_judge(puzzle, aim) == SOLVED:
				out.append(aim)
				if out.size() > MAX_SOLUTIONS:
					break
		return out
	var hit := {}
	for aim in range(0, 360, 2):
		if judge(puzzle, aim).result == SOLVED:
			hit[aim] = true
			for n in [aim - 1, aim + 1]:
				if not hit.has(posmod(n, 360)) and judge(puzzle, posmod(n, 360)).result == SOLVED:
					hit[posmod(n, 360)] = true
			if hit.size() > MAX_SOLUTIONS:
				break
	for aim in 360:
		if hit.has(aim):
			out.append(aim)
	return out


## The puzzle for a day: the first candidate with a fair number of solving
## aims (or, failing that, the hardest solvable one), plus `solutions`, every
## solving whole-degree aim. Takes a few milliseconds per candidate.
static func generate(day: int, shooter := "", level := 1) -> Dictionary:
	var best := {}
	var loose := {} ## A 3-star the ability doesn't decide: only if nothing else turns up.
	for k in (MAX_CANDIDATES if level == 1 else MAX_CANDIDATES * 2):
		var puzzle := candidate(day, k, shooter, level)
		if puzzle.is_empty():
			continue
		var solutions := _solve(puzzle)
		if solutions.is_empty() or direct_aim(puzzle) in solutions:
			continue
		puzzle.solutions = solutions
		puzzle.candidate = k
		if level == 3:
			# The ability has to be what solves it.
			var plain := puzzle.duplicate()
			plain.erase("abilities")
			var needs := solutions.filter(func(a): return fast_judge(plain, a) != SOLVED).size()
			if needs < ceili(solutions.size() * ABILITY_SHARE):
				if loose.is_empty():
					loose = puzzle
				continue
		if solutions.size() >= MIN_SOLUTIONS and solutions.size() <= MAX_SOLUTIONS:
			return puzzle
		if best.is_empty() or solutions.size() < best.solutions.size():
			best = puzzle
	return best if not best.is_empty() else loose


## The day's puzzle at `level` stars: from the bundled file when it has the
## day, else generated here (levels 2 and 3 take a few seconds).
static func daily(day: int, level := 1) -> Dictionary:
	if level == 1:
		return generate(day)
	if _bundled == null:
		_bundled = {}
		if FileAccess.file_exists(BUNDLED):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(BUNDLED))
			if parsed is Dictionary:
				_bundled = parsed
	var key := "%d-%d" % [day, level]
	if _bundled.has(key):
		return from_json(_bundled[key])
	var p := generate(day, "", level)
	if p.is_empty(): # Nothing fair turned up: that day's 1-star stands in.
		p = generate(day)
	_bundled[key] = to_json(p)
	return p


## A puzzle as JSON-safe data (Vector2s as [x, y]) and back.
static func to_json(p: Dictionary) -> Dictionary:
	var out := p.duplicate(true)
	out.starts = p.starts.map(func(v): return [v.x, v.y])
	out.obstacles = p.get("obstacles", []).map(func(o): return {"pos": [o.pos.x, o.pos.y], "radius": o.radius, "kind": o.kind})
	return out


static func from_json(d: Dictionary) -> Dictionary:
	var p := d.duplicate(true)
	var starts: Array[Vector2] = []
	for v in d.starts:
		starts.append(Vector2(float(v[0]), float(v[1])))
	p.starts = starts
	p.obstacles = d.get("obstacles", []).map(func(o): return {"pos": Vector2(float(o.pos[0]), float(o.pos[1])), "radius": float(o.radius), "kind": str(o.kind)})
	var sol: Array[int] = []
	for a in d.get("solutions", []):
		sol.append(int(a))
	p.solutions = sol
	p.walls = Array(d.walls).map(func(w): return str(w))
	p.day = int(d.day)
	p.level = int(d.get("level", 1))
	if d.has("candidate"):
		p.candidate = int(d.candidate)
	return p
