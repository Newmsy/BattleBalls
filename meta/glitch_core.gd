## The Glitch (design/bosses.md, design/glitch.md): the weekly story boss in
## the Corrupted Core. It rewrites the rules every 10 seconds (Static, Warp,
## Pull). Three tries a week; the first win pays a big bundle (Summon Eggs,
## Lures and Hammers) and ends its week. Opens when the Zone 5 boss is
## beaten.
##
## Same flow as the other bosses (meta/gear_vault.gd): start() before the
## fight, finish() with the result. The Glitch lives in sim/bosses.gd.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Bosses := preload("res://sim/bosses.gd")
const BossRuns := preload("res://meta/boss_runs.gd")

const BOSS := "the_glitch"
const KEY := "glitch"
const ENERGY_COST := 12
const RUNS_PER_DAY := 3 ## Tries per WEEK (the hall reads this name).
const ZONE := 4 ## Beating this zone's boss (0-based) opens it.
## One difficulty: check it with tools/boss_difficulty.gd --boss=the_glitch.
const DIFFICULTIES := [{"name": "Weekly", "power": 7.5}]
const BUNDLE := [{"kind": "orbs", "n": 10}, {"kind": "lures", "n": 2}, {"kind": "hammers", "n": 15}]
const WIN_XP := 40
const LOSS_XP := 5


static func week_number(now: int) -> int:
	return BossRuns.week_number(now)


static func is_unlocked(profile) -> bool:
	return ZONE < Zones.ZONES.size() and Campaign.is_cleared(profile, ZONE, Zones.zone(ZONE).stages.size() - 1)


## Tries left this week (none once it's beaten).
static func runs_left(profile, now: int) -> int:
	return BossRuns.runs_left(profile, KEY, RUNS_PER_DAY, now, true)


static func enemy_rating(difficulty: int, _now := 0) -> int:
	return Power.rating(DIFFICULTIES[difficulty].power)


static func start(profile, _difficulty: int, fighter: String, now: int) -> Dictionary:
	if not is_unlocked(profile):
		return {"error": "locked"}
	if not Campaign.can_fight(profile, fighter):
		return {"error": "no_ball"}
	if runs_left(profile, now) <= 0:
		return {"error": "runs"}
	if not profile.spend_energy(ENERGY_COST, now):
		return {"error": "energy"}
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, 1, true)
	var cfg := {
		"seed": _seed(profile.runs, week_number(now)),
		"p2": BOSS,
		"arena": Bosses.DEFS[BOSS].arena,
		"angles": [null, null],
		"tiers": [1, 1],
		"powers": [1.0, DIFFICULTIES[0].power],
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


static func cancel(profile, now: int) -> void:
	profile.refund_energy(ENERGY_COST)
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, -1, true)


## Applies a finished fight. A win pays BUNDLE and uses up the week's tries.
## Returns {won, bundle, gear, xp, levels, refund, account_levels}.
static func finish(profile, _difficulty: int, fighter: String, fight: Dictionary, now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var result := {"won": won, "bundle": [], "gear": [], "xp": LOSS_XP, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = ENERGY_COST - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		Campaign.give_xp(profile, result, fighter)
		return result
	for r in BUNDLE:
		profile.grant(r)
	result.bundle = BUNDLE.duplicate(true)
	BossRuns.use(profile, KEY, RUNS_PER_DAY, now, RUNS_PER_DAY, true)
	result.xp = WIN_XP
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _seed(runs: int, week: int) -> int:
	return (runs * 3967 + week * 911 + 31) & 0x7FFFFFFF
