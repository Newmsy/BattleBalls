## Ball Royale: 8 balls in one arena, every ball for itself, last one standing
## (design/ball-royale.md in the project files). A MatchSim with more balls:
## movement, collisions, beams and abilities are the 1v1 rules unchanged, at
## equal power. What changes is the setup (8 seats round the arena), an early
## and faster shrink, KO credit and placements.
##
## Config: { seed: int, critters: [8 ids], angles: [8 x (tenths of a degree or null)] }
## Ball 0 is the player. Like every fight, a royale replays exactly from the
## seed and the launch angles (null angles are drawn from the seed).
extends "res://sim/match_sim.gd"

const SIZE := 8
const SEAT_RADIUS := 360.0 ## Seats sit on a ring round the centre.
const SEAT_START := 135.0 ## Degrees, screen space: seat 0 (you) is bottom left.
const ROYALE_SHRINK_START := 20.0
const ROYALE_SHRINK_SPEED := 10.0 ## Units per second per side: fully shrunk at 50s.
const ROYALE_TIME_LIMIT := 90.0
## Crowd rules, tuned so every critter's win share stays near 1 in 8
## (tests/test_royale.gd). Balls are a little smaller so eight fit; all damage
## is lower so the pile-up at the centre doesn't end it in seconds; and heals
## are cut because a healer hits far more often in a crowd than in a 1v1.
const RADIUS_SCALE := 0.85
const DAMAGE_SCALE := 0.6
const HEAL_SCALE := 0.35
const RANDOM_SPREAD := 300 ## Random aims: tenths of a degree either side of the centre.

## Finishing order: ball indexes, winner first. Filled as balls go out.
var placings: Array[int] = []
## KOs credited to each ball.
var kos: Array[int] = []
## Who knocked each ball out (ball index, or -1 if it is still in).
var ko_by: Array[int] = []

var _out: Array[int] = [] ## Balls in the order they went out.
var _last_hitter: Array[int] = []


func _init(cfg: Dictionary) -> void:
	# The 1v1 setup builds two placeholder balls; replace them with the eight seats.
	super({"seed": int(cfg.get("seed", 1))})
	config = cfg
	rng = Rng.new(int(cfg.get("seed", 1)))
	balls.clear()
	launch_angles.clear()
	overtime_start = ROYALE_SHRINK_START
	shrink_speed = ROYALE_SHRINK_SPEED
	time_limit = ROYALE_TIME_LIMIT
	var types: Array = cfg.get("critters", [])
	assert(types.size() == SIZE, "Ball Royale needs %d critters" % SIZE)
	var angles: Array = cfg.get("angles", [])
	for i in SIZE:
		var def := BallDefs.get_def(types[i]).duplicate()
		def.heal_ratio = def.get("heal_ratio", 0.0) * HEAL_SCALE
		var b := Ball.new()
		b.index = i
		b.type_id = types[i]
		b.def = def
		b.radius = def.radius * RADIUS_SCALE
		b.speed = def.speed
		b.max_hp = def.hp
		b.hp = def.hp
		b.contact_damage = def.contact_damage
		b.pos = seat(i)
		# Always draw from the rng so a given aim doesn't shift later rolls.
		var random_aim: int = aim_at_centre(i) + rng.range_int(-RANDOM_SPREAD, RANDOM_SPREAD)
		var given = angles[i] if i < angles.size() else null
		var aim: int = random_aim if given == null else int(given)
		launch_angles.append(aim)
		b.vel = Vector2.from_angle(deg_to_rad(aim / 10.0)) * b.speed
		balls.append(b)
		kos.append(0)
		ko_by.append(-1)
		_last_hitter.append(-1)


## Arena position of seat `i`, going clockwise on screen from seat 0.
static func seat(i: int) -> Vector2:
	var a := deg_to_rad(SEAT_START + i * 360.0 / SIZE)
	return Vector2(ARENA_SIZE / 2.0, ARENA_SIZE / 2.0) + Vector2.from_angle(a) * SEAT_RADIUS


## Launch angle (tenths of a degree) from seat `i` straight at the centre.
static func aim_at_centre(i: int) -> int:
	return posmod(roundi((SEAT_START + 180.0 + i * 360.0 / SIZE) * 10.0) + 1800, 3600) - 1800


func alive_count() -> int:
	return balls.filter(func(b: Ball) -> bool: return b.alive()).size()


## Finishing place of ball `i` (1 = winner), or 0 while it is still in.
func place_of(i: int) -> int:
	var at := placings.find(i)
	if at >= 0:
		return at + 1
	at = _out.find(i)
	return SIZE - at if at >= 0 else 0


func summary() -> Dictionary:
	var hp: Array[float] = []
	for b in balls:
		hp.append(b.hp)
	return {
		"winner": winner,
		"reason": end_reason,
		"ticks": tick,
		"time": time(),
		"hp": hp,
		"placings": placings.duplicate(),
		"kos": kos.duplicate(),
		"hash": state_hash(),
	}


func _apply_hits(hits: Array[Dictionary]) -> void:
	# The last ball to land damage gets the KO.
	for h in hits:
		h.amount *= DAMAGE_SCALE
		if h.amount > 0.0 and balls[h.target].alive():
			_last_hitter[h.target] = h.source
	super._apply_hits(hits)


func _check_end(hp_before: Array[float]) -> void:
	var gone: Array[int] = []
	for b in balls:
		if not b.alive() and not _out.has(b.index):
			gone.append(b.index)
	# Balls out on the same tick: more HP going into it places higher.
	gone.sort_custom(func(x: int, y: int) -> bool:
		return hp_before[x] < hp_before[y] if hp_before[x] != hp_before[y] else x > y)
	var left := alive_count()
	for i in gone:
		_out.append(i)
		var by := _last_hitter[i]
		ko_by[i] = by
		if by >= 0:
			kos[by] += 1
		events.append({"type": "ko", "ball": i, "by": by, "place": SIZE - _out.size() + 1})
	if left <= 1:
		var order: Array[int] = []
		if left == 1:
			for b in balls:
				if b.alive():
					order.append(b.index)
		_set_placings(order)
		# Everyone left went out on the same tick: the last of them to go places first.
		_finish(placings[0], "knockout" if left == 1 else "double_knockout")
	elif time() >= time_limit:
		# Time: survivors place by HP share, then by KOs, then by seat.
		var order: Array[int] = []
		for b in balls:
			if b.alive():
				order.append(b.index)
		order.sort_custom(func(x: int, y: int) -> bool:
			var fx := balls[x].hp / balls[x].max_hp
			var fy := balls[y].hp / balls[y].max_hp
			if fx != fy:
				return fx > fy
			return kos[x] > kos[y] if kos[x] != kos[y] else x < y)
		_set_placings(order)
		_finish(placings[0], "time_limit")


## Survivors (best first) followed by everyone who went out, last out first.
func _set_placings(survivors: Array[int]) -> void:
	placings = survivors.duplicate()
	for k in range(_out.size() - 1, -1, -1):
		placings.append(_out[k])
