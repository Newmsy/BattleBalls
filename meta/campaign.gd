## Campaign rules (pve.md section 3): unlocking, energy, stars, XP and drops.
## The game calls start() before a stage fight and finish() with the result.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const Power := preload("res://sim/power.gd")
const RisingStar := preload("res://meta/rising_star.gd")

const RARE_BONUS_CHANCE := 0.05
## Second star: win before overtime. Third star: win with this share of HP
## left (a stand-in for "win without the power tap" until the tap exists).
const STAR_CLEAN_FRACTION := 0.3
const WIN_XP_BASE := 10
const WIN_XP_PER_STAGE := 4
const LOSS_XP := 3


static func is_unlocked(profile, zone_index: int, stage_index: int) -> bool:
	if stage_index == 0:
		return zone_index == 0 or is_cleared(profile, zone_index - 1, Zones.zone(zone_index - 1).stages.size() - 1)
	return is_cleared(profile, zone_index, stage_index - 1)


static func is_cleared(profile, zone_index: int, stage_index: int) -> bool:
	return profile.stars.get(Zones.stage_key(zone_index, stage_index), 0) > 0


static func stars_of(profile, zone_index: int, stage_index: int) -> int:
	return profile.stars.get(Zones.stage_key(zone_index, stage_index), 0)


static func can_sweep(profile, zone_index: int, stage_index: int) -> bool:
	return stars_of(profile, zone_index, stage_index) >= 3


static func enemy_rating(zone_index: int, stage_index: int) -> int:
	return Power.rating(Zones.stage(zone_index, stage_index).power)


## Critters that exist in the fight sim can fight; the rest of the roster is
## collectable before its ability is built.
static func can_fight(profile, id: String) -> bool:
	return profile.owns(id) and BallDefs.PLAYABLE.has(id)


## The fighter to use: the lineup critter if it can fight, otherwise the
## strongest owned critter that can.
static func fighter_for(profile) -> String:
	if can_fight(profile, profile.lineup):
		return profile.lineup
	var best_id := ""
	for id in BallDefs.PLAYABLE:
		if profile.owns(id) and (best_id == "" or profile.power_of(id) > profile.power_of(best_id)):
			best_id = id
	return best_id


## Spends energy and returns the fight config for a stage, with the player's
## aim left as null for the caller to fill in. Returns {error: "..."} instead
## when the stage is locked, the ball is unknown or energy is short.
static func start(profile, zone_index: int, stage_index: int, fighter: String, now: int) -> Dictionary:
	if not is_unlocked(profile, zone_index, stage_index):
		return {"error": "locked"}
	if not can_fight(profile, fighter):
		return {"error": "no_ball"}
	var st := Zones.stage(zone_index, stage_index)
	if not profile.spend_energy(Zones.cost(st), now):
		return {"error": "energy"}
	return {
		"seed": _seed(profile.runs, zone_index, stage_index),
		"p1": fighter,
		"p2": st.enemy,
		"angles": [null, null],
		"powers": [profile.fight_power(fighter), st.power],
		"sizes": [1.0, Zones.BOSS_SIZE if Zones.is_boss(st) else 1.0],
	}


## Applies a finished stage fight. `fight` is MatchSim.summary() plus the
## player's max HP ("max_hp"). Returns what happened for the result screen:
## {won, stars, first_clear, drops: [critter ids], xp, levels, refund,
## account_levels, rising_star}. XP includes the Rising Star boost when it is
## on at `now` (unix seconds; -1 reads the clock).
static func finish(profile, zone_index: int, stage_index: int, fighter: String, fight: Dictionary, now := -1) -> Dictionary:
	if now < 0:
		now = int(Time.get_unix_time_from_system())
	var st := Zones.stage(zone_index, stage_index)
	var key := Zones.stage_key(zone_index, stage_index)
	var won: bool = fight.winner == 0
	var boosted := RisingStar.active(profile, now)
	var result := {"won": won, "stars": 0, "first_clear": false, "drops": [], "xp": 0, "levels": 0, "refund": 0, "account_levels": 0, "rising_star": boosted}
	if not won:
		result.refund = Zones.cost(st) - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(RisingStar.account_xp(profile, Zones.LOSS_COST, now))
		result.xp = RisingStar.critter_xp(profile, LOSS_XP, now)
		result.levels = profile.add_xp(fighter, result.xp)
		return result
	var hp_fraction: float = fight.hp[0] / fight.max_hp
	var stars := 1
	if fight.time < MatchSim.OVERTIME_START:
		stars += 1
	if hp_fraction >= STAR_CLEAN_FRACTION:
		stars += 1
	result.stars = stars
	result.first_clear = profile.stars.get(key, 0) == 0
	profile.stars[key] = maxi(profile.stars.get(key, 0), stars)
	result.xp = RisingStar.critter_xp(profile, WIN_XP_BASE + WIN_XP_PER_STAGE * stage_index, now)
	result.levels = profile.add_xp(fighter, result.xp)
	result.drops = _roll_drops(profile, zone_index, stage_index, result.first_clear)
	result.account_levels = profile.add_account_xp(RisingStar.account_xp(profile, Zones.cost(st), now))
	profile.runs += 1
	profile.changed.emit()
	return result


## Replays a 3-starred stage off-screen (pve.md: same cost, same drops, no
## fight shown). The fight is still simulated, so a sweep can lose.
static func sweep(profile, zone_index: int, stage_index: int, fighter: String, now: int) -> Dictionary:
	if not can_sweep(profile, zone_index, stage_index):
		return {"error": "not_three_stars"}
	var cfg := start(profile, zone_index, stage_index, fighter, now)
	if cfg.has("error"):
		return cfg
	var sim := MatchSim.new(cfg)
	var fight := sim.run_to_end()
	fight.max_hp = sim.balls[0].max_hp
	return finish(profile, zone_index, stage_index, fighter, fight, now)


## One copy per win from the zone's featured critters (with a small chance of
## the next rarity up), plus a copy of the beaten enemy on first clear, plus
## the zone's guaranteed reward on the boss's first clear.
static func _roll_drops(profile, zone_index: int, stage_index: int, first_clear: bool) -> Array:
	var z := Zones.zone(zone_index)
	var st := Zones.stage(zone_index, stage_index)
	var rng := Rng.new(_seed(profile.runs, zone_index, stage_index) ^ 0x5bd1e995)
	var types: Array[String] = []
	if rng.next_float() < RARE_BONUS_CHANCE and not z.rare_bonus.is_empty():
		types.append(z.rare_bonus[rng.range_int(0, z.rare_bonus.size() - 1)])
	else:
		types.append(z.featured[rng.range_int(0, z.featured.size() - 1)])
	if first_clear:
		types.append(st.enemy)
		if Zones.is_boss(st):
			types.append(z.boss_reward)
	profile.add_copies(types)
	return types


static func _seed(runs: int, zone_index: int, stage_index: int) -> int:
	return (runs * 7919 + zone_index * 131 + stage_index * 17 + 1) & 0x7FFFFFFF
