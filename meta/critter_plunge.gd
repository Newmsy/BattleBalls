## Critter Plunge (sim/plunge.gd) as a Versus mode: you race your fighter
## against a field of CPU critters at your fighter's power, so the drop and the
## race verbs decide it, not who levelled more. Watch only: nothing to aim.
## Pays coins by place, critter XP, account XP and Faction XP after every race.
##
## Same flow as the bosses (meta/pinata_party.gd): start() spends the energy
## and returns the race, finish() pays out the finished race.
extends RefCounted

const Plunge := preload("res://sim/plunge.gd")
const Campaign := preload("res://meta/campaign.gd")

const ENERGY_COST := 4
const FIELD_SIZES := Plunge.FIELD_SIZES
const DEFAULT_FIELD := 6
const WIN_COINS := 100 ## 1st pays this...
const LAST_COINS := 10 ## ...last (or knocked out) this, sliding in between.
const XP := 6

## The race the Plunge screen started, for the race scene (game/plunge.gd):
## {cfg (Plunge config, your fighter first), fighter}.
static var pending := {}
## Set by the race scene so the home screen reopens on the Plunge screen.
static var reopen := false


## Coins for `place` (1 = winner) out of `n` racers.
static func coins_for(place: int, n: int) -> int:
	if n <= 1:
		return WIN_COINS
	var f := 1.0 - float(clampi(place, 1, n) - 1) / float(n - 1)
	return LAST_COINS + roundi((WIN_COINS - LAST_COINS) * f * f)


## The race config for `fighter` in a field of `n`: {seed, racers, powers}.
## Your fighter is racer 0; the rest are drawn by the seed, all at its power.
static func race_for(profile, fighter: String, n: int, seed_value: int) -> Dictionary:
	var ids := [fighter] + Plunge.draw_field(seed_value, n - 1, [fighter])
	var power: float = profile.fight_power(fighter) if profile != null else 1.0
	var powers := []
	for id in ids:
		powers.append(power)
	return {"seed": seed_value, "racers": ids, "powers": powers}


static func start(profile, fighter: String, n: int, now: int) -> Dictionary:
	if not Campaign.can_fight(profile, fighter):
		return {"error": "no_ball"}
	if not FIELD_SIZES.has(n):
		return {"error": "field"}
	if not profile.spend_energy(ENERGY_COST, now):
		return {"error": "energy"}
	var cfg := race_for(profile, fighter, n, _seed(profile.runs, now))
	profile.runs += 1
	profile.changed.emit()
	return cfg


## Pays out a finished race for your racer 0 that came `place` of `n`
## (`knocked_out` if it didn't make it down). Returns {place, n, coins, xp,
## knocked_out, levels, account_levels, critters}.
static func finish(profile, fighter: String, place: int, n: int, knocked_out: bool) -> Dictionary:
	var result := {"place": place, "n": n, "coins": coins_for(place, n), "xp": XP, "knocked_out": knocked_out,
		"levels": 0, "account_levels": 0, "critters": []}
	profile.grant({"kind": "coins", "n": result.coins})
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	# Faction XP as a fight pays it: a win for 1st, a draw for the top half.
	profile.fight_faction_xp([fighter], 0 if place == 1 else (-1 if place <= n / 2.0 else 1))
	profile.changed.emit()
	return result


static func _seed(runs: int, now: int) -> int:
	return (runs * 7727 + now * 31 + 101) & 0x7FFFFFFF
