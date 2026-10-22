## Campaign rules (pve.md section 3): unlocking, energy, stars, XP and drops.
## The game calls start() before a stage fight and finish() with the result.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const Power := preload("res://sim/power.gd")
const Lineup := preload("res://sim/lineup.gd")
const Relay := preload("res://sim/relay.gd")
const Economy := preload("res://meta/economy.gd")
## Gear a campaign win can drop (design/gear.md section 4): Shells and Cores,
## since Charms only fit 3-star critters.
const GEAR_POOL := ["iron_shell", "bubble_shell", "thorn_shell", "spring_shell", "spike_core", "echo_core", "leech_core", "ricochet_core"]

const RARE_BONUS_CHANCE := 0.05
## Second star: win before overtime. Third star: win with this share of HP
## left (a stand-in for "win without the power tap" until the tap exists).
const STAR_CLEAN_FRACTION := 0.3
const WIN_XP_BASE := 10
const WIN_XP_PER_STAGE := 4
const LOSS_XP := 3
## Stage XP is multiplied by the zone number (zone 1 x1 ... zone 7 x7): a level
## costs 10 x level (Profile.xp_to_next) and later zones are fought at much
## higher levels, so a win keeps moving the bar about as much as in zone 1.
static func zone_xp_mult(zone_index: int) -> int:
	return zone_index + 1


## Critter XP for winning stage `stage_index` of zone `zone_index`.
static func win_xp(zone_index: int, stage_index: int) -> int:
	return (WIN_XP_BASE + WIN_XP_PER_STAGE * stage_index) * zone_xp_mult(zone_index)


## Critter XP for losing a stage in zone `zone_index`.
static func loss_xp(zone_index: int) -> int:
	return LOSS_XP * zone_xp_mult(zone_index)



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
	var best_power := 0
	for id in BallDefs.PLAYABLE:
		if not profile.owns(id):
			continue
		var power: int = profile.power_of(id)
		if best_id == "" or power > best_power:
			best_id = id
			best_power = power
	return best_id


## The team for a pairs or trios zone: the team you picked (Profile
## campaign_team) in order, or else the lineup critter first; then the
## strongest other critters that can fight, up to `size`.
static func team_for(profile, size: int) -> Array:
	var ids: Array = []
	# The team you picked comes first, in your order.
	for id in profile.campaign_team:
		if ids.size() < size and can_fight(profile, id) and not id in ids:
			ids.append(id)
	var first := fighter_for(profile)
	if first != "" and ids.is_empty():
		ids.append(first)
	var rest: Array = BallDefs.PLAYABLE.filter(func(id): return profile.owns(id) and not id in ids)
	var power := {}
	for id in rest:
		power[id] = profile.power_of(id)
	rest.sort_custom(func(a, b): return power[a] > power[b])
	for id in rest:
		if ids.size() >= size:
			break
		ids.append(id)
	return ids


## Spends energy and returns the relay config (sim/relay.gd) for a stage in a
## pairs or trios zone, your `picks` (critter ids) in order against the stage's
## enemies on the stage's arena (the zone's unless the stage names one). Your aims are null for the caller to fill in.
## Returns {error: "..."} like start().
static func start_team(profile, zone_index: int, stage_index: int, picks: Array, now: int) -> Dictionary:
	if not is_unlocked(profile, zone_index, stage_index):
		return {"error": "locked"}
	if picks.is_empty() or not picks.all(func(id): return can_fight(profile, id)):
		return {"error": "no_ball"}
	var st := Zones.stage(zone_index, stage_index)
	if not profile.spend_energy(Zones.cost(st), now):
		return {"error": "energy"}
	var foes := Zones.enemies(st)
	var slots: Array = picks.map(func(id): return profile.slot_of(id))
	var sizes: Array = foes.map(func(_e): return 1.0)
	if Zones.is_boss(st):
		sizes[-1] = Zones.BOSS_SIZE
	return {
		"seed": _seed(profile.runs, zone_index, stage_index),
		"arena": st.get("arena", Zones.zone(zone_index).get("arena", "square")),
		"sides": [picks.duplicate(), foes.duplicate()],
		"aims": [picks.map(func(_p): return null), foes.map(func(_e): return null)],
		"powers": [slots.map(func(s): return Lineup.power(s)), foes.map(func(_e): return float(st.foe_power))],
		"tiers": [slots.map(func(s): return Lineup.clean(s).tier), foes.map(func(_e): return st.tier)],
		"gear": [slots.map(func(s): return Lineup.kit(Lineup.clean(s))), foes.map(func(_e): return null)],
		"sizes": [picks.map(func(_p): return 1.0), sizes],
	}


## True when a stage is a real 2v2 (all four balls at once) rather than a
## relay: a duo stage with two picks against two foes.
static func is_pair(zone_index: int, stage_index: int, picks: Array) -> bool:
	return Zones.format(zone_index, stage_index) == "duo" and picks.size() == 2 and Zones.enemies(Zones.stage(zone_index, stage_index)).size() == 2


## True when a stage is a 3v3 brawl: all six balls at once on the zoomed-out arena.
static func is_brawl(zone_index: int, stage_index: int, picks: Array) -> bool:
	return Zones.format(zone_index, stage_index) == "brawl" and picks.size() == 3 and Zones.enemies(Zones.stage(zone_index, stage_index)).size() == 3


## The MatchSim config for a 2v2 or 3v3 stage, from start_team()'s relay
## config `rc`: your picks are p1, p3 (and p5), the foes p2, p4 (and p6), the
## boss last at BOSS_SIZE. A 3v3 shrinks every ball by BRAWL_SIZE, which reads
## as an arena twice the size. Your critters fight as you own them, talents
## included. Your aim (index 0) is null for the caller to fill in; your mates
## aim themselves.
static func team_config(profile, rc: Dictionary) -> Dictionary:
	var foes: Array = rc.sides[1]
	var n: int = mini(rc.sides[0].size(), foes.size())
	var k := Zones.BRAWL_SIZE if n >= 3 else 1.0
	var cfg := {"seed": rc.seed, "arena": rc.arena, "angles": [], "tiers": [], "powers": [], "gear": [], "sizes": []}
	for j in n:
		cfg["p%d" % (2 * j + 2)] = foes[j]
		cfg.angles.append_array([null, null])
		cfg.tiers.append_array([1, rc.tiers[1][j]])
		cfg.powers.append_array([1.0, rc.powers[1][j]])
		cfg.gear.append_array([null, null])
		cfg.sizes.append_array([k, rc.sizes[1][j] * k])
	for j in n:
		Lineup.apply(cfg, 2 * j, profile.slot_of(rc.sides[0][j]))
	return cfg


## The 2v2 config for a pairs stage (team_config()).
static func pair_config(profile, rc: Dictionary) -> Dictionary:
	return team_config(profile, rc)


## The finish() input for a finished 2v2 or 3v3: HP and max HP are your team's.
static func pair_fight(sim) -> Dictionary:
	var fight: Dictionary = sim.summary()
	fight.max_hp = 0.0
	for i in range(0, sim.starters, 2):
		fight.max_hp += sim.balls[i].max_hp
	return fight


## The finish() input for a finished relay: a win's second star needs no ball
## lost, its third the last ball standing on 30%+ HP. `last` is the final
## leg's MatchSim.
static func relay_fight(relay, last) -> Dictionary:
	var won: bool = relay.winner == 0
	var hp: float = last.balls[0].hp if won else 0.0
	return {"winner": 0 if won else 1, "hp": [hp, 0.0], "max_hp": last.balls[0].max_hp,
		"time": 0.0 if won and relay.slot[0] == 0 else MatchSim.OVERTIME_START + 1.0}


## finish() for a team: the first pick takes the result, every pick gets the XP.
static func finish_team(profile, zone_index: int, stage_index: int, picks: Array, fight: Dictionary) -> Dictionary:
	var r := finish(profile, zone_index, stage_index, picks[0], fight)
	for k in range(1, picks.size()):
		var g: Dictionary = profile.gain_xp(picks[k], r.xp)
		if not g.is_empty():
			r.critters.append(g)
			if g.levels > 0:
				r.levels += 1
	return r


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
	# Your critter fights as you own it: its tier (ability upgrades and power),
	# level and gear. All of it is in the config, so the fight replays.
	var cfg := {
		"seed": _seed(profile.runs, zone_index, stage_index),
		"p2": st.enemy,
		"angles": [null, null],
		"tiers": [1, st.tier],
		"powers": [1.0, st.foe_power],
		"gear": [null, null],
		"sizes": [1.0, Zones.BOSS_SIZE if Zones.is_boss(st) else 1.0],
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


## Applies a finished stage fight. `fight` is MatchSim.summary() plus the
## player's max HP ("max_hp"). Returns what happened for the result screen:
## {won, stars, first_clear, drops: [critter ids], gear: [new pieces], xp,
## levels, refund, account_levels}.
static func finish(profile, zone_index: int, stage_index: int, fighter: String, fight: Dictionary) -> Dictionary:
	var st := Zones.stage(zone_index, stage_index)
	var key := Zones.stage_key(zone_index, stage_index)
	var won: bool = fight.winner == 0
	var result := {"won": won, "stars": 0, "first_clear": false, "drops": [], "orbs": 0, "gear": [], "xp": 0, "levels": 0, "refund": 0, "account_levels": 0, "critters": []}
	if not won:
		result.refund = Zones.cost(st) - Zones.LOSS_COST
		profile.refund_energy(result.refund)
		result.account_levels = profile.add_account_xp(Zones.LOSS_COST)
		result.xp = loss_xp(zone_index)
		give_xp(profile, result, fighter)
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
	result.xp = win_xp(zone_index, stage_index)
	give_xp(profile, result, fighter)
	result.drops = _roll_drops(profile, zone_index, stage_index, result.first_clear, result)
	result.gear = _roll_gear(profile, zone_index, stage_index, stars, result.first_clear)
	result.account_levels = profile.add_account_xp(Zones.cost(st))
	profile.runs += 1
	profile.changed.emit()
	return result


## Gives `fighter` the result's XP and keeps the before and after in
## `result.critters` for the results popup's XP bars.
static func give_xp(profile, result: Dictionary, fighter: String) -> void:
	var g: Dictionary = profile.gain_xp(fighter, result.xp)
	result.levels = int(g.get("levels", 0))
	if not g.is_empty():
		result.critters.append(g)


## Replays a 3-starred stage off-screen (pve.md: same cost, same drops, no
## fight shown). The fight is still simulated, so a sweep can lose.
static func sweep(profile, zone_index: int, stage_index: int, fighter: String, now: int) -> Dictionary:
	if not can_sweep(profile, zone_index, stage_index):
		return {"error": "not_three_stars"}
	if Zones.zone(zone_index).lineup > 1:
		var picks := team_for(profile, Zones.team_size(zone_index, stage_index))
		var rc := start_team(profile, zone_index, stage_index, picks, now)
		if rc.has("error"):
			return rc
		if is_pair(zone_index, stage_index, picks) or is_brawl(zone_index, stage_index, picks):
			var duo := MatchSim.new(pair_config(profile, rc))
			duo.run_to_end()
			return finish_team(profile, zone_index, stage_index, picks, pair_fight(duo))
		var relay := Relay.new(rc)
		var last = null
		while not relay.finished:
			last = MatchSim.new(relay.leg_config())
			last.run_to_end()
			relay.record_leg(last)
		return finish_team(profile, zone_index, stage_index, picks, relay_fight(relay, last))
	var cfg := start(profile, zone_index, stage_index, fighter, now)
	if cfg.has("error"):
		return cfg
	var sim := MatchSim.new(cfg)
	var fight := sim.run_to_end()
	fight.max_hp = sim.balls[0].max_hp
	return finish(profile, zone_index, stage_index, fighter, fight)


## A copy from the zone's featured critters on Economy.CAMPAIGN_DROP_CHANCE of
## wins (with a small chance of the next rarity up), Summon Eggs on the rest
## (into `result.orbs`), plus a copy of the beaten enemy on first clear, plus
## the zone's guaranteed reward on the boss's first clear.
static func _roll_drops(profile, zone_index: int, stage_index: int, first_clear: bool, result := {}) -> Array:
	var z := Zones.zone(zone_index)
	var st := Zones.stage(zone_index, stage_index)
	var rng := Rng.new(_seed(profile.runs, zone_index, stage_index) ^ 0x5bd1e995)
	var types: Array[String] = []
	if rng.next_float() >= Economy.CAMPAIGN_DROP_CHANCE:
		result.orbs = Economy.ORBS_CAMPAIGN_WIN
		profile.orbs += Economy.ORBS_CAMPAIGN_WIN
	elif rng.next_float() < RARE_BONUS_CHANCE and not z.rare_bonus.is_empty():
		types.append(z.rare_bonus[rng.range_int(0, z.rare_bonus.size() - 1)])
	else:
		types.append(z.featured[rng.range_int(0, z.featured.size() - 1)])
	if first_clear:
		types.append(st.enemy)
		if Zones.is_boss(st):
			types.append(z.boss_reward)
	profile.add_copies(types)
	return types


## A piece on Economy.GEAR_CAMPAIGN_CHANCE of wins at Economy.gear_tier for
## the stage, and a boss's first clear always gives one at
## Economy.GEAR_BOSS_TIER (+1 per zone). Rolled from the run seed.
static func _roll_gear(profile, zone_index: int, stage_index: int, stars: int, first_clear: bool) -> Array:
	var rng := Rng.new(_seed(profile.runs, zone_index, stage_index) ^ 0x2545f491)
	var out := []
	if rng.next_float() < Economy.GEAR_CAMPAIGN_CHANCE:
		out.append(profile.add_gear(GEAR_POOL[rng.range_int(0, GEAR_POOL.size() - 1)], Economy.gear_tier(zone_index, stage_index)))
	if first_clear and Zones.is_boss(Zones.stage(zone_index, stage_index)):
		out.append(profile.add_gear(GEAR_POOL[rng.range_int(0, GEAR_POOL.size() - 1)], mini(5, Economy.GEAR_BOSS_TIER + zone_index)))
	return out


static func _seed(runs: int, zone_index: int, stage_index: int) -> int:
	return (runs * 7919 + zone_index * 131 + stage_index * 17 + 1) & 0x7FFFFFFF
