## Boss levels (Newms 2026-10-20): each daily farming boss with a power
## ladder (Anvil King, Brood Queen, Totem of Nine, Prism Wyrm) has 15 levels,
## each stronger than the last and paying more. Beating a level opens the
## next. Level 9 is a hard fight for a maxed T5 critter (~7,700 power since one
## rarity step became a whole tier, 2026-10-22: every curve's level 9 went x1.4); 10-15
## go up from there for stronger teams. A level is its 0-based index in the
## boss's DIFFICULTIES table, which the rules files write out in full.
##
## profile.boss_levels: {key: highest level beaten, 0-15}.
extends RefCounted

const COUNT := 15


static func beaten(profile, key: String) -> int:
	return clampi(int(profile.boss_levels.get(key, 0)), 0, COUNT)


## 0-based level `difficulty` can be fought: level 1, or the one after a beaten one.
static func is_open(profile, key: String, difficulty: int) -> bool:
	return difficulty >= 0 and difficulty < COUNT and difficulty <= beaten(profile, key)


## The highest open level (0-based).
static func top_open(profile, key: String) -> int:
	return mini(beaten(profile, key), COUNT - 1)


## A win at 0-based `difficulty` opens the next level.
static func beat(profile, key: String, difficulty: int) -> void:
	profile.boss_levels[key] = clampi(maxi(beaten(profile, key), difficulty + 1), 0, COUNT)


## A boss's power at each level: geometric from `first` (level 1) to `ninth`
## (level 9), then on up at `step` a level. Used to write the tables below
## and by the test that checks they still follow it.
static func curve(first: float, ninth: float, step := 1.12) -> Array:
	var out := []
	var k := pow(ninth / first, 1.0 / 8.0)
	for i in COUNT:
		out.append(snappedf(first * pow(k, i) if i <= 8 else ninth * pow(step, i - 8), 0.1))
	return out
