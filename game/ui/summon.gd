## Summon Portal rolls (design/ui.md section 4). Every summon is a Tier 1
## critter. Odds match campaign drops; a x10 always holds a Rare or better;
## the Legendary pity counter (Rare+ rolls until a Legendary) is shared with
## drops. Pools come from the critter files, so new critters join on their own;
## a rarity with no critters yet rolls the next rarity down. UI-side randomness only,
## never used by the fight sim.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")
const LiveOps := preload("res://game/liveops.gd")

const ODDS := [["legendary", 1.5], ["epic", 5.5], ["rare", 15.0], ["uncommon", 28.0], ["common", 50.0]]
const PITY_RESET := 50
## This week's featured critter (the Critter Spotlight in liveops.json)
## takes half of the rolls of its rarity.
static func featured() -> String:
	return LiveOps.spotlight(LiveOps.now()).critter


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
		if _rank(rarity_of(id)) >= _rank("rare"):
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
	if rare_plus and _rank(rarity) < _rank("rare"):
		rarity = "rare"
	if _rank(rarity) >= _rank("rare"):
		profile.legendary_pity -= 1
		if profile.legendary_pity <= 0:
			rarity = "legendary"
	if rarity == "legendary":
		profile.legendary_pity = PITY_RESET
	var spotlight := featured()
	if rarity == rarity_of(spotlight) and rng.randf() < .5:
		return spotlight
	for k in range(_rank(rarity), -1, -1):
		var pool: Array = Roster.CRITTERS.filter(func(c): return c.rarity == Roster.RARITIES[k])
		if not pool.is_empty():
			return pool[rng.randi_range(0, pool.size() - 1)].id
	return Roster.CRITTERS[0].id


static func _rank(rarity: String) -> int:
	return Roster.RARITIES.find(rarity)
