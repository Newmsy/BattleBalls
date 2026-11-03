## Bounce Run chests (Newms 2026-10-25): every run counts the same, and the
## best floor you reach in a UTC day opens a chest the next day. Each tier up
## floor (5, 10, 15, 20) is a better chest; beating the Champion on floor 25
## opens the Champion Chest, the only one with gear.
##
## Best floors per day live in user://bounce_run.cfg ("best" section, written
## by game/bounce_run.gd). The last day whose chest was opened is
## profile.bounce_chest, so a claim and its rewards save together.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const Gear := preload("res://sim/gear.gd")
const ChestDrops := preload("res://meta/chest_drops.gd")

const SAVE_PATH := "user://bounce_run.cfg"
## Unopened chests older than this many days are gone.
const KEEP_DAYS := 7

## Lowest first. Rewards are ChestDrops tables (ranges and chances, with the
## same averages as the old fixed chests); the Champion's gear piece gets its
## type from the day (rewards()).
const TIERS := [
	{"id": "bronze", "name": "Bronze Chest", "floor": 5, "color": Color("e09a5b"),
		"rewards": [{"kind": "coins", "lo": 50, "hi": 150, "step": 10}]},
	{"id": "silver", "name": "Silver Chest", "floor": 10, "color": Color("c9d6ec"),
		"rewards": [{"kind": "coins", "lo": 50, "hi": 150, "step": 10}, {"kind": "orbs", "n": 2, "pct": 50}]},
	{"id": "gold", "name": "Gold Chest", "floor": 15, "color": Color("ffc23d"),
		"rewards": [{"kind": "coins", "lo": 150, "hi": 350, "step": 10}, {"kind": "orbs", "n": 2, "pct": 50}, {"kind": "hammers", "n": 2, "pct": 50}]},
	{"id": "crystal", "name": "Crystal Chest", "floor": 20, "color": Color("6fe8ff"),
		"rewards": [{"kind": "coins", "lo": 150, "hi": 350, "step": 10}, {"kind": "orbs", "lo": 1, "hi": 3}, {"kind": "hammers", "n": 2, "pct": 50}, {"kind": "xp_chip", "n": 2, "pct": 50}]},
	{"id": "champion", "name": "Champion Chest", "floor": 25, "color": Color("ff6ad5"),
		"rewards": [{"kind": "coins", "lo": 300, "hi": 600, "step": 10}, {"kind": "orbs", "lo": 2, "hi": 6}, {"kind": "hammers", "n": 2, "pct": 50}, {"kind": "xp_chip", "n": 2, "pct": 50}, {"kind": "gear", "tier": 2}]},
]


## The chest tier (index into TIERS) a best floor opens, or -1 for none.
static func tier_for(best_floor: int) -> int:
	var t := -1
	for i in TIERS.size():
		if best_floor >= int(TIERS[i].floor):
			t = i
	return t


## Chance (out of 100) each chest tier also holds an Ascension Spark: up to
## 5% at the Champion Chest (Newms 2026-11-02).
const SPARK_CHANCE := [1, 2, 3, 4, 5]


## The drop table chest `tier` shows: its items, then the Spark chance.
static func odds(tier: int) -> Array:
	var out: Array = TIERS[tier].rewards.duplicate()
	out.append({"kind": "spark", "n": 1, "pct": int(SPARK_CHANCE[tier])})
	return out


## What chest `tier` from `day` holds for the player with chest `salt`
## (Profile.chest_seed(); 0 = the plain roll).
static func rewards(tier: int, day: int, salt := 0) -> Array:
	var out := ChestDrops.roll(odds(tier), ChestDrops.salted(day * 9173 + 29, salt))
	for g in out:
		if g.kind == "gear":
			var types := Gear.PIECES.keys()
			types.sort()
			g.type = types[Rng.new(ChestDrops.salted(day * 7349 + 11, salt)).range_int(0, types.size() - 1)]
	return out


## {day: best floor} for every day played, from the Bounce Run save.
static func best_floors(path := SAVE_PATH) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK or not cfg.has_section("best"):
		return {}
	var out := {}
	for k in cfg.get_section_keys("best"):
		out[int(k)] = int(cfg.get_value("best", k, 0))
	return out


## Sets `day`'s best floor in the Bounce Run save (Settings > Testing).
static func set_best(day: int, best_floor: int, path := SAVE_PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("best", str(day), best_floor)
	cfg.save(path)


## The oldest chest still to open: {day, floor, tier}, or {} when none. Only
## days before `today` count (today's climb isn't over yet), after
## `opened_through` (profile.bounce_chest) and within KEEP_DAYS.
static func pending(best: Dictionary, opened_through: int, today: int) -> Dictionary:
	var days := best.keys()
	days.sort()
	for d in days:
		if d <= opened_through or d >= today or d < today - KEEP_DAYS:
			continue
		var t := tier_for(int(best[d]))
		if t >= 0:
			return {"day": int(d), "floor": int(best[d]), "tier": t}
	return {}


## Opens `chest` (from pending()) into `profile`: grants what it holds and
## marks its day opened. Returns the rewards given.
static func open(profile, chest: Dictionary) -> Array:
	if chest.is_empty() or int(chest.day) <= int(profile.bounce_chest):
		return []
	var got := rewards(int(chest.tier), int(chest.day), profile.chest_seed())
	profile.bounce_chest = int(chest.day)
	for r in got:
		profile.grant(r)
	return got
