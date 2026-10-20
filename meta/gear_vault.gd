## The Anvil King (design/bosses.md; was the Gear Vault): a daily boss fight
## on The Forge that drops one gear piece and a pile of Hammers (the gear
## merge currency) per win. Pick a difficulty; the day decides the slot
## (Mon/Thu Shells, Tue/Fri Cores, Wed/Sat Charms, Sun any). Opens when the
## Zone 1 boss is beaten. 5 runs a day, 8 energy a run.
##
## Like the campaign, the game calls start() before the fight and finish()
## with the result. The fight is built from known setup only (your slot, the
## boss and its power), so it replays from the seed and the angles. The boss
## itself lives in sim/bosses.gd.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Gear := preload("res://sim/gear.gd")
const Bosses := preload("res://sim/bosses.gd")
const BossLevels := preload("res://meta/boss_levels.gd")

const ENERGY_COST := 8
const RUNS_PER_DAY := 5
const DAY_SECONDS := 86400
const KEY := "vault" ## Its entry in profile.boss_levels.
const BOSS := "anvil_king"
## The 15 levels (meta/boss_levels.gd): the drop's tier, the Hammers a win
## gives and the boss's power (1.0 is a T1 level 1 Common; the Zone 1 boss
## is 1.75). Power is BossLevels.curve(1.3, 11.0): level 9 is about a coin
## flip for a T5 at 5,500 power. Check with tools/boss_difficulty.gd --tier=5.
const DIFFICULTIES := [
	{"name": "Level 1", "tier": 1, "hammers": 3, "power": 1.3},
	{"name": "Level 2", "tier": 1, "hammers": 4, "power": 1.7},
	{"name": "Level 3", "tier": 1, "hammers": 5, "power": 2.2},
	{"name": "Level 4", "tier": 2, "hammers": 6, "power": 2.9},
	{"name": "Level 5", "tier": 2, "hammers": 7, "power": 3.8},
	{"name": "Level 6", "tier": 2, "hammers": 8, "power": 4.9},
	{"name": "Level 7", "tier": 3, "hammers": 9, "power": 6.4},
	{"name": "Level 8", "tier": 3, "hammers": 10, "power": 8.4},
	{"name": "Level 9", "tier": 3, "hammers": 11, "power": 11.0},
	{"name": "Level 10", "tier": 4, "hammers": 12, "power": 12.3},
	{"name": "Level 11", "tier": 4, "hammers": 13, "power": 13.8},
	{"name": "Level 12", "tier": 4, "hammers": 14, "power": 15.5},
	{"name": "Level 13", "tier": 5, "hammers": 15, "power": 17.3},
	{"name": "Level 14", "tier": 5, "hammers": 16, "power": 19.4},
	{"name": "Level 15", "tier": 5, "hammers": 17, "power": 21.7},
]
## By UTC weekday (0 Sunday): the slot that drops, "" for any.
const DAYS := [
	{"slot": ""}, {"slot": "Shell"}, {"slot": "Core"}, {"slot": "Charm"},
	{"slot": "Shell"}, {"slot": "Core"}, {"slot": "Charm"},
]
const WIN_XP := 20
const LOSS_XP := 3


static func day_number(now: int) -> int:
	return int(now / DAY_SECONDS)


## Today's rotation entry: {slot}.
static func today(now: int) -> Dictionary:
	# 1970-01-01 was a Thursday.
	return DAYS[(day_number(now) + 4) % 7]


## The gear types that can drop today.
static func types_today(now: int) -> Array:
	var slot: String = today(now).slot
	return Gear.TYPES.filter(func(t): return slot == "" or Gear.PIECES[t].slot == slot)


static func is_unlocked(profile) -> bool:
	return Campaign.is_cleared(profile, 0, Zones.zone(0).stages.size() - 1)


static func runs_left(profile, now: int) -> int:
	if int(profile.vault.get("day", -1)) != day_number(now):
		return RUNS_PER_DAY
	return maxi(0, RUNS_PER_DAY - int(profile.vault.get("runs", 0)))


## The boss's Power Rating at a difficulty.
static func enemy_rating(difficulty: int, _now := 0) -> int:
	return Power.rating(DIFFICULTIES[difficulty].power)


## Spends energy and a run and returns the fight config, with the player's
## aim left as null. Returns {error: "..."} when locked, out of runs or energy.
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


## Backing out before launch: energy and the run come back.
static func cancel(profile, now: int) -> void:
	profile.refund_energy(ENERGY_COST)
	_use_run(profile, now, -1)


## Applies a finished Anvil King fight (`fight` as for Campaign.finish).
## Returns {won, gear: [new piece], hammers, xp, levels, refund, account_levels}.
static func finish(profile, difficulty: int, fighter: String, fight: Dictionary, now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var result := {"won": won, "gear": [], "hammers": 0, "xp": LOSS_XP, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = ENERGY_COST - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		Campaign.give_xp(profile, result, fighter)
		return result
	var rng := Rng.new(_seed(profile.runs, day_number(now), difficulty) ^ 0x68e31da4)
	var types := types_today(now)
	var d: Dictionary = DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)]
	result.gear = [profile.add_gear(types[rng.range_int(0, types.size() - 1)], d.tier)]
	result.hammers = d.hammers
	profile.hammers += d.hammers
	BossLevels.beat(profile, KEY, difficulty)
	result.xp = WIN_XP + clampi(difficulty, 0, BossLevels.COUNT - 1) ## A little more XP each level up.
	Campaign.give_xp(profile, result, fighter)
	result.account_levels = profile.add_account_xp(ENERGY_COST)
	profile.runs += 1
	profile.changed.emit()
	return result


static func _use_run(profile, now: int, n: int) -> void:
	var day := day_number(now)
	if int(profile.vault.get("day", -1)) != day:
		profile.vault = {"day": day, "runs": 0}
	profile.vault.runs = clampi(int(profile.vault.runs) + n, 0, RUNS_PER_DAY)
	profile.changed.emit()


static func _seed(runs: int, day: int, difficulty: int) -> int:
	return (runs * 6151 + day * 389 + difficulty * 29 + 7) & 0x7FFFFFFF
