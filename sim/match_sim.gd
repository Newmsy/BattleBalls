## Deterministic 1v1 match simulation. No nodes, no engine physics, no
## rendering: the same config always produces the same fight, so it can run
## headless for tests and balance sims, and be replayed from a Report code.
##
## Config: { seed: int, p1: String, p2: String, angles: [a1, a2], starts: [v1, v2], hp: [h1, h2],
##           tiers: [t1, t2], powers: [w1, w2], sizes: [s1, s2], arena: String, modifier: String }
## Angles are launch directions in tenths of a degree (screen space, y down),
## or null to let the seed pick one. `starts` (optional) overrides the start
## corners with arena positions; random aims still centre on the corners.
## `hp` (optional) sets each ball's starting HP (null = full), for relays
## where a winner stays in with what it has left.
## `boons` (optional, [[ids], [ids]]) gives each ball Bounce Run boons from
## sim/boons.gd.
## `fields: false` (optional) switches off every-tick abilities (fields like
## Flux's), so Daily Trick Shot balls fly straight.
## `tiers` (optional, default 1) apply each critter's T1-T5 ability upgrades.
## `powers` (optional) are progression multipliers (sim/power.gd); 1.0 is a T1
## level 1 Common. `sizes` (optional) scale the radius (campaign bosses).
## Critters and their abilities come from sim/critters/ via sim/ball_defs.gd;
## this file only fires their triggers (sim/abilities.gd).
## `modifier` is an optional Chaos Weekend rule twist from sim/modifiers.gd,
## applied to both balls.
## `arena` (optional) is an id from sim/arenas.gd (default "square").
## `gear` (optional) is each ball's gear: a list of pieces or stat totals
## (sim/gear.gd), or null for none.
##
## Every hit rolls its damage (+-DAMAGE_VARIANCE) and a crit from its own
## stream seeded by the fight seed, so a fight still replays from the seed and
## the launch angles alone. `damage_rolls: false` (optional) turns the spread
## and crits off, for unit tests that check exact damage.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const Modifiers := preload("res://sim/modifiers.gd")
const Arenas := preload("res://sim/arenas.gd")
const Abilities := preload("res://sim/abilities.gd")
const Power := preload("res://sim/power.gd")
const Gear := preload("res://sim/gear.gd")

## Bump whenever a change alters fight outcomes (i.e. golden replays are
## re-recorded): saved Ghost Arena lineups only meet fights on the same rules.
const RULES_VERSION := 2
const TICK_RATE := 60
const DT := 1.0 / TICK_RATE
const ARENA_SIZE := 1000.0
const OVERTIME_START := 45.0 ## Default; a modifier can move it (see overtime_start).
const SHRINK_SPEED := 12.0 ## Arena units per second, per side.
const MIN_HALF := 200.0
const OVERTIME_DAMAGE_RAMP := 0.05 ## +5% damage per second of overtime.
const TIME_LIMIT := 120.0
const CONTACT_COOLDOWN := 0.25
## Contact damage ranges from (1 - spread)x to (1 + spread)x by who rammed whom.
const IMPACT_SPREAD := 0.4
const BEAM_HALF_WIDTH := 5.0
const MIN_BEAM_LENGTH := 30.0
const RANDOM_AIM_SPREAD := 400 ## Tenths of a degree either side of the centre line.
## Speed multiplier after bouncing off a bumper. 1.3 gave Laser 64% over
## Vampire (11 points off the square); bumpers already add Laser bounces.
const BUMPER_BOOST := 1.15
const BUMPER_BOOST_TIME := 1.0 ## Seconds.
## Obstacles vanish once overtime has shrunk the arena below this share of its
## width, so the final squeeze is always a clean box.
const OBSTACLE_MIN_SCALE := 0.7
## Inward normals of the four cut corners: bottom-left, top-left, top-right, bottom-right.
const CORNER_NORMALS := [Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]
## Each hit deals between (1 - variance)x and (1 + variance)x its damage (Newms).
const DAMAGE_VARIANCE := 0.10
const BASE_CRIT_CHANCE := 0.05
const BASE_CRIT_MULT := 1.5
## A contact hit from behind: both balls heading within BACKSTAB_ANGLE degrees
## of each other, the striker catching the target up.
const BACKSTAB_MULT := 1.3
const BACKSTAB_ANGLE := 45.0
## Mixed into the fight seed for the per-hit roll stream.
const ROLL_SALT := 0x2F6B3C1D

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
	var shield := 0.0 ## Absorbs damage before HP (Bounce Run boons).
	var landed_hit := false
	var banked := false ## Bounced off a wall since its last contact hit.
	var boost_ticks := 0 ## Ticks of bumper speed boost left.
	var fired := {} ## One-shot triggers already used (Abilities.tick_triggers).
	var state := {} ## Per-ball ability state, e.g. a field's "pulling" (read by the renderer).
	## Per-hit stats, from gear (sim/gear.gd).
	var attack := 0.0
	var defense := 0.0
	var crit_chance := BASE_CRIT_CHANCE
	var crit_mult := BASE_CRIT_MULT

	func alive() -> bool:
		return hp > 0.0

	func current_speed() -> float:
		return speed * BUMPER_BOOST if boost_ticks > 0 else speed


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


var config: Dictionary
var modifier := Modifiers.NONE
var overtime_start := OVERTIME_START
var arena_id: String
var arena: Dictionary
var rng
## Damage and crit rolls only, so abilities that use `rng` never shift them.
var rolls
var damage_rolls := true
var balls: Array[Ball] = []
var beams: Array[Beam] = []
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
var _hits: Array[Dictionary] = [] ## This tick's hits, so effects can add some (add_hit).


func _init(cfg: Dictionary) -> void:
	config = cfg
	arena_id = cfg.get("arena", "square")
	arena = Arenas.get_def(arena_id)
	rng = Rng.new(int(cfg.get("seed", 1)))
	modifier = cfg.get("modifier", Modifiers.NONE)
	var mod := Modifiers.get_def(modifier)
	overtime_start = mod.get("overtime_start", OVERTIME_START)
	abilities = Abilities.new()
	rolls = Rng.new(int(cfg.get("seed", 1)) ^ ROLL_SALT)
	damage_rolls = cfg.get("damage_rolls", true)
	var types: Array = [cfg.get("p1", "plain"), cfg.get("p2", "plain")]
	if mod.get("mirror", false):
		var mirrored := Modifiers.mirror_ball(int(cfg.get("seed", 1)))
		types = [mirrored, mirrored]
	var angles: Array = cfg.get("angles", [null, null])
	var starts: Array = cfg.get("starts", START_CORNERS)
	var start_hp: Array = cfg.get("hp", [null, null])
	var tiers: Array = cfg.get("tiers", [1, 1])
	var powers: Array = cfg.get("powers", [1.0, 1.0])
	var sizes: Array = cfg.get("sizes", [1.0, 1.0])
	var gear: Array = cfg.get("gear", [null, null])
	for i in 2:
		var kit := Gear.totals(gear[i])
		var def := Modifiers.apply_to_def(Gear.apply_def(Power.scale_def(BallDefs.get_def(types[i], int(tiers[i])), float(powers[i])), kit), modifier)
		if cfg.has("boons"):
			def = Boons.apply_to_def(def, cfg.boons[i])
		var b := Ball.new()
		b.index = i
		b.type_id = types[i]
		b.def = def
		b.radius = def.radius * float(sizes[i])
		b.speed = def.speed
		b.max_hp = def.hp
		b.hp = def.hp if start_hp[i] == null else clampf(float(start_hp[i]), 0.01, def.hp)
		b.contact_damage = def.contact_damage
		b.attack = kit.get("attack", 0.0)
		b.defense = kit.get("defense", 0.0)
		b.crit_chance = BASE_CRIT_CHANCE + kit.get("crit_chance", 0.0)
		b.crit_mult = BASE_CRIT_MULT + kit.get("crit_damage", 0.0)
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
	return time() >= overtime_start


func damage_multiplier() -> float:
	return 1.0 + maxf(0.0, time() - overtime_start) * OVERTIME_DAMAGE_RAMP


func arena_rect() -> Rect2:
	return Rect2(centre - Vector2(half_size, half_size), Vector2(half_size, half_size) * 2.0)


## 1.0 at full size, shrinking toward MIN_HALF / half the arena in overtime.
func arena_scale() -> float:
	return half_size / (ARENA_SIZE / 2.0)


## Obstacles at the current overtime scale, moved toward the centre with the walls.
func obstacles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var k := arena_scale()
	if k < OBSTACLE_MIN_SCALE:
		return out
	for o in arena.obstacles:
		out.append({"pos": centre + (o.pos - centre) * k, "radius": o.radius * k, "kind": o.kind})
	return out


## Cut-corner walls as [inward unit normal, distance from the centre].
## A point p is inside when normal.dot(p - centre) + distance >= 0.
func corner_walls() -> Array:
	var out := []
	if arena.corner_cut <= 0.0:
		return out
	var distance: float = arena_scale() * (ARENA_SIZE - arena.corner_cut) / sqrt(2.0)
	for n in CORNER_NORMALS:
		out.append([n.normalized(), distance])
	return out


## Outline of the playable area at the current scale, for rendering.
func arena_outline() -> PackedVector2Array:
	var r := arena_rect()
	var cut: float = arena.corner_cut * arena_scale()
	if cut <= 0.0:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var a := r.position
	var b := r.end
	return PackedVector2Array([
		Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut), Vector2(b.x, b.y - cut),
		Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y), Vector2(a.x, b.y - cut), Vector2(a.x, a.y + cut)])


func step() -> void:
	if finished:
		return
	events.clear()
	var hp_before: Array[float] = []
	for b in balls:
		hp_before.append(b.hp)

	if tick == int(round(overtime_start * TICK_RATE)):
		for b in balls:
			if b.def.get("overtime_shield", 0.0) > 0.0 and b.alive():
				b.shield += b.def.overtime_shield
				events.append({"type": "shield", "target": b.index, "amount": b.def.overtime_shield, "pos": b.pos})
	if in_overtime():
		half_size = maxf(MIN_HALF, ARENA_SIZE / 2.0 - SHRINK_SPEED * (time() - overtime_start))

	if config.get("fields", true):
		for b in balls:
			if b.alive():
				abilities.fire(self, "always", b)
	var hits: Array[Dictionary] = []
	_hits = hits
	for b in balls:
		if b.alive():
			if b.boost_ticks > 0:
				b.boost_ticks -= 1
				if b.boost_ticks == 0:
					b.vel = b.vel.normalized() * b.speed
			b.pos += b.vel * DT
			_resolve_walls(b)
	_resolve_ball_collisions(hits)
	_update_beams(hits)
	_apply_hits(hits)
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
	for wall in corner_walls():
		var n: Vector2 = wall[0]
		var dist: float = n.dot(b.pos - centre) + wall[1]
		if dist < b.radius:
			b.pos += n * (b.radius - dist)
			if b.vel.dot(n) < 0.0:
				b.vel -= 2.0 * b.vel.dot(n) * n
				_on_wall_bounce(b, b.pos - n * b.radius)
	for o in obstacles():
		var delta: Vector2 = b.pos - o.pos
		var reach: float = b.radius + o.radius
		var dist := delta.length()
		if dist >= reach:
			continue
		var n := delta / dist if dist > 0.0001 else Vector2.UP
		b.pos = o.pos + n * reach
		if b.vel.dot(n) < 0.0:
			b.vel -= 2.0 * b.vel.dot(n) * n
			if o.kind == "bumper":
				b.boost_ticks = int(round(BUMPER_BOOST_TIME * TICK_RATE))
				b.vel = b.vel.normalized() * b.current_speed()
				events.append({"type": "bumper", "ball": b.index, "pos": o.pos + n * o.radius})
			_on_wall_bounce(b, o.pos + n * o.radius)


func _on_wall_bounce(b: Ball, point: Vector2) -> void:
	events.append({"type": "bounce", "ball": b.index, "pos": point})
	b.banked = true
	var bounce_heal: float = b.def.get("bounce_heal", 0.0)
	if bounce_heal > 0.0:
		var gained := minf(bounce_heal, b.max_hp - b.hp)
		if gained > 0.0:
			b.hp += gained
			b.healed += gained
			events.append({"type": "heal", "target": b.index, "amount": gained, "pos": b.pos, "boon": true})
	abilities.fire(self, "wall", b, {"point": point})
	for other in balls:
		if other != b and other.alive():
			abilities.fire(self, "foe_wall", other, {"other": b, "point": point})
	b.has_bounce = true
	b.last_bounce = point


## Adds a hit to this tick's damage (e.g. a slam raised during a wall bounce).
func add_hit(source: Ball, target: Ball, amount: float, kind: String, pos: Vector2) -> void:
	_hits.append({"source": source.index, "target": target.index, "amount": amount, "kind": kind, "pos": pos})


## A beam from `a` to `b` owned by ball `owner`, using its beam_* params. Keeps
## at most beam_max of the owner's beams, dropping the oldest.
func add_beam(owner: Ball, a: Vector2, b: Vector2) -> void:
	var beam := Beam.new()
	beam.owner = owner.index
	beam.a = a
	beam.b = b
	beam.life = owner.def.beam_life
	beam.damage = owner.def.beam_damage
	beam.cooldown_ticks = int(round(owner.def.beam_hit_cooldown * TICK_RATE))
	beams.append(beam)
	var own_beams := beams.filter(func(x: Beam) -> bool: return x.owner == owner.index)
	if own_beams.size() > owner.def.beam_max:
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
			var stab := _backstabber(a.vel, b.vel, n)
			# Share of the closing speed each ball supplied, from before the bounce.
			var a_share := clampf(a.vel.dot(n) / approach, 0.0, 1.0)
			var impulse := 2.0 * approach / (1.0 / ma + 1.0 / mb)
			a.vel -= n * (impulse / ma)
			b.vel += n * (impulse / mb)
			# Balls keep a constant speed: only direction changes.
			a.vel = a.vel.normalized() * a.current_speed() if a.vel.length() > 0.001 else -n * a.current_speed()
			b.vel = b.vel.normalized() * b.current_speed() if b.vel.length() > 0.001 else n * b.current_speed()
			var contact := a.pos + n * a.radius
			events.append({"type": "collide", "a": i, "b": j, "pos": contact})
			abilities.fire(self, "bump", a, {"other": b})
			abilities.fire(self, "bump", b, {"other": a})
			var key := "%d:%d" % [i, j]
			if tick < int(_contact_cooldown_until.get(key, 0)):
				continue
			_contact_cooldown_until[key] = tick + int(round(CONTACT_COOLDOWN * TICK_RATE))
			# The ball that rams harder hits harder, so even mirror matches trade unevenly.
			hits.append({"source": i, "target": j, "amount": a.contact_damage * _impact_scale(a_share) * _strike(a, b), "kind": "contact", "pos": b.pos, "backstab": stab == 0})
			hits.append({"source": j, "target": i, "amount": b.contact_damage * _impact_scale(1.0 - a_share) * _strike(b, a), "kind": "contact", "pos": a.pos, "backstab": stab == 1})


## Which ball (0 = a, 1 = b) rams the other from behind, from velocities before
## the bounce and the normal from a to b; -1 when it's not a backstab. Both
## must head the same way within BACKSTAB_ANGLE, and the struck ball must be
## moving away from the striker. They close in, so only one can qualify.
static func _backstabber(va: Vector2, vb: Vector2, n: Vector2) -> int:
	if va.length() < 0.001 or vb.length() < 0.001:
		return -1
	if va.normalized().dot(vb.normalized()) < cos(deg_to_rad(BACKSTAB_ANGLE)):
		return -1
	if vb.dot(n) > 0.0:
		return 0
	if va.dot(n) < 0.0:
		return 1
	return -1


## Contact damage multiplier from the striker's "strike" effects (e.g. snap).
func _strike(striker: Ball, target: Ball) -> float:
	var ctx := {"target": target, "mult": 1.0}
	abilities.fire(self, "strike", striker, ctx)
	return ctx.mult


## Turns a ball by `accel` (units/s^2) for one tick, keeping its speed.
func steer(b: Ball, accel: Vector2) -> void:
	var v := b.vel + accel * DT
	if v.length() > 0.001:
		b.vel = v.normalized() * b.current_speed()


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
			if target.index == beam.owner or not target.alive():
				continue
			var closest := Geometry2D.get_closest_point_to_segment(target.pos, beam.a, beam.b)
			if closest.distance_to(target.pos) > target.radius + BEAM_HALF_WIDTH:
				continue
			var last: int = beam.last_hit_tick.get(target.index, -1000000)
			if tick - last < beam.cooldown_ticks:
				continue
			beam.last_hit_tick[target.index] = tick
			hits.append({"source": beam.owner, "target": target.index, "amount": beam.damage, "kind": "beam", "pos": closest})


func _apply_hits(hits: Array[Dictionary]) -> void:
	var mult := damage_multiplier()
	var heals: Array[Dictionary] = []
	for h in hits:
		var amount: float = h.amount
		var target := balls[h.target]
		var source := balls[h.source]
		if h.kind == "contact":
			amount = _boon_contact_damage(source, target, amount)
		amount *= mult
		if amount <= 0.0:
			continue
		var backstab: bool = h.get("backstab", false)
		# Always two rolls per hit, so the stream never depends on the outcome.
		var spread: float = 1.0 + DAMAGE_VARIANCE * (2.0 * rolls.next_float() - 1.0)
		var crit: bool = rolls.next_float() < source.crit_chance
		if not damage_rolls:
			spread = 1.0
			crit = false
		amount *= spread * (1.0 + source.attack) * (1.0 - target.defense)
		if crit:
			amount *= source.crit_mult
		if backstab:
			amount *= BACKSTAB_MULT
		if target.shield > 0.0:
			var absorbed := minf(target.shield, amount)
			target.shield -= absorbed
			source.damage_dealt += absorbed
			amount -= absorbed
			events.append({"type": "shield_hit", "target": h.target, "amount": absorbed, "pos": h.pos})
			if amount <= 0.0:
				continue
		target.hp -= amount
		source.damage_dealt += amount
		events.append({"type": "damage", "target": h.target, "source": h.source, "amount": amount, "kind": h.kind, "pos": h.pos, "crit": crit, "backstab": backstab})
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


## Contact damage after the source's and target's boons. Without boons every
## term is zero and `amount` comes back unchanged.
func _boon_contact_damage(source: Ball, target: Ball, amount: float) -> float:
	if not source.landed_hit:
		source.landed_hit = true
		amount += source.def.get("first_strike", 0.0)
	if source.banked:
		source.banked = false
		amount *= 1.0 + source.def.get("bank_bonus", 0.0)
	return amount * (1.0 - target.def.get("contact_armor", 0.0))


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
