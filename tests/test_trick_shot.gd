extends "res://tests/test_case.gd"

const TrickShot := preload("res://sim/trick_shot.gd")
const MatchSim := preload("res://sim/match_sim.gd")


func test_day_numbers_count_calendar_days() -> void:
	check_eq(TrickShot.day_number({"year": 2026, "month": 10, "day": 14}), 1, "launch day")
	check_eq(TrickShot.day_number({"year": 2026, "month": 10, "day": 15}), 2, "next day")
	check_eq(TrickShot.day_number({"year": 2027, "month": 1, "day": 1}), 80, "new year")
	check_eq(TrickShot.day_number({"year": 2027, "month": 10, "day": 14, "hour": 23}), 366, "a year on, late evening")


func test_puzzles_are_deterministic() -> void:
	check_eq(TrickShot.generate(7), TrickShot.generate(7), "same day, same puzzle")
	check(TrickShot.generate(7) != TrickShot.generate(8), "different days should differ")


## Every day of the first year is solvable, and nearly every day is fair (a
## few fallback days are tolerated so new balls don't break this test).
func test_every_day_is_fair() -> void:
	var unfair := []
	for day in range(1, 366):
		var p := TrickShot.generate(day)
		var n: int = p.solutions.size()
		check(n >= 1, "day %d has no solution" % day)
		if n < TrickShot.MIN_SOLUTIONS or n > TrickShot.MAX_SOLUTIONS:
			unfair.append(day)
		check(p.starts[0].distance_to(p.starts[1]) >= TrickShot.MIN_START_GAP, "day %d starts too close" % day)
		check(p.walls.size() >= 1 and p.walls.size() <= 3, "day %d calls %d walls" % [day, p.walls.size()])
	check(unfair.size() <= 5, "days without a fair puzzle: %s" % [unfair])


## The generator's fast replay must agree with the real sim on every aim.
func test_fast_judge_matches_the_sim() -> void:
	for day in range(1, 7):
		var p := TrickShot.generate(day)
		var mismatches := []
		for aim in 360:
			var real: String = TrickShot.judge(p, aim).result
			if TrickShot.fast_judge(p, aim) != real:
				mismatches.append("%d (sim says %s)" % [aim, real])
		check(mismatches.is_empty(), "day %d disagrees at aims %s" % [day, mismatches])


func test_a_solution_banks_off_the_called_walls() -> void:
	var p := TrickShot.generate(3)
	var shot := TrickShot.judge(p, p.solutions[0])
	check_eq(shot.result, TrickShot.SOLVED, "solution result")
	check_eq(shot.walls, p.walls, "walls bounced off")
	check(shot.time <= TrickShot.TIME_LIMIT, "hit in time")


func test_aiming_straight_at_the_foe_is_too_early() -> void:
	for day in range(1, 11):
		var p := TrickShot.generate(day)
		var to_foe: Vector2 = p.starts[1] - p.starts[0]
		var shot := TrickShot.judge(p, posmod(roundi(rad_to_deg(to_foe.angle())), 360))
		check_eq(shot.result, TrickShot.WRONG_WALLS, "day %d direct shot" % day)


func test_sim_start_positions_can_be_set() -> void:
	var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "starts": [Vector2(300, 400), Vector2(700, 600)]})
	check_eq(sim.balls[0].pos, Vector2(300, 400), "p1 start")
	check_eq(sim.balls[1].pos, Vector2(700, 600), "p2 start")


## Catches compile errors in the Trick Shot screen, which the sim tests don't load.
func test_trick_shot_scene_loads() -> void:
	var scene: PackedScene = load("res://game/trick_shot.tscn")
	check(scene != null and scene.can_instantiate(), "trick_shot.tscn should load")
	check(load("res://game/trick_shot.gd").can_instantiate(), "trick_shot.gd should compile")
