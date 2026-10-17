## The Brood Queen (design/bosses.md): a daily boss fight on The Nest that
## pays Summon Eggs. A win pays the difficulty's eggs, plus a bonus for the
## eggs you cracked before they hatched. Opens when the Zone 2 boss is
## beaten. 3 runs a day, 8 energy a run.
##
## Same flow as the Anvil King (meta/gear_vault.gd): start() before the
## fight, finish() with the result. The boss lives in sim/bosses.gd.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Bosses := preload("res://sim/bosses.gd")

const BOSS := "brood_queen"
const ENERGY_COST := 8
const RUNS_PER_DAY := 3
const DAY_SECONDS := 86400
const ZONE := 1 ## Beating this zone's boss (0-based) opens it.
## Difficulty: the orbs a win pays and the boss's power. Check win rates with
## tools/boss_difficulty.gd --boss=brood_queen.
const DIFFICULTIES := [
	{"name": "Easy", "orbs": 1, "power": 1.6},
	{"name": "Hard", "orbs": 2, "power": 2.3},
	{"name": "Elite", "orbs": 3, "power": 3.2},
]
const EGGS_PER_BONUS := 3 ## Every this many eggs cracked adds an orb...
const BONUS_MAX := 2 ## ...up to this many.
const WIN_XP := 20
const LOSS_XP := 3


static func day_number(now: int) -> int:
	return int(now / DAY_SECONDS)


static func is_unlocked(profile) -> bool:
	return ZONE < Zones.ZONES.size() and Campaign.is_cleared(profile, ZONE, Zones.zone(ZONE).stages.size() - 1)


static func runs_left(profile, now: int) -> int:
	if int(profile.nest.get("day", -1)) != day_number(now):
		return RUNS_PER_DAY
	return maxi(0, RUNS_PER_DAY - int(profile.nest.get("runs", 0)))


static func enemy_rating(difficulty: int, _now := 0) -> int:
	return Power.rating(DIFFICULTIES[difficulty].power)


## Bonus orbs for `cracked` eggs.
static func egg_bonus(cracked: int) -> int:
	return mini(BONUS_MAX, cracked / EGGS_PER_BONUS)


## Spends energy and a run and returns the fight config, with the player's
## aim left as null. Returns {error: "..."} when locked, out of runs or energy.
static func start(profile, difficulty: int, fighter: String, now: int) -> Dictionary:
	if not is_unlocked(profile):
		return {"error": "locked"}
	if not Campaign.can_fight(profile, fighter):
		return {"error": "no_ball"}
	if runs_left(profile, now) <= 0:
		return {"error": "runs"}
	if not profile.spend_energy(ENERGY_COST, now):
		return {"error": "energy"}
	_use_run(profile, now, 1)
	var d: Dictionary = DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]
	var cfg := {
		"seed": _seed(profile.runs, day_number(now), difficulty),
		"p2": BOSS,
		"arena": Bosses.DEFS[BOSS].arena,
		"angles": [null, null],
		"tiers": [1, 1],
		"powers": [1.0, d.power],
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


static func cancel(profile, now: int) -> void:
	profile.refund_energy(ENERGY_COST)
	_use_run(profile, now, -1)


## Applies a finished fight (`fight` as for Campaign.finish, plus `cracked`:
## eggs broken before they hatched). Returns {won, orbs, cracked, bonus, gear,
## xp, levels, refund, account_levels}.
static func finish(profile, difficulty: int, fighter: String, fight: Dictionary, now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var cracked := int(fight.get("cracked", 0))
	var result := {"won": won, "orbs": 0, "cracked": cracked, "bonus": 0, "gear": [], "xp": LOSS_XP, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = ENERGY_COST - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		Campaign.give_xp(profile, result, fighter)
		return result
	var d: Dictionary = DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]
	result.bonus = egg_bonus(cracked)
	result.orbs = d.orbs + result.bonus
	profile.grant({"kind": "orbs", "n": result.orbs})
	result.xp = WIN_XP
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _use_run(profile, now: int, n: int) -> void:
	var day := day_number(now)
	if int(profile.nest.get("day", -1)) != day:
		profile.nest = {"day": day, "runs": 0}
	profile.nest.runs = clampi(int(profile.nest.runs) + n, 0, RUNS_PER_DAY)
	profile.changed.emit()


static func _seed(runs: int, day: int, difficulty: int) -> int:
	return (runs * 7177 + day * 433 + difficulty * 31 + 11) & 0x7FFFFFFF
