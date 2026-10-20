## The Prism Wyrm (design/bosses.md): a daily boss in the Crystal Rift that
## pays Lures. Lures buy a guaranteed copy of a critter on your wishlist
## (Profile.use_lure; rarer critters cost more), so it's the targeted way to
## chase the one you want. Opens when the Zone 4 boss is beaten. 2 runs a
## day, 10 energy a run.
##
## Same flow as the other bosses (meta/gear_vault.gd): start() before the
## fight, finish() with the result. The wyrm lives in sim/bosses.gd.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Bosses := preload("res://sim/bosses.gd")
const BossRuns := preload("res://meta/boss_runs.gd")

const BOSS := "prism_wyrm"
const KEY := "wyrm"
const ENERGY_COST := 10
const RUNS_PER_DAY := 2
const ZONE := 3 ## Beating this zone's boss (0-based) opens it.
## Difficulty: the Lures a win pays and the wyrm's power. Check win rates
## with tools/boss_difficulty.gd --boss=prism_wyrm.
const DIFFICULTIES := [
	{"name": "Easy", "lures": 1, "power": 4.0},
	{"name": "Hard", "lures": 2, "power": 5.8},
	{"name": "Elite", "lures": 3, "power": 8.1},
]
const WIN_XP := 20
const LOSS_XP := 3


static func day_number(now: int) -> int:
	return BossRuns.day_number(now)


static func is_unlocked(profile) -> bool:
	return ZONE < Zones.ZONES.size() and Campaign.is_cleared(profile, ZONE, Zones.zone(ZONE).stages.size() - 1)


static func runs_left(profile, now: int) -> int:
	return BossRuns.runs_left(profile, KEY, RUNS_PER_DAY, now)


static func enemy_rating(difficulty: int, _now := 0) -> int:
	return Power.rating(DIFFICULTIES[difficulty].power)


static func start(profile, difficulty: int, fighter: String, now: int) -> Dictionary:
	if not is_unlocked(profile):
		return {"error": "locked"}
	if not Campaign.can_fight(profile, fighter):
		return {"error": "no_ball"}
	if runs_left(profile, now) <= 0:
		return {"error": "runs"}
	if not profile.spend_energy(ENERGY_COST, now):
		return {"error": "energy"}
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, 1)
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
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, -1)


## Applies a finished fight. Returns {won, lures, gear, xp, levels, refund,
## account_levels}.
static func finish(profile, difficulty: int, fighter: String, fight: Dictionary, _now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var result := {"won": won, "lures": 0, "gear": [], "xp": LOSS_XP, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = ENERGY_COST - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		Campaign.give_xp(profile, result, fighter)
		return result
	result.lures = DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)].lures
	profile.grant({"kind": "lures", "n": result.lures})
	result.xp = WIN_XP
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _seed(runs: int, day: int, difficulty: int) -> int:
	return (runs * 4441 + day * 653 + difficulty * 41 + 29) & 0x7FFFFFFF
