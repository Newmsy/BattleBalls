## Summon Portal rolls (design/ui.md section 4). Every summon is a Tier 1
## critter. Odds match campaign drops; a x10 always holds a Rare or better;
## the Legendary pity counter is shared with drops. UI-side randomness only,
## never used by the fight sim.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")

const ODDS := [["legendary", 0.5], ["epic", 4.5], ["rare", 25.0], ["common", 70.0]]
const PITY_RESET := 150
## This week's featured critter takes half of the rolls of its rarity.
const FEATURED := "magnet" ## Season 1 debut critter.


## Rolls `count` critters and updates profile.legendary_pity. Returns ids.
static func pull(profile, count: int, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for i in count:
		out.append(_roll(profile, rng, count == 10 and i == count - 1 and not _has_rare_plus(out)))
	return out


static func rarity_of(id: String) -> String:
	return Roster.get_critter(id).rarity


static func _has_rare_plus(ids: Array) -> bool:
	for id in ids:
		if rarity_of(id) != "common":
			return true
	return false


static func _roll(profile, rng: RandomNumberGenerator, rare_plus: bool) -> String:
	var r := rng.randf() * 100.0
	var rarity := "common"
	var acc := 0.0
	for o in ODDS:
		acc += o[1]
		if r < acc:
			rarity = o[0]
			break
	if rare_plus and rarity == "common":
		rarity = "rare"
	if rarity != "common":
		profile.legendary_pity -= 1
		if profile.legendary_pity <= 0:
			rarity = "legendary"
	if rarity == "legendary":
		profile.legendary_pity = PITY_RESET
	if rarity == rarity_of(FEATURED) and rng.randf() < .5:
		return FEATURED
	var pool: Array = Roster.CRITTERS.filter(func(c): return c.rarity == rarity)
	return pool[rng.randi_range(0, pool.size() - 1)].id
