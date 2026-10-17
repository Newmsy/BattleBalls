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
