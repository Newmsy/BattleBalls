extends "res://tests/test_case.gd"
## 2v2: four balls in the arena at once (p3 joins p1's team, p4 joins p2's).

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Lineup := preload("res://sim/lineup.gd")
const Arenas := preload("res://sim/arenas.gd")


func _cfg(s: int) -> Dictionary:
	return {"seed": s, "p1": "vampire", "p2": "laser", "p3": "honey", "p4": "magnet", "angles": [-450, null]}


func test_four_balls_on_two_teams() -> void:
	var sim := MatchSim.new(_cfg(1))
	check_eq(sim.balls.size(), 4, "four balls")
	check_eq(sim.starters, 4, "four starters")
	check_eq(sim.balls.map(func(b): return b.team), [0, 1, 0, 1], "p3 with p1, p4 with p2")
	check_eq(sim.balls.map(func(b): return b.type_id), ["vampire", "laser", "honey", "magnet"], "types")
	for i in 4:
		check_eq(sim.balls[i].pos, MatchSim.TEAM_STARTS[i], "start %d" % i)
	check_eq(sim.launch_angles[0], -450, "your aim")


func test_starts_are_point_symmetric() -> void:
	var c := Vector2.ONE * MatchSim.ARENA_SIZE
	check_eq(MatchSim.TEAM_STARTS[0] + MatchSim.TEAM_STARTS[1], c, "leads")
	check_eq(MatchSim.TEAM_STARTS[2] + MatchSim.TEAM_STARTS[3], c, "mates")


func test_duo_is_deterministic_and_ends() -> void:
	for s in [1, 5, 42]:
		var a := MatchSim.new(_cfg(s)).run_to_end()
		check_eq(a, MatchSim.new(_cfg(s)).run_to_end(), "seed %d" % s)
		check(a.reason in ["knockout", "double_knockout", "time_limit"], "ends: %s" % a.reason)


func test_teammates_never_hurt_each_other() -> void:
	for s in 6:
		var sim := MatchSim.new(_cfg(s))
		while not sim.finished:
			sim.step()
			for e in sim.events:
				if e.type == "damage" and e.source != e.target:
					check(sim.balls[e.source].team != sim.balls[e.target].team, "friendly fire on seed %d" % s)


func test_a_team_wins_only_when_both_foes_are_down() -> void:
	for s in 10:
		var sim := MatchSim.new(_cfg(s))
		sim.run_to_end()
		if sim.end_reason != "knockout":
			continue
		var loser := 1 - sim.winner
		for b in sim.balls:
			if b.team == loser:
				check(not b.alive(), "seed %d: a loser still standing" % s)


func test_tiered_lineup_fills_all_four() -> void:
	var cfg := {"seed": 3, "p1": "vampire", "p2": "laser"}
	for i in 4:
		Lineup.apply(cfg, i, Lineup.make(BallDefs.PLAYABLE[i], 3 if i % 2 == 0 else 1))
	check_eq(cfg.tiers, [3, 1, 3, 1], "tiers")
	var sim := MatchSim.new(cfg)
	check_eq(sim.balls.size(), 4, "four balls")
	check(sim.balls[2].type_id == BallDefs.PLAYABLE[2], "mate type")


func test_every_arena_runs_a_duo() -> void:
	for id in Arenas.PLAYABLE:
		var cfg := _cfg(7)
		cfg.arena = id
		var sim := MatchSim.new(cfg)
		for b in sim.balls:
			for o in sim.obstacles():
				check(b.pos.distance_to(o.pos) > o.radius + b.radius, "%s: ball %d starts inside an obstacle" % [id, b.index])
		var r := sim.run_to_end()
		check(r.ticks > 0, id)
