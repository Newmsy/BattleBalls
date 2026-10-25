## Bounce Run chests (Newms 2026-10-25): every run counts the same, and the
## best floor you reach in a UTC day opens a chest the next day. Each tier up
## floor (4, 8, 12, 16) is a better chest; beating the Champion on floor 20
## opens the Champion Chest, the only one with gear.
##
## Best floors per day live in user://bounce_run.cfg ("best" section, written
## by game/bounce_run.gd). The last day whose chest was opened is
## profile.bounce_chest, so a claim and its rewards save together.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const Gear := preload("res://sim/gear.gd")

const SAVE_PATH := "user://bounce_run.cfg"
## Unopened chests older than this many days are gone.
const KEEP_DAYS := 7

## Lowest first. Rewards are Profile.grant() dicts; the Champion's gear piece
## gets its type from the day (rewards()).
const TIERS := [
	{"id": "bronze", "name": "Bronze Chest", "floor": 4, "color": Color("e09a5b"),
		"rewards": [{"kind": "coins", "n": 100}]},
	{"id": "silver", "name": "Silver Chest", "floor": 8, "color": Color("c9d6ec"),
		"rewards": [{"kind": "coins", "n": 100}, {"kind": "orbs", "n": 1}]},
	{"id": "gold", "name": "Gold Chest", "floor": 12, "color": Color("ffc23d"),
		"rewards": [{"kind": "coins", "n": 250}, {"kind": "orbs", "n": 1}, {"kind": "hammers", "n": 1}]},
	{"id": "crystal", "name": "Crystal Chest", "floor": 16, "color": Color("6fe8ff"),
		"rewards": [{"kind": "coins", "n": 250}, {"kind": "orbs", "n": 2}, {"kind": "hammers", "n": 1}, {"kind": "xp_chip", "n": 1}]},
	{"id": "champion", "name": "Champion Chest", "floor": 20, "color": Color("ff6ad5"),
		"rewards": [{"kind": "coins", "n": 450}, {"kind": "orbs", "n": 4}, {"kind": "hammers", "n": 1}, {"kind": "xp_chip", "n": 1}, {"kind": "gear", "tier": 2}]},
]


## The chest tier (index into TIERS) a best floor opens, or -1 for none.
static func tier_for(best_floor: int) -> int:
	var t := -1
	for i in TIERS.size():
		if best_floor >= int(TIERS[i].floor):
			t = i
	return t


## What chest `tier` from `day` holds.
static func rewards(tier: int, day: int) -> Array:
	var out: Array = []
	for r in TIERS[tier].rewards:
		var g: Dictionary = r.duplicate()
		if g.kind == "gear":
			var types := Gear.PIECES.keys()
			types.sort()
			g.type = types[Rng.new(day * 7349 + 11).range_int(0, types.size() - 1)]
		out.append(g)
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
	var got := rewards(int(chest.tier), int(chest.day))
	profile.bounce_chest = int(chest.day)
	for r in got:
		profile.grant(r)
	return got
