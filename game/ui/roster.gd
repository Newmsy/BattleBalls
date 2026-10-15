## UI catalogue of every critter: names, rarity, colours and the per-tier
## ability text shown on the detail and fuse screens. Built from the critter
## files in sim/critters/ (sim/critter_db.gd), so a new file shows up here too.
## Planned critters appear in the collection before their ability is built.
extends RefCounted

const CritterDb := preload("res://sim/critter_db.gd")

const RARITIES := CritterDb.RARITIES
const RARITY_NAMES := {"common": "Common", "uncommon": "Uncommon", "rare": "Rare", "epic": "Epic", "legendary": "Legendary"}
const RARITY_COLORS := {"common": Color("c9d3e0"), "uncommon": Color("4cd98a"), "rare": Color("3d9bff"), "epic": Color("b366ff"), "legendary": Color("ffc23d")}
## One rarity step is worth half a tier (BALANCE.md rule 5): x sqrt(1.25) each,
## so a Legendary starts two tiers above a Common.
const RARITY_STEP := 1.118034
const MAX_TIER := 5

static var CRITTERS: Array = _critters()


static func _critters() -> Array:
	var out: Array = []
	for id in CritterDb.ids():
		var c := CritterDb.get_critter(id)
		if c.status == "baseline":
			continue
		out.append({"id": id, "name": c.name, "type": c.type, "rarity": c.rarity, "role": c.role, "color": Color(c.color),
			"vibe": c.vibe, "ladder": c.tiers.map(func(t): return t.text), "live": c.status == "live"})
	return out


static func rarity_base(rarity: String) -> float:
	return 100.0 * pow(RARITY_STEP, RARITIES.find(rarity))


static func ids() -> Array:
	return CRITTERS.map(func(c): return c.id)


static func get_critter(id: String) -> Dictionary:
	for c in CRITTERS:
		if c.id == id:
			return c
	assert(false, "Unknown critter: %s" % id)
	return {}


static func level_cap(tier: int) -> int:
	return tier * 10


## Power Rating: rarity base (+half a tier per step), +25% per tier, +2.5% per level, +4% per gear piece.
static func power(id: String, tier: int, level: int, gear_count := 0) -> int:
	var p: float = rarity_base(get_critter(id).rarity) * pow(1.25, tier - 1) * (1.0 + 0.025 * (level - 1))
	p *= 1.0 + 0.04 * gear_count
	return roundi(p * 10.0)
