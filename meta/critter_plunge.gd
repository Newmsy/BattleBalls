## Critter Plunge (sim/plunge.gd) as a Versus mode: you race one of your
## racing critters (Plunge.RACERS) against a field of CPU critters at its
## tier, so its abilities show at their tier but the drop decides it, not who
## levelled more. Watch only: nothing to aim.
## Pays coins by place, critter XP, account XP and Faction XP after every race.
##
## Same flow as the bosses (meta/pinata_party.gd): start() spends the energy
## and returns the race, finish() pays out the finished race.
extends RefCounted

const Plunge := preload("res://sim/plunge.gd")
const Campaign := preload("res://meta/campaign.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")

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
## The racer picked last on the Plunge screen, kept while the game runs.
static var racer := ""


## Who races for you: the racer picked last, else your lineup's fighter if it
## races, else your strongest racing critter; "" when you own none.
static func racer_for(profile) -> String:
	if racer != "" and profile.owns(racer) and Plunge.can_race(racer):
		return racer
	if Plunge.can_race(profile.lineup) and Campaign.can_fight(profile, profile.lineup):
		return profile.lineup
	var best := ""
	var best_power := -1
	for id in Plunge.RACERS:
		if profile.owns(id) and profile.power_of(id) > best_power:
			best = id
			best_power = profile.power_of(id)
	return best


## Coins for `place` (1 = winner) out of `n` racers.
static func coins_for(place: int, n: int) -> int:
	if n <= 1:
		return WIN_COINS
	var f := 1.0 - float(clampi(place, 1, n) - 1) / float(n - 1)
	return LAST_COINS + roundi((WIN_COINS - LAST_COINS) * f * f)


## The race config for `fighter` in a field of `n`: {seed, racers, tiers,
## boosts}. Your fighter is racer 0 with your race talents for its family; the
## rest are drawn by the seed, all at its tier.
static func race_for(profile, fighter: String, n: int, seed_value: int) -> Dictionary:
	var ids := [fighter] + Plunge.draw_field(seed_value, n - 1, [fighter])
	var tier: int = int(profile.best(fighter).get("tier", 1)) if profile != null else 1
	var boosts := [PlungeTalents.effects(profile, fighter) if profile != null else null]
	return {"seed": seed_value, "racers": ids, "tiers": ids.map(func(_id): return tier), "boosts": boosts}


static func start(profile, fighter: String, n: int, now: int) -> Dictionary:
	if not Campaign.can_fight(profile, fighter) or not Plunge.can_race(fighter):
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
## medal ("" for none), knocked_out, levels, account_levels, critters}.
static func finish(profile, fighter: String, place: int, n: int, knocked_out: bool, watched := true, _course := "") -> Dictionary:
	var result := {"place": place, "n": n, "coins": coins_for(place, n), "xp": XP, "knocked_out": knocked_out,
		"medal": "" if knocked_out else PlungeTalents.medal_for(place, n), "levels": 0, "account_levels": 0, "critters": []}
	if not watched:
		result.medal = ""
	profile.grant({"kind": "coins", "n": result.coins})
	PlungeTalents.add_medal(profile, result.medal)
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	# Faction XP as a fight pays it: a win for 1st, a draw for the top half.
	profile.fight_faction_xp([fighter], 0 if place == 1 else (-1 if place <= n / 2.0 else 1))
	profile.changed.emit()
	return result


static func _seed(runs: int, now: int) -> int:
	return (runs * 7727 + now * 31 + 101) & 0x7FFFFFFF
