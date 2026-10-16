## Deterministic 1v1 (or 2v2) match simulation. No nodes, no engine physics, no
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
## Flux's) and ability movement (teleports, charges, strings, yanks, gear
## speed), so Daily Trick Shot balls fly straight.
## `tiers` (optional, default 1) apply each critter's T1-T5 ability upgrades.
## `powers` (optional) are progression multipliers (sim/power.gd); 1.0 is a T1
## level 1 Common. `sizes` (optional) scale the radius (campaign bosses).
## `p3`, `p4` (optional) make it a 2v2: all four balls fight at once, p3 on
## p1's team and p4 on p2's. Then the per-ball arrays above may hold four
## entries (index 2 = p3, 3 = p4; missing ones default) and the balls start
## from TEAM_STARTS. Teammates never damage each other.
## Critters and their abilities come from sim/critters/ via sim/ball_defs.gd;
## this file only fires their triggers (sim/abilities.gd).
## `modifier` is an optional Chaos Weekend rule twist from sim/modifiers.gd,
## applied to both balls.
## `arena` (optional) is an id from sim/arenas.gd (default "square").
## `gear` (optional) is each ball's gear: a list of pieces or stat totals
## (sim/gear.gd), or null for none.
## `talents` (optional) is each ball's faction talent picks {node: rank}
## (sim/talents.gd), or null for none; they're cleaned against its tier here.
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
const Talents := preload("res://sim/talents.gd")
const Weight := preload("res://sim/weight.gd")

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
## A blocking piece closer than this (plus its radius) to the arena's edge
## snaps onto the edge (add_piece): a ball wedged in a narrower gap would
## rattle between the two.
const PIECE_WALL_GAP := 160.0
## A blocking piece leaving a narrower gap than this to an arena obstacle
## isn't placed (it may touch or overlap one: no gap, no wedge).
const PIECE_OBSTACLE_GAP := 140.0
## Obstacles vanish once overtime has shrunk the arena below this share of its
## width, so the final squeeze is always a clean box.
const OBSTACLE_MIN_SCALE := 0.7
## Spikes (Spike Yard posts and spiked walls): a small hit per bounce, at most
## once per SPIKE_COOLDOWN per ball. Arena hazards (spikes, lava) together
## never take more than HAZARD_CAP of a ball's max HP over a whole fight, so
## the arena nicks but never decides a fight.
const SPIKE_DAMAGE := 4.0
const SPIKE_COOLDOWN := 0.5
const HAZARD_CAP := 0.15
const LAVA_DPS := 6.0 ## Dealt in half-second ticks while a ball overlaps lava.
const ICE_SPEED := 1.3 ## Speed multiplier while a ball's centre is on ice.
const PORTAL_COOLDOWN := 1.0 ## Seconds before a ball can take a portal again.
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
## Statuses (roster.md): a stun (freeze) holds a ball still for at most
## STUN_MAX seconds, then it can't be stunned again for STUN_IMMUNITY seconds,
## so nothing chain-locks. Vulnerable makes a ball take more damage; all its
## sources add up to at most VULNERABLE_CAP.
const STUN_MAX := 0.6
const STUN_IMMUNITY := 3.0
const VULNERABLE_CAP := 0.5

const START_CORNERS := [Vector2(170, 830), Vector2(830, 170)]
const AIM_AT_CENTRE := [-450, 1350] ## Tenths of a degree from each corner.
## 2v2 starts by ball index: each pair near its corner, point-symmetric.
const TEAM_STARTS := [Vector2(170, 700), Vector2(830, 300), Vector2(300, 830), Vector2(700, 170)]


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
	var shield := 0.0 ## Absorbs damage before HP (abilities, Bounce Run boons).
	var dots: Array[Dictionary] = [] ## Damage over time: {source, dps, until, next}.
	var landed_hit := false
	var banked := false ## Bounced off a wall since its last contact hit.
	var boon_hits := 0 ## Contact hits landed, for the Overcharge boon.
	var boost_ticks := 0 ## Ticks of bumper speed boost left.
	var charge_mult := 1.0 ## Speed multiplier while charging (see charge()).
	var charge_ticks := 0 ## Ticks of charge left.
	var slow_amount := 0.0 ## A timed slow (slow_for()), on top of zone slows.
	var slow_until := -1
	var fired := {} ## One-shot triggers already used (Abilities.tick_triggers).
	var state := {} ## Per-ball ability state, e.g. a field's "pulling" (read by the renderer).
	var stun_until := -1 ## Stunned (frozen in place) while tick < this.
	var stun_immune_until := -1
	## Timed statuses by key: {kind: "vulnerable" | "slow", amount, until (tick, exclusive), source}.
	var statuses := {}
	## Per-hit stats, from gear (sim/gear.gd).
	var attack := 0.0
	var defense := 0.0
	var crit_chance := BASE_CRIT_CHANCE
	var crit_mult := BASE_CRIT_MULT
	## Size/speed/damage modifiers (grow and shrink): key -> {radius, speed,
	## damage (multipliers), add (flat contact damage), until (tick, -1 = rest
	## of fight)}. Set them with MatchSim.set_mod, never by hand.
	var mods := {}
	var tal := {} ## Faction talent effects (sim/talents.gd), empty for none.
	var tal_state := {} ## Talent timers and counters (a foe's Haunt lands here too).
	var base := {} ## radius, speed and contact_damage before any mod.
	var weight := 1.0 ## How hard pulls move it (sim/weight.gd); heavier = less.
	var hazard_taken := 0.0 ## Arena hazard damage so far (before overtime scaling).
	var spike_ready := 0 ## Tick it may next be spiked.
	var lava_ready := 0 ## Tick lava may next burn it.
	var portal_ready := 0 ## Tick it may next take a portal.
	var floor_speed := 1.0 ## Ice under it (see ICE_SPEED).

	func alive() -> bool:
		return hp > 0.0

	func current_speed() -> float:
		var v := speed * BUMPER_BOOST if boost_ticks > 0 else speed
		v *= floor_speed
		return v * charge_mult if charge_ticks > 0 else v


class Beam:
	var owner: int
	var a: Vector2
	var b: Vector2
	var age := 0.0
	var life: float
	var damage: float
	var cooldown_ticks: int
	var last_hit_tick := {} ## target index -> tick of last hit
	## Extra on each hit: vulnerable / vulnerable_secs, burn / burn_secs.
	var on_hit := {}

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
	var follow := -1 ## Ball index it rides on (a stink cloud, a clinging chill); -1 stays put.
	var vulnerable := 0.0 ## Foes inside take this much more damage...
	var vulnerable_linger := 0.0 ## ...until this many seconds after they leave.
	var after := {} ## add_zone opts for a zone the blast leaves behind (Blizz's frost).
	var next_hit := {} ## target index -> tick it may next take dps damage

	func armed() -> bool:
		return age >= arm


## A projectile owned by a ball. A straight shot flies at a constant speed
## (turning toward the nearest foe at `homing` radians a second when above 0)
## and hits the first foe it touches; a lobbed shot (lob) flies over
## everything from `from` to `land` in `flight` seconds and acts on landing.
class Shot:
	var owner: int
	var kind: String ## For the renderer: "pea", "stinger", "pearl", "seed", "rocket", "shell", "blob"...
	var pos: Vector2
	var vel: Vector2
	var radius := 10.0
	var damage := 0.0
	var life := 3.0
	var age := 0.0
	var homing := 0.0
	var bounces := 0 ## Wall bounces left before it vanishes.
	var split := 0 ## Splits into this many when it hits a wall with no bounces left.
	var burn := 0.0 ## Burn per second on the struck foe, for 2s.
	var knock := false ## Turns the struck foe to fly the shot's way.
	var slow := 0.0 ## Slows the struck foe by this share for 1s.
	var burst_radius := 0.0 ## A pulse when its life runs out, when above 0.
	var burst_damage := 0.0
	var lob := false
	var from := Vector2.ZERO
	var land := Vector2.ZERO
	var flight := 1.0
	var land_radius := 0.0 ## Landing pulse, when above 0.
	var zone := {} ## add_zone opts for a puddle left where it lands.


## A piece a critter places in the arena (batch H): Sprout's seed pillars,
## Glacia's ice ring, Old Oak's roots, Foxfire's illusions. A blocking piece
## is a solid round obstacle balls of both teams bounce off, once it has grown
## (`grow` seconds) and no ball overlaps it, so it never shoves a ball out of
## the way; bouncing off one isn't a wall bounce for abilities. A piece with
## `vel` drifts and bounces off the arena's edge.
## Effects in sim/abilities.gd decide what a piece does; the sim only moves,
## blocks and expires it.
class Piece:
	var owner: int
	var kind: String ## For the renderer and the owner's effects: "seed", "vine", "ice", "root", "illusion".
	var pos: Vector2
	var vel := Vector2.ZERO
	var radius: float
	var life: float
	var age := 0.0
	var grow := 0.0
	var block := true ## Wants to block balls...
	var blocking := false ## ...and does, once grown and clear of balls.
	var damage := 0.0 ## Dealt to a foe of the owner that bounces off it.

	## True on the piece's last tick, so its owner can act as it ends (the sim
	## removes it right after "always" effects run).
	func ending(dt: float) -> bool:
		return age + dt >= life


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
var zones: Array[Zone] = []
## Strings tying a foe to a ball (tether()): {owner, target, length, until}.
var tethers: Array[Dictionary] = []
var shots: Array[Shot] = []
var pieces: Array[Piece] = []
var tick := 0
var half_size := ARENA_SIZE / 2.0
var centre := Vector2(ARENA_SIZE / 2.0, ARENA_SIZE / 2.0)
var finished := false
var winner := -1 ## Ball index, or -1 for a draw (only meaningful when finished).
var end_reason := ""
var ko_hp: Array[float] = [] ## On a double knockout, each ball's HP going into the final tick.
var launch_angles: Array[int] = []
var starters := 2 ## Balls the fight started with (4 in a 2v2); later ones are split-offs.
## Events produced by the most recent step(), for the renderer and tests.
var events: Array[Dictionary] = []

var abilities: Abilities

var _contact_cooldown_until := {} ## "i:j" -> tick
## Damage queued by effects and collisions (add_hit), applied in _apply_hits.
## Damage queued after that (revive blasts, timed pulses) lands next tick.
var _hits: Array[Dictionary] = []


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
	if cfg.has("p3"):
		types.append_array([cfg.p3, cfg.get("p4", "plain")])
	starters = types.size()
	if mod.get("mirror", false):
		var mirrored := Modifiers.mirror_ball(int(cfg.get("seed", 1)))
		types.fill(mirrored)
	var angles: Array = _per_ball(cfg.get("angles", []), null)
	var starts: Array = cfg.get("starts", START_CORNERS if starters == 2 else TEAM_STARTS)
	var start_hp: Array = _per_ball(cfg.get("hp", []), null)
	var tiers: Array = _per_ball(cfg.get("tiers", []), 1)
	var powers: Array = _per_ball(cfg.get("powers", []), 1.0)
	var sizes: Array = _per_ball(cfg.get("sizes", []), 1.0)
	var gear: Array = _per_ball(cfg.get("gear", []), null)
	var talents: Array = _per_ball(cfg.get("talents", []), null)
	for i in starters:
		var kit := Gear.totals(gear[i])
		var def := Modifiers.apply_to_def(Gear.apply_def(Power.scale_def(BallDefs.get_def(types[i], int(tiers[i])), float(powers[i])), kit), modifier)
		def = Modifiers.apply_arena_tweaks(def, arena_id)
		if cfg.has("boons") and i < cfg.boons.size():
			def = Boons.apply_to_def(def, cfg.boons[i])
		var b := Ball.new()
		b.index = i
		b.team = i % 2
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
		b.weight = Weight.of(types[i], float(sizes[i]))
		if talents[i] is Dictionary and not talents[i].is_empty():
			var faction := Talents.faction_of(types[i])
			b.tal = Talents.effects(faction, Talents.clean(faction, talents[i], int(tiers[i])))
			Talents.setup(self, b)
		b.pos = starts[i]
		# Always draw from the rng so a given aim doesn't shift later rolls.
		var random_aim: int = aim_at_centre(i, starters) + rng.range_int(-RANDOM_AIM_SPREAD, RANDOM_AIM_SPREAD)
		var aim: int = random_aim if angles[i] == null else int(angles[i])
		launch_angles.append(aim)
		b.vel = Vector2.from_angle(deg_to_rad(aim / 10.0)) * b.speed
		balls.append(b)


## `arr` padded to one entry per starting ball with `fill`.
func _per_ball(arr: Array, fill) -> Array:
	var out := arr.duplicate()
	while out.size() < starters:
		out.append(fill)
	return out


## Start positions for a fight of `count` balls (2 or 4).
static func start_positions(count: int) -> Array:
	return START_CORNERS if count <= 2 else TEAM_STARTS


## Launch angle (tenths of a degree) from ball `i`'s start straight at the centre.
static func aim_at_centre(i: int, count := 2) -> int:
	if count <= 2:
		return AIM_AT_CENTRE[i]
	var p: Vector2 = TEAM_STARTS[i]
	return roundi(rad_to_deg((Vector2(ARENA_SIZE, ARENA_SIZE) / 2.0 - p).angle()) * 10.0)


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
		var at: Vector2 = o.pos
		if o.has("orbit"): # Circles the centre at orbit rad/s, starting at pos.
			at = centre + (o.pos - centre).rotated(o.orbit * time())
		out.append({"pos": centre + (at - centre) * k, "radius": o.radius * k, "kind": o.kind})
	for p in pieces:
		if p.blocking:
			out.append({"pos": p.pos, "radius": p.radius, "kind": p.kind, "piece": p})
	return out


## Gravity wells at the current overtime scale (gone with the obstacles).
func wells() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var k := arena_scale()
	if k < OBSTACLE_MIN_SCALE:
		return out
	for w in arena.get("wells", []):
		out.append({"pos": centre + (w.pos - centre) * k, "reach": w.reach * k, "accel": w.accel, "core": w.core * k})
	return out


## Floor pads at the current overtime scale (gone with the obstacles): each
## a copy of its def with pos/radius (or rect) moved toward the centre.
func floors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var k := arena_scale()
	if k < OBSTACLE_MIN_SCALE:
		return out
	for f in arena.get("floors", []):
		var g: Dictionary = f.duplicate()
		if f.has("rect"):
			g.rect = Rect2(centre + (f.rect.position - centre) * k, f.rect.size * k)
		else:
			g.pos = centre + (f.pos - centre) * k
			g.radius = f.radius * k
		out.append(g)
	return out


static func on_floor(f: Dictionary, p: Vector2, margin := 0.0) -> bool:
	if f.has("rect"):
		return f.rect.grow(margin).has_point(p)
	return p.distance_to(f.pos) <= f.radius + margin


## Ice speeds balls up, goo slows them, lava burns, conveyors push (by
## weight) and portals send a ball to their partner pad with its velocity.
## A ball is on a pad when its centre is.
func _update_floors() -> void:
	var pads := floors()
	for b in balls:
		if not b.alive():
			continue
		var ice := 1.0
		for i in pads.size():
			var f: Dictionary = pads[i]
			if not on_floor(f, b.pos, 0.0 if f.kind == "portal" else b.radius * 0.5):
				continue
			match f.kind:
				"ice":
					ice = ICE_SPEED
				"goo":
					b.slow = maxf(b.slow, f.slow)
				"lava":
					if tick >= b.lava_ready:
						b.lava_ready = tick + TICK_RATE / 2
						if _hazard(b, LAVA_DPS * 0.5, "lava", b.pos):
							events.append({"type": "lava", "ball": b.index, "pos": b.pos})
				"conveyor":
					pull(b, f.dir * f.accel)
				"portal":
					if tick >= b.portal_ready and b.pos.distance_to(f.pos) <= f.radius * 0.6:
						var to: Vector2 = pads[f.to].pos
						b.portal_ready = tick + int(round(PORTAL_COOLDOWN * TICK_RATE))
						events.append({"type": "portal", "ball": b.index, "from": b.pos, "to": to})
						b.pos = to
		if ice != b.floor_speed:
			b.floor_speed = ice
			b.vel = b.vel.normalized() * b.current_speed()


## Half-length of the spiked stretch in the middle of the left and right
## walls at the current scale; 0 when the arena has none (or overtime ate it).
func spike_wall_half() -> float:
	var k := arena_scale()
	if not arena.has("spike_walls") or k < OBSTACLE_MIN_SCALE:
		return 0.0
	return arena.spike_walls.half * k


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
	# An arena may start its own slower squeeze early (shrink_start /
	# shrink_speed); overtime's squeeze takes over once it is the tighter one.
	var shrink_from: float = minf(overtime_start, arena.get("shrink_start", overtime_start))
	if time() >= shrink_from:
		var early: float = arena.get("shrink_speed", SHRINK_SPEED) * (time() - shrink_from)
		var late := SHRINK_SPEED * maxf(0.0, time() - overtime_start)
		half_size = maxf(MIN_HALF, ARENA_SIZE / 2.0 - maxf(early, late))

	for b in balls:
		b.slow = b.slow_amount if tick < b.slow_until else 0.0
		if b.state.has("shot_slow"): # A slowing shot's hold (Shot.slow).
			if tick < b.state.shot_slow.until:
				b.slow = maxf(b.slow, b.state.shot_slow.amount)
			else:
				b.state.erase("shot_slow")
		if not b.statuses.is_empty():
			_update_statuses(b)
	if config.get("fields", true):
		for b in balls:
			if b.alive():
				abilities.fire(self, "always", b)
	if arena.has("wells"):
		_update_wells()
	if arena.has("floors"):
		_update_floors()
	_update_zones()
	_update_pieces()
	var seek: float = config.get("seek", 0.0)
	if seek > 0.0: # Gentle pull: every ball curves a little toward its nearest foe.
		for b in balls:
			if b.alive() and not stunned(b):
				var f = nearest_foe(b)
				if f != null and f.pos.distance_to(b.pos) > 0.001:
					steer(b, (f.pos - b.pos).normalized() * seek)
	for b in balls:
		if not b.tal.is_empty():
			Talents.tick(self, b)
	_update_dots()
	for b in balls:
		if not b.mods.is_empty():
			_expire_mods(b)
	for b in balls:
		if b.alive():
			if b.boost_ticks > 0:
				b.boost_ticks -= 1
				if b.boost_ticks == 0:
					b.vel = b.vel.normalized() * b.current_speed()
			if b.charge_ticks > 0:
				b.charge_ticks -= 1
				if b.charge_ticks == 0:
					b.vel = b.vel.normalized() * b.current_speed()
			if tick >= b.stun_until:
				# A charge carries its own momentum: slows don't drag it.
				b.pos += b.vel * DT * (1.0 - (b.slow if b.charge_ticks == 0 else 0.0))
			_resolve_walls(b)
	if not tethers.is_empty():
		_update_tethers()
	_resolve_ball_collisions(_hits)
	_update_beams(_hits)
	_update_shots()
	_apply_hits(_hits)
	# "fall" (e.g. a revive) only while a foe still stands: when both drop on
	# the same tick the fight is already over, and the double-knockout rule
	# decides it.
	for b in balls:
		if not b.alive() and not b.fired.has("fall") and not foes(b).is_empty():
			b.fired["fall"] = true
			abilities.fire(self, "fall", b)
		# Phoenix Feather (a Legendary Bounce Run boon): back up once per fight.
		if not b.alive() and b.def.get("boon_revive", 0.0) > 0.0 and not b.fired.has("boon_revive") and not foes(b).is_empty():
			b.fired["boon_revive"] = true
			b.hp = b.max_hp * b.def.boon_revive
			events.append({"type": "revive", "ball": b.index, "pos": b.pos, "boon": true})
	for i in balls.size(): # A split adds balls here; they start next tick.
		if balls[i].alive():
			abilities.tick_triggers(self, balls[i])

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
		"hp": [team_hp(0), team_hp(1)],
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
		if not b.base.is_empty(): # Only once a mod was used, so older goldens keep their hash.
			data.append_array([b.index, b.radius, b.speed, b.contact_damage])
		if b.stun_until >= 0 or not b.statuses.is_empty():
			data.append_array([b.index, b.stun_until, vulnerable(b), status_amount(b, "slow")])
	for s in shots:
		data.append_array([s.pos.x, s.pos.y, s.vel.x, s.vel.y, s.age])
	for p in pieces: # Empty unless a critter placed one, so older goldens keep their hash.
		data.append_array([p.pos.x, p.pos.y, p.age, 1.0 if p.blocking else 0.0])
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
			_spike_wall(b, Vector2(r.position.x, b.pos.y))
			_on_wall_bounce(b, Vector2(r.position.x, b.pos.y))
	elif b.pos.x + b.radius > r.end.x:
		b.pos.x = r.end.x - b.radius
		if b.vel.x > 0.0:
			b.vel.x = -b.vel.x
			_spike_wall(b, Vector2(r.end.x, b.pos.y))
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
			elif o.kind == "spike":
				_spike(b, o.pos + n * o.radius)
			if o.has("piece"):
				# A critter's piece isn't a wall for abilities: bounce-fed
				# abilities (Optic's beams, Zip's speed-up) would farm the
				# rattle of a ball lashed or ringed by one.
				if o.piece.damage > 0.0 and balls[o.piece.owner].team != b.team:
					deal(balls[o.piece.owner], b, o.piece.damage, "pillar", o.pos + n * o.radius)
				events.append({"type": "bounce", "ball": b.index, "pos": o.pos + n * o.radius, "piece": true})
				continue
			_on_wall_bounce(b, o.pos + n * o.radius, true)


## Pulls every ball toward each gravity well, fading to 0 at its reach.
func _update_wells() -> void:
	for w in wells():
		for b in balls:
			if not b.alive():
				continue
			var d: Vector2 = w.pos - b.pos
			var dist := d.length()
			if dist <= w.core or dist >= w.reach:
				continue
			pull(b, d / dist * w.accel * (1.0 - dist / w.reach))


func _spike_wall(b: Ball, point: Vector2) -> void:
	var half := spike_wall_half()
	if half > 0.0 and absf(point.y - centre.y) <= half:
		_spike(b, point)


## A spike hit on `b` at `point`, within the cooldown and the per-fight cap.
## The ball is its own source: no crits, gear or reflects, and nobody's
## damage dealt goes up.
func _spike(b: Ball, point: Vector2) -> void:
	if not b.alive() or tick < b.spike_ready:
		return
	if _hazard(b, SPIKE_DAMAGE, "spike", point):
		b.spike_ready = tick + int(round(SPIKE_COOLDOWN * TICK_RATE))
		events.append({"type": "spike", "ball": b.index, "pos": point})


## Queues `amount` of arena damage on `b`, cut to what HAZARD_CAP leaves.
## False when the cap is used up.
func _hazard(b: Ball, amount: float, kind: String, point: Vector2) -> bool:
	amount = minf(amount, HAZARD_CAP * b.max_hp - b.hazard_taken)
	if amount <= 0.0:
		return false
	b.hazard_taken += amount
	_hits.append({"source": b.index, "target": b.index, "amount": amount, "kind": kind, "pos": point, "env": true})
	return true


## `obstacle`: it bounced off a pillar or bumper, not the arena's edge.
func _on_wall_bounce(b: Ball, point: Vector2, obstacle := false) -> void:
	events.append({"type": "bounce", "ball": b.index, "pos": point})
	var slam: Dictionary = b.state.get("slam", {})
	# A slam with "walls_only" (Mammoth's) waits for the arena's edge.
	if not slam.is_empty() and tick <= slam.until and not (obstacle and slam.get("walls_only", false)):
		b.state.erase("slam")
		deal(balls[slam.source], b, slam.damage, "slam", point)
		if slam.get("stun", 0.0) > 0.0:
			stun(balls[slam.source], b, slam.stun)
		if slam.has("zone"):
			add_zone(balls[slam.source], point, slam.zone)
	b.banked = true
	if not b.tal.is_empty():
		Talents.on_bounce(self, b)
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
## `opts` may override "life", "damage" and "cooldown" (seconds), and add
## "on_hit" (see Beam.on_hit). Returns the beam.
func add_beam(owner: Ball, a: Vector2, b: Vector2, opts := {}) -> Beam:
	var beam := Beam.new()
	beam.owner = owner.index
	beam.a = a
	beam.b = b
	beam.life = opts.get("life", owner.def.get("beam_life", 1.0))
	beam.damage = opts.get("damage", owner.def.get("beam_damage", 0.0))
	beam.cooldown_ticks = int(round(opts.get("cooldown", owner.def.get("beam_hit_cooldown", 0.5)) * TICK_RATE))
	beam.on_hit = opts.get("on_hit", {})
	beams.append(beam)
	var own_beams := beams.filter(func(x: Beam) -> bool: return x.owner == owner.index)
	if own_beams.size() > owner.def.get("beam_max", 6):
		beams.erase(own_beams[0])
	events.append({"type": "beam", "owner": owner.index, "a": beam.a, "b": beam.b})
	return beam


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
			if a.team == b.team:
				continue
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


## Turns `b` like steer(), scaled by its weight (sim/weight.gd): light balls
## are dragged harder, heavy ones resist. Use it for anything that pulls or
## pushes a ball from outside (wells, fields, wind); steer() is for a ball's
## own movement.
func pull(b: Ball, accel: Vector2) -> void:
	steer(b, accel * Weight.pull_scale(b.weight))


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
			if not beam.on_hit.is_empty():
				var owner := balls[beam.owner]
				if beam.on_hit.get("vulnerable", 0.0) > 0.0:
					add_status(owner, target, "beam:%d" % beam.owner, "vulnerable", beam.on_hit.vulnerable, beam.on_hit.vulnerable_secs)
				if beam.on_hit.get("burn", 0.0) > 0.0:
					add_burn(owner, target, beam.on_hit.burn, beam.on_hit.burn_secs)
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
		var amount: float = h.amount
		var target := balls[h.target]
		var source := balls[h.source]
		if source != target and source.team == target.team and not h.get("env", false):
			continue # Teammates never hurt each other.
		# The arena's own damage (spikes) never triggers talents.
		var talented: bool = not h.get("env", false) and (not source.tal.is_empty() or not target.tal.is_empty() or source.tal_state.has("haunted"))
		if talented:
			amount *= Talents.hit_mult(self, source, target, h)
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
		var env: bool = h.get("env", false) # The arena's own damage (spikes).
		if env:
			crit = false
		else:
			amount *= spread * (1.0 + source.attack) * (1.0 - target.defense)
		if talented:
			var c := Talents.crit_mult(self, source, target, crit)
			crit = c.crit
			amount *= c.mult
		elif crit:
			amount *= source.crit_mult
		if backstab:
			amount *= BACKSTAB_MULT
		var guard := {"source": source, "kind": h.kind, "mult": 1.0, "amount": amount}
		abilities.fire(self, "guard", target, guard)
		amount *= guard.mult
		if not target.statuses.is_empty():
			amount *= 1.0 + vulnerable(target)
		if amount <= 0.0: # Soaked whole (a bubble).
			events.append({"type": "shielded", "target": h.target, "pos": h.pos})
			continue
		if target.shield > 0.0:
			var absorbed := minf(target.shield, amount)
			target.shield -= absorbed
			if not env:
				source.damage_dealt += absorbed
			amount -= absorbed
			events.append({"type": "shield_hit", "target": h.target, "amount": absorbed, "pos": h.pos})
			if amount <= 0.0:
				continue
		target.hp -= amount
		if not env:
			source.damage_dealt += amount
		events.append({"type": "damage", "target": h.target, "source": h.source, "amount": amount, "kind": h.kind, "pos": h.pos, "crit": crit, "backstab": backstab})
		if talented:
			Talents.after_hit(self, source, target, amount, h.kind, heals)
		if h.kind == "contact":
			abilities.fire(self, "hit", source, {"target": target, "amount": amount, "heals": heals})
			_boon_after_contact(source, target, amount, h.pos, hits, heals)
		abilities.fire(self, "hurt", target, {"source": source, "amount": amount, "kind": h.kind})
	hits.clear()
	# Heals land after damage, so a lethal hit can't be out-healed in the same tick.
	for heal in heals:
		var b := balls[heal.ball]
		if not b.alive():
			continue
		var gained := minf(heal.amount * (Talents.heal_mult(b) if not b.tal.is_empty() else 1.0), b.max_hp - b.hp)
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
	var every := int(source.def.get("overcharge", 0.0))
	if every > 0:
		source.boon_hits += 1
		if source.boon_hits % every == 0:
			amount *= 2.0
			events.append({"type": "overcharge", "ball": source.index, "pos": source.pos})
	return amount * (1.0 - target.def.get("contact_armor", 0.0))


## Legendary boons that react to a landed bump: Thorn Crown hits the bumper
## back (as "thorns", which never bounces again) and Vampire Kiss heals.
func _boon_after_contact(source: Ball, target: Ball, amount: float, pos: Vector2, hits: Array[Dictionary], heals: Array[Dictionary]) -> void:
	var thorns: float = target.def.get("thorns", 0.0)
	if thorns > 0.0 and source.team != target.team:
		hits.append({"source": target.index, "target": source.index, "amount": amount * thorns, "kind": "thorns", "pos": pos})
		events.append({"type": "reflect", "ball": target.index, "from": target.pos, "to": source.pos})
	var steal: float = source.def.get("lifesteal", 0.0)
	if steal > 0.0:
		heals.append({"ball": source.index, "amount": amount * steal})


## A team's HP: its starting ball's, plus what its mate and split-off balls have left.
func team_hp(team: int) -> float:
	var hp := balls[team].hp
	for i in range(2, balls.size()):
		if balls[i].team == team:
			hp += maxf(0.0, balls[i].hp)
	return hp


func _team_max_hp(team: int) -> float:
	var hp := balls[team].max_hp
	for i in range(2, balls.size()):
		if balls[i].team == team:
			hp += balls[i].max_hp
	return hp


## Teams win, not balls: a team is out once all its balls are (a Splitter's
## minis). The starting balls are teams 0 and 1, so winner is a team index.
func _check_end(hp_before: Array[float]) -> void:
	var standing := [false, false]
	for b in balls:
		if b.alive():
			standing[b.team] = true
	if standing[0] != standing[1]:
		_finish(0 if standing[0] else 1, "knockout")
	elif not standing[0]:
		# Both teams fell on the same tick: whoever had more HP going into it wins.
		var before := [hp_before[0], hp_before[1]]
		for i in range(2, balls.size()):
			if i < hp_before.size():
				before[balls[i].team] += maxf(0.0, hp_before[i])
		ko_hp.assign(before)
		if before[0] == before[1]:
			_finish(-1, "double_knockout")
		else:
			_finish(0 if before[0] > before[1] else 1, "double_knockout")
	elif time() >= TIME_LIMIT:
		var f0 := team_hp(0) / _team_max_hp(0)
		var f1 := team_hp(1) / _team_max_hp(1)
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


## Sets (or replaces) the size/speed/damage modifier `key` on `b`: `mod` may
## hold "radius", "speed" and "damage" multipliers and "add" (flat contact
## damage). It lasts `secs` seconds, or the rest of the fight when <= 0. The
## ball's speed changes at once and keeps its direction; a bigger ball is
## pushed off the walls on its next move. Emits "grow" with the new size.
func set_mod(b: Ball, key: String, mod: Dictionary, secs := 0.0) -> void:
	var m := mod.duplicate()
	if b.state.has("copy_until"):
		m.copied = true # Echo borrowed this; it ends with the copy (Abilities._end_copy).
	m.until = tick + int(round(secs * TICK_RATE)) if secs > 0.0 else -1
	b.mods[key] = m
	_apply_mods(b)


func clear_mod(b: Ball, key: String) -> void:
	if b.mods.erase(key):
		_apply_mods(b)


func has_mod(b: Ball, key: String) -> bool:
	return b.mods.has(key)


func _expire_mods(b: Ball) -> void:
	var gone := false
	for key in b.mods.keys():
		var until: int = b.mods[key].until
		if until >= 0 and tick >= until:
			b.mods.erase(key)
			gone = true
	if gone:
		_apply_mods(b)


## Recomputes radius, speed and contact damage from the base stats and every mod.
func _apply_mods(b: Ball) -> void:
	if b.base.is_empty():
		b.base = {"radius": b.radius, "speed": b.speed, "contact_damage": b.contact_damage}
	var size := 1.0
	var pace := 1.0
	var hit := 1.0
	var add := 0.0
	for m in b.mods.values():
		size *= m.get("radius", 1.0)
		pace *= m.get("speed", 1.0)
		hit *= m.get("damage", 1.0)
		add += m.get("add", 0.0)
	var old_radius := b.radius
	b.radius = b.base.radius * size
	b.speed = b.base.speed * pace
	b.contact_damage = maxf(0.0, b.base.contact_damage * hit + add)
	if b.vel.length() > 0.001:
		b.vel = b.vel.normalized() * b.current_speed()
	if not is_equal_approx(old_radius, b.radius):
		events.append({"type": "grow", "ball": b.index, "pos": b.pos, "scale": size, "bigger": b.radius > old_radius})


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


## Splits `parent` into two: it shrinks into a mini with `hp` (also its new
## max HP), and a twin mini with the same HP joins its team, heading off
## `turn` radians from it. The twin copies its def, tier stats, gear and
## one-shot triggers. Returns the twin (index 2 and up).
func spawn_twin(parent: Ball, hp: float, radius_mult: float, speed_mult: float, add_damage: float, turn: float) -> Ball:
	parent.max_hp = hp
	parent.hp = hp
	if parent.base.is_empty():
		parent.radius *= radius_mult
		parent.speed *= speed_mult
		parent.contact_damage += add_damage
	else: # Grown or shrunk right now: split the base and keep the mods.
		parent.base.radius *= radius_mult
		parent.base.speed *= speed_mult
		parent.base.contact_damage += add_damage
		_apply_mods(parent)
	var b := Ball.new()
	b.index = balls.size()
	b.team = parent.team
	b.type_id = parent.type_id
	b.def = parent.def
	b.radius = parent.radius
	b.speed = parent.speed
	b.max_hp = hp
	b.hp = hp
	b.contact_damage = parent.contact_damage
	b.attack = parent.attack
	b.defense = parent.defense
	b.crit_chance = parent.crit_chance
	b.crit_mult = parent.crit_mult
	b.fired = parent.fired.duplicate()
	b.mods = parent.mods.duplicate(true)
	b.base = parent.base.duplicate()
	b.state = {"split_gen": parent.state.get("split_gen", 0)}
	var dir := parent.vel.normalized() if parent.vel.length() > 0.001 else Vector2.RIGHT
	parent.vel = dir.rotated(-turn) * parent.speed
	b.vel = dir.rotated(turn) * b.speed
	b.pos = inside(parent.pos + dir.rotated(turn).orthogonal() * parent.radius, b.radius + 4.0)
	parent.pos = inside(parent.pos - dir.rotated(turn).orthogonal() * parent.radius, parent.radius + 4.0)
	balls.append(b)
	return b


## A floor zone owned by `owner`. `opts`: kind, radius, life, arm, slow, dps,
## blast, blast_radius, chain, follow (a ball index), vulnerable,
## vulnerable_linger, after. Returns it.
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
	z.follow = opts.get("follow", -1)
	if z.follow >= 0:
		z.pos = balls[z.follow].pos
	z.vulnerable = opts.get("vulnerable", 0.0)
	z.vulnerable_linger = opts.get("vulnerable_linger", 0.0)
	z.after = opts.get("after", {})
	zones.append(z)
	return z


## Damage over time on `target`, ticking every half second.
func add_burn(source: Ball, target: Ball, dps: float, secs: float) -> void:
	var until := tick + int(round(secs * TICK_RATE))
	for d in target.dots: # Burns don't stack: the same burn again just lasts longer.
		if d.source == source.index and d.dps == dps:
			d.until = maxi(d.until, until)
			return
	target.dots.append({"source": source.index, "dps": dps, "until": until, "next": tick + TICK_RATE / 2})


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


## Wind: turns every foe of `owner` within `reach` of `pos` away from it, at
## `accel` (units/s^2) next to `pos`, fading to 0 at the edge of `reach`.
## Like steer(), it bends a ball's path and keeps its speed.
func push_away(owner: Ball, pos: Vector2, reach: float, accel: float) -> void:
	for o in foes(owner):
		var d := o.pos - pos
		var dist := d.length()
		if dist < 0.001 or dist >= reach:
			continue
		pull(o, d / dist * accel * (1.0 - dist / reach))


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
		if z.follow >= 0:
			z.pos = balls[z.follow].pos
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
			if z.vulnerable > 0.0:
				add_status(owner, o, "zone:%d" % z.owner, "vulnerable", z.vulnerable, DT + z.vulnerable_linger)
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
	if not z.after.is_empty():
		add_zone(owner, z.pos, z.after)
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


## A straight (or homing) shot owned by `owner`, flying from `pos` with
## velocity `vel`. `opts` sets any Shot field by name (kind, radius, damage,
## life, homing, bounces, split, burn, knock, slow, burst_radius, burst_damage).
## Emits "shot". Returns it.
func add_shot(owner: Ball, pos: Vector2, vel: Vector2, opts := {}) -> Shot:
	var s := Shot.new()
	s.owner = owner.index
	s.pos = pos
	s.vel = vel
	for key in opts:
		s.set(key, opts[key])
	shots.append(s)
	events.append({"type": "shot", "ball": owner.index, "pos": pos, "kind": s.kind})
	return s


## A lobbed shot from `owner` landing at `to` (kept inside the arena) after
## `flight` seconds. On landing it pulses land_radius for `damage` (knocking
## when `knock`) and leaves `zone` (add_zone opts) when given. Emits "shot".
func add_lob(owner: Ball, to: Vector2, flight: float, opts := {}) -> Shot:
	var r := arena_rect().grow(-20.0)
	var s := add_shot(owner, owner.pos, Vector2.ZERO, opts)
	s.lob = true
	s.from = owner.pos
	s.land = to.clamp(r.position, r.end)
	s.flight = flight
	s.life = flight
	return s


func _update_shots() -> void:
	if shots.is_empty():
		return
	for s in shots.duplicate():
		s.age += DT
		var owner := balls[s.owner]
		if s.lob:
			s.pos = s.from.lerp(s.land, minf(1.0, s.age / s.flight))
			if s.age >= s.flight:
				shots.erase(s)
				if s.land_radius > 0.0:
					pulse(owner, s.land, s.land_radius, s.damage, s.knock, s.kind)
				if not s.zone.is_empty():
					add_zone(owner, s.land, s.zone)
			continue
		if s.age >= s.life:
			shots.erase(s)
			if s.burst_radius > 0.0:
				pulse(owner, s.pos, s.burst_radius, s.burst_damage, false, "pulse")
			continue
		if s.homing > 0.0:
			var target: Ball = null
			for o in foes(owner):
				if target == null or s.pos.distance_squared_to(o.pos) < s.pos.distance_squared_to(target.pos):
					target = o
			if target != null:
				var turn := clampf(s.vel.angle_to(target.pos - s.pos), -s.homing * DT, s.homing * DT)
				s.vel = s.vel.rotated(turn)
		s.pos += s.vel * DT
		var struck := false
		for o in foes(owner):
			if s.pos.distance_to(o.pos) > o.radius + s.radius:
				continue
			struck = true
			deal(owner, o, s.damage, "shot", s.pos)
			if s.burn > 0.0:
				add_burn(owner, o, s.burn, 2.0)
			if s.knock and s.vel.length() > 0.001:
				o.vel = s.vel.normalized() * o.speed
			if s.slow > 0.0:
				o.state.shot_slow = {"amount": s.slow, "until": tick + TICK_RATE}
			break
		if struck:
			shots.erase(s)
		elif _shot_walls(s):
			if s.bounces > 0:
				s.bounces -= 1
			else:
				shots.erase(s)
				events.append({"type": "shot_pop", "ball": s.owner, "pos": s.pos, "kind": s.kind})
				for k in s.split:
					var dir: Vector2 = s.vel.rotated(deg_to_rad(30.0 * (k - (s.split - 1) / 2.0)))
					add_shot(owner, s.pos, dir, {"kind": s.kind, "radius": s.radius * 0.7, "damage": s.damage * 0.5,
						"life": 1.5, "burn": s.burn, "slow": s.slow})


## Where ball `b` will be in `secs` if nothing but walls and obstacles turn
## it (no other balls, no steering). Changes nothing.
func predict(b: Ball, secs: float) -> Vector2:
	var s := Shot.new()
	s.pos = b.pos
	s.vel = b.vel
	s.radius = b.radius
	for i in int(round(secs * TICK_RATE)):
		s.pos += s.vel * DT
		_shot_walls(s)
	return s.pos


## Bounces a shot off the walls, cut corners and obstacles; true if it hit one.
func _shot_walls(s: Shot) -> bool:
	var hit := false
	var r := arena_rect()
	if (s.pos.x - s.radius < r.position.x and s.vel.x < 0.0) or (s.pos.x + s.radius > r.end.x and s.vel.x > 0.0):
		s.vel.x = -s.vel.x
		hit = true
	if (s.pos.y - s.radius < r.position.y and s.vel.y < 0.0) or (s.pos.y + s.radius > r.end.y and s.vel.y > 0.0):
		s.vel.y = -s.vel.y
		hit = true
	s.pos = s.pos.clamp(r.position + Vector2.ONE * s.radius, r.end - Vector2.ONE * s.radius)
	for wall in corner_walls():
		var n: Vector2 = wall[0]
		if n.dot(s.pos - centre) + wall[1] < s.radius and s.vel.dot(n) < 0.0:
			s.vel -= 2.0 * s.vel.dot(n) * n
			hit = true
	for o in obstacles():
		var delta: Vector2 = s.pos - o.pos
		if delta.length() < s.radius + o.radius and delta.length() > 0.0001:
			var n := delta.normalized()
			if s.vel.dot(n) < 0.0:
				s.vel -= 2.0 * s.vel.dot(n) * n
				hit = true
	return hit


# --- Statuses: stun (freeze), vulnerable, timed slow ---------------------------

func stunned(b: Ball) -> bool:
	return tick < b.stun_until


## Freezes `target` in place for `secs` (at most STUN_MAX). Does nothing while
## it is already stunned or in its STUN_IMMUNITY window. Returns whether it
## took. Emits "stun".
func stun(source: Ball, target: Ball, secs: float) -> bool:
	if not target.alive() or tick < target.stun_immune_until:
		return false
	target.stun_until = tick + maxi(1, int(round(minf(secs, STUN_MAX) * TICK_RATE)))
	target.stun_immune_until = target.stun_until + int(round(STUN_IMMUNITY * TICK_RATE))
	target.state.stun_source = source.index
	events.append({"type": "stun", "ball": target.index, "source": source.index, "pos": target.pos, "secs": minf(secs, STUN_MAX)})
	return true


## Sets the timed status `key` on `target` (kind "vulnerable": takes `amount`
## more damage; "slow": loses `amount` of its movement) for `secs`, replacing
## whatever that key held. Effects that stack read status() first.
func add_status(source: Ball, target: Ball, key: String, kind: String, amount: float, secs: float) -> void:
	target.statuses[key] = {"kind": kind, "amount": amount, "until": tick + maxi(1, int(round(secs * TICK_RATE))), "source": source.index}


## The live status under `key`, or an empty dictionary.
func status(b: Ball, key: String) -> Dictionary:
	var st: Dictionary = b.statuses.get(key, {})
	return st if not st.is_empty() and tick < st.until else {}


func clear_status(b: Ball, key: String) -> void:
	b.statuses.erase(key)


## Extra damage share `b` takes: its vulnerable statuses added up, capped.
func vulnerable(b: Ball) -> float:
	return minf(status_amount(b, "vulnerable"), VULNERABLE_CAP)


## Sum of `b`'s live statuses of `kind` ("slow" takes the strongest).
func status_amount(b: Ball, kind: String) -> float:
	var total := 0.0
	for key in b.statuses:
		var st: Dictionary = b.statuses[key]
		if st.kind == kind and tick < st.until:
			total = maxf(total, st.amount) if kind == "slow" else total + st.amount
	return total


## Drops expired statuses and applies timed slows (zones may slow it more).
func _update_statuses(b: Ball) -> void:
	for key in b.statuses.keys():
		if tick >= b.statuses[key].until:
			b.statuses.erase(key)
	b.slow = maxf(b.slow, status_amount(b, "slow"))


# --- Movement: teleport, charge, tether (critter batch F) ---------------------

## False when the fight is a Trick Shot (`fields: false`): balls fly straight.
func ability_moves() -> bool:
	return config.get("fields", true)


## Moves `b` straight to `to`, keeping its heading. Emits "teleport".
func teleport(b: Ball, to: Vector2) -> void:
	if not ability_moves():
		return
	events.append({"type": "teleport", "ball": b.index, "from": b.pos, "to": to})
	b.pos = to


## A seeded open spot for `b` at least `min_dist` from `away`: inside the
## walls, clear of obstacles and other balls. Falls back to the farthest of
## its tries when none is that far.
func teleport_spot(b: Ball, away: Vector2, min_dist: float) -> Vector2:
	var r := arena_rect().grow(-(b.radius + 10.0))
	var best := b.pos
	var best_dist := -1.0
	for i in 24:
		var p := Vector2(lerpf(r.position.x, r.end.x, rng.next_float()), lerpf(r.position.y, r.end.y, rng.next_float()))
		if not _open_spot(b, p):
			continue
		var d := p.distance_to(away)
		if d >= min_dist:
			return p
		if d > best_dist:
			best = p
			best_dist = d
	return best


func _open_spot(b: Ball, p: Vector2) -> bool:
	for wall in corner_walls():
		if wall[0].dot(p - centre) + wall[1] < b.radius + 10.0:
			return false
	for o in obstacles():
		if p.distance_to(o.pos) < o.radius + b.radius + 10.0:
			return false
	for o in balls:
		if o != b and o.alive() and p.distance_to(o.pos) < o.radius + b.radius + 20.0:
			return false
	return true


## Launches `b` along `dir` at `mult` x its speed for `secs`; it keeps the
## extra speed through bounces until the charge runs out, and slows don't
## hold it back meanwhile. Emits "charge".
func charge(b: Ball, dir: Vector2, mult: float, secs: float) -> void:
	if dir.length() < 0.001 or not ability_moves():
		return
	b.charge_mult = mult
	b.charge_ticks = maxi(1, int(round(secs * TICK_RATE)))
	b.vel = dir.normalized() * b.current_speed()
	events.append({"type": "charge", "ball": b.index, "pos": b.pos, "dir": dir.normalized()})


func charging(b: Ball) -> bool:
	return b.charge_ticks > 0


## Ends a charge early (back to normal speed).
func end_charge(b: Ball) -> void:
	if b.charge_ticks > 0:
		b.charge_ticks = 0
		if b.vel.length() > 0.001:
			b.vel = b.vel.normalized() * b.current_speed()


## Puts a ball moved by an effect back inside the walls (bouncing as usual).
func keep_inside(b: Ball) -> void:
	_resolve_walls(b)


## Slows `target` by `amount` (0-1) for `secs`. A stronger or longer slow
## already on it is kept.
func slow_for(target: Ball, amount: float, secs: float) -> void:
	var until := tick + int(round(secs * TICK_RATE))
	if tick >= target.slow_until:
		target.slow_amount = 0.0
	target.slow_amount = maxf(target.slow_amount, amount)
	target.slow_until = maxi(target.slow_until, until)


## Ties `target` to `owner` for `secs`: the gap between them can't grow past
## `length`, so the target is dragged along behind, and it can't charge
## while tied. Emits "tether".
func tether(owner: Ball, target: Ball, length: float, secs: float) -> void:
	if not ability_moves():
		return
	tethers = tethers.filter(func(t): return t.owner != owner.index)
	tethers.append({"owner": owner.index, "target": target.index, "length": length, "until": tick + int(round(secs * TICK_RATE))})
	events.append({"type": "tether", "ball": owner.index, "target": target.index, "pos": target.pos})


## The string held by `owner`, or an empty dictionary.
func tether_of(owner: Ball) -> Dictionary:
	for t in tethers:
		if t.owner == owner.index:
			return t
	return {}


func _update_tethers() -> void:
	for t in tethers.duplicate():
		var o := balls[t.owner]
		var f := balls[t.target]
		if tick > t.until or not o.alive() or not f.alive():
			tethers.erase(t)
			events.append({"type": "tether_end", "ball": t.owner, "target": t.target, "pos": f.pos})
			continue
		end_charge(f) # A tied ball can't charge or pounce.
		var reach: float = o.radius + f.radius + t.length
		var d := f.pos - o.pos
		var dist := d.length()
		if dist <= reach or dist < 0.001:
			continue
		var n := d / dist
		f.pos = o.pos + n * reach
		# Drop the part of its heading that pulls away from the string.
		var out := f.vel.dot(n)
		if out > 0.0:
			f.vel -= n * out
		f.vel = f.vel.normalized() * f.current_speed() if f.vel.length() > 0.001 else -n * f.current_speed()
		_resolve_walls(f)


## A piece (see Piece) owned by `owner` at `pos`. `opts`: kind, radius, life,
## grow, block, vel, damage. A blocking piece whose gap to the arena's edge
## would be narrower than a ball snaps onto the edge instead, so no ball gets
## wedged behind it; one that would leave such a gap to an arena obstacle
## isn't placed. Returns it, or null when not placed, or once overtime has
## shrunk the arena below OBSTACLE_MIN_SCALE (blocking pieces only: the final
## squeeze stays a clean box).
func add_piece(owner: Ball, pos: Vector2, opts: Dictionary) -> Piece:
	var p := Piece.new()
	p.owner = owner.index
	p.kind = opts.get("kind", "pillar")
	p.radius = opts.get("radius", 30.0)
	p.life = opts.get("life", 3.0)
	p.grow = opts.get("grow", 0.0)
	p.block = opts.get("block", true)
	p.vel = opts.get("vel", Vector2.ZERO)
	p.damage = opts.get("damage", 0.0)
	var r := arena_rect()
	if p.block:
		if arena_scale() < OBSTACLE_MIN_SCALE:
			return null
		var gap := PIECE_WALL_GAP + p.radius
		pos = pos.clamp(r.position, r.end)
		for axis in 2:
			if pos[axis] - r.position[axis] < gap:
				pos[axis] = r.position[axis]
			elif r.end[axis] - pos[axis] < gap:
				pos[axis] = r.end[axis]
		for wall in corner_walls(): # The same onto a cut corner.
			var d: float = wall[0].dot(pos - centre) + wall[1]
			if d < gap:
				pos -= wall[0] * d
		for o in obstacles():
			var surface_gap: float = pos.distance_to(o.pos) - o.radius - p.radius
			if not o.has("piece") and surface_gap > 0.0 and surface_gap < PIECE_OBSTACLE_GAP:
				return null
	else:
		pos = inside(pos, p.radius)
	p.pos = pos
	pieces.append(p)
	events.append({"type": "piece", "ball": owner.index, "kind": p.kind, "pos": p.pos, "radius": p.radius})
	return p


## `pos` moved just far enough to sit at least `margin` inside the arena's
## walls (cut corners included).
func inside(pos: Vector2, margin: float) -> Vector2:
	var r := arena_rect()
	pos = pos.clamp(r.position + Vector2.ONE * margin, r.end - Vector2.ONE * margin)
	for wall in corner_walls():
		var d: float = wall[0].dot(pos - centre) + wall[1]
		if d < margin:
			pos += wall[0] * (margin - d)
	return pos


## Ages, moves and expires pieces; a blocking piece starts blocking once grown
## and clear of every ball.
func _update_pieces() -> void:
	if pieces.is_empty():
		return
	var r := arena_rect()
	var squeezed := arena_scale() < OBSTACLE_MIN_SCALE
	for p in pieces.duplicate():
		p.age += DT
		if p.age >= p.life or (p.block and (squeezed or not r.grow(1.0).has_point(p.pos))):
			pieces.erase(p)
			continue
		if p.vel != Vector2.ZERO:
			p.pos += p.vel * DT
			for axis in 2:
				if p.pos[axis] - p.radius < r.position[axis]:
					p.pos[axis] = r.position[axis] + p.radius
					p.vel[axis] = absf(p.vel[axis])
				elif p.pos[axis] + p.radius > r.end[axis]:
					p.pos[axis] = r.end[axis] - p.radius
					p.vel[axis] = -absf(p.vel[axis])
			for wall in corner_walls():
				var n: Vector2 = wall[0]
				var d: float = n.dot(p.pos - centre) + wall[1]
				if d < p.radius:
					p.pos += n * (p.radius - d)
					if p.vel.dot(n) < 0.0:
						p.vel -= 2.0 * p.vel.dot(n) * n
		if p.block and not p.blocking and p.age >= p.grow:
			var clear := true
			for b in balls:
				if b.alive() and b.pos.distance_to(p.pos) < b.radius + p.radius:
					clear = false
					break
			p.blocking = clear


## Pieces owned by `owner` of `kind` ("" for any).
func pieces_of(owner: Ball, kind := "") -> Array[Piece]:
	var out: Array[Piece] = []
	for p in pieces:
		if p.owner == owner.index and (kind == "" or p.kind == kind):
			out.append(p)
	return out
