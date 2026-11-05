## Daily Trick Shot prizes: each of the day's three puzzles (1, 2 and 3
## stars) pays once, more for more stars and fewer tries. Faction XP goes to
## the family of the puzzle's shooter (a random critter), so a solve feeds a
## talent tree even when you don't own it. Only today's puzzles pay (old days
## opened with ?day= don't): profile.trick_reward is the last day paid and
## profile.trick_levels which of its puzzles, so a claim and its rewards save
## together.
extends RefCounted

const Talents := preload("res://sim/talents.gd")

## By stars, then tries used (1, 2, 3). Profile.grant() dicts; the faction XP
## row gets its family from the shooter (rewards()).
const BY_LEVEL := [
	[
		[{"kind": "coins", "n": 80}, {"kind": "faction_xp", "n": 6}],
		[{"kind": "coins", "n": 60}, {"kind": "faction_xp", "n": 4}],
		[{"kind": "coins", "n": 40}, {"kind": "faction_xp", "n": 3}],
	],
	[
		[{"kind": "coins", "n": 150}, {"kind": "orbs", "n": 1}, {"kind": "faction_xp", "n": 12}],
		[{"kind": "coins", "n": 100}, {"kind": "faction_xp", "n": 8}],
		[{"kind": "coins", "n": 60}, {"kind": "faction_xp", "n": 5}],
	],
	[
		[{"kind": "coins", "n": 220}, {"kind": "orbs", "n": 2}, {"kind": "faction_xp", "n": 18}],
		[{"kind": "coins", "n": 150}, {"kind": "orbs", "n": 1}, {"kind": "faction_xp", "n": 12}],
		[{"kind": "coins", "n": 90}, {"kind": "faction_xp", "n": 8}],
	],
]


## What a `level`-star solve in `tries` tries with `shooter` earns.
static func rewards(tries: int, shooter: String, level := 1) -> Array:
	var out: Array = []
	var fam := Talents.faction_of(shooter)
	var table: Array = BY_LEVEL[clampi(level, 1, BY_LEVEL.size()) - 1]
	for r in table[clampi(tries, 1, table.size()) - 1]:
		if r.kind == "faction_xp" and fam == "":
			continue
		var g: Dictionary = r.duplicate()
		if g.kind == "faction_xp":
			g.id = fam
		out.append(g)
	return out


## Whether `day`'s `level`-star puzzle was already paid (or a later day was).
static func paid(profile, day: int, level := 1) -> bool:
	var last := int(profile.trick_reward)
	return day < last or (day == last and int(profile.trick_levels) & (1 << (level - 1)) != 0)


## Pays `day`'s `level`-star solve into `profile` unless it was already paid.
## Returns the rewards given, empty when nothing was.
static func claim(profile, day: int, tries: int, shooter: String, level := 1) -> Array:
	if paid(profile, day, level):
		return []
	if day > int(profile.trick_reward):
		profile.trick_reward = day
		profile.trick_levels = 0
	profile.trick_levels = int(profile.trick_levels) | (1 << (level - 1))
	var got := rewards(tries, shooter, level)
	for r in got:
		profile.grant(r)
	return got
