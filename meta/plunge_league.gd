## The Critter Plunge league: Bronze to Neon, the arena's leagues and crests
## (game/ui/versus_art/league_<id>_Lcrest.png). Medals climb it: league
## points are every medal ever won in Plunge, in bronze (gold 4, silver 2,
## bronze 1; PlungeTalents.points), so spending medals on talents never
## lowers it and a league is never lost. Each league races a stronger CPU
## field (every talent of its own family's tree at `rank`, the ranks your
## own racer buys) and multiplies the prize races' coins by `coins`.
##
## `min` is set so a regular player (about 15 races a day, about one bronze
## a race in a field of 6) reaches Silver on day 1 or 2, Gold in about a
## week and Neon in about 7 weeks.
extends RefCounted

const PlungeTalents := preload("res://meta/plunge_talents.gd")

const LEAGUES := [
	{"id": "bronze", "name": "Bronze", "min": 0, "rank": 0, "coins": 1.0},
	{"id": "silver", "name": "Silver", "min": 20, "rank": 2, "coins": 1.15},
	{"id": "gold", "name": "Gold", "min": 100, "rank": 4, "coins": 1.3},
	{"id": "platinum", "name": "Platinum", "min": 250, "rank": 6, "coins": 1.5},
	{"id": "diamond", "name": "Diamond", "min": 450, "rank": 8, "coins": 1.75},
	{"id": "neon", "name": "Neon", "min": 700, "rank": 10, "coins": 2.0},
]


## The league `points` reach (an index into LEAGUES).
static func index_for(points: int) -> int:
	var idx := 0
	for i in LEAGUES.size():
		if points >= LEAGUES[i].min:
			idx = i
	return idx


## Your league (an index into LEAGUES).
static func index(profile) -> int:
	return index_for(PlungeTalents.points(profile)) if profile != null else 0


static func league(profile) -> Dictionary:
	return LEAGUES[index(profile)]


## How far `points` are from their league to the next, 0 to 1 (1 in Neon).
static func progress(points: int) -> float:
	var idx := index_for(points)
	if idx == LEAGUES.size() - 1:
		return 1.0
	var lo: int = LEAGUES[idx].min
	return float(points - lo) / float(LEAGUES[idx + 1].min - lo)


## What a CPU `critter` races with in league `idx` (sim/plunge.gd boosts),
## or null in Bronze.
static func field_boost(critter: String, idx: int):
	var r: int = LEAGUES[clampi(idx, 0, LEAGUES.size() - 1)].rank
	return PlungeTalents.at_rank(critter, r) if r > 0 else null
