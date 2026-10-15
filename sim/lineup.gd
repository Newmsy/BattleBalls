## A fighter's known setup, as a lineup slot: the critter, its tier and level,
## and the gear it wears. Every progression mode (campaign, Ghost Arena, the
## Spire) fights owned critters through this, and the same slot shape is the
## Ghost Arena lineup (game/online/ghost_lineup.gd), so a fight replays from
## the slots, the seed and the launch angles alone.
##
## Slot: {critter, tier, level, gear: [{slot, rarity, stats: {line: value}}]}.
## Reading a slot clamps everything to the game's rules (tier 1-5, level up to
## the tier's cap, one piece per gear slot, gear lines capped in sim/gear.gd),
## so a tampered lineup can't field a T9 or stack ten Legendary cores.
## Optional `boost`: {line: value} from Arena Boosts (sim/arena_boosts.gd),
## clamped to a fully boosted family and fought as one more gear piece.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")
const Power := preload("res://sim/power.gd")
const Gear := preload("res://sim/gear.gd")
const ArenaBoosts := preload("res://sim/arena_boosts.gd")

const MAX_TIER := 5
const GEAR_SLOTS := ["Shell", "Core"]


## Highest level a critter can reach at `tier` (game/ui/roster.gd agrees).
static func level_cap(tier: int) -> int:
	return tier * 10


static func make(critter: String, tier := 1, level := 1, gear: Array = []) -> Dictionary:
	return clean({"critter": critter, "tier": tier, "level": level, "gear": gear})


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
			if not gs in GEAR_SLOTS or taken.has(gs):
				continue
			taken[gs] = true
			var stats := {}
			for line in piece.stats:
				if Gear.LINES.has(line):
					stats[line] = clampf(float(piece.stats[line]), 0.0, float(Gear.LINES[line].legendary))
			pieces.append({"slot": gs, "rarity": str(piece.get("rarity", "common")), "stats": stats})
	var out := {"critter": str(slot.get("critter", "")), "tier": tier,
		"level": clampi(int(slot.get("level", 1)), 1, level_cap(tier)), "gear": pieces}
	var boost := ArenaBoosts.clean(slot.get("boost"))
	if not boost.is_empty():
		out.boost = boost
	return out


## The pieces a slot fights with: its gear plus its Arena Boost, if any.
static func kit(s: Dictionary) -> Array:
	if not s.has("boost"):
		return s.gear
	return s.gear + [{"slot": "Boost", "stats": s.boost}]


## The slot's progression multiplier (sim/power.gd): rarity, tier and level.
## Gear isn't in it; it fights as its own stat lines.
static func power(slot: Dictionary) -> float:
	var s := clean(slot)
	var rarity := "common"
	if CritterDb.has(s.critter):
		rarity = CritterDb.get_critter(s.critter).rarity
	return Power.multiplier(rarity, s.tier, s.level)


## One side of a relay (sim/relay.gd) or the per-ball MatchSim keys, from its
## slots: {sides, tiers, powers, gear}.
static func side(slots: Array) -> Dictionary:
	var out := {"sides": [], "tiers": [], "powers": [], "gear": []}
	for raw in slots:
		var s := clean(raw)
		out.sides.append(s.critter)
		out.tiers.append(s.tier)
		out.powers.append(power(s))
		out.gear.append(kit(s))
	return out


## Adds one fighter's setup to a MatchSim config as player `i` (0 or 1).
static func apply(cfg: Dictionary, i: int, slot: Dictionary) -> Dictionary:
	var s := clean(slot)
	for key in ["tiers", "powers", "gear"]:
		if not cfg.has(key):
			cfg[key] = [1, 1] if key == "tiers" else ([1.0, 1.0] if key == "powers" else [null, null])
	cfg["p%d" % (i + 1)] = s.critter
	cfg.tiers[i] = s.tier
	cfg.powers[i] = power(s)
	cfg.gear[i] = kit(s)
	return cfg
