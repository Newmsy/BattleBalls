## The one place a live match's fight config is built, used by the live server
## (server/live_lobby.gd) and by both phones, so all three run the same fight.
## Inputs only: the server's seed, each side's slots (Lineup slots, cleaned) and
## each side's launch angle (null: the seed aims, like a ghost).
extends RefCounted

const Lineup := preload("res://sim/lineup.gd")
const Arenas := preload("res://sim/arenas.gd")
const CritterDb := preload("res://sim/critter_db.gd")


## A side's slots made safe to fight with: cleaned, known critters, no repeats,
## no Arena Boost (that's for the Arena only). [] if they aren't.
static func clean_slots(raw: Array, count: int) -> Array:
	if raw.size() != count:
		return []
	var out: Array = []
	var seen := {}
	for r in raw:
		if not r is Dictionary:
			return []
		var s := Lineup.clean(r)
		if not CritterDb.live_ids().has(s.critter) or seen.has(s.critter):
			return []
		s.erase("boost")
		seen[s.critter] = true
		out.append(s)
	return out


## sides: [side 0's slots, side 1's slots] (1 each for 1v1, 2 each for 2v2).
## In a 2v2 each player aims their front ball; the seed aims the mates.
static func config(seed_value: int, sides: Array, angles: Array) -> Dictionary:
	var cfg := {"seed": seed_value, "arena": Arenas.pick(seed_value)}
	Lineup.apply(cfg, 0, sides[0][0])
	Lineup.apply(cfg, 1, sides[1][0])
	var aims: Array = [_angle(angles[0]), _angle(angles[1])]
	if sides[0].size() > 1:
		Lineup.apply(cfg, 2, sides[0][1])
		Lineup.apply(cfg, 3, sides[1][1])
		aims.append_array([null, null])
	cfg.angles = aims
	return cfg


static func _angle(a) -> Variant:
	return null if a == null else clampi(int(a), -1800, 1799)
