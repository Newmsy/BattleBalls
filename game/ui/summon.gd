## Summon Portal rolls (design/ui.md section 4). Every summon is a Tier 1
## critter. Odds match campaign drops; a x10 always holds a Rare or better;
## the Legendary pity counter is shared with drops. UI-side randomness only,
## never used by the fight sim.
##
## Wishlist: the player's (up to 3) wishlisted critters count double when the
## game picks which critter of a rarity you get. The rarity roll, the x10
## guarantee and pity never change. Campaign and hunt drops must roll through
## `roll()` (or `pick_in_rarity()` for a drop with a fixed rarity) so the
## wishlist and pity apply there too.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")
const LiveOps := preload("res://game/liveops.gd")

const ODDS := [["legendary", 0.5], ["epic", 4.5], ["rare", 25.0], ["common", 70.0]]
const PITY_RESET := 150
## How much more often a wishlisted critter comes up than others of its rarity.
const WISHLIST_WEIGHT := 2.0
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


## One drop roll with the summon odds and the shared pity, e.g. a campaign or
## hunt drop. Returns a critter id.
static func roll(profile, rng: RandomNumberGenerator) -> String:
	return _roll(profile, rng, false)


## Which critter of `rarity` you get: the Spotlight takes half the rolls of
## its rarity, the rest are weighted with wishlisted critters counting double.
static func pick_in_rarity(profile, rarity: String, rng: RandomNumberGenerator) -> String:
	var spotlight := featured()
	if rarity == rarity_of(spotlight) and rng.randf() < .5:
		return spotlight
	var pool: Array = Roster.CRITTERS.filter(func(c): return c.rarity == rarity)
	var total := 0.0
	for c in pool:
		total += _weight(profile, c.id)
	var r := rng.randf() * total
	for c in pool:
		r -= _weight(profile, c.id)
		if r < 0.0:
			return c.id
	return pool[-1].id


## The chance (0-1) that a roll of `id`'s rarity gives `id`.
static func share_in_rarity(profile, id: String) -> float:
	var rarity := rarity_of(id)
	var spotlight := featured()
	var held := .5 if rarity_of(spotlight) == rarity else 0.0
	var total := 0.0
	for c in Roster.CRITTERS:
		if c.rarity == rarity:
			total += _weight(profile, c.id)
	return (held if id == spotlight else 0.0) + (1.0 - held) * _weight(profile, id) / total


## The chance in percent that one summon (or drop) gives `id`, before the x10
## guarantee and pity. This is what the summon screen shows.
static func chance(profile, id: String) -> float:
	for o in ODDS:
		if o[0] == rarity_of(id):
			return o[1] * share_in_rarity(profile, id)
	return 0.0


static func _weight(profile, id: String) -> float:
	return WISHLIST_WEIGHT if profile.on_wishlist(id) else 1.0


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
	return pick_in_rarity(profile, rarity, rng)
