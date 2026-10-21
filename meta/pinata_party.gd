## The Piñata Titan (design/bosses.md): a daily 30-second smash on Fiesta
## Plaza that pays coins for the damage you do. It never hits back, so every
## run pays; break it before the clock for the jackpot. The piñata is as
## strong as your fighter, so a better critter (or a better aim) is what earns
## more, not just a higher level. Opens after Zone 1 stage 5. 3 runs a day.
##
## Same flow as the other bosses (meta/gear_vault.gd): start() before the
## fight, finish() with the result. The piñata lives in sim/bosses.gd.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Bosses := preload("res://sim/bosses.gd")
const BossRuns := preload("res://meta/boss_runs.gd")

const BOSS := "pinata_titan"
const KEY := "pinata"
const ENERGY_COST := 5
const RUNS_PER_DAY := 3
const UNLOCK_STAGE := 4 ## Zone 1 stage 5 (0-based) cleared opens it.
## One way to play it; the piñata matches your fighter's power.
const DIFFICULTIES := [{"name": "Smash", "power": 1.0}]
const BASE_COINS := 40 ## Every run pays this...
const DAMAGE_COINS := 260 ## ...plus this share of the piñata's HP knocked off...
const JACKPOT := 150 ## ...and this if it breaks.
const XP := 8


static func day_number(now: int) -> int:
	return BossRuns.day_number(now)


static func is_unlocked(profile) -> bool:
	return Campaign.is_cleared(profile, 0, UNLOCK_STAGE)


static func runs_left(profile, now: int) -> int:
	return BossRuns.runs_left(profile, KEY, RUNS_PER_DAY, now)


## The piñata's power for `fighter`: your Power Rating, gear and all.
static func boss_power(profile, fighter: String) -> float:
	return maxf(1.0, profile.power_of(fighter) / 1000.0)


static func enemy_rating(_difficulty: int, _now := 0) -> int:
	return Power.rating(1.0)


## Coins for knocking `frac` (0-1) of its HP off, broken or not.
static func coins_for(frac: float, broken: bool) -> int:
	return BASE_COINS + roundi(DAMAGE_COINS * clampf(frac, 0.0, 1.0)) + (JACKPOT if broken else 0)


static func start(profile, _difficulty: int, fighter: String, now: int) -> Dictionary:
	if not is_unlocked(profile):
		return {"error": "locked"}
	if not Campaign.can_fight(profile, fighter):
		return {"error": "no_ball"}
	if runs_left(profile, now) <= 0:
		return {"error": "runs"}
	if not profile.spend_energy(ENERGY_COST, now):
		return {"error": "energy"}
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, 1)
	var cfg := {
		"seed": _seed(profile.runs, day_number(now)),
		"p2": BOSS,
		"arena": Bosses.DEFS[BOSS].arena,
		"angles": [null, null],
		"tiers": [1, 1],
		"powers": [1.0, boss_power(profile, fighter)],
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


static func cancel(profile, now: int) -> void:
	profile.refund_energy(ENERGY_COST)
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, -1)


## Applies a finished smash (`fight` as for Campaign.finish, plus
## `boss_dealt` and `boss_max`: the piñata's HP knocked off and its full HP).
## Returns {won (true: every run pays), broken, frac, coins, xp, levels,
## account_levels}.
static func finish(profile, _difficulty: int, fighter: String, fight: Dictionary, _now: int) -> Dictionary:
	var broken: bool = fight.winner == 0
	var frac := 1.0 if broken else float(fight.get("boss_dealt", 0.0)) / maxf(1.0, float(fight.get("boss_max", 1.0)))
	var result := {"won": true, "broken": broken, "frac": frac, "coins": coins_for(frac, broken), "gear": [], "xp": XP, "levels": 0, "account_levels": 0, "critters": []}
	profile.grant({"kind": "coins", "n": result.coins})
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _seed(runs: int, day: int) -> int:
	return (runs * 6131 + day * 389 + 17) & 0x7FFFFFFF
