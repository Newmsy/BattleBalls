## Progression rules: power, energy, account level, campaign stars, drops and
## the save round trip. Fusion itself is covered in test_ui.gd.
extends "res://tests/test_case.gd"

const Profile := preload("res://meta/profile.gd")
const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")
const Roster := preload("res://game/ui/roster.gd")
const Power := preload("res://sim/power.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")
const Relay := preload("res://sim/relay.gd")

const T0 := 1_800_000_000


func _win(time := 20.0, hp := 90.0) -> Dictionary:
	return {"winner": 0, "hp": [hp, 0.0], "time": time, "max_hp": 100.0}


func _loss() -> Dictionary:
	return {"winner": 1, "hp": [0.0, 50.0], "time": 40.0, "max_hp": 100.0}


func test_new_game_starts_with_one_critter_and_full_energy() -> void:
	var p = Profile.new_game(T0)
	check_eq(p.stacks.size(), 1, "starter stacks")
	check_eq(p.best(Profile.STARTER).tier, 1, "everything drops at tier 1")
	check_eq(p.lineup, Profile.STARTER, "starter fights")
	check_eq(p.energy, Profile.ENERGY_MAX, "energy")


func test_fight_power_matches_the_power_rating_players_see() -> void:
	var p = Profile.new_game(T0)
	p.stacks.append({"id": "laser", "tier": 3, "count": 1, "level": 7, "xp": 0})
	p.gear.append({"uid": 1, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "text": "", "on": "laser"})
	check_eq(Power.rating(p.fight_power("laser")), p.power_of("laser"), "rating")
	check_eq(Power.rating(p.fight_power("vampire")), Roster.power("vampire", 1, 1), "base")


func test_power_steps_match_the_design_budget() -> void:
	check_near(Power.multiplier("common", 2, 1), 1.25, 0.0001, "one tier")
	check_near(Power.multiplier("common", 1, 11), 1.25, 0.0001, "ten levels")
	check_near(Power.multiplier("legendary", 1, 1), Power.multiplier("common", 3, 1), 0.001, "a T1 Legendary is two tiers above a T1 Common")


func test_power_scales_hp_and_damage_but_not_speed() -> void:
	var sim := MatchSim.new({"seed": 1, "p1": "laser", "p2": "laser", "powers": [1.44, 1.0]})
	check_near(sim.balls[0].max_hp, 126.0, 0.001, "hp x sqrt(1.44)")
	check_near(sim.balls[0].def.beam_damage, sim.balls[1].def.beam_damage * 1.2, 0.001, "beam damage scales")
	check_eq(sim.balls[0].speed, sim.balls[1].speed, "speed unchanged")


func test_rarity_builds_the_ability_half_a_tier_up() -> void:
	# A T1 Legendary's ability hits like a T3 one (two rarity steps = one tier),
	# so it can fight a T3 Common evenly, as its stats already do.
	var sim := MatchSim.new({"seed": 1, "p1": "glacia", "p2": "crumb"})
	check_near(sim.balls[0].def.shard_damage, BallDefs.get_def("glacia").shard_damage * 1.5, 0.001, "Legendary T1 potency = T3 (x1.5)")
	check_eq(Power.rarity_tiers("common"), 0.0, "Commons get none")
	var off := MatchSim.new({"seed": 1, "p1": "glacia", "p2": "crumb", "rarity_potency": false})
	check_near(off.balls[0].def.shard_damage, BallDefs.get_def("glacia").shard_damage, 0.001, "audits can switch it off")


func test_levels_are_capped_by_tier() -> void:
	var p = Profile.new_game(T0)
	p.add_xp("vampire", 100000)
	check_eq(p.best("vampire").level, Roster.level_cap(1), "T1 caps at level 10")
	check_eq(p.best("vampire").xp, 0, "no xp banked at the cap")


func test_xp_gain_and_chips_report_the_bar() -> void:
	var p = Profile.new_game(T0)
	var g: Dictionary = p.gain_xp("vampire", 35)
	check_eq([g.from_level, g.from_xp, g.to_level, g.to_xp, g.levels], [1, 0, 3, 5, 2], "35 XP: 10 + 20 to level 3, 5 over")
	check_eq(p.use_xp_chip("vampire"), {}, "no chips yet")
	p.grant({"kind": "xp_chip", "n": 1})
	var c: Dictionary = p.use_xp_chip("vampire")
	check_eq(c.xp, Profile.XP_CHIP_XP, "a chip gives its XP")
	check_eq(p.xp_chips(), 0, "and is spent")
	check_eq(c.from_level, 3, "bar starts where it was")
	var won := Campaign.finish(p, 0, 0, "vampire", {"winner": 1, "hp": [0.0, 1.0], "max_hp": 1.0, "time": 10.0})
	check_eq(won.critters.size(), 1, "a result carries the fighter's XP bar")


func test_energy_regenerates_and_stops_at_max() -> void:
	var p = Profile.new_game(T0)
	check(p.spend_energy(20, T0), "spend")
	check_eq(p.energy, 40, "after spend")
	p.update_energy(T0 + Profile.ENERGY_REGEN_SECONDS * 4 + 10)
	check_eq(p.energy, 44, "four points regenerated")
	check_eq(p.seconds_to_next_energy(T0 + Profile.ENERGY_REGEN_SECONDS * 4 + 10), Profile.ENERGY_REGEN_SECONDS - 10, "partial progress kept")
	p.update_energy(T0 + 100000)
	check_eq(p.energy, Profile.ENERGY_MAX, "capped at max")
	check(not p.spend_energy(Profile.ENERGY_MAX + 1, T0 + 100000), "can't overspend")


func test_account_xp_comes_from_finished_runs_only() -> void:
	var p = Profile.new_game(T0)
	p.spend_energy(Zones.STAGE_COST, T0)
	check_eq(p.account_xp, 0, "spending alone earns nothing (a cancelled run is refunded)")
	Campaign.start(p, 0, 0, "vampire", T0)
	Campaign.finish(p, 0, 0, "vampire", _win())
	check_eq(p.account_xp, Zones.STAGE_COST, "a finished win earns its cost")


func test_account_level_up_refills_energy() -> void:
	var p = Profile.new_game(T0)
	p.energy = 10
	check_eq(p.add_account_xp(p.account_xp_to_next()), 1, "levelled up")
	check_eq(p.energy, Profile.ENERGY_MAX, "refilled")


func test_stages_unlock_in_order() -> void:
	var p = Profile.new_game(T0)
	check(Campaign.is_unlocked(p, 0, 0), "first stage open")
	check(not Campaign.is_unlocked(p, 0, 1), "second stage locked")
	check_eq(Campaign.start(p, 0, 1, "vampire", T0).get("error"), "locked", "can't start a locked stage")
	check_eq(p.energy, Profile.ENERGY_MAX, "a refused start costs nothing")


func test_only_owned_critters_with_a_built_ability_fight() -> void:
	var p = Profile.new_game(T0)
	check_eq(Campaign.start(p, 0, 0, "laser", T0).get("error"), "no_ball", "not owned")
	p.add_copies(["splitter"])
	p.set_lineup("splitter")
	check_eq(Campaign.fighter_for(p), "splitter", "every critter is built now, so an owned one fights")
	p.lineup = "no_such_critter"
	var fallback := Campaign.fighter_for(p)
	check(p.owns(fallback) and Campaign.can_fight(p, fallback), "falls back to an owned critter that can fight")


func test_win_spends_energy_gives_stars_xp_and_drops() -> void:
	var p = Profile.new_game(T0)
	var enemy: String = Zones.stage(0, 0).enemy
	var cfg: Dictionary = Campaign.start(p, 0, 0, "vampire", T0)
	check(not cfg.has("error"), "started")
	check_eq(p.energy, Profile.ENERGY_MAX - Zones.STAGE_COST, "energy spent")
	check_eq(cfg.p2, enemy, "enemy")
	var r: Dictionary = Campaign.finish(p, 0, 0, "vampire", _win())
	check(r.won, "won")
	check_eq(r.stars, 3, "a quick, healthy win is 3 stars")
	check(r.first_clear, "first clear")
	check_eq(r.drops.size() + (1 if r.orbs > 0 else 0), 2, "a copy or orbs, plus the first-clear copy")
	check(p.owns(enemy), "first clear gives the beaten critter")
	check(Campaign.is_unlocked(p, 0, 1), "next stage opens")
	check(p.best("vampire").level > 1, "fighter levelled")


func test_stars_track_speed_and_remaining_hp() -> void:
	var p = Profile.new_game(T0)
	Campaign.start(p, 0, 0, "vampire", T0)
	check_eq(Campaign.finish(p, 0, 0, "vampire", _win(50.0, 20.0)).stars, 1, "low HP win in overtime")
	Campaign.start(p, 0, 0, "vampire", T0)
	check_eq(Campaign.finish(p, 0, 0, "vampire", _win(30.0, 20.0)).stars, 2, "low HP win before overtime")
	Campaign.start(p, 0, 0, "vampire", T0)
	var r: Dictionary = Campaign.finish(p, 0, 0, "vampire", _win(50.0, 40.0))
	check_eq(r.stars, 2, "healthy win in overtime")
	check_eq(Campaign.stars_of(p, 0, 0), 2, "best stars kept")
	check(not r.first_clear, "replays aren't first clears")
	check_eq(r.drops.size() + (1 if r.orbs > 0 else 0), 1, "replays drop one copy or orbs")


func test_loss_refunds_all_but_one_energy() -> void:
	var p = Profile.new_game(T0)
	Campaign.start(p, 0, 0, "vampire", T0)
	var r: Dictionary = Campaign.finish(p, 0, 0, "vampire", _loss())
	check(not r.won, "lost")
	check_eq(p.energy, Profile.ENERGY_MAX - Zones.LOSS_COST, "only the loss cost is kept")
	check(r.drops.is_empty(), "no drops on a loss")
	check(not Campaign.is_cleared(p, 0, 0), "not cleared")


func test_boss_first_clear_gives_the_zone_reward() -> void:
	var p = Profile.new_game(T0)
	var last: int = Zones.zone(0).stages.size() - 1
	for i in last:
		p.stars[Zones.stage_key(0, i)] = 1
	var cfg: Dictionary = Campaign.start(p, 0, last, "vampire", T0)
	check_eq(p.energy, Profile.ENERGY_MAX - Zones.BOSS_COST, "boss cost")
	check(cfg.sizes[1] > 1.0, "boss is bigger")
	var r: Dictionary = Campaign.finish(p, 0, last, "vampire", _win())
	check(r.drops.has(Zones.zone(0).boss_reward), "guaranteed boss reward")


func test_sweep_needs_three_stars_and_runs_the_fight() -> void:
	var p = Profile.new_game(T0)
	check_eq(Campaign.sweep(p, 0, 0, "vampire", T0).get("error"), "not_three_stars", "locked until 3 stars")
	p.stars["1-1"] = 3
	var r: Dictionary = Campaign.sweep(p, 0, 0, "vampire", T0)
	check(r.has("won"), "sweep produced a result")
	check(p.energy < Profile.ENERGY_MAX, "sweep costs energy")


func test_drops_vary_between_runs_but_are_repeatable() -> void:
	var seen := {}
	for attempt in 2:
		var p = Profile.new_game(T0)
		p.stars["1-1"] = 1
		var types: Array = []
		var orb_wins := 0
		for i in 60:
			Campaign.start(p, 0, 0, "vampire", T0 + i * 10000)
			var r: Dictionary = Campaign.finish(p, 0, 0, "vampire", _win())
			types.append_array(r.drops)
			orb_wins += 1 if r.orbs > 0 else 0
		check(orb_wins > 30 and orb_wins < 55, "most wins drop orbs (%d of 60)" % orb_wins)
		seen[",".join(types)] = true
		var distinct := {}
		for t in types:
			distinct[t] = true
		check(distinct.size() >= 3, "drops spread across the featured critters")
	check_eq(seen.size(), 1, "same history gives the same drops")


func test_save_round_trip() -> void:
	var p = Profile.new_game(T0)
	p.add_copies(["laser", "laser", "spiker"])
	p.stars["1-1"] = 3
	p.spend_energy(6, T0)
	p.toggle_wishlist("laser")
	p.gear.append(Profile.gear_piece({"uid": 3, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "on": "laser"}))
	var json := JSON.stringify(p.to_dict())
	var q = Profile.from_dict(JSON.parse_string(json), T0)
	check_eq(JSON.stringify(q.to_dict()), json, "profile survives a JSON round trip")
	check_eq(typeof(q.stacks[0].tier), TYPE_INT, "ints stay ints")
	check_eq(q.items[0].color, p.items[0].color, "colours survive")
	check(q.on_wishlist("laser"), "wishlist survives")


func test_a_broken_save_starts_a_new_game() -> void:
	var q = Profile.from_dict({"stacks": []}, T0)
	check(q.owns(Profile.STARTER), "fresh starter")


func test_zone_two_is_pairs_on_bumpers_after_the_zone_one_boss() -> void:
	var p = Profile.new_game(T0)
	check_eq(Zones.zone(1).lineup, 2, "Circuit Lab is pairs")
	check(not Campaign.is_unlocked(p, 1, 0), "locked until Mega Boulder falls")
	for i in Zones.zone(0).stages.size():
		p.stars[Zones.stage_key(0, i)] = 3
	check(Campaign.is_unlocked(p, 1, 0), "open after the zone 1 boss")
	for st in Zones.zone(1).stages:
		for id in Zones.enemies(st):
			check(BallDefs.PLAYABLE.has(id), "zone 2 foe %s can fight" % id)
	p.add_copies(["laser"])
	var picks := Campaign.team_for(p, 2)
	check_eq(picks.size(), 2, "a team of two")
	var cfg: Dictionary = Campaign.start_team(p, 1, 0, picks, T0)
	check_eq(cfg.get("arena"), "bumpers", "fought on the Bumpers arena")
	check_eq(cfg.sides[1].size(), 2, "two foes")
	check(Campaign.is_pair(1, 0, picks), "pairs stages are a real 2v2, not a relay")
	var duo: Dictionary = Campaign.pair_config(p, cfg)
	check_eq([duo.p1, duo.p3], picks, "your pair is p1 and p3")
	check_eq([duo.p2, duo.p4], Zones.enemies(Zones.stage(1, 0)), "the foes are p2 and p4")
	var sim := MatchSim.new(duo)
	check_eq(sim.starters, 4, "all four fight at once")
	sim.run_to_end()
	var r: Dictionary = Campaign.finish_team(p, 1, 0, picks, Campaign.pair_fight(sim))
	check(r.has("won"), "the 2v2 settles like a stage")
	if r.won:
		check(Campaign.is_cleared(p, 1, 0), "a win clears 2-1")
	p.stars["2-1"] = 3
	check(Campaign.sweep(p, 1, 0, picks[0], T0).has("won"), "pairs stages sweep too")


func test_zone_three_is_trios_after_the_zone_two_boss() -> void:
	var p = Profile.new_game(T0)
	check_eq(Zones.zone(2).lineup, 3, "Frostbite Caves is trios")
	for z in 2:
		for i in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, i)] = 3
	check(Campaign.is_unlocked(p, 2, 0), "open after the zone 2 boss")
	for st in Zones.zone(2).stages:
		check_eq(Zones.enemies(st).size(), 3, "three foes")
		for id in Zones.enemies(st):
			check(BallDefs.PLAYABLE.has(id), "zone 3 foe %s can fight" % id)
	p.add_copies(["laser", "frost"])
	var picks := Campaign.team_for(p, 3)
	check_eq(picks.size(), 3, "a team of three")
	check_eq(Campaign.start_team(p, 2, 0, picks, T0).get("arena"), "frost", "the zone's frozen lake by default")
	check(not Campaign.is_pair(2, 0, picks), "trios stay relays")
	p.energy = 999
	p.stars["3-1"] = 1
	p.stars["3-2"] = 1
	check_eq(Campaign.start_team(p, 2, 2, picks, T0).get("arena"), "spikes", "a stage can name its own arena")


func test_every_built_zone_has_fightable_foes_and_a_boss_last() -> void:
	for z in Zones.ZONES.size():
		var zone: Dictionary = Zones.zone(z)
		check(Zones.is_boss(zone.stages[-1]), "%s ends in its boss" % zone.name)
		check(BallDefs.PLAYABLE.has(zone.boss_reward), "%s boss reward is a critter" % zone.name)
		for st in zone.stages:
			check_eq(Zones.enemies(st).size(), zone.lineup, "%s stages bring %d foes" % [zone.name, zone.lineup])
			check(Arenas.PLAYABLE.has(st.get("arena", zone.get("arena", "square"))), "%s arena exists" % zone.name)
			for id in Zones.enemies(st):
				check(BallDefs.PLAYABLE.has(id), "%s foe %s can fight" % [zone.name, id])


func test_later_zones_give_more_xp_per_stage() -> void:
	check_eq(Campaign.win_xp(0, 0), Campaign.WIN_XP_BASE, "1-1 gives the base XP")
	check_eq(Campaign.win_xp(6, 0), Campaign.WIN_XP_BASE * 7, "7-1 gives seven times that")
	check(Campaign.win_xp(1, 10) > Campaign.win_xp(0, 10), "a zone 2 stage beats the same zone 1 stage")
	check_eq(Campaign.loss_xp(3), Campaign.LOSS_XP * 4, "losses scale too")
	var p = Profile.new_game(T0)
	for z in 2:
		for i in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, i)] = 3
	p.add_copies(["laser"])
	var r: Dictionary = Campaign.finish(p, 2, 0, "laser", _win())
	check_eq(r.xp, Campaign.win_xp(2, 0), "a win pays its zone's XP")


func test_a_picked_campaign_team_fights_in_its_order() -> void:
	var p = Profile.new_game(T0)
	p.add_copies(["laser", "frost", "vampire"])
	p.campaign_team = ["frost", "laser"]
	check_eq(Campaign.team_for(p, 2), ["frost", "laser"], "your pair, in your order")
	var trio := Campaign.team_for(p, 3)
	check_eq(trio.slice(0, 2), ["frost", "laser"], "a trio keeps your picks first")
	check_eq(trio.size(), 3, "and fills the gap with your strongest")
	var back = Profile.from_dict(p.to_dict(), T0)
	check_eq(back.campaign_team, ["frost", "laser"], "the team is saved")
