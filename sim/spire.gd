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
const Families := preload("res://sim/families.gd")

const FLOORS := 50
## Monday 2026-01-05 00:00 UTC, week 0 (same epoch as game/liveops.gd).
const EPOCH := 1767571200
const WEEK := 7 * 86400

## Enemy power multiplier (sim/power.gd scale, 1.0 = T1 level 1 Common):
## about a T1 level 5 Common on floor 1, rising a fixed step per floor to
## about a T5 level 40 Rare on floor 50 (x1.25 since one rarity step became a
## whole tier, 2026-10-22: the step was 1.0323). Tuned with tools/spire_curve.gd.
const POWER_START := 1.1
const POWER_STEP := 1.037
const BOSS_FLOORS := [10, 20, 30, 40, 50]
## Drawn and fought this much bigger than a normal ball (campaign bosses are 1.35).
const BOSS_SIZE := 1.7
## Foes tier up every 10 floors (T1 on 1-10 ... T5 on 41-50). Their ability
## upgrades make a tier worth more than its power, so the power drops by the
## campaign's measured factor (meta/zones.gd FOE_POWER) to keep each floor as
## hard as before.
const FLOORS_PER_TIER := 10
const FOE_POWER := [1.0, 0.92, 0.76, 0.7, 0.65]
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


## How hard a floor is, as power at T1 (sim/power.gd scale). The foes fight
## at tier_at() with power_at() x FOE_POWER, which is about as hard.
static func power_at(floor_no: int) -> float:
	return POWER_START * DMath.ipow(POWER_STEP, floor_no - 1)


static func tier_at(floor_no: int) -> int:
	return clampi(1 + (floor_no - 1) / FLOORS_PER_TIER, 1, 5)


## The family a floor's foes all come from: each floor moves one family on,
## and the week shifts where the cycle starts.
static func family_at(week: int, floor_no: int) -> String:
	var ids := Families.ids()
	return ids[posmod(week + floor_no - 1, ids.size())]


## The floor's fight seed and enemy lineup, all from the floor's family.
## Returns {floor, seed, boss, lineup (balls per side), family, tier,
## enemies: [{id, power, tier, scale, rating}]}: `power` is what the foe
## fights at, `rating` the T1-equivalent Power Rating shown.
static func floor_def(week: int, floor_no: int, pool: Array = []) -> Dictionary:
	if pool.is_empty():
		pool = BallDefs.PLAYABLE
	assert(floor_no >= 1 and floor_no <= FLOORS, "No such floor: %d" % floor_no)
	var rng := Rng.new(_mix(week, floor_no))
	var fight_seed := int(rng.next_u32() & 0x7FFFFFFF)
	var size := lineup_size(floor_no)
	var family := family_at(week, floor_no)
	var kin := pool.filter(func(id): return Families.of(id) == family)
	if kin.size() >= size:
		pool = kin
	var tier := tier_at(floor_no)
	var rating := power_at(floor_no)
	var power: float = rating * FOE_POWER[tier - 1]
	var enemies: Array = []
	if is_boss(floor_no):
		var id: String = pool[rng.range_int(0, pool.size() - 1)]
		enemies.append({"id": id, "power": power * BOSS_POWER[size], "tier": tier, "scale": BOSS_SIZE, "rating": rating * BOSS_POWER[size]})
	else:
		var bag := pool.duplicate()
		for i in size:
			if bag.is_empty():
				bag = pool.duplicate()
			var id: String = bag.pop_at(rng.range_int(0, bag.size() - 1))
			enemies.append({"id": id, "power": power, "tier": tier, "scale": 1.0, "rating": rating})
	return {"floor": floor_no, "seed": fight_seed, "boss": is_boss(floor_no), "lineup": size, "family": family, "tier": tier,
		"enemies": enemies, "arena": Arenas.pick(fight_seed)}


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
		"tiers": [picks.map(func(p): return Lineup.clean(p.slot).tier if p.has("slot") else 1), spec.enemies.map(func(e): return int(e.get("tier", 1)))],
		"gear": [picks.map(func(p): return Lineup.clean(p.slot).gear if p.has("slot") else null), spec.enemies.map(func(_e): return null)],
		"talents": [picks.map(func(p): return Lineup.clean(p.slot).get("talents", {}) if p.has("slot") else null), spec.enemies.map(func(_e): return null)],
		"sizes": [picks.map(func(_p): return 1.0), spec.enemies.map(func(e): return float(e.scale))],
		"tie_to": 0, # Both out together is your win.
	}


## Boss floors' gear piece (design/gear.md section 4): [type, tier], one per
## boss floor in BOSS_FLOORS order.
const BOSS_GEAR := [["thorn_shell", 2], ["spike_core", 2], ["spring_shell", 3], ["leech_core", 3], ["phoenix_charm", 4]]


## Critter XP a floor pays each ball that came out to fight. A win grows with
## the floor like campaign stages do (meta/campaign.gd) and boss floors pay
## double; a loss pays a little, like a lost stage. Stamina caps how often.
const WIN_XP_BASE := 10
const WIN_XP_PER_FLOOR := 3
const LOSS_XP := 3


static func xp(floor_no: int, won: bool) -> int:
	if not won:
		return LOSS_XP + floor_no / 5
	return (WIN_XP_BASE + WIN_XP_PER_FLOOR * floor_no) * (2 if is_boss(floor_no) else 1)


## First-clear reward for a floor, paid once per week.
## {coins, orbs, hammers, gear: {} or {type, tier}}. Every third floor pays
## a Hammer (it paid an XP Chip until the 2026-10-25 progression check).
static func reward(floor_no: int) -> Dictionary:
	var r := {"coins": 40 + 10 * floor_no, "orbs": 0, "hammers": 0, "gear": {}}
	if floor_no % 3 == 0:
		r.hammers = 1
	if floor_no % 5 == 0:
		r.orbs = 1
	if is_boss(floor_no):
		var g: Array = BOSS_GEAR[BOSS_FLOORS.find(floor_no)]
		r.gear = {"type": g[0], "tier": g[1]}
	return r


static func _mix(week: int, floor_no: int) -> int:
	var h := (week * 0x9E3779B1 + floor_no * 0x85EBCA77) & 0xFFFFFFFF
	h = ((h ^ (h >> 16)) * 0x7FEB352D) & 0xFFFFFFFF
	return (h ^ (h >> 15)) & 0x7FFFFFFF
