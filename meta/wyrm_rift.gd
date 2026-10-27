## The Prism Wyrm (design/bosses.md): a daily boss in the Crystal Rift that
## pays Lures. Lures buy a guaranteed copy of a critter on your wishlist
## (Profile.use_lure; rarer critters cost more), so it's the targeted way to
## chase the one you want. Opens when the Zone 3 boss is beaten. 2 runs a
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
const BossLevels := preload("res://meta/boss_levels.gd")
const BossRuns := preload("res://meta/boss_runs.gd")

const BOSS := "prism_wyrm"
const KEY := "wyrm"
const ENERGY_COST := 10
const RUNS_PER_DAY := 2
const ZONE := 2 ## Beating this zone's boss (0-based) opens it.
## The 15 levels (meta/boss_levels.gd): the Lures a win pays and the wyrm's
## power, BossLevels.curve(4.0, 61.6). Power moves the wyrm less than other
## bosses (only its shining scale takes damage), so its numbers run higher
## for the same odds. Check with tools/boss_difficulty.gd --boss=prism_wyrm --tier=5.
const DIFFICULTIES := [
	{"name": "Level 1", "lures": 1, "power": 4.0},
	{"name": "Level 2", "lures": 1, "power": 5.6},
	{"name": "Level 3", "lures": 1, "power": 7.9},
	{"name": "Level 4", "lures": 2, "power": 11.2},
	{"name": "Level 5", "lures": 2, "power": 15.7},
	{"name": "Level 6", "lures": 2, "power": 22.1},
	{"name": "Level 7", "lures": 3, "power": 31.1},
	{"name": "Level 8", "lures": 3, "power": 43.8},
	{"name": "Level 9", "lures": 3, "power": 61.6},
	{"name": "Level 10", "lures": 4, "power": 69.0},
	{"name": "Level 11", "lures": 4, "power": 77.3},
	{"name": "Level 12", "lures": 4, "power": 86.5},
	{"name": "Level 13", "lures": 5, "power": 96.9},
	{"name": "Level 14", "lures": 5, "power": 108.6},
	{"name": "Level 15", "lures": 5, "power": 121.6},
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
	if not BossLevels.is_open(profile, KEY, difficulty):
		return {"error": "level"}
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
	BossLevels.beat(profile, KEY, difficulty)
	result.xp = WIN_XP + clampi(difficulty, 0, BossLevels.COUNT - 1) ## A little more XP each level up.
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _seed(runs: int, day: int, difficulty: int) -> int:
	return (runs * 4441 + day * 653 + difficulty * 41 + 29) & 0x7FFFFFFF
