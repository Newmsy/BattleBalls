## Daily Trick Shot prize: solving today's puzzle pays once, more for fewer
## tries. Faction XP goes to the family of the day's shooter (a random
## critter), so a solve feeds a talent tree even when you don't own it.
## Only today's puzzle pays (old days opened with ?day= don't), and only once:
## profile.trick_reward is the last day paid, so a claim and its rewards
## save together.
extends RefCounted

const Talents := preload("res://sim/talents.gd")

## By tries used (1, 2, 3). Profile.grant() dicts; the faction XP row gets
## its family from the shooter (rewards()).
const BY_TRIES := [
	[{"kind": "coins", "n": 150}, {"kind": "orbs", "n": 1}, {"kind": "faction_xp", "n": 12}],
	[{"kind": "coins", "n": 100}, {"kind": "faction_xp", "n": 8}],
	[{"kind": "coins", "n": 60}, {"kind": "faction_xp", "n": 5}],
]


## What a solve in `tries` tries with `shooter` earns.
static func rewards(tries: int, shooter: String) -> Array:
	var out: Array = []
	var fam := Talents.faction_of(shooter)
	for r in BY_TRIES[clampi(tries, 1, BY_TRIES.size()) - 1]:
		if r.kind == "faction_xp" and fam == "":
			continue
		var g: Dictionary = r.duplicate()
		if g.kind == "faction_xp":
			g.id = fam
		out.append(g)
	return out


## Pays `day`'s solve into `profile` unless that day (or a later one) was
## already paid. Returns the rewards given, empty when nothing was.
static func claim(profile, day: int, tries: int, shooter: String) -> Array:
	if day <= int(profile.trick_reward):
		return []
	profile.trick_reward = day
	var got := rewards(tries, shooter)
	for r in got:
		profile.grant(r)
	return got
