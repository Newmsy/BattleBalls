## Critter Plunge: a marble-run race where critters fight on the way down.
## 4, 6 or 8 critters drop from a gate through one of 20 courses
## (sim/plunge_course.gd); first over the line wins. Each critter races with
## its real ability: this is a MatchSim (sim/match_sim.gd) where every ball is
## its own team, so sim/abilities.gd runs unchanged. Gravity and the course
## replace the arena's walls, and a bounce off the course counts as a wall
## bounce for "wall" abilities. Only critters whose abilities read well on a
## course race (RACERS); more join as they're balanced in.
##
## Each course has a hazard section in the arenas' own pieces (gravity
## wells, lava, goo or sliding bumpers), its own set piece (spinners,
## pendulums, drifting rocks, wind, portals, launch pads, thorns...) and
## pickups (power cores, heals, shields): they sit in `arena` so the fight
## view draws them, and the race runs them by its own rules (_update_wells,
## _update_floors, _hit_movers).
##
## Damage changes places: a hit staggers its target (it loses speed), slows,
## stuns and pulls work as in a fight, and a racer at 0 HP is knocked out and
## places last.
##
## Deterministic like MatchSim: the same config always gives the same race.
##
## Config: {seed: int, racers: [ids], course: id?, tiers: [int]?, boosts:
## [{tough, power, swift, <signature>} or null]?}; with no course the seed
## picks one. Everyone races at the same power, so the drop and the
## abilities decide it; boosts are race talents (meta/plunge_talents.gd), one
## per racer: tough adds that share of HP, power of damage, swift of top
## speed (and takes SWIFT_DRAG times it off air drag), and a family's
## signature (SIGNATURES) changes how that racer races on every course, from
## 0 to its full effect at share 1.
extends "res://sim/match_sim.gd"

const PlungeCourse := preload("res://sim/plunge_course.gd")
const CritterDb := preload("res://sim/critter_db.gd")

## Bump whenever a change alters race outcomes.
const RACE_RULES := 13
const FIELD_SIZES := [4, 6, 8]
const WIDTH := PlungeCourse.WIDTH
const PART_CELL := 100.0 ## Band height for finding the moving parts near the race.
const PART_REACH := 150.0 ## How far from a racer or shot a part is still placed each tick (past a racer's reach plus a part's).
const RADIUS := 30.0 ## Every racer races this size, whatever its fight size.
const GRAVITY := 900.0
const MAX_SPEED := 600.0
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
const RUSH := 320.0 ## Taking a power core also kicks the taker down the course this fast.
## Racer-on-racer bumps only hit (contact damage, "hit" abilities) when they
## close this fast: a pile resting together doesn't grind itself down.
const BUMP_MIN := 260.0
## Speed kept when a hit of STAGGER_AT or more damage lands.
const STAGGER := 0.6
const STAGGER_AT := 3.0
## Damage by field size: most damage happens in jams, so crowded fields
## need less of it.
const DAMAGE_BY_FIELD := {4: 1.1, 6: 0.75, 8: 0.6}
## The knockout knob (Newms 2026-10-29: about 1 racer in 10 knocked out, by
## health alone): every racer's HP is scaled by this for its field size.
## About half again for the moving-machine courses, whose races run longer.
const HP_BY_FIELD := {4: 1.3, 6: 1.4, 8: 1.45}
## Higher tiers hit much harder in a race than they gain health, so every
## racer's HP also scales by the field's tier (T1..T5) to keep knockouts near
## 1 in 10 at every tier.
const HP_BY_TIER := [1.0, 1.25, 1.6, 2.0, 2.6]
## Swift (a shared race talent): air drag drops by this times its top-speed share.
const SWIFT_DRAG := 1.5
## Each family's signature race talent at full share (rank 10). Every one
## works in every race, on every course:
## lava (Scorch): its hard bumps set the rival burning, this many HP a second
##   for SCORCH_SECS, and it runs hot: SCORCH_TOP times its share more top
##   speed and gravity for SCORCH_HOT seconds.
## ice (Ice Skates): every ramp is slick for it: pushed along downhill by this
##   share of an icy ramp's push (on icy ramps and belts, on top of theirs).
## current (Wave Rider): share of the speed a stagger takes that it keeps,
##   and it surges on down at WAVE_SURGE times that.
## orbit (Heavy Star): share added to its gravity; in a bump it weighs
##   1 + HEAVY_BUMP times its share (rivals push it less, it shoves them more).
## core (Overclock): seconds between power rushes (a RUSH down the course, once
##   it's slow), from SLOW_EVERY.core at the lowest share.
## shield (Sugar Shell): start shield, as a share of max HP, and SHIELD_AGAIN
##   of that again once it's halfway down; each one's break is a sugar rush
##   (SUGAR_TOP).
## portal (Ghost Step): seconds between phasing through a rival or a moving
##   part (for PHASE_SECS, when hits don't stagger it either), from
##   SLOW_EVERY.portal at the lowest share.
## spring (Spring Loaded): a hard bounce off the course (BOUNCE_MIN) kicks it
##   on down and sideways at this share of MAX_SPEED.
## thorn (Regrowth): seconds between regrowing REGROW_HEAL of its max HP and
##   shaking off slows and stuns (then rolling on at REGROW_SURGE), from
##   SLOW_EVERY.thorn at the lowest share.
const SIGNATURES := {"lava": 14.0, "ice": 0.8, "current": 1.0, "orbit": 0.15, "core": 4.0,
	"shield": 0.16, "portal": 2.5, "spring": 0.15, "thorn": 1.5}
const SLOW_EVERY := {"core": 9.0, "portal": 8.0, "thorn": 5.0}
## Scorch is short (at full rank its burn ticks still stagger) and its
## racer runs hot: a 3 s burn of 18 HP/s took a third of a bare racer's HP
## and won Fire little (a bare racer in a Neon field was knocked out 39%).
const SCORCH_SECS := 1.5
const SCORCH_TOP := 0.4
const SCORCH_HOT := 1.5
const HEAVY_BUMP := 1.0
const SHIELD_AGAIN := 1.0
const PHASE_SECS := 0.6
const WAVE_SURGE := 350.0
const REGROW_HEAL := 0.05
const REGROW_SURGE := 250.0
## Sugar Shell's rush when a shell breaks, at full share: a RUSH down, then
## SUGAR_TOP more top speed and gravity for SUGAR_SECS.
const SUGAR_TOP := 0.35
const SUGAR_SECS := 3.0
## Overclock waits until its racer is moving down the course slower than this share of MAX_SPEED.
const OVERCLOCK_BELOW := 0.5
## A signature calls out (the "talent" event) at most this often per racer.
const TALENT_GAP := 3.0

## The critters that race, by family: ones whose abilities read well on a
## course. Others join as they're balanced in.
const RACERS := [
	"pip", "thorns", "whiff", "swarm", # nature
	"bubbles", "ink", "ripple", "kraken", # sea
	"laser", "static", "zapper", "megabot", # tech
	"honey", "gumdrop", "pucker", "bonbon", # sweet
	"frost", "drizzle", "blizz", "gust", # frost
	"drum", "mortar", "pinball", "jackpot", # toybox
	"vampire", "sonar", "brewster", "foxfire", # spooky
	"sooty", "bomber", "magmo", "drako", # fire
	"comet", "gravity", "prism", "eclipse", # cosmic
]

## Race-only scaling of a critter's ability params (multipliers), where its
## fight numbers don't fit a race (tools/plunge_stats.gd). Gravity's pull
## dragged the pack onto it; a stun or slow costs far more in a race, where
## the stuck racer sinks while the field falls on.
const RACE_TWEAKS := {
	"gravity": {"pull_accel": 0.8},
	"frost": {"trail_slow": 0.5},
	"zapper": {"zap_stun": 0.5},
	"bonbon": {"wrap_hold": 0.7},
	"pip": {"shot_speed": 1.4}, # Peas fly along its fall: at 600 they barely outran it.
	"pucker": {"pucker_stun": 1.4},
	# T5 honey lobs pulled and held the racer ahead every 6s: it won 2.3x,
	# and still 2x in fields of 8 with a lob every 18s: a quarter of the pull.
	"honey": {"honey_lob": 3.0, "honey_stick": 0.6, "honey_pull": 0.25},
	# T5 Foxfire blinked to whichever illusion was touched, mostly back up
	# the course (0.3x at T5): no swap in a race (0 switches it off).
	"foxfire": {"illusion_swap": 0.0},
}
## Race-only HP multipliers, for racers knocked out far more often than the
## field (they brawl in the jams).
const RACE_HP := {
	"gumdrop": 1.15,
	"pucker": 1.15,
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
var _boost: Array[Dictionary] = [] ## Racer -> its signature shares ({} for none).
var _swift: Array[float] = [] ## Racer -> its Swift share (top speed added).
var _sig_ready: Array[int] = [] ## Racer -> tick its Overclock or Ghost Step is ready again.
var _phase_until: Array[int] = [] ## Racer -> tick its Ghost Step phase ends.
var _reshield: Array[bool] = [] ## Racer -> Sugar Shell's second shield is still to come.
var _shelled: Array[bool] = [] ## Racer -> its Sugar Shell holds (its break gives a rush).
var _rush_until: Array[int] = [] ## Racer -> tick its sugar rush (or Scorch's heat) ends.
var _rush_top: Array[float] = [] ## Racer -> the top speed and gravity share its rush adds.
var _talent_ready: Array[int] = []
var _stalled: Array[float] = []
var _nudge_ready: Array[int] = []
var _bounce_ready: Array[int] = []
var _win_tick := -1
var _parts: Array[Dictionary] = [] ## This tick's moving parts (obstacles()), fetched once.
var _parts_tick := -1
var _parts_by_cell := {} ## Band -> indexes into _parts, this tick.
var _part_r_max := 0.0 ## The biggest moving part's radius.
var _part_cells := {} ## Course band (PART_CELL tall) -> moving parts that can ever reach it.
var _part_moving: Array[bool] = [] ## Per course part: whether it moves (as the fight tells).
var _view_key := [] ## parts_between's last [tick, bands], and its parts (render only).
var _view_parts: Array[Dictionary] = []
var _part_last := {} ## Moving part -> [tick, where it was placed], so its speed reuses last tick's spot.
var _near_tick := -1
var _near: Array[Dictionary] = [] ## This tick's moving parts near the race (obstacles()).
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
	course = PlungeCourse.new(seed_value, str(cfg.get("course", "")))
	finish_y = course.finish_y
	_focus_y = PlungeCourse.START_Y + 400.0
	# The course's hazards ride on the arena's own pieces, so the fight view
	# draws them and pickups work as in a fight; wells, goo, lava and the
	# sliding bumpers run by the race's rules below.
	arena = arena.duplicate()
	arena.floors = course.floors
	arena.wells = course.wells
	arena.cores = course.cores
	arena.obstacles = Arenas.expand_bars(course.movers)
	_index_parts()
	_core_ready.clear()
	for c in course.cores:
		_core_ready.append(0) # Lit from the start.
	var boosts: Array = cfg.get("boosts", [])
	var hp_scale: float = HP_BY_FIELD.get(ids.size(), HP_BY_FIELD[8 if ids.size() > 6 else (6 if ids.size() > 4 else 4)])
	for b in balls:
		var tier: int = clampi(int(tiers[b.index]) if b.index < tiers.size() else 1, 1, HP_BY_TIER.size())
		b.max_hp *= hp_scale * HP_BY_TIER[tier - 1] * RACE_HP.get(b.type_id, 1.0)
		b.hp = b.max_hp
		var boost = boosts[b.index] if b.index < boosts.size() else null
		var sig := {}
		var swift := 0.0
		if boost is Dictionary:
			b.max_hp *= 1.0 + float(boost.get("tough", 0.0))
			b.hp = b.max_hp
			b.attack += float(boost.get("power", 0.0))
			swift = clampf(float(boost.get("swift", 0.0)), 0.0, 0.5)
			for key in SIGNATURES:
				if float(boost.get(key, 0.0)) > 0.0:
					sig[key] = clampf(float(boost[key]), 0.0, 1.0)
		_boost.append(sig)
		_swift.append(swift)
		_reshield.append(sig.has("shield"))
		_shelled.append(sig.has("shield"))
		_rush_until.append(0)
		_rush_top.append(0.0)
		_phase_until.append(0)
		_talent_ready.append(0)
		var timed := "core"
		for key in SLOW_EVERY:
			if sig.has(key):
				timed = key
		_sig_ready.append(int(round((GATE_SECONDS + _every(b, timed)) * TICK_RATE)))
		b.shield += b.max_hp * _sig(b, "shield") * SIGNATURES.shield
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


## `b`'s share (0 to 1) of signature talent `key`: 0 for a racer without it
## and for anything that isn't a racer.
func _sig(b: Ball, key: String) -> float:
	return float(_boost[b.index].get(key, 0.0)) if b.index < _boost.size() else 0.0


## Seconds between Overclock's rushes, Ghost Step's phases or Regrowth's
## heals (`key`) for `b`.
func _every(b: Ball, key: String) -> float:
	return every(key, _sig(b, key))


## Seconds between Overclock's rushes, Ghost Step's phases or Regrowth's heals at `share`.
static func every(key: String, share: float) -> float:
	return lerpf(SLOW_EVERY[key], SIGNATURES[key], share)


## What signature `key` does at `share`, as its talent text shows it: HP a
## second (lava), seconds (core, portal, thorn) or a percent.
static func shown(key: String, share: float) -> float:
	match key:
		"lava":
			return SIGNATURES.lava * share
		"core", "portal", "thorn":
			return every(key, share)
	return SIGNATURES[key] * share * 100.0


## A signature talent just did something you can see (render only), at most
## once per TALENT_GAP for each racer.
func _talent(b: Ball, key: String, pos: Vector2) -> void:
	if b.index >= _talent_ready.size() or tick < _talent_ready[b.index]:
		return
	_talent_ready[b.index] = tick + int(TALENT_GAP * TICK_RATE)
	events.append({"type": "talent", "ball": b.index, "talent": key, "pos": pos})


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
			b.vel *= stagger_keep(b)
			if _sig(b, "current") > 0.0: # Wave Rider surges on.
				b.vel.y += WAVE_SURGE * _sig(b, "current") * SIGNATURES.current
				_talent(b, "current", b.pos)
		if b.pos.y >= finish_y:
			_cross_line(i)
			continue
		if not _boost[i].is_empty() and time() >= GATE_SECONDS:
			_signature_tick(b)
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


## The share of its speed `b` keeps when a hit staggers it: Sea's Wave
## Rider keeps more, and Ghost Step mid-phase all of it.
func stagger_keep(b: Ball) -> float:
	if b.index < _phase_until.size() and tick < _phase_until[b.index]:
		return 1.0
	var ride := _sig(b, "current") * SIGNATURES.current
	return STAGGER + (1.0 - STAGGER) * ride if ride > 0.0 else STAGGER


## Signatures that run on the clock: Nature's Regrowth heals and shakes off
## slows and stuns every few seconds (and rolls on, if it was hurt or held),
## and Sweet's Sugar Shell rushes when it breaks and shields again once,
## halfway down.
func _signature_tick(b: Ball) -> void:
	if _sig(b, "thorn") > 0.0 and tick >= _sig_ready[b.index]:
		_sig_ready[b.index] = tick + int(round(_every(b, "thorn") * TICK_RATE))
		var held := tick < b.stun_until or tick < b.slow_until or b.state.has("shot_slow") or status_amount(b, "slow") > 0.0
		b.stun_until = mini(b.stun_until, tick)
		b.slow_until = mini(b.slow_until, tick)
		b.state.erase("shot_slow")
		for key in b.statuses.keys():
			if b.statuses[key].kind == "slow":
				b.statuses.erase(key)
		var gained := minf(b.max_hp * REGROW_HEAL, b.max_hp - b.hp)
		if gained > 0.0:
			b.hp += gained
			b.healed += gained
			events.append({"type": "heal", "target": b.index, "amount": gained, "pos": b.pos})
		if held or gained > 0.0: # Back on its feet, it rolls on.
			b.vel.y = maxf(b.vel.y, 0.0) + REGROW_SURGE * _sig(b, "thorn")
			_talent(b, "thorn", b.pos)
	if _shelled[b.index] and b.shield <= 0.0:
		_shelled[b.index] = false # The shell broke: a sugar rush.
		b.vel.y = maxf(b.vel.y, 0.0) + RUSH * _sig(b, "shield")
		_rush(b, SUGAR_TOP * _sig(b, "shield"), SUGAR_SECS)
		_talent(b, "shield", b.pos)
	if _reshield[b.index] and progress(b.index) >= 0.5:
		_reshield[b.index] = false
		_shelled[b.index] = true
		var amount := b.max_hp * _sig(b, "shield") * SIGNATURES.shield * SHIELD_AGAIN
		b.shield += amount
		events.append({"type": "shield", "target": b.index, "amount": amount, "pos": b.pos})
		_talent(b, "shield", b.pos)


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
		var swift := _swift[b.index] if b.index < _swift.size() else 0.0
		var top := MAX_SPEED * (1.0 + swift) # Swift: a higher top speed and less drag.
		var fall := 1.0 + _sig(b, "orbit") * SIGNATURES.orbit # Heavy Star falls harder.
		if b.index < _rush_until.size() and tick < _rush_until[b.index]: # A sugar rush or Scorch's heat.
			top *= 1.0 + _rush_top[b.index]
			fall += _rush_top[b.index]
		b.vel.y += GRAVITY * fall * DT
		b.vel *= 1.0 - DRAG * (1.0 - swift * SWIFT_DRAG) * DT
		var sp := b.vel.length()
		if sp > top:
			b.vel *= top / sp
	var hit := course.collide(b, DT)
	_hit_movers(b, hit)
	if b.index < _boost.size() and not _boost[b.index].is_empty():
		_slide(b, hit)
		_overclock(b, hit)
	if hit.peg != null and hit.speed >= PEG_EVENT:
		events.append({"type": "course_hit", "ball": b.index, "peg": hit.peg, "bumper": hit.bumper, "pos": hit.point})
	if hit.speed >= BOUNCE_MIN and tick >= _bounce_ready[b.index] and b.index < starters:
		_bounce_ready[b.index] = tick + int(BOUNCE_GAP * TICK_RATE)
		_spring(b, hit.point)
		_on_wall_bounce(b, hit.point, true)
	b.speed = b.vel.length()


## Frost's Ice Skates: every ramp it touches is slick, pushing it on
## downhill; an icy ramp or belt pushes it harder still.
func _slide(b: Ball, hit: Dictionary) -> void:
	var share := _sig(b, "ice") * SIGNATURES.ice
	var s = hit.get("ramp")
	if share <= 0.0 or s == null:
		return
	var down: Vector2 = s.down
	if absf(down.y) < 0.1 and b.vel.dot(down) < 0.0:
		down = -down # A flat ramp: on the way it's rolling.
	b.vel += down * PlungeCourse.ICE_ACCEL * share * DT
	if s.has("ice"):
		b.vel += down * PlungeCourse.ICE_ACCEL * share * DT
	elif s.has("belt") and b.vel.dot(down) < PlungeCourse.BELT_TOP * (1.0 + share):
		b.vel += down * s.belt * share * DT
	_talent(b, "ice", b.pos)


## Tech's Overclock: every few seconds, once it's slow, a power rush down
## the course (along the ramp it's on, if any).
func _overclock(b: Ball, hit: Dictionary) -> void:
	if _sig(b, "core") <= 0.0 or tick < _sig_ready[b.index] or tick < b.stun_until:
		return
	var s = hit.get("ramp")
	var dir: Vector2 = s.down if s != null and s.down.y > 0.1 else Vector2.DOWN
	var along := b.vel.dot(dir)
	if along >= MAX_SPEED * OVERCLOCK_BELOW:
		return
	_sig_ready[b.index] = tick + int(round(_every(b, "core") * TICK_RATE))
	b.vel += dir * (maxf(0.0, -along) + RUSH)
	_talent(b, "core", b.pos)


## Toybox's Spring Loaded: a hard bounce off the course kicks it on, down
## and the way it was going sideways.
func _spring(b: Ball, at: Vector2) -> void:
	var share := _sig(b, "spring")
	if share <= 0.0:
		return
	var dir := Vector2(0.6 * signf(b.vel.x), 1.0).normalized()
	b.vel += dir * MAX_SPEED * SIGNATURES.spring * share
	_talent(b, "spring", at)


## The course's moving parts and thorns: a bounce in the part's own frame
## (a bumper kicks you away), and thorns hurt.
func _hit_movers(b: Ball, hit: Dictionary) -> void:
	if _parts_tick != tick:
		_parts_tick = tick
		_parts = obstacles()
		_parts_by_cell.clear()
		for k in _parts.size():
			var c := floori(_parts[k].pos.y / PART_CELL)
			if not _parts_by_cell.has(c):
				_parts_by_cell[c] = []
			_parts_by_cell[c].append(k)
	# Only parts in the bands round it can be in reach; once a bounce moves
	# it, the rest of the list is checked in full, so the order is the fight's.
	var reach_y: float = b.radius + _part_r_max
	var near: Array = []
	for c in range(floori((b.pos.y - reach_y) / PART_CELL), floori((b.pos.y + reach_y) / PART_CELL) + 1):
		near.append_array(_parts_by_cell.get(c, []))
	near.sort()
	var moved := -1
	var at := 0
	while true:
		var k: int
		if moved < 0:
			if at >= near.size():
				break
			k = near[at]
			at += 1
		else:
			k = moved
			moved += 1
			if k >= _parts.size():
				break
		var o: Dictionary = _parts[k]
		if o.has("piece"):
			continue
		var d: Vector2 = b.pos - o.pos
		var reach: float = b.radius + o.radius
		if d.y >= reach or d.y <= -reach or d.x >= reach or d.x <= -reach:
			continue
		var dist2 := d.length_squared()
		if dist2 >= reach * reach or dist2 < 0.0001:
			continue
		if b.index < starters and _phase(b):
			continue # Ghost Step: it passes through.
		var n := d / sqrt(dist2)
		b.pos = o.pos + n * reach
		if moved < 0:
			moved = k + 1
		var rel: Vector2 = b.vel - o.get("vel", Vector2.ZERO)
		var vn := rel.dot(n)
		if vn >= 0.0:
			continue
		if o.kind == "bumper":
			b.vel += n * (maxf(-vn * PlungeCourse.PEG_BOUNCE, PlungeCourse.BUMPER_KICK) - vn)
		else:
			b.vel -= n * vn * (1.0 + PlungeCourse.PEG_BOUNCE)
			if o.kind == "spike" and b.index < starters:
				_spike(b, o.pos + n * o.radius)
		if -vn > hit.speed:
			hit.speed = -vn
			hit.point = o.pos + n * o.radius
			hit.bumper = o.kind == "bumper"
		if not hit.has("ramp"): # Rolling along a moving piece: downhill along its surface, for Ice Skates and Overclock.
			var down := Vector2(-n.y, n.x)
			hit.ramp = {"down": down if down.y >= 0.0 else -down}
		events.append({"type": "course_hit", "ball": b.index, "peg": null, "bumper": o.kind == "bumper", "pos": o.pos + n * o.radius})


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
			if j < starters and (_phase(a) or _phase(b)):
				continue # Ghost Step: it passes through.
			var overlap := reach - dist
			var approach := (a.vel - b.vel).dot(n)
			# Heavy Star: rivals push it less (and it them more).
			var a_heavy := 1.0 + _sig(a, "orbit") * HEAVY_BUMP
			var b_heavy := 1.0 + _sig(b, "orbit") * HEAVY_BUMP
			var a_push := 0.5 if a_heavy == b_heavy else b_heavy / (a_heavy + b_heavy)
			a.pos -= n * overlap * a_push
			b.pos += n * overlap * (1.0 - a_push)
			if approach <= 0.0:
				continue
			var a_share := clampf(a.vel.dot(n) / approach, 0.0, 1.0)
			var impulse := approach * (1.0 + RACER_BOUNCE)
			a.vel -= n * impulse * a_push
			b.vel += n * impulse * (1.0 - a_push)
			a.speed = a.vel.length()
			b.speed = b.vel.length()
			if approach < BUMP_MIN:
				continue
			var contact := a.pos + n * a.radius
			events.append({"type": "collide", "a": i, "b": j, "pos": contact})
			if a_heavy != b_heavy:
				_talent(a if a_heavy > b_heavy else b, "orbit", contact)
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
			_scorch(a, b, contact)
			_scorch(b, a, contact)


## Ghost Step: whether racer `b` passes through rivals and moving parts now.
## A touch while its phase is ready starts one.
func _phase(b: Ball) -> bool:
	if tick < _phase_until[b.index]:
		return true
	if _sig(b, "portal") <= 0.0 or tick < _sig_ready[b.index]:
		return false
	_phase_until[b.index] = tick + int(round(PHASE_SECS * TICK_RATE))
	_sig_ready[b.index] = tick + int(round(_every(b, "portal") * TICK_RATE))
	_talent(b, "portal", b.pos)
	return true


## Fire's Scorch: `b`'s hard bump on `other` sets it burning, and `b`
## runs hot for a moment.
func _scorch(b: Ball, other: Ball, at: Vector2) -> void:
	var share := _sig(b, "lava")
	if share > 0.0:
		add_burn(b, other, SIGNATURES.lava * share, SCORCH_SECS)
		_rush(b, SCORCH_TOP * share, SCORCH_HOT) # It runs hot.
		_talent(b, "lava", at)


## A rush for `b`: `top` more top speed and gravity for `secs` (the
## stronger of two at once, to the later end).
func _rush(b: Ball, top: float, secs: float) -> void:
	var until := tick + int(round(secs * TICK_RATE))
	_rush_top[b.index] = top if tick >= _rush_until[b.index] else maxf(_rush_top[b.index], top)
	_rush_until[b.index] = maxi(_rush_until[b.index], until)


## A racer the course's hazards act on: still racing and out of the gate.
func _on_course(b: Ball) -> bool:
	return b.alive() and b.index < starters and racing(b.index) and time() >= GATE_SECONDS


## Wells pull for real in a race: a fight's well only bends a ball at its
## constant speed. The pull stays under gravity, so a well never holds anyone.
func _update_wells() -> void:
	for w in wells():
		for b in balls:
			if not _on_course(b):
				continue
			var d: Vector2 = w.pos - b.pos
			var dist := d.length()
			if dist <= w.core or dist >= w.reach:
				continue
			b.vel += d / dist * w.accel * (1.0 - dist / w.reach) * DT


## Goo drags, lava burns (in half-second ticks, under the fight's hazard
## cap), wind pushes, a portal sends a racer on to its exit at the same
## speed, and a launch pad throws a racer that falls onto it.
func _update_floors() -> void:
	var pads := floors()
	for f in pads:
		for b in balls:
			if not _on_course(b):
				continue
			if f.kind == "wind":
				if f.rect.has_point(b.pos):
					b.vel += f.dir * f.accel * DT
				continue
			if f.kind == "portal" or f.kind == "launch":
				if b.pos.distance_squared_to(f.pos) > f.radius * f.radius * 0.36:
					continue
				if f.kind == "portal" and f.has("to") and tick >= b.portal_ready:
					b.portal_ready = tick + int(round(PORTAL_COOLDOWN * TICK_RATE))
					events.append({"type": "portal", "ball": b.index, "from": b.pos, "to": pads[f.to].pos})
					b.pos = pads[f.to].pos
				elif f.kind == "launch" and tick >= b.launch_ready and b.vel.y > 0.0:
					b.launch_ready = tick + TICK_RATE
					b.vel = f.kick
					events.append({"type": "course_hit", "ball": b.index, "peg": null, "bumper": true, "pos": f.pos})
				continue
			if not on_floor(f, b.pos, b.radius * 0.5):
				continue
			if f.kind == "goo":
				b.vel *= 1.0 - PlungeCourse.GOO_DRAG * DT
			elif f.kind == "lava" and tick >= b.lava_ready:
				b.lava_ready = tick + TICK_RATE / 2
				if _hazard(b, LAVA_DPS * 0.5, "lava", b.pos):
					events.append({"type": "lava", "ball": b.index, "pos": b.pos})


## Pickups as in a fight, and a power core also rushes its taker down.
func _update_cores() -> void:
	var from := events.size()
	super._update_cores()
	for k in range(from, events.size()):
		var e: Dictionary = events[k]
		if e.type == "core":
			var b := balls[e.ball]
			b.vel.y = maxf(b.vel.y, 0.0) + RUSH
			b.speed = b.vel.length()


## Where a moving part can ever be, by band down the course, so a tick only
## moves the parts near the race (battery: a course is mostly moving parts).
func _index_parts() -> void:
	_part_cells.clear()
	_part_moving.clear()
	for i in arena.obstacles.size():
		var o: Dictionary = arena.obstacles[i]
		_part_moving.append(o.has("orbit") or o.has("slide")) # As the fight tells a moving part (a swing carries a slide).
		_part_r_max = maxf(_part_r_max, o.radius)
		var y: float = o.pos.y
		var reach: float = o.radius + o.get("slide", Vector2.ZERO).length()
		if o.has("orbit") or o.has("swing"):
			if not o.has("pivot"):
				reach = INF # Round the arena's centre: always placed.
			else:
				y = o.pivot.y
				reach += o.pos.distance_to(o.pivot)
		var lo := -1 if reach == INF else floori((y - reach) / PART_CELL)
		var hi := -1 if reach == INF else floori((y + reach) / PART_CELL)
		for c in range(lo, hi + 1):
			if not _part_cells.has(c):
				_part_cells[c] = []
			_part_cells[c].append(i)


## The course's moving parts near a racer, a shot or the "arena" abilities
## see (arena_rect), placed just as the fight places every obstacle: a part
## further off can't touch anything this tick, so skipping it changes
## nothing, bit for bit.
func obstacles() -> Array[Dictionary]:
	if not _crystals.is_empty() or arena_scale() != 1.0:
		return super.obstacles()
	if _near_tick != tick:
		_near_tick = tick
		_near = _parts_near()
	var out := _near.duplicate()
	for p in pieces:
		if p.blocking:
			out.append({"pos": p.pos, "radius": p.radius, "kind": p.kind, "piece": p})
	return out


func _parts_near() -> Array[Dictionary]:
	var cells := {-1: true}
	var mark := func(y: float, reach: float) -> void:
		for c in range(floori((y - reach) / PART_CELL), floori((y + reach) / PART_CELL) + 1):
			cells[c] = true
	mark.call(_focus_y, PART_REACH)
	for b in balls:
		if b.alive():
			mark.call(b.pos.y, PART_REACH)
	for sh in shots:
		mark.call(sh.pos.y, PART_REACH)
	return _place_parts(cells.keys())


## The parts that can be between world y `top` and `bottom` now, for the
## view (render only: it reads, the race's own list is untouched). Blinked
## out parts come too, marked `ghost`, so the view can show where they'll be.
func parts_between(top: float, bottom: float) -> Array[Dictionary]:
	var lo := floori(top / PART_CELL)
	var hi := floori(bottom / PART_CELL)
	var key := [tick, lo, hi]
	if key == _view_key: # Drawn again before the next tick (battery): same parts.
		return _view_parts
	var cells := [-1]
	for c in range(lo, hi + 1):
		cells.append(c)
	_view_key = key
	_view_parts = _place_parts(cells, true)
	return _view_parts


## Places the parts that can reach these bands, in course order, exactly as
## the fight's obstacles() places them. A part with `blink` is there for
## `blink` seconds, then gone as long (from `blink_at` seconds in).
func _place_parts(cells: Array, ghosts := false) -> Array[Dictionary]:
	var ids := {}
	for c in cells:
		for i in _part_cells.get(c, []):
			ids[i] = true
	var order := ids.keys()
	order.sort()
	var out: Array[Dictionary] = []
	var t := time()
	var k := arena_scale()
	for i in order:
		var o: Dictionary = arena.obstacles[i]
		var ghost := false
		if o.has("blink") and fmod(t + o.blink_at, o.blink * 2.0) >= o.blink:
			if not ghosts:
				continue
			ghost = true
		var moving: bool = _part_moving[i]
		var at: Vector2 = _moving_at(o, t) if moving else o.pos
		var d := {"pos": centre + (at - centre) * k, "radius": o.radius * k, "kind": o.kind}
		if ghost:
			d.ghost = true
		if o.has("tint"): # How the view paints it (render only).
			d.tint = o.tint
		if o.has("group"):
			d.group = o.group
		if o.has("retract") and fmod(t, o.retract * 2.0) >= o.retract:
			d.kind = "pillar" # Thorns pulled in: a plain post until they come back out.
			d.retracted = true
		if moving:
			# Where it was last tick: remembered when it was placed then.
			var last = _part_last.get(i)
			var was: Vector2 = last[1] if last != null and last[0] == tick - 1 else _moving_at(o, t - DT)
			if not ghosts:
				_part_last[i] = [tick, at]
			d.vel = (at - was) / DT * k
			if o.has("bar"):
				d.bar = o.bar
				if o.has("orbit"):
					d.hub = centre + (o.get("pivot", centre) - centre) * k
		out.append(d)
	return out


## Swinging parts (pendulums, flippers) swing `swing` radians either way
## round their pivot; the rest move as in a fight.
## A slide with a `phase` runs that far through its period ahead (rows and
## worm segments out of step).
func _moving_at(o: Dictionary, t: float) -> Vector2:
	if o.has("swing"):
		return o.pivot + _rotated_now(o.pos - o.pivot, o.swing * _sincos_now(TAU * (t / o.period + o.phase))[0])
	if o.has("phase") and o.has("slide"):
		var at: Vector2 = o.pos + o.slide * _sincos_now(TAU * (t / o.period + o.phase))[0]
		if o.has("orbit"):
			var pivot: Vector2 = o.get("pivot", centre)
			at = pivot + _rotated_now(at - pivot, o.orbit * t)
		return at
	return super._moving_at(o, t)


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
