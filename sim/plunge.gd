## Critter Plunge: a marble-run race where critters fight on the way down.
## 4, 6 or 8 critters drop from a gate through a seeded course
## (sim/plunge_course.gd); first over the line wins. Each critter races with
## its real ability: this is a MatchSim (sim/match_sim.gd) where every ball is
## its own team, so sim/abilities.gd runs unchanged. Gravity and the course
## replace the arena's walls, and a bounce off the course counts as a wall
## bounce for "wall" abilities. Only critters whose abilities read well on a
## course race (RACERS); more join as they're balanced in.
##
## Damage changes places: a hit staggers its target (it loses speed), slows,
## stuns and pulls work as in a fight, and a racer at 0 HP is knocked out and
## places last.
##
## Deterministic like MatchSim: the same config always gives the same race.
##
## Config: {seed: int, racers: [ids], tiers: [int]?, boosts: [{tough, power,
## steady} or null]?}. Everyone races at the same power, so the drop and the
## abilities decide it; boosts are your race talents (meta/plunge_talents.gd):
## tough adds that share of HP, power of damage, and steady takes that share
## off the speed a hit costs.
extends "res://sim/match_sim.gd"

const PlungeCourse := preload("res://sim/plunge_course.gd")
const CritterDb := preload("res://sim/critter_db.gd")

## Bump whenever a change alters race outcomes.
const RACE_RULES := 3
const FIELD_SIZES := [4, 6, 8]
const WIDTH := PlungeCourse.WIDTH
const RADIUS := 30.0 ## Every racer races this size, whatever its fight size.
const GRAVITY := 900.0
const MAX_SPEED := 900.0
const DRAG := 0.35 ## Fraction of speed lost per second in the air.
const RACER_BOUNCE := 0.8
const STUN_SINK := 70.0 ## How fast a stunned racer sinks (it doesn't hang in the air).
const CHARGE_SIDE := 260.0 ## Sideways speed of a charge at x1.
const GATE_SECONDS := 1.0
const RACE_LIMIT := 120.0
const PARK_DROP := 110.0 ## How far past the line finished racers line up.
const AFTER_WIN := 12.0 ## Seconds the race runs on after the winner, for places.
## A bounce off the course this hard counts as a wall bounce ("wall"
## abilities), at most once per BOUNCE_GAP seconds per racer.
const BOUNCE_MIN := 180.0
const BOUNCE_GAP := 0.6
const PEG_EVENT := 200.0 ## A peg hit this hard flashes the peg (render only).
## A racer that really is stuck (balanced on a peg, pinned in a pile) gets a
## sideways nudge along the ground, never a hop: rolling stays rolling.
const STALL_SPEED := 30.0
const STALL := 1.5
const NUDGE_COOLDOWN := 3.0
const NUDGE := 140.0
## Racer-on-racer bumps only hit (contact damage, "hit" abilities) when they
## close this fast: a pile resting together doesn't grind itself down.
const BUMP_MIN := 260.0
## Speed kept when a hit of STAGGER_AT or more damage lands.
const STAGGER := 0.6
const STAGGER_AT := 3.0
## The knockout knob: most damage happens in jams, so crowded fields need
## less of it. Tuned for about 1 racer in 4 knocked out.
const DAMAGE_BY_FIELD := {4: 1.1, 6: 0.75, 8: 0.6}

## The critters that race, by family: ones whose abilities read well on a
## course. Others join as they're balanced in.
const RACERS := [
	"pip", "thorns", "whiff", # nature
	"bubbles", "ink", "ripple", # sea
	"laser", "static", "zapper", # tech
	"honey", "gumdrop", "pucker", # sweet
	"frost", "drizzle", "blizz", # frost
	"drum", "mortar", "pinball", # toybox
	"vampire", "sonar", "brewster", # spooky
	"sooty", "bomber", "magmo", # fire
	"comet", "gravity", "prism", # cosmic
]

## Race-only scaling of a critter's ability params (multipliers), where its
## fight numbers don't fit a race. Gravity's pull dragged the pack onto it.
const RACE_TWEAKS := {
	"gravity": {"pull_accel": 0.5},
}

var course: PlungeCourse
var finish_y := 0.0
var lanes: Array[int] = [] ## Racer -> its gate, 0 = leftmost.
var places: Array[int] = [] ## Racer -> 1 = winner; 0 while racing.
var finish_ticks: Array[int] = []
var ko_ticks: Array[int] = []
var order: Array[int] = [] ## Racer indexes by place, once finished.
var kos: Array[int] = [] ## Racer indexes in the order they were knocked out.
var damage_scale := 1.0

var _starts: Array[Vector2] = []
var _steady: Array[float] = []
var _stalled: Array[float] = []
var _nudge_ready: Array[int] = []
var _bounce_ready: Array[int] = []
var _win_tick := -1
var _focus_y := 0.0 ## Where the pack is: the "arena" abilities see is around it.


func _init(cfg: Dictionary) -> void:
	var seed_value := int(cfg.get("seed", 1))
	var ids: Array = cfg.get("racers", [])
	if ids.is_empty():
		ids = draw_field(seed_value, 6)
	# Gates are shuffled by the seed so nobody picks a lane.
	var shuffle := Rng.new(seed_value * 131 + 3)
	var lane_of := range(ids.size())
	for i in range(lane_of.size() - 1, 0, -1):
		var j: int = shuffle.range_int(0, i)
		var t = lane_of[i]
		lane_of[i] = lane_of[j]
		lane_of[j] = t
	var lane_w := WIDTH / ids.size()
	var starts := []
	var sizes := []
	for i in ids.size():
		lanes.append(lane_of[i])
		starts.append(Vector2(lane_w * (lane_of[i] + 0.5), PlungeCourse.START_Y))
		sizes.append(RADIUS / float(BallDefs.DEFS[ids[i]].radius))
	var tiers: Array = cfg.get("tiers", [])
	super._init({"seed": seed_value, "players": ids, "ffa": true, "starts": starts, "sizes": sizes,
		"angles": ids.map(func(_i): return 900), "tiers": tiers, "rarity_potency": false,
		"family_edges": false, "racers": ids})
	config.merge(cfg, true)
	overtime_start = INF
	damage_scale = field_damage(ids.size())
	course = PlungeCourse.new(seed_value)
	finish_y = course.finish_y
	_focus_y = PlungeCourse.START_Y + 400.0
	var boosts: Array = cfg.get("boosts", [])
	for b in balls:
		var boost = boosts[b.index] if b.index < boosts.size() else null
		if boost is Dictionary:
			b.max_hp *= 1.0 + float(boost.get("tough", 0.0))
			b.hp = b.max_hp
			b.attack += float(boost.get("power", 0.0))
		_steady.append(float(boost.get("steady", 0.0)) if boost is Dictionary else 0.0)
		if RACE_TWEAKS.has(b.type_id):
			b.def = b.def.duplicate()
			for key in RACE_TWEAKS[b.type_id]:
				b.def[key] = b.def[key] * RACE_TWEAKS[b.type_id][key]
		_starts.append(b.pos)
		b.vel = Vector2(-90.0 + 180.0 * rng.next_float(), 60.0 * rng.next_float())
		places.append(0)
		finish_ticks.append(-1)
		ko_ticks.append(-1)
		_stalled.append(0.0)
		_nudge_ready.append(0)
		_bounce_ready.append(0)


## The damage multiplier for a field of `n` racers (between the tuned sizes
## it is interpolated).
static func field_damage(n: int) -> float:
	if DAMAGE_BY_FIELD.has(n):
		return DAMAGE_BY_FIELD[n]
	if n <= 4:
		return DAMAGE_BY_FIELD[4]
	if n >= 8:
		return DAMAGE_BY_FIELD[8]
	var lo := 4 if n < 6 else 6
	var hi := 6 if n < 6 else 8
	return lerpf(DAMAGE_BY_FIELD[lo], DAMAGE_BY_FIELD[hi], float(n - lo) / float(hi - lo))


static func can_race(id: String) -> bool:
	return RACERS.has(id)


## `n` different racing critters for a seed, never one in `exclude`.
static func draw_field(seed_value: int, n: int, exclude: Array = []) -> Array:
	var r := Rng.new(seed_value * 31 + 7)
	var pool: Array = []
	for id in RACERS:
		if not exclude.has(id) and CritterDb.has(id):
			pool.append(id)
	var out := []
	while out.size() < n and not pool.is_empty():
		out.append(pool.pop_at(r.range_int(0, pool.size() - 1)))
	return out


func racing(i: int) -> bool:
	return places[i] == 0 and ko_ticks[i] < 0


## How far down the course racer `i` is, 0 at the gate to 1 at the finish.
func progress(i: int) -> float:
	if places[i] > 0 and ko_ticks[i] < 0:
		return 1.0
	return clampf((balls[i].pos.y - PlungeCourse.START_Y) / (finish_y - PlungeCourse.START_Y), 0.0, 1.0)


## Racer indexes in race order: finished racers by place, then those still
## racing by how far down they are, then the knocked out (latest first).
func standings() -> Array[int]:
	if finished:
		return order.duplicate()
	var out: Array[int] = order.duplicate()
	var rest: Array = range(starters).filter(func(i): return racing(i))
	rest.sort_custom(func(a, b): return balls[a].pos.y > balls[b].pos.y if balls[a].pos.y != balls[b].pos.y else a < b)
	for i in rest:
		out.append(i)
	for i in range(kos.size() - 1, -1, -1):
		out.append(kos[i])
	return out


func race_winner() -> int:
	return order[0] if not order.is_empty() else -1


## Runs the race to the end and returns {order, kos, time, win_time}.
func run() -> Dictionary:
	while not finished:
		step()
	return {"order": order.duplicate(), "kos": kos.duplicate(), "time": time(), "win_time": _win_tick * DT if _win_tick >= 0 else time()}


func step() -> void:
	if finished:
		return
	# Balls in a fight keep a constant speed: give each racer its own speed
	# every tick, so bounces and pulls turn it without braking or boosting it.
	for b in balls:
		b.speed = b.vel.length()
	var hp_before: Array[float] = []
	for b in balls:
		hp_before.append(b.hp)
	super.step()
	var sum := 0.0
	var n := 0
	for i in starters:
		var b := balls[i]
		if not racing(i):
			continue
		if not b.alive():
			_knock_out(i)
			continue
		if b.hp < hp_before[i] - STAGGER_AT and time() >= GATE_SECONDS:
			b.vel *= STAGGER + (1.0 - STAGGER) * _steady[i]
		if b.pos.y >= finish_y:
			_cross_line(i)
			continue
		_stalled[i] = _stalled[i] + DT if b.vel.length() < STALL_SPEED and time() >= GATE_SECONDS else 0.0
		if _stalled[i] >= STALL and tick >= _nudge_ready[i]:
			_nudge_ready[i] = tick + int(NUDGE_COOLDOWN * TICK_RATE)
			_stalled[i] = 0.0
			b.vel.x += NUDGE if b.pos.x < WIDTH / 2.0 else -NUDGE
		sum += b.pos.y
		n += 1
	if n > 0:
		_focus_y = sum / n
	if order.size() + kos.size() >= starters or time() >= RACE_LIMIT or (_win_tick >= 0 and tick - _win_tick >= int(AFTER_WIN * TICK_RATE)):
		_settle()


# --- MatchSim hooks --------------------------------------------------------------

## A race has no overtime and no fight-ending knockouts: step() ends it.
func _check_end(_hp_before: Array[float]) -> void:
	pass


func damage_multiplier() -> float:
	return damage_scale


## What abilities see as "the arena": a screen-sized window round the pack,
## the full width of the shaft.
func arena_rect() -> Rect2:
	return Rect2(0.0, _focus_y - WIDTH / 2.0, WIDTH, WIDTH)


## Racers who finished or are out aren't targets.
func foes(b: Ball) -> Array[Ball]:
	var out: Array[Ball] = []
	for o in balls:
		if o.team != b.team and o.alive() and (o.index >= starters or racing(o.index)):
			out.append(o)
	return out


## Aimed abilities (shots, charges, lunges) go for the nearest racer ahead:
## in a race that's the one worth hitting, and a charge uphill would throw
## the race. With nobody ahead, the nearest one behind.
func nearest_foe(b: Ball) -> Ball:
	var best: Ball = null
	var best_ahead := false
	for o in foes(b):
		var ahead: bool = o.pos.y > b.pos.y
		if best == null or (ahead and not best_ahead) or (ahead == best_ahead and b.pos.distance_squared_to(o.pos) < b.pos.distance_squared_to(best.pos)):
			best = o
			best_ahead = ahead
	return best


## A charge or lunge in a race is a swerve toward its target: a sideways
## shove that never speeds the drop (a charge aimed downhill won 3.5x), and
## the racer stays "charging" for abilities that hit harder meanwhile.
func charge(b: Ball, dir: Vector2, mult: float, secs: float) -> void:
	if dir.length() < 0.001:
		return
	var d := dir.normalized()
	b.charge_mult = 1.0
	b.charge_ticks = maxi(1, int(round(secs * TICK_RATE)))
	b.vel.x += d.x * CHARGE_SIDE * minf(2.0, mult)
	b.speed = b.vel.length()
	events.append({"type": "charge", "ball": b.index, "pos": b.pos, "dir": d})


## Gravity and the course, in place of the arena's walls. Called once a tick
## for each ball after it moves.
func _resolve_walls(b: Ball) -> void:
	if b.index < starters and not racing(b.index):
		return
	if time() < GATE_SECONDS:
		b.pos = _starts[b.index] if b.index < _starts.size() else b.pos
		return
	if tick < b.stun_until: # Stunned (frozen, stuck in honey): it sinks slowly.
		b.vel = Vector2(0.0, STUN_SINK)
		b.pos += b.vel * DT
	else:
		b.vel.y += GRAVITY * DT
		b.vel *= 1.0 - DRAG * DT
		var sp := b.vel.length()
		if sp > MAX_SPEED:
			b.vel *= MAX_SPEED / sp
	var hit := course.collide(b, DT)
	if hit.peg != null and hit.speed >= PEG_EVENT:
		events.append({"type": "course_hit", "ball": b.index, "peg": hit.peg, "bumper": hit.bumper, "pos": hit.point})
	if hit.speed >= BOUNCE_MIN and tick >= _bounce_ready[b.index] and b.index < starters:
		_bounce_ready[b.index] = tick + int(BOUNCE_GAP * TICK_RATE)
		_on_wall_bounce(b, hit.point, true)
	b.speed = b.vel.length()


## Racers bounce off each other like marbles, not fight balls (they keep no
## constant speed), and only a hard bump hurts.
func _resolve_ball_collisions(hits: Array[Dictionary]) -> void:
	for i in balls.size():
		var a := balls[i]
		if not a.alive() or (i < starters and not racing(i)):
			continue
		for j in range(i + 1, balls.size()):
			var b := balls[j]
			if not b.alive() or (j < starters and not racing(j)):
				continue
			# A stunned racer (frozen, stuck in honey) sinks out of the way:
			# others pass it, so a trap never walls in the one who set it.
			if tick < a.stun_until or tick < b.stun_until:
				continue
			var delta := b.pos - a.pos
			var reach := a.radius + b.radius
			if delta.x >= reach or delta.x <= -reach or delta.y >= reach or delta.y <= -reach:
				continue
			var dist := delta.length()
			if dist >= reach:
				continue
			var n := delta / dist if dist > 0.0001 else Vector2.RIGHT
			var overlap := reach - dist
			a.pos -= n * overlap * 0.5
			b.pos += n * overlap * 0.5
			var approach := (a.vel - b.vel).dot(n)
			if approach <= 0.0:
				continue
			var a_share := clampf(a.vel.dot(n) / approach, 0.0, 1.0)
			var impulse := approach * (1.0 + RACER_BOUNCE) * 0.5
			a.vel -= n * impulse
			b.vel += n * impulse
			a.speed = a.vel.length()
			b.speed = b.vel.length()
			if approach < BUMP_MIN:
				continue
			var contact := a.pos + n * a.radius
			events.append({"type": "collide", "a": i, "b": j, "pos": contact})
			abilities.fire(self, "bump", a, {"other": b})
			abilities.fire(self, "bump", b, {"other": a})
			var key := "%d:%d" % [i, j]
			if tick < int(_contact_cooldown_until.get(key, 0)):
				continue
			_contact_cooldown_until[key] = tick + int(round(CONTACT_COOLDOWN * TICK_RATE))
			# The racer that rams harder hits harder.
			var force := minf(2.0, approach / 500.0)
			hits.append({"source": i, "target": j, "amount": a.contact_damage * force * _impact_scale(a_share) * _strike(a, b), "kind": "contact", "pos": b.pos})
			hits.append({"source": j, "target": i, "amount": b.contact_damage * force * _impact_scale(1.0 - a_share) * _strike(b, a), "kind": "contact", "pos": a.pos})


# --- Places ---------------------------------------------------------------------

func _cross_line(i: int) -> void:
	order.append(i)
	places[i] = order.size()
	finish_ticks[i] = tick
	if _win_tick < 0:
		_win_tick = tick
	events.append({"type": "finish", "racer": i, "place": places[i], "pos": balls[i].pos})
	_park(i)


func _knock_out(i: int) -> void:
	ko_ticks[i] = tick
	kos.append(i)
	events.append({"type": "race_ko", "racer": i, "pos": balls[i].pos})


## A finished racer leaves the course for its spot in the row past the
## finish, in place order; its zones go with it and its abilities stop.
func _park(i: int) -> void:
	var b := balls[i]
	b.vel = Vector2.ZERO
	b.speed = 0.0
	b.pos = Vector2(WIDTH * (places[i] - 0.5) / starters, finish_y + PARK_DROP)
	b.def = b.def.duplicate()
	b.def.effects = [] # Its race is run: its abilities rest.
	for z in zones.duplicate():
		if z.owner == i:
			zones.erase(z)


## Places everyone left: those still racing by how far down they got, then
## the knocked out, the latest knockout highest.
func _settle() -> void:
	var rest: Array = range(starters).filter(func(i): return racing(i))
	rest.sort_custom(func(a, b): return balls[a].pos.y > balls[b].pos.y if balls[a].pos.y != balls[b].pos.y else a < b)
	for i in rest:
		order.append(i)
		places[i] = order.size()
	for k in range(kos.size() - 1, -1, -1):
		order.append(kos[k])
		places[kos[k]] = order.size()
	finished = true
	events.append({"type": "race_end"})
