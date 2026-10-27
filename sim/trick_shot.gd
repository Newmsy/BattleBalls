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
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const DMath := preload("res://sim/dmath.gd")

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

const SOLVED := "solved"
const WRONG_WALLS := "wrong_walls" ## Hit the foe before banking off every called wall.
const MISS := "miss"

## {critter id: {radius, speed}} as the sim builds them, for fast_judge().
static var _stats := {}


## 1 on EPOCH, counting up one per calendar day. `date` has year, month, day.
static func day_number(date: Dictionary) -> int:
	var d := {"year": date.year, "month": date.month, "day": date.day}
	return int(floor((Time.get_unix_time_from_datetime_dict(d) - Time.get_unix_time_from_datetime_dict(EPOCH)) / 86400.0)) + 1


## Setup number `k` for a day. Generation tries k = 0, 1, 2... until one has a
## fair number of solutions. `shooter` forces your ball and makes a different
## puzzle from the day's main one. Both critters come from the whole live
## roster (abilities are off in a trick shot, so any of them flies straight).
static func candidate(day: int, k: int, shooter := "") -> Dictionary:
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
	var walls: Array[String] = []
	var roll := rng.range_int(0, 99)
	for i in (1 if roll < WALL_ODDS[0] else (2 if roll < WALL_ODDS[0] + WALL_ODDS[1] else 3)):
		var w: String = WALLS[rng.range_int(0, 3)]
		while not walls.is_empty() and w == walls[-1]:
			w = WALLS[rng.range_int(0, 3)]
		walls.append(w)
	return {"day": day, "p1": p1, "p2": p2, "starts": starts, "walls": walls, "obstacles": obstacles}


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
	var sim := MatchSim.new({"seed": 1, "p1": puzzle.p1, "p2": puzzle.p2, "starts": puzzle.starts, "angles": [aim_deg * 10, 0],
		"arena": ARENA_ID, "arena_def": arena_def(puzzle), "abilities": false, "fields": false, "seek": 0.0}) # An aim puzzle: no pull.
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
		elif e.type == "collide":
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


## The puzzle for a day: the first candidate with a fair number of solving
## aims (or, failing that, the hardest solvable one), plus `solutions`, every
## solving whole-degree aim. Takes a few milliseconds per candidate.
static func generate(day: int, shooter := "") -> Dictionary:
	var best := {}
	for k in MAX_CANDIDATES:
		var puzzle := candidate(day, k, shooter)
		var solutions: Array[int] = []
		for aim in 360:
			if fast_judge(puzzle, aim) == SOLVED:
				solutions.append(aim)
				if solutions.size() > MAX_SOLUTIONS:
					break
		if solutions.is_empty() or direct_aim(puzzle) in solutions:
			continue
		puzzle.solutions = solutions
		puzzle.candidate = k
		if solutions.size() >= MIN_SOLUTIONS and solutions.size() <= MAX_SOLUTIONS:
			return puzzle
		if best.is_empty() or solutions.size() < best.solutions.size():
			best = puzzle
	return best
