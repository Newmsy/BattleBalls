## Daily Trick Shot: one called bank shot per day, built from the day number
## alone so every device gets the same puzzle without a server.
##
## Both balls are placed and the foe sits still. The player picks a launch
## angle (whole degrees) that bounces off the called walls, in order, and then
## hits the foe within TIME_LIMIT seconds. Only the flight before the first
## contact matters, so the outcome changes smoothly with the aim (a full fight
## is chaotic: one degree flips the winner).
extends RefCounted

const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")

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
## Balls the day's puzzle picks from. A fixed list, so adding a critter never
## changes a published day's puzzle. (A Critter Shot can force any playable
## shooter; trick shots switch Flux's field off so every shot flies straight.)
const BALLS := ["vampire", "laser"]

const SOLVED := "solved"
const WRONG_WALLS := "wrong_walls" ## Hit the foe before banking off every called wall.
const MISS := "miss"


## 1 on EPOCH, counting up one per calendar day. `date` has year, month, day.
static func day_number(date: Dictionary) -> int:
	var d := {"year": date.year, "month": date.month, "day": date.day}
	return int(floor((Time.get_unix_time_from_datetime_dict(d) - Time.get_unix_time_from_datetime_dict(EPOCH)) / 86400.0)) + 1


## Setup number `k` for a day. Generation tries k = 0, 1, 2... until one has a
## fair number of solutions. `shooter` forces your ball (the Try-a-Critter
## Critter Shot) and makes a different puzzle from the day's main one.
static func candidate(day: int, k: int, shooter := "") -> Dictionary:
	var rng := Rng.new(day * 7919 + k * 104729 + (17 if shooter == "" else 31337 + shooter.hash() % 9973))
	var p1: String = BALLS[rng.range_int(0, BALLS.size() - 1)]
	if shooter != "":
		p1 = shooter
	var p2: String = BALLS[rng.range_int(0, BALLS.size() - 1)]
	var starts: Array[Vector2] = []
	while starts.size() < 2:
		var p := Vector2(_coord(rng), _coord(rng))
		if starts.is_empty() or p.distance_to(starts[0]) >= MIN_START_GAP:
			starts.append(p)
	var walls: Array[String] = []
	for i in rng.range_int(1, 3):
		var w: String = WALLS[rng.range_int(0, 3)]
		while not walls.is_empty() and w == walls[-1]:
			w = WALLS[rng.range_int(0, 3)]
		walls.append(w)
	return {"day": day, "p1": p1, "p2": p2, "starts": starts, "walls": walls}


static func _coord(rng) -> float:
	return EDGE_MARGIN + float(rng.range_int(0, int(MatchSim.ARENA_SIZE - 2.0 * EDGE_MARGIN)))


## The real sim for a shot: the foe waits until it is hit.
static func make_sim(puzzle: Dictionary, aim_deg: int) -> MatchSim:
	var sim := MatchSim.new({"seed": 1, "p1": puzzle.p1, "p2": puzzle.p2, "starts": puzzle.starts, "angles": [aim_deg * 10, 0], "fields": false, "seek": 0.0}) # An aim puzzle: no pull.
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
			shot.walls.append(_wall_at(e.pos))
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


static func _wall_at(pos: Vector2) -> String:
	if pos.x <= 0.0:
		return "left"
	if pos.x >= MatchSim.ARENA_SIZE:
		return "right"
	return "top" if pos.y <= 0.0 else "bottom"


## judge().result without a MatchSim: until the first contact the balls only
## fly straight and bounce off the walls, so this replays just that with the
## sim's own arithmetic, many times faster. Tests check it agrees with judge()
## on every aim.
static func fast_judge(puzzle: Dictionary, aim_deg: int) -> String:
	var r0: float = BallDefs.get_def(puzzle.p1).radius
	var r1: float = BallDefs.get_def(puzzle.p2).radius
	var min_dist := r0 + r1
	var p: Vector2 = puzzle.starts[0]
	var target: Vector2 = puzzle.starts[1]
	var speed: float = BallDefs.get_def(puzzle.p1).speed
	var v := Vector2.from_angle(deg_to_rad(aim_deg * 10 / 10.0)) * speed
	var hi := MatchSim.ARENA_SIZE
	var called: Array = puzzle.walls
	var walls := 0
	for t in int(TIME_LIMIT * MatchSim.TICK_RATE):
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
		if solutions.is_empty():
			continue
		puzzle.solutions = solutions
		puzzle.candidate = k
		if solutions.size() >= MIN_SOLUTIONS and solutions.size() <= MAX_SOLUTIONS:
			return puzzle
		if best.is_empty() or solutions.size() < best.solutions.size():
			best = puzzle
	return best
