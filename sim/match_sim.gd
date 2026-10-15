## Deterministic 1v1 match simulation. No nodes, no engine physics, no
## rendering: the same config always produces the same fight, so it can run
## headless for tests and balance sims, and be replayed from a Report code.
##
## Config: { seed: int, p1: String, p2: String, angles: [a1, a2], starts: [v1, v2], tiers: [t1, t2] }
## Angles are launch directions in tenths of a degree (screen space, y down),
## or null to let the seed pick one. `starts` (optional) overrides the start
## corners with arena positions; random aims still centre on the corners.
## `hp` (optional) sets each ball's starting HP (null = full), for relays
## where a winner stays in with what it has left.
## `fields: false` (optional) switches off every-tick abilities (fields like
## Flux's), so Daily Trick Shot balls fly straight.
## `tiers` (optional, default 1) apply each critter's T1-T5 ability upgrades.
## Critters and their abilities come from sim/critters/ via sim/ball_defs.gd;
## this file only fires their triggers (sim/abilities.gd).
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Abilities := preload("res://sim/abilities.gd")

## Bump whenever a change alters fight outcomes (i.e. golden replays are
## re-recorded): saved Ghost Arena lineups only meet fights on the same rules.
const RULES_VERSION := 1
const TICK_RATE := 60
const DT := 1.0 / TICK_RATE
const ARENA_SIZE := 1000.0
const OVERTIME_START := 45.0
const SHRINK_SPEED := 12.0 ## Arena units per second, per side.
const MIN_HALF := 200.0
const OVERTIME_DAMAGE_RAMP := 0.05 ## +5% damage per second of overtime.
const TIME_LIMIT := 120.0
const CONTACT_COOLDOWN := 0.25
## Contact damage ranges from (1 - spread)x to (1 + spread)x by who rammed whom.
const IMPACT_SPREAD := 0.5
const BEAM_HALF_WIDTH := 5.0
const MIN_BEAM_LENGTH := 30.0
const RANDOM_AIM_SPREAD := 400 ## Tenths of a degree either side of the centre line.

const START_CORNERS := [Vector2(170, 830), Vector2(830, 170)]
const AIM_AT_CENTRE := [-450, 1350] ## Tenths of a degree from each corner.


class Ball:
	var index: int
	var type_id: String
	var def: Dictionary
	var pos: Vector2
	var vel: Vector2
	var radius: float
	var speed: float
	var hp: float
	var max_hp: float
	var contact_damage: float
	var has_bounce := false
	var last_bounce := Vector2.ZERO
	var damage_dealt := 0.0
	var healed := 0.0
	var team: int ## 0 or 1; the two starting balls are teams 0 and 1.
	var slow := 0.0 ## 0-1 share of movement lost this tick (zones set it).
	var shield := 0.0 ## Absorbs damage before HP.
	var dots: Array[Dictionary] = [] ## Damage over time: {source, dps, until, next}.
	var fired := {} ## One-shot triggers already used (Abilities.tick_triggers).
	var state := {} ## Per-ball ability state, e.g. a field's "pulling" (read by the renderer).

	func alive() -> bool:
		return hp > 0.0


class Beam:
	var owner: int
	var a: Vector2
	var b: Vector2
	var age := 0.0
	var life: float
	var damage: float
	var cooldown_ticks: int
	var last_hit_tick := {} ## target index -> tick of last hit

	func strength() -> float:
		return clampf(1.0 - age / life, 0.0, 1.0)


## A circle on the floor owned by a ball: a mine, an icy trail blob, a fire
## patch. It slows and/or damages the owner's foes while they overlap it; a
## mine (blast > 0) explodes once on the first foe that touches it.
class Zone:
	var owner: int
	var kind: String ## For the renderer: "mine", "ice", "fire", "ring"...
	var pos: Vector2
	var radius: float
	var life: float
	var age := 0.0
	var arm := 0.0 ## Seconds before it does anything.
	var slow := 0.0
	var dps := 0.0
	var blast := 0.0
	var blast_radius := 0.0
	var chain := false ## A blast sets off the owner's other armed mines in reach.
	var next_hit := {} ## target index -> tick it may next take dps damage

	func armed() -> bool:
		return age >= arm


var config: Dictionary
var rng
var balls: Array[Ball] = []
var beams: Array[Beam] = []
var zones: Array[Zone] = []
var tick := 0
var half_size := ARENA_SIZE / 2.0
var centre := Vector2(ARENA_SIZE / 2.0, ARENA_SIZE / 2.0)
var finished := false
var winner := -1 ## Ball index, or -1 for a draw (only meaningful when finished).
var end_reason := ""
var ko_hp: Array[float] = [] ## On a double knockout, each ball's HP going into the final tick.
var launch_angles: Array[int] = []
## Events produced by the most recent step(), for the renderer and tests.
var events: Array[Dictionary] = []

var abilities: Abilities

var _contact_cooldown_until := {} ## "i:j" -> tick
var _hits: Array[Dictionary] = [] ## This tick's damage, applied in _apply_hits.


func _init(cfg: Dictionary) -> void:
	config = cfg
	rng = Rng.new(int(cfg.get("seed", 1)))
	abilities = Abilities.new()
	var types: Array = [cfg.get("p1", "plain"), cfg.get("p2", "plain")]
	var angles: Array = cfg.get("angles", [null, null])
	var starts: Array = cfg.get("starts", START_CORNERS)
	var start_hp: Array = cfg.get("hp", [null, null])
	var tiers: Array = cfg.get("tiers", [1, 1])
	for i in 2:
		var def := BallDefs.get_def(types[i], int(tiers[i]))
		var b := Ball.new()
		b.index = i
		b.team = i
		b.type_id = types[i]
		b.def = def
		b.radius = def.radius
		b.speed = def.speed
		b.max_hp = def.hp
		b.hp = def.hp if start_hp[i] == null else clampf(float(start_hp[i]), 0.01, def.hp)
		b.contact_damage = def.contact_damage
		b.pos = starts[i]
		# Always draw from the rng so a given aim doesn't shift later rolls.
		var random_aim: int = AIM_AT_CENTRE[i] + rng.range_int(-RANDOM_AIM_SPREAD, RANDOM_AIM_SPREAD)
		var aim: int = random_aim if angles[i] == null else int(angles[i])
		launch_angles.append(aim)
		b.vel = Vector2.from_angle(deg_to_rad(aim / 10.0)) * b.speed
		balls.append(b)


func time() -> float:
	return tick * DT


func in_overtime() -> bool:
	return time() >= OVERTIME_START


func damage_multiplier() -> float:
	return 1.0 + maxf(0.0, time() - OVERTIME_START) * OVERTIME_DAMAGE_RAMP


func arena_rect() -> Rect2:
	return Rect2(centre - Vector2(half_size, half_size), Vector2(half_size, half_size) * 2.0)


func step() -> void:
	if finished:
		return
	events.clear()
	var hp_before: Array[float] = []
	for b in balls:
		hp_before.append(b.hp)

	if in_overtime():
		half_size = maxf(MIN_HALF, ARENA_SIZE / 2.0 - SHRINK_SPEED * (time() - OVERTIME_START))

	_hits = []
	for b in balls:
		b.slow = 0.0
	if config.get("fields", true):
		for b in balls:
			if b.alive():
				abilities.fire(self, "always", b)
	_update_zones()
	_update_dots()
	for b in balls:
		if b.alive():
			b.pos += b.vel * DT * (1.0 - b.slow)
			_resolve_walls(b)
	_resolve_ball_collisions(_hits)
	_update_beams(_hits)
	_apply_hits(_hits)
	for b in balls:
		if not b.alive() and not b.fired.has("fall"):
			b.fired["fall"] = true
			abilities.fire(self, "fall", b)
	for b in balls:
		if b.alive():
			abilities.tick_triggers(self, b)

	tick += 1
	_check_end(hp_before)


## Runs until the match ends. Returns a summary dictionary.
func run_to_end() -> Dictionary:
	var max_ticks := int(TIME_LIMIT * TICK_RATE) + 1
	while not finished and tick <= max_ticks:
		step()
	return summary()


func summary() -> Dictionary:
	return {
		"winner": winner,
		"reason": end_reason,
		"ticks": tick,
		"time": time(),
		"hp": [balls[0].hp, balls[1].hp],
		"hash": state_hash(),
	}


## Hash of the full simulation state; equal hashes mean identical fights.
func state_hash() -> String:
	var data := PackedFloat64Array([tick, half_size, beams.size()])
	for b in balls:
		data.append_array([b.pos.x, b.pos.y, b.vel.x, b.vel.y, b.hp])
	for beam in beams:
		data.append_array([beam.a.x, beam.a.y, beam.b.x, beam.b.y, beam.age])
	for z in zones:
		data.append_array([z.pos.x, z.pos.y, z.age])
	for b in balls:
		if b.shield > 0.0 or not b.dots.is_empty():
			data.append_array([b.index, b.shield, b.dots.size()])
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data.to_byte_array())
	return ctx.finish().hex_encode()


func _resolve_walls(b: Ball) -> void:
	var r := arena_rect()
	if b.pos.x - b.radius < r.position.x:
		b.pos.x = r.position.x + b.radius
		if b.vel.x < 0.0:
			b.vel.x = -b.vel.x
			_on_wall_bounce(b, Vector2(r.position.x, b.pos.y))
	elif b.pos.x + b.radius > r.end.x:
		b.pos.x = r.end.x - b.radius
		if b.vel.x > 0.0:
			b.vel.x = -b.vel.x
			_on_wall_bounce(b, Vector2(r.end.x, b.pos.y))
	if b.pos.y - b.radius < r.position.y:
		b.pos.y = r.position.y + b.radius
		if b.vel.y < 0.0:
			b.vel.y = -b.vel.y
			_on_wall_bounce(b, Vector2(b.pos.x, r.position.y))
	elif b.pos.y + b.radius > r.end.y:
		b.pos.y = r.end.y - b.radius
		if b.vel.y > 0.0:
			b.vel.y = -b.vel.y
			_on_wall_bounce(b, Vector2(b.pos.x, r.end.y))


func _on_wall_bounce(b: Ball, point: Vector2) -> void:
	events.append({"type": "bounce", "ball": b.index, "pos": point})
	var slam: Dictionary = b.state.get("slam", {})
	if not slam.is_empty() and tick <= slam.until:
		b.state.erase("slam")
		deal(balls[slam.source], b, slam.damage, "slam", point)
	abilities.fire(self, "wall", b, {"point": point})
	b.has_bounce = true
	b.last_bounce = point


## A beam from `a` to `b` owned by ball `owner`, using its beam_* params. Keeps
## at most beam_max of the owner's beams, dropping the oldest.
## `opts` may override "life", "damage" and "cooldown" (seconds).
func add_beam(owner: Ball, a: Vector2, b: Vector2, opts := {}) -> void:
	var beam := Beam.new()
	beam.owner = owner.index
	beam.a = a
	beam.b = b
	beam.life = opts.get("life", owner.def.get("beam_life", 1.0))
	beam.damage = opts.get("damage", owner.def.get("beam_damage", 0.0))
	beam.cooldown_ticks = int(round(opts.get("cooldown", owner.def.get("beam_hit_cooldown", 0.5)) * TICK_RATE))
	beams.append(beam)
	var own_beams := beams.filter(func(x: Beam) -> bool: return x.owner == owner.index)
	if own_beams.size() > owner.def.get("beam_max", 6):
		beams.erase(own_beams[0])
	events.append({"type": "beam", "owner": owner.index, "a": beam.a, "b": beam.b})


func _resolve_ball_collisions(hits: Array[Dictionary]) -> void:
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			var a := balls[i]
			var b := balls[j]
			if not a.alive() or not b.alive():
				continue
			var delta := b.pos - a.pos
			var dist := delta.length()
			var min_dist := a.radius + b.radius
			if dist >= min_dist:
				continue
			var n := delta / dist if dist > 0.0001 else Vector2.RIGHT
			var ma := a.radius * a.radius
			var mb := b.radius * b.radius
			# Push apart in proportion to the other ball's mass.
			var overlap := min_dist - dist
			a.pos -= n * overlap * (mb / (ma + mb))
			b.pos += n * overlap * (ma / (ma + mb))
			var approach := (a.vel - b.vel).dot(n)
			if approach <= 0.0:
				continue
			# Share of the closing speed each ball supplied, from before the bounce.
			var a_share := clampf(a.vel.dot(n) / approach, 0.0, 1.0)
			var impulse := 2.0 * approach / (1.0 / ma + 1.0 / mb)
			a.vel -= n * (impulse / ma)
			b.vel += n * (impulse / mb)
			# Balls keep a constant speed: only direction changes.
			a.vel = a.vel.normalized() * a.speed if a.vel.length() > 0.001 else -n * a.speed
			b.vel = b.vel.normalized() * b.speed if b.vel.length() > 0.001 else n * b.speed
			var contact := a.pos + n * a.radius
			events.append({"type": "collide", "a": i, "b": j, "pos": contact})
			abilities.fire(self, "bump", a, {"other": b})
			abilities.fire(self, "bump", b, {"other": a})
			if a.team == b.team:
				continue
			var key := "%d:%d" % [i, j]
			if tick < int(_contact_cooldown_until.get(key, 0)):
				continue
			_contact_cooldown_until[key] = tick + int(round(CONTACT_COOLDOWN * TICK_RATE))
			# The ball that rams harder hits harder, so even mirror matches trade unevenly.
			hits.append({"source": i, "target": j, "amount": a.contact_damage * _impact_scale(a_share) * _strike(a, b), "kind": "contact", "pos": b.pos})
			hits.append({"source": j, "target": i, "amount": b.contact_damage * _impact_scale(1.0 - a_share) * _strike(b, a), "kind": "contact", "pos": a.pos})


## Contact damage multiplier from the striker's "strike" effects (e.g. snap).
func _strike(striker: Ball, target: Ball) -> float:
	var ctx := {"target": target, "mult": 1.0}
	abilities.fire(self, "strike", striker, ctx)
	return ctx.mult


## Turns a ball by `accel` (units/s^2) for one tick, keeping its speed.
func steer(b: Ball, accel: Vector2) -> void:
	var v := b.vel + accel * DT
	if v.length() > 0.001:
		b.vel = v.normalized() * b.speed


## 0 share (was hit while moving away) -> 1 - IMPACT_SPREAD; 1 share -> 1 + IMPACT_SPREAD.
func _impact_scale(share: float) -> float:
	return 1.0 + IMPACT_SPREAD * (2.0 * share - 1.0)


func _update_beams(hits: Array[Dictionary]) -> void:
	for beam in beams.duplicate():
		beam.age += DT
		if beam.age >= beam.life:
			beams.erase(beam)
			continue
		for target in balls:
			if target.team == balls[beam.owner].team or not target.alive():
				continue
			var closest := Geometry2D.get_closest_point_to_segment(target.pos, beam.a, beam.b)
			if closest.distance_to(target.pos) > target.radius + BEAM_HALF_WIDTH:
				continue
			var last: int = beam.last_hit_tick.get(target.index, -1000000)
			if tick - last < beam.cooldown_ticks:
				continue
			beam.last_hit_tick[target.index] = tick
			hits.append({"source": beam.owner, "target": target.index, "amount": beam.damage, "kind": "beam", "pos": closest})


## Effects reacting to a hit (reflect) may add more hits while this runs;
## they land in the same tick.
func _apply_hits(hits: Array[Dictionary]) -> void:
	var mult := damage_multiplier()
	var heals: Array[Dictionary] = []
	var k := 0
	while k < hits.size():
		var h: Dictionary = hits[k]
		k += 1
		var amount: float = h.amount * mult
		if amount <= 0.0:
			continue
		var target := balls[h.target]
		var source := balls[h.source]
		var guard := {"source": source, "kind": h.kind, "mult": 1.0}
		abilities.fire(self, "guard", target, guard)
		amount *= guard.mult
		if target.shield > 0.0:
			var absorbed := minf(target.shield, amount)
			target.shield -= absorbed
			amount -= absorbed
			if amount <= 0.0:
				events.append({"type": "shielded", "target": h.target, "pos": h.pos})
				continue
		target.hp -= amount
		source.damage_dealt += amount
		events.append({"type": "damage", "target": h.target, "source": h.source, "amount": amount, "kind": h.kind, "pos": h.pos})
		if h.kind == "contact":
			abilities.fire(self, "hit", source, {"target": target, "amount": amount, "heals": heals})
		abilities.fire(self, "hurt", target, {"source": source, "amount": amount, "kind": h.kind})
	# Heals land after damage, so a lethal hit can't be out-healed in the same tick.
	for heal in heals:
		var b := balls[heal.ball]
		if not b.alive():
			continue
		var gained := minf(heal.amount, b.max_hp - b.hp)
		if gained > 0.0:
			b.hp += gained
			b.healed += gained
			events.append({"type": "heal", "target": b.index, "amount": gained, "pos": b.pos})


func _check_end(hp_before: Array[float]) -> void:
	var alive: Array[int] = []
	for b in balls:
		if b.alive():
			alive.append(b.index)
	if alive.size() == 1:
		_finish(alive[0], "knockout")
	elif alive.is_empty():
		# Both died on the same tick: whoever had more HP going into it wins.
		ko_hp = hp_before.duplicate()
		if hp_before[0] == hp_before[1]:
			_finish(-1, "double_knockout")
		else:
			_finish(0 if hp_before[0] > hp_before[1] else 1, "double_knockout")
	elif time() >= TIME_LIMIT:
		var f0 := balls[0].hp / balls[0].max_hp
		var f1 := balls[1].hp / balls[1].max_hp
		_finish(-1 if f0 == f1 else (0 if f0 > f1 else 1), "time_limit")


func _finish(winning_index: int, reason: String) -> void:
	finished = true
	winner = winning_index
	end_reason = reason
	events.append({"type": "end", "winner": winning_index, "reason": reason})


# --- Helpers for ability effects (sim/abilities.gd) ---------------------------

## Queues damage from `source` to `target` this tick (`kind` names the cause:
## "mine", "burn", "reflect"...). Overtime scaling applies when it lands.
func deal(source: Ball, target: Ball, amount: float, kind: String, pos = null) -> void:
	_hits.append({"source": source.index, "target": target.index, "amount": amount, "kind": kind, "pos": target.pos if pos == null else pos})


## The living balls on the other team from `b`.
func foes(b: Ball) -> Array[Ball]:
	var out: Array[Ball] = []
	for o in balls:
		if o.team != b.team and o.alive():
			out.append(o)
	return out


## The nearest living foe of `b`, or null.
func nearest_foe(b: Ball) -> Ball:
	var best: Ball = null
	for o in foes(b):
		if best == null or b.pos.distance_squared_to(o.pos) < b.pos.distance_squared_to(best.pos):
			best = o
	return best


## A floor zone owned by `owner`. `opts`: kind, radius, life, arm, slow, dps,
## blast, blast_radius, chain. Returns it.
func add_zone(owner: Ball, pos: Vector2, opts: Dictionary) -> Zone:
	var z := Zone.new()
	z.owner = owner.index
	z.pos = pos
	z.kind = opts.get("kind", "zone")
	z.radius = opts.get("radius", 30.0)
	z.life = opts.get("life", 1.0)
	z.arm = opts.get("arm", 0.0)
	z.slow = opts.get("slow", 0.0)
	z.dps = opts.get("dps", 0.0)
	z.blast = opts.get("blast", 0.0)
	z.blast_radius = opts.get("blast_radius", z.radius)
	z.chain = opts.get("chain", false)
	zones.append(z)
	return z


## Damage over time on `target`, ticking every half second.
func add_burn(source: Ball, target: Ball, dps: float, secs: float) -> void:
	target.dots.append({"source": source.index, "dps": dps, "until": tick + int(round(secs * TICK_RATE)), "next": tick + TICK_RATE / 2})


## Hits every foe of `owner` within `radius` of `pos` for `damage` and, with
## knock, turns them to fly straight away from `pos`. Emits "pulse".
func pulse(owner: Ball, pos: Vector2, radius: float, damage: float, knock := false, kind := "pulse") -> void:
	events.append({"type": "pulse", "ball": owner.index, "pos": pos, "radius": radius, "kind": kind})
	for o in foes(owner):
		var d := o.pos - pos
		if d.length() > radius + o.radius:
			continue
		if damage > 0.0:
			deal(owner, o, damage, kind)
		if knock and d.length() > 0.001:
			o.vel = d.normalized() * o.speed


func _update_zones() -> void:
	if zones.is_empty():
		return
	var half := TICK_RATE / 2
	var foes_of := {}
	for z in zones.duplicate():
		if not zones.has(z):
			continue
		z.age += DT
		if z.age >= z.life:
			zones.erase(z)
			continue
		if not z.armed():
			continue
		var owner := balls[z.owner]
		if not foes_of.has(z.owner):
			foes_of[z.owner] = foes(owner)
		for o in foes_of[z.owner]:
			if not o.alive() or o.pos.distance_to(z.pos) > z.radius + o.radius:
				continue
			if z.blast > 0.0:
				_explode(z)
				break
			o.slow = maxf(o.slow, z.slow)
			if z.dps > 0.0 and tick >= int(z.next_hit.get(o.index, 0)):
				z.next_hit[o.index] = tick + half
				deal(owner, o, z.dps * 0.5, z.kind, z.pos)


func _explode(z: Zone) -> void:
	zones.erase(z)
	var owner := balls[z.owner]
	events.append({"type": "boom", "ball": z.owner, "pos": z.pos, "radius": z.blast_radius})
	for o in foes(owner):
		if o.pos.distance_to(z.pos) <= z.blast_radius + o.radius:
			deal(owner, o, z.blast, "mine", z.pos)
	if z.chain:
		for other in zones.duplicate():
			if other.owner == z.owner and other.blast > 0.0 and other.armed() and zones.has(other) and other.pos.distance_to(z.pos) <= z.blast_radius * 2.0:
				_explode(other)


func _update_dots() -> void:
	for b in balls:
		if b.dots.is_empty() or not b.alive():
			continue
		for d in b.dots.duplicate():
			if tick > d.until:
				b.dots.erase(d)
			elif tick >= d.next:
				d.next = tick + TICK_RATE / 2
				deal(balls[d.source], b, d.dps * 0.5, "burn")
