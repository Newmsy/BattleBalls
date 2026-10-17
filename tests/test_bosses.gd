## Farming bosses (sim/bosses.gd, design/bosses.md): anchored set pieces with
## their own scripts, fought in a normal MatchSim.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Bosses := preload("res://sim/bosses.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")
const Profile := preload("res://meta/profile.gd")
const Economy := preload("res://meta/economy.gd")


func _cfg(p1: String, seed_value := 3, boss := "anvil_king") -> Dictionary:
	return {"seed": seed_value, "p1": p1, "p2": boss, "arena": Bosses.DEFS[boss].arena, "angles": [null, null]}


func test_boss_never_moves() -> void:
	var sim := MatchSim.new(_cfg("juggernaut"))
	var start: Vector2 = sim.balls[1].pos
	var bounced := false
	while not sim.finished:
		sim.step()
		bounced = bounced or sim.events.any(func(e): return e.type == "collide")
		check(sim.balls[1].pos == start, "pinned at tick %d" % sim.tick)
		if sim.balls[1].pos != start:
			break
	check(bounced, "the critter bumped into it")


func test_every_critter_finishes_a_boss_fight() -> void:
	for boss in Bosses.DEFS:
		for id in BallDefs.PLAYABLE:
			var s := MatchSim.new(_cfg(id, 11, boss)).run_to_end()
			check(s.reason != "", "%s vs %s has a result" % [id, boss])
			check(s.time <= Bosses.DEFS[boss].time + 0.05, "%s vs %s ends on the boss clock" % [id, boss])


func test_boss_wins_when_its_clock_runs_out() -> void:
	var sim := MatchSim.new(_cfg("plain"))
	sim.balls[0].max_hp = 9999.0
	sim.balls[0].hp = 9999.0
	sim.balls[0].contact_damage = 0.0 # It can't hurt the boss either.
	var s := sim.run_to_end()
	check_eq(s.winner, 1, "the boss outlasted you")
	check_eq(s.reason, "time_limit")


func test_stun_cancels_a_slam() -> void:
	var sim := MatchSim.new(_cfg("plain"))
	while not sim.balls[1].state.has("act"):
		sim.step()
	check_eq(sim.balls[1].state.act.kind, "slam", "the first swing is a slam")
	var shots := sim.shots.size()
	sim.stun(sim.balls[0], sim.balls[1], 0.3)
	sim.step()
	check(not sim.balls[1].state.has("act"), "wind-up cancelled")
	check_eq(sim.shots.size(), shots - 1, "the hammer is gone")
	check(sim.events.any(func(e): return e.type == "boss_fizzle"), "it fizzles")


func test_boss_fights_replay() -> void:
	var cfg := _cfg("laser", 21)
	cfg.angles = [300, null]
	cfg.powers = [1.6, 1.9]
	check_eq(MatchSim.new(cfg).run_to_end(), MatchSim.new(cfg).run_to_end(), "same config, same fight")


func test_boss_maps_stay_out_of_the_picker() -> void:
	for id in Arenas.BOSS_ARENAS:
		check(not Arenas.DEFS.has(id) and id not in Arenas.PLAYABLE, "%s is a boss map only" % id)
		check(Arenas.get_def(id).has("min_half"), "%s keeps room around its boss in overtime" % id)
	for boss in Bosses.DEFS:
		check(Arenas.BOSS_ARENAS.has(Bosses.DEFS[boss].arena), "%s has its own map" % boss)


func test_old_saves_get_starter_hammers() -> void:
	var p = Profile.new_game(1_800_000_000)
	check_eq(p.hammers, Economy.STARTER_HAMMERS, "new players start with hammers")
	var d: Dictionary = p.to_dict()
	d.erase("hammers")
	check_eq(Profile.from_dict(d, 1_800_000_000).hammers, Economy.STARTER_HAMMERS, "a save from before hammers gets them once")
	p.hammers = 3
	check_eq(Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), 1_800_000_000).hammers, 3, "hammers save")


func test_brood_queen_lays_eggs_that_hatch_or_crack() -> void:
	var sim := MatchSim.new(_cfg("plain", 5, "brood_queen"))
	sim.balls[0].contact_damage = 0.0
	var egg = null
	while egg == null and sim.tick < 600:
		sim.step()
		for m in sim.balls:
			if m.def.get("minion", false):
				egg = m
	check(egg != null, "she lays an egg")
	if egg == null:
		return
	check(egg.anchored, "eggs sit still")
	var start: Vector2 = egg.pos
	var hatched := false
	while not sim.finished and sim.tick < 1200 and not hatched:
		sim.step()
		hatched = egg.type_id == "brood_chick"
		if not hatched:
			check(egg.pos == start, "an egg never moves")
	check(hatched and not egg.anchored and egg.speed > 0.0, "it hatches into a chick that runs about")
	# Cracking: break the next egg before it hatches.
	var next = null
	while next == null and sim.tick < 2400 and not sim.finished:
		sim.step()
		for m in sim.balls:
			if m.type_id == "brood_egg" and m.alive():
				next = m
	if next != null:
		sim.deal(sim.balls[0], next, 999.0, "test")
		sim.step()
		sim.step()
		check_eq(sim.balls[1].state.cracked, 1, "a cracked egg counts")


func test_minions_never_keep_a_boss_fight_going() -> void:
	var sim := MatchSim.new(_cfg("plain", 5, "brood_queen"))
	for i in 400:
		sim.step()
	check(sim.balls.size() > 2, "eggs are out")
	sim.deal(sim.balls[0], sim.balls[1], 9999.0, "test")
	sim.step()
	check(sim.finished and sim.winner == 0, "the queen down wins it, eggs and all")


func test_brood_queen_pays_orbs_and_an_egg_bonus() -> void:
	var BroodNest = load("res://meta/brood_nest.gd")
	var Zones = load("res://meta/zones.gd")
	var p = Profile.new_game(1_800_000_000)
	check_eq(BroodNest.start(p, 0, "vampire", 1_800_000_000).get("error"), "locked", "locked before zone 2")
	for z in 2:
		for i in Zones.zone(z).stages.size():
			p.stars[Zones.stage_key(z, i)] = 3
	var cfg: Dictionary = BroodNest.start(p, 2, "vampire", 1_800_000_000)
	check_eq(cfg.get("p2"), "brood_queen", "she's the boss")
	var orbs: int = p.orbs
	var r: Dictionary = BroodNest.finish(p, 2, "vampire", {"winner": 0, "hp": [10.0, 0.0], "time": 20.0, "max_hp": 50.0, "cracked": 7}, 1_800_000_000)
	check_eq(r.orbs, BroodNest.DIFFICULTIES[2].orbs + BroodNest.BONUS_MAX, "Elite plus the capped egg bonus")
	check_eq(p.orbs - orbs, r.orbs, "orbs land")
	check_eq(BroodNest.runs_left(p, 1_800_000_000), BroodNest.RUNS_PER_DAY - 1, "a run used")
