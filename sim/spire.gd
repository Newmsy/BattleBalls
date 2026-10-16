## The Spire (design/spire.md): a 50-floor tower that is the same for every
## player in a given week. Everything about a floor (enemies, their power,
## its fight seed) comes from the week number and the floor number, so a
## clear is replayable from {week, floor, picks, aims} alone.
##
## Pure data and rules, no nodes or clock: callers pass the week in.
extends RefCounted

const Arenas := preload("res://sim/arenas.gd")
const Rng := preload("res://sim/rng.gd")
const Lineup := preload("res://sim/lineup.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const DMath := preload("res://sim/dmath.gd")

const FLOORS := 50
## Monday 2026-01-05 00:00 UTC, week 0 (same epoch as game/liveops.gd).
const EPOCH := 1767571200
const WEEK := 7 * 86400

## Enemy power multiplier (sim/power.gd scale, 1.0 = T1 level 1 Common):
## about a T1 level 5 Common on floor 1, rising a fixed step per floor to
## about a T5 level 40 Rare on floor 50. Tuned with tools/spire_curve.gd.
const POWER_START := 1.1
const POWER_STEP := 1.0323
const BOSS_FLOORS := [10, 20, 30, 40, 50]
const BOSS_SIZE := 1.35
## A boss fights your whole lineup alone, so it gets a power bonus by how
## many balls it has to get through.
const BOSS_POWER := {1: 1.0, 2: 1.2, 3: 1.4}


static func week_of(unix_time: int) -> int:
	return floori(float(unix_time - EPOCH) / WEEK)


## Unix time the given week ends (the next Monday 00:00 UTC).
static func week_end(week: int) -> int:
	return EPOCH + (week + 1) * WEEK


## How many balls each side brings: 1 on floors 1-4, 2 on 5-14, 3 from 15
## (the campaign's zone 1 / zone 2 / zone 3+ pattern).
static func lineup_size(floor_no: int) -> int:
	if floor_no < 5:
		return 1
	if floor_no < 15:
		return 2
	return 3


static func is_boss(floor_no: int) -> bool:
	return floor_no in BOSS_FLOORS


static func power_at(floor_no: int) -> float:
	return POWER_START * DMath.ipow(POWER_STEP, floor_no - 1)


## The floor's fight seed and enemy lineup.
## Returns {floor, seed, boss, lineup (balls per side), enemies: [{id, power, scale}]}.
static func floor_def(week: int, floor_no: int, pool: Array = []) -> Dictionary:
	if pool.is_empty():
		pool = BallDefs.PLAYABLE
	assert(floor_no >= 1 and floor_no <= FLOORS, "No such floor: %d" % floor_no)
	var rng := Rng.new(_mix(week, floor_no))
	var fight_seed := int(rng.next_u32() & 0x7FFFFFFF)
	var size := lineup_size(floor_no)
	var power := power_at(floor_no)
	var enemies: Array = []
	if is_boss(floor_no):
		var id: String = pool[rng.range_int(0, pool.size() - 1)]
		enemies.append({"id": id, "power": power * BOSS_POWER[size], "scale": BOSS_SIZE})
	else:
		var bag := pool.duplicate()
		for i in size:
			if bag.is_empty():
				bag = pool.duplicate()
			var id: String = bag.pop_at(rng.range_int(0, bag.size() - 1))
			enemies.append({"id": id, "power": power, "scale": 1.0})
	return {"floor": floor_no, "seed": fight_seed, "boss": is_boss(floor_no), "lineup": size, "enemies": enemies, "arena": Arenas.pick(fight_seed)}


## Relay config (sim/relay.gd) for an attempt. `picks` are your balls in
## order as {id, power}, or with `slot` (sim/lineup.gd) a ball fights at that
## owned tier, level and gear instead; `aims` your launch angles per slot
## (null = unaimed).
static func relay_config(spec: Dictionary, picks: Array, aims: Array = []) -> Dictionary:
	assert(picks.size() >= 1 and picks.size() <= spec.lineup, "Bring 1 to %d balls" % spec.lineup)
	var my_aims: Array = []
	for i in picks.size():
		my_aims.append(aims[i] if i < aims.size() else null)
	return {
		"seed": spec.seed,
		"arena": spec.get("arena", "square"),
		"sides": [picks.map(func(p): return p.id), spec.enemies.map(func(e): return e.id)],
		"aims": [my_aims, spec.enemies.map(func(_e): return null)],
		"powers": [picks.map(func(p): return Lineup.power(p.slot) if p.has("slot") else float(p.power)), spec.enemies.map(func(e): return float(e.power))],
		"tiers": [picks.map(func(p): return Lineup.clean(p.slot).tier if p.has("slot") else 1), spec.enemies.map(func(_e): return 1)],
		"gear": [picks.map(func(p): return Lineup.clean(p.slot).gear if p.has("slot") else null), spec.enemies.map(func(_e): return null)],
		"talents": [picks.map(func(p): return Lineup.clean(p.slot).get("talents", {}) if p.has("slot") else null), spec.enemies.map(func(_e): return null)],
		"sizes": [picks.map(func(_p): return 1.0), spec.enemies.map(func(e): return float(e.scale))],
	}


## Boss floors' gear piece (design/gear.md section 4): [type, tier], one per
## boss floor in BOSS_FLOORS order.
const BOSS_GEAR := [["bubble_shell", 2], ["spike_core", 2], ["iron_shell", 3], ["echo_core", 3], ["jet_charm", 4]]


## First-clear reward for a floor, paid once per week.
## {coins, orbs, xp_chips, gear: {} or {type, tier}}.
static func reward(floor_no: int) -> Dictionary:
	var r := {"coins": 40 + 10 * floor_no, "orbs": 0, "xp_chips": 0, "gear": {}}
	if floor_no % 3 == 0:
		r.xp_chips = 1
	if floor_no % 5 == 0:
		r.orbs = 1
	if is_boss(floor_no):
		var g: Array = BOSS_GEAR[BOSS_FLOORS.find(floor_no)]
		r.gear = {"type": g[0], "tier": g[1]}
	return r


## A display tier (1-5) for an enemy of this power and rarity: the tier a
## mid-levelled critter of that rarity would need to reach the power.
static func display_tier(power: float, rarity_mult: float) -> int:
	for t in range(5, 1, -1):
		var mid_level := 1.0 + 0.025 * (t * 5 - 1)
		if rarity_mult * DMath.ipow(1.25, t - 1) * mid_level <= power:
			return t
	return 1


static func _mix(week: int, floor_no: int) -> int:
	var h := (week * 0x9E3779B1 + floor_no * 0x85EBCA77) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x7FEB352D) & 0xFFFFFFFF
	return (h ^ (h >> 15)) & 0x7FFFFFFF
