## A fighter's known setup, as a lineup slot: the critter, its tier and level,
## and the gear it wears. Every progression mode (campaign, Ghost Arena, the
## Spire) fights owned critters through this, and the same slot shape is the
## Ghost Arena lineup (game/online/ghost_lineup.gd), so a fight replays from
## the slots, the seed and the launch angles alone.
##
## Slot: {critter, tier, level, gear: [{slot, tier, stats: {line: value}}],
##        talents: {node: rank}} (talents optional: the faction tree, sim/talents.gd).
## Reading a slot clamps everything to the game's rules (tier 1-5, level up to
## the tier's cap, one piece per gear slot, a Charm only from 3 stars, no line
## above a 5-star piece's), so a tampered lineup can't field a T9 or stack ten
## 5-star cores.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")
const Power := preload("res://sim/power.gd")
const Gear := preload("res://sim/gear.gd")
const Talents := preload("res://sim/talents.gd")

const MAX_TIER := 5
const GEAR_SLOTS := Gear.SLOTS


## Highest level a critter can reach at `tier` (game/ui/roster.gd agrees).
static func level_cap(tier: int) -> int:
	return tier * 10


static func make(critter: String, tier := 1, level := 1, gear: Array = [], talents := {}) -> Dictionary:
	return clean({"critter": critter, "tier": tier, "level": level, "gear": gear, "talents": talents})


## A slot with every value inside the rules.
static func clean(slot: Dictionary) -> Dictionary:
	var tier := clampi(int(slot.get("tier", 1)), 1, MAX_TIER)
	var pieces: Array = []
	var taken := {}
	var gear = slot.get("gear", [])
	if gear is Array:
		for piece in gear:
			if not piece is Dictionary or not piece.get("stats") is Dictionary:
				continue
			var gs := str(piece.get("slot", ""))
			if not gs in GEAR_SLOTS or taken.has(gs) or (gs == "Charm" and tier < Gear.CHARM_TIER):
				continue
			taken[gs] = true
			var stats := {}
			for line in piece.stats:
				if Gear.LINES.has(line):
					stats[line] = clampf(float(piece.stats[line]), 0.0, float(Gear.LINES[line].t5))
			pieces.append({"slot": gs, "tier": Gear.tier_of(piece.get("tier", piece.get("rarity", 1))), "stats": stats})
	var critter := str(slot.get("critter", ""))
	var out := {"critter": critter, "tier": tier,
		"level": clampi(int(slot.get("level", 1)), 1, level_cap(tier)), "gear": pieces}
	var talents := Talents.clean(Talents.faction_of(critter), slot.get("talents", {}), tier)
	if not talents.is_empty():
		out.talents = talents
	return out


## The slot's progression multiplier (sim/power.gd): rarity, tier and level.
## Gear isn't in it; it fights as its own stat lines (rating() adds it).
static func power(slot: Dictionary) -> float:
	var s := clean(slot)
	var rarity := "common"
	if CritterDb.has(s.critter):
		rarity = CritterDb.get_critter(s.critter).rarity
	return Power.multiplier(rarity, s.tier, s.level)


## The Power Rating players see for a slot: power() plus its gear's worth
## (sim/gear.gd stats_power), on the 1000-for-a-base-ball scale.
static func rating(slot: Dictionary) -> int:
	var s := clean(slot)
	return Power.rating(power(s) * (1.0 + Gear.gear_power(s.gear)) * (1.0 + talent_power(s)))


## What a slot's active talents add to its Power Rating, as a fraction.
static func talent_power(slot: Dictionary) -> float:
	return Talents.power(Talents.faction_of(str(slot.get("critter", ""))), slot.get("talents", {}))


## Faction Bond (relays): a critter with its faction's capstone gets
## +BOND_POWER per other same-faction critter in the team, up to BOND_MAX.
static func bond(slots: Array, i: int) -> float:
	var s: Dictionary = slots[i]
	var faction := Talents.faction_of(s.critter)
	var cap: Array = Talents.tree(faction).filter(func(n): return n.row == 5)
	if cap.is_empty() or not s.get("talents", {}).has(cap[0].id):
		return 1.0
	var n := 0
	for j in slots.size():
		if j != i and Talents.faction_of(slots[j].critter) == faction:
			n += 1
	return 1.0 + Talents.BOND_POWER * mini(n, Talents.BOND_MAX)


## One side of a relay (sim/relay.gd) or the per-ball MatchSim keys, from its
## slots: {sides, tiers, powers, gear, talents}.
static func side(slots: Array) -> Dictionary:
	var out := {"sides": [], "tiers": [], "powers": [], "gear": [], "talents": []}
	var cleaned: Array = slots.map(func(raw): return clean(raw))
	for i in cleaned.size():
		var s: Dictionary = cleaned[i]
		out.sides.append(s.critter)
		out.tiers.append(s.tier)
		out.powers.append(power(s) * bond(cleaned, i))
		out.gear.append(s.gear)
		out.talents.append(s.get("talents", {}))
	return out


## Adds one fighter's setup to a MatchSim config as player `i` (0 or 1).
static func apply(cfg: Dictionary, i: int, slot: Dictionary) -> Dictionary:
	var s := clean(slot)
	for key in ["tiers", "powers", "gear", "talents"]:
		if not cfg.has(key):
			cfg[key] = [1, 1] if key == "tiers" else ([1.0, 1.0] if key == "powers" else [null, null])
	cfg["p%d" % (i + 1)] = s.critter
	cfg.tiers[i] = s.tier
	cfg.powers[i] = power(s)
	cfg.gear[i] = s.gear
	cfg.talents[i] = s.get("talents", {})
	return cfg
