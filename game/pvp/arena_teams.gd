## Themed Arena teams: until online play opens, every Ghost Arena opponent is
## a seeded team from one family (a Frost Squad, a Toybox Gang...), built to
## a target strength. The target starts at the player's own trio power, so a
## new player meets teams their size, and climbs with trophies. Each card
## (easier / even / harder) scales it. Everything comes from fixed seeds, so
## a team (and the fight against it) replays from its config alone.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Lineup := preload("res://sim/lineup.gd")
const Families := preload("res://sim/families.gd")
const Gear := preload("res://sim/gear.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")

## Team strength against yours, per card.
const CARD_SCALE := {"easier": 0.85, "even": 1.0, "harder": 1.15}
## Teams grow this much stronger than you per 1,000 trophies, up to LADDER_MAX.
const LADDER_STEP := 0.08
const LADDER_MAX := 0.5
## Weakest team a card can show (a fresh T1 Common trio is about 1000).
const MIN_TARGET := 900

const TEAM_NAMES := {
	"nature": ["Bramble Bunch", "Moss Mob", "Petal Patrol"],
	"sea": ["Tide Crew", "Reef Raiders", "Bubble Squad"],
	"tech": ["Circuit Gang", "Bolt Brigade", "Gear Crew"],
	"sweet": ["Sugar Rush", "Candy Crew", "Fizz Gang"],
	"frost": ["Frost Squad", "Ice Pack", "Snow Patrol"],
	"toybox": ["Toybox Gang", "Pinball Posse", "Arcade Crew"],
	"spooky": ["Haunt House", "Night Shift", "Ghoul Gang"],
	"fire": ["Ember Gang", "Blaze Crew", "Cinder Squad"],
	"cosmic": ["Star Fleet", "Orbit Crew", "Comet Club"],
}


## Rating a team should have on `card`, for a player whose trio rates
## `mine` (Lineup.rating summed over the trio) at `trophies`.
static func target(mine: int, trophies: int, card: String) -> int:
	var ladder := 1.0 + minf(LADDER_MAX, LADDER_STEP * maxi(0, trophies) / 1000.0)
	return maxi(MIN_TARGET * 3, roundi(mine * ladder * CARD_SCALE[card]))


## Today's three cards: {card, bot}. A bot is a full lineup, so the fight
## needs nothing else to replay. Stable for (day, refresh, trophies, power).
static func offers(trophies: int, mine: int, day: int, refresh := 0) -> Array[Dictionary]:
	var rng = Rng.new(hash("teams|%d|%d|%d" % [day, refresh, trophies / 50]))
	var fams: Array = Families.ids()
	var cards: Array[Dictionary] = []
	for card in Ladder.CARD_ORDER:
		var goal := target(mine, trophies, card)
		# Only themes that can build a team this small (low targets rule out
		# families with few Commons); else the theme that gets closest.
		var can: Array = fams.filter(func(f): return weakest(f) <= goal * 1.05)
		if can.is_empty():
			var low: Array = fams.duplicate()
			low.sort_custom(func(a, b): return weakest(a) < weakest(b))
			can = [low[0]]
		var fam: String = can[rng.range_int(0, can.size() - 1)]
		fams.erase(fam)
		var team := make(fam, goal, rng.range_int(1, 0x7FFFFFFF))
		team.id = "team-%d-%d-%s" % [day, refresh, card]
		team.trophies = maxi(0, trophies + Ladder.CARDS[card].offset)
		cards.append({"card": card, "bot": team})
	return cards


## One themed team of three different critters from `family`, levelled so
## the trio's summed Power Rating lands as close to `goal` as it can.
static func make(family: String, goal: int, seed_value: int) -> Dictionary:
	var rng = Rng.new(seed_value)
	var per := goal / 3.0
	var members: Array = Families.MEMBERS[family].filter(func(id): return id in BallDefs.PLAYABLE)
	# Critters that can be built down to the goal; rarer ones only when the
	# goal is high enough for them even at 1 star.
	var fits: Array = members.filter(func(id): return Lineup.rating(Lineup.make(id)) <= per * 1.05)
	if fits.size() < 3:
		members.sort_custom(func(a, b): return Lineup.rating(Lineup.make(a)) < Lineup.rating(Lineup.make(b)))
		fits = members.slice(0, 3)
	var picks: Array = []
	while picks.size() < 3:
		picks.append(fits.pop_at(rng.range_int(0, fits.size() - 1)))
	var slots: Array = []
	var shots: Array = []
	for id in picks:
		var s := _build(id, per)
		s.aim = rng.range_int(-ArenaGhosts.AIM_SPREAD, ArenaGhosts.AIM_SPREAD)
		shots.append(s.aim)
		slots.append(s)
	var names: Array = TEAM_NAMES[family]
	return {
		"id": "team",
		"name": names[rng.range_int(0, names.size() - 1)],
		"family": family,
		"is_bot": true,
		"trophies": 0,
		"lineup": {"v": 1, "slots": slots, "aim": shots},
	}


## The weakest team a family can field: its three weakest critters at 1 star.
static func weakest(family: String) -> int:
	var r: Array = Families.MEMBERS[family].filter(func(id): return id in BallDefs.PLAYABLE).map(func(id): return Lineup.rating(Lineup.make(id)))
	r.sort()
	return r[0] + r[1] + r[2]


## The team's summed Power Rating.
static func rating(team: Dictionary) -> int:
	var total := 0
	for s in team.lineup.slots:
		total += Lineup.rating(s)
	return total


## `critter` at the tier and level whose rating is nearest `per`, wearing the
## gear a player at that tier would (ArenaGhosts.bot_gear's pieces).
static func _build(critter: String, per: float) -> Dictionary:
	var best := {}
	var best_gap := INF
	for tier in range(1, Lineup.MAX_TIER + 1):
		var gear := _gear(tier)
		for level in range(1, Lineup.level_cap(tier) + 1):
			var s := Lineup.make(critter, tier, level, gear)
			var gap := absf(Lineup.rating(s) - per)
			if gap < best_gap:
				best_gap = gap
				best = s
	return best


static func _gear(tier: int) -> Array:
	if tier < 2:
		return []
	var types := ["bubble_shell", "spike_core"]
	if tier >= Gear.CHARM_TIER:
		types.append("jet_charm")
	return types.map(func(t): return {"slot": Gear.PIECES[t].slot, "tier": tier - 1, "stats": Gear.stats_for(t, tier - 1)})
