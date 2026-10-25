## Summon Portal rolls (design/ui.md section 4). Every summon is a Tier 1
## critter. Odds match campaign drops; a x10 always holds a Rare or better;
## the Legendary pity counter (Rare+ rolls until a Legendary) is shared with
## drops. Pools come from the critter files, so new critters join on their own;
## a rarity with no critters yet rolls the next rarity down. UI-side randomness only,
## never used by the fight sim.
##
## Wishlist: the player's (up to 3) wishlisted critters count double when the
## game picks which critter of a rarity you get. The rarity roll, the x10
## guarantee and pity never change. Campaign and hunt drops must roll through
## `roll()` (or `pick_in_rarity()` for a drop with a fixed rarity) so the
## wishlist and pity apply there too.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")

const ODDS := [["legendary", 1.5], ["epic", 5.5], ["rare", 15.0], ["uncommon", 28.0], ["common", 50.0]]
const PITY_RESET := 50
## How much more often a wishlisted critter comes up than others of its rarity.
const WISHLIST_WEIGHT := 2.0

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


## Which critter of `rarity` you get: every critter of the rarity is equally
## likely, with wishlisted critters counting double.
static func pick_in_rarity(profile, rarity: String, rng: RandomNumberGenerator) -> String:
	var pool: Array = []
	for k in range(_rank(rarity), -1, -1):
		pool = Roster.CRITTERS.filter(func(c): return c.rarity == Roster.RARITIES[k])
		if not pool.is_empty():
			break
	var total := 0.0
	for c in pool:
		total += _weight(profile, c.id)
	var r := rng.randf() * total
	for c in pool:
		r -= _weight(profile, c.id)
		if r < 0.0:
			return c.id
	return pool[-1].id


## One drop roll inside a set of critters (a Rift's family): the summon odds
## and the shared pity pick the rarity (Rare or better with `rare_plus`), then
## a critter of that rarity from `ids`, wishlisted ones counting double. A
## rarity `ids` doesn't have falls to the nearest one down, then up.
static func roll_in(profile, rng: RandomNumberGenerator, ids: Array, rare_plus := false) -> String:
	var rarity := _roll_rarity(profile, rng, rare_plus)
	var pool: Array = []
	var order: Array = range(_rank(rarity), -1, -1) + range(_rank(rarity) + 1, Roster.RARITIES.size())
	for k in order:
		pool = ids.filter(func(id): return rarity_of(id) == Roster.RARITIES[k])
		if not pool.is_empty():
			break
	if pool.is_empty():
		return ""
	var total := 0.0
	for id in pool:
		total += _weight(profile, id)
	var r := rng.randf() * total
	for id in pool:
		r -= _weight(profile, id)
		if r < 0.0:
			return id
	return pool[-1]


## The chance (0-1) that a roll of `id`'s rarity gives `id`.
static func share_in_rarity(profile, id: String) -> float:
	var rarity := rarity_of(id)
	var total := 0.0
	for c in Roster.CRITTERS:
		if c.rarity == rarity:
			total += _weight(profile, c.id)
	return _weight(profile, id) / total


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
		if _rank(rarity_of(id)) >= _rank("rare"):
			return true
	return false


static func _roll(profile, rng: RandomNumberGenerator, rare_plus: bool) -> String:
	return pick_in_rarity(profile, _roll_rarity(profile, rng, rare_plus), rng)


## The rarity of one roll, with the odds, the Rare+ guarantee and the shared pity.
static func _roll_rarity(profile, rng: RandomNumberGenerator, rare_plus: bool) -> String:
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
	return rarity


static func _rank(rarity: String) -> int:
	return Roster.RARITIES.find(rarity)
