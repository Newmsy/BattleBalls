## The Totem of Nine (design/bosses.md): a daily boss in the Spirit Shrine
## that pays Family Sigils, Faction XP for today's family's talent tree. The
## family turns every day through all nine; critters of today's family hit
## the totem half as hard again, so bring one. Opens when the Zone 3 boss is
## beaten. 3 runs a day, 8 energy a run.
##
## Same flow as the other bosses (meta/gear_vault.gd): start() before the
## fight, finish() with the result. The totem lives in sim/bosses.gd.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Bosses := preload("res://sim/bosses.gd")
const Talents := preload("res://sim/talents.gd")
const BossRuns := preload("res://meta/boss_runs.gd")

const BOSS := "totem_of_nine"
const KEY := "totem"
const ENERGY_COST := 8
const RUNS_PER_DAY := 3
const ZONE := 2 ## Beating this zone's boss (0-based) opens it.
## Difficulty: the sigils (Faction XP) a win pays and the totem's power.
## Check win rates with tools/boss_difficulty.gd --boss=totem_of_nine.
const DIFFICULTIES := [
	{"name": "Easy", "sigils": 60, "power": 2.9},
	{"name": "Hard", "sigils": 100, "power": 4.2},
	{"name": "Elite", "sigils": 160, "power": 5.9},
]
const WIN_XP := 20
const LOSS_XP := 3


static func day_number(now: int) -> int:
	return BossRuns.day_number(now)


## Today's lit family.
static func family_today(now: int) -> String:
	return Talents.FACTIONS[posmod(day_number(now), Talents.FACTIONS.size())]


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
		"boss": {"family": family_today(now)},
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


static func cancel(profile, now: int) -> void:
	profile.refund_energy(ENERGY_COST)
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, -1)


## Applies a finished fight. Returns {won, family, sigils, gear, xp, levels,
## refund, account_levels}.
static func finish(profile, difficulty: int, fighter: String, fight: Dictionary, now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var family := family_today(now)
	var result := {"won": won, "family": family, "sigils": 0, "gear": [], "xp": LOSS_XP, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = ENERGY_COST - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		Campaign.give_xp(profile, result, fighter)
		return result
	result.sigils = DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)].sigils
	profile.add_faction_xp(family, result.sigils)
	result.xp = WIN_XP
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _seed(runs: int, day: int, difficulty: int) -> int:
	return (runs * 5309 + day * 571 + difficulty * 37 + 23) & 0x7FFFFFFF
