## Turns progression (rarity, tier, level) into one power multiplier, and
## applies a multiplier to a ball's stats. 1.0 is a T1, level 1 Common.
## Matches the Power Rating players see (game/ui/roster.gd: rarity base, +25%
## per tier, +2.5% per level, plus each gear piece's worth from sim/gear.gd),
## so a number on screen is the strength that fights.
extends RefCounted
const DMath := preload("res://sim/dmath.gd")

const TIER_STEP := 1.25
const LEVEL_STEP := 0.025 ## Per level above 1, so level 11 is +25%.
## One rarity step is worth half a tier (BALANCE.md rule 5), as in
## Roster.rarity_base: a T1 Legendary fights like a T3 Common.
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITY_STEP := 1.118034 ## sqrt(TIER_STEP)


static func multiplier(rarity: String, tier: int, level: int) -> float:
	return DMath.ipow(RARITY_STEP, maxi(0, RARITIES.find(rarity))) * DMath.ipow(TIER_STEP, tier - 1) * (1.0 + LEVEL_STEP * (level - 1))


## Rarity's half tier per step also counts for the ability: MatchSim builds a
## ball's ability at its tier plus this many tiers of potency (no tier
## upgrades), so a T1 Legendary's ability hits like a T3 one, as its stats do.
## Without it a tier (stats and ability) outweighed two rarity steps (stats
## only): T3 Commons beat T1 Legendaries 67% (tools/rarity_check.gd).
static func rarity_tiers(rarity: String) -> float:
	return 0.5 * maxi(0, RARITIES.find(rarity))


## Power Rating on the same scale as Roster.power: 1000 for a base ball.
static func rating(power: float) -> int:
	return roundi(1000.0 * power)


## HP and every damage stat (contact, *_damage and per-second *_dps) scale by
## sqrt(power), so HP x damage scales by `power`. Returns the def unchanged
## at 1.0, so unpowered fights are untouched.
static func scale_def(def: Dictionary, power: float) -> Dictionary:
	if power == 1.0:
		return def
	var k := sqrt(power)
	var scaled := def.duplicate()
	scaled.hp = def.hp * k
	scaled.contact_damage = def.contact_damage * k
	for key in scaled:
		if (String(key).ends_with("_damage") and key != "contact_damage") or String(key).ends_with("_dps"):
			scaled[key] = def[key] * k
	return scaled
