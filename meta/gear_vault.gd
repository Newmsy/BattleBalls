## Gear Vault (design/gear.md section 4, pve.md "Gear Vault"): a daily mode
## that drops one gear piece per win. Pick a difficulty; the day decides the
## slot (Mon/Thu Shells, Tue/Fri Cores, Wed/Sat Charms, Sun any). Opens when
## the Zone 1 boss is beaten. 5 runs a day, 8 energy a run.
##
## Like the campaign, the game calls start() before the fight and finish()
## with the result. The fight is built from known setup only (your slot, the
## day's enemy and its gear), so it replays from the seed and the angles.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Gear := preload("res://sim/gear.gd")

const ENERGY_COST := 8
const RUNS_PER_DAY := 5
const DAY_SECONDS := 86400
## Difficulty: the drop's tier and the enemy's power (1.0 is a T1 level 1
## Common; the Zone 1 boss is 1.75). The enemy wears a piece at `tier`.
const DIFFICULTIES := [
	{"name": "Easy", "tier": 1, "power": 1.3},
	{"name": "Hard", "tier": 2, "power": 1.9},
	{"name": "Elite", "tier": 3, "power": 2.7},
]
## By UTC weekday (0 Sunday): the slot that drops, "" for any, and the enemy
## that guards it.
const DAYS := [
	{"slot": "", "enemy": "juggernaut"},
	{"slot": "Shell", "enemy": "juggernaut"},
	{"slot": "Core", "enemy": "spiker"},
	{"slot": "Charm", "enemy": "speedster"},
	{"slot": "Shell", "enemy": "juggernaut"},
	{"slot": "Core", "enemy": "spiker"},
	{"slot": "Charm", "enemy": "speedster"},
]
const WIN_XP := 20
const LOSS_XP := 3


static func day_number(now: int) -> int:
	return int(now / DAY_SECONDS)


## Today's rotation entry: {slot, enemy}.
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


## The enemy's Power Rating: its power boost and the piece it wears.
static func enemy_rating(difficulty: int, now: int) -> int:
	return Power.rating(DIFFICULTIES[difficulty].power * (1.0 + Gear.stats_power(enemy_piece(difficulty, now).stats)))


## The piece the enemy wears: the day's first type at the difficulty's tier.
## It goes straight into the fight's gear (no slot rules for enemies).
static func enemy_piece(difficulty: int, now: int) -> Dictionary:
	var type: String = types_today(now)[0]
	var tier: int = DIFFICULTIES[difficulty].tier
	return {"slot": Gear.PIECES[type].slot, "tier": tier, "stats": Gear.stats_for(type, tier)}


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
		"p2": today(now).enemy,
		"angles": [null, null],
		"tiers": [1, 1],
		"powers": [1.0, d.power],
		"gear": [null, [enemy_piece(difficulty, now)]],
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


## Backing out before launch: energy and the run come back.
static func cancel(profile, now: int) -> void:
	profile.refund_energy(ENERGY_COST)
	_use_run(profile, now, -1)


## Applies a finished Vault fight (`fight` as for Campaign.finish). Returns
## {won, gear: [new piece], xp, levels, refund, account_levels}.
static func finish(profile, difficulty: int, fighter: String, fight: Dictionary, now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var result := {"won": won, "gear": [], "xp": LOSS_XP, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = ENERGY_COST - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		Campaign.give_xp(profile, result, fighter)
		return result
	var rng := Rng.new(_seed(profile.runs, day_number(now), difficulty) ^ 0x68e31da4)
	var types := types_today(now)
	var tier: int = DIFFICULTIES[clampi(difficulty, 0, DIFFICULTIES.size() - 1)].tier
	result.gear = [profile.add_gear(types[rng.range_int(0, types.size() - 1)], tier)]
	result.xp = WIN_XP
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
