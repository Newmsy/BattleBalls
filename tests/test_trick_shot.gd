extends "res://tests/test_case.gd"

const TrickShot := preload("res://sim/trick_shot.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const TrickReward := preload("res://meta/trick_reward.gd")
const Profile := preload("res://meta/profile.gd")
const Talents := preload("res://sim/talents.gd")


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
	for day in range(1, 13):
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


func test_aiming_straight_at_the_foe_never_solves() -> void:
	for day in range(1, 11):
		var p := TrickShot.generate(day)
		var to_foe: Vector2 = p.starts[1] - p.starts[0]
		var shot := TrickShot.judge(p, posmod(roundi(rad_to_deg(to_foe.angle())), 360))
		check(shot.result != TrickShot.SOLVED, "day %d direct shot solved it" % day)


## Pillars and bumpers: on the floor, clear of both starts and of each other.
func test_layouts_have_pieces_clear_of_the_starts() -> void:
	var with_pieces := 0
	var bumpers := 0
	for day in range(1, 61):
		var p := TrickShot.generate(day)
		with_pieces += 1 if not p.obstacles.is_empty() else 0
		for o in p.obstacles:
			bumpers += 1 if o.kind == "bumper" else 0
			for s in p.starts:
				check(s.distance_to(o.pos) >= o.radius + TrickShot.START_CLEARANCE, "day %d piece on a start" % day)
			for q in p.obstacles:
				if q != o:
					check(o.pos.distance_to(q.pos) >= o.radius + q.radius + TrickShot.GAP, "day %d pieces too close" % day)
	check(with_pieces >= 55, "most days have pieces (%d of 60)" % with_pieces)
	check(bumpers >= 10, "bumpers turn up (%d)" % bumpers)


## Each day draws its own pair from the whole roster.
func test_critters_vary_by_day() -> void:
	var shooters := {}
	for day in range(1, 41):
		var p := TrickShot.generate(day)
		check(p.p1 != p.p2, "day %d is a mirror" % day)
		check(p.p1 in TrickShot.critters() and p.p2 in TrickShot.critters(), "day %d critters live" % day)
		shooters[p.p1] = true
	check(shooters.size() >= 20, "only %d shooters in 40 days" % shooters.size())


func test_a_solve_pays_once_with_faction_xp() -> void:
	var profile = Profile.new_game(0)
	var coins: int = profile.coins
	var orbs: int = profile.orbs
	var fam := Talents.faction_of("drako")
	var xp: int = profile.faction_xp_rank(fam).xp
	var got := TrickReward.claim(profile, 5, 1, "drako")
	check(not got.is_empty(), "first solve pays")
	check_eq(profile.coins, coins + 150, "coins")
	check_eq(profile.orbs, orbs + 1, "an egg for a first-try solve")
	check(profile.faction_xp_rank(fam).xp > xp or profile.faction_xp_rank(fam).rank > 0, "shooter's faction XP")
	check(TrickReward.claim(profile, 5, 1, "drako").is_empty(), "same day pays once")
	check(TrickReward.claim(profile, 4, 1, "drako").is_empty(), "an older day doesn't pay")
	check_eq(Profile.from_dict(profile.to_dict(), 0).trick_reward, 5, "paid day saves")
	check(TrickReward.rewards(3, "drako").size() < TrickReward.rewards(1, "drako").size(), "fewer tries pay more")


func test_sim_start_positions_can_be_set() -> void:
	var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "starts": [Vector2(300, 400), Vector2(700, 600)]})
	check_eq(sim.balls[0].pos, Vector2(300, 400), "p1 start")
	check_eq(sim.balls[1].pos, Vector2(700, 600), "p2 start")


## Catches compile errors in the Trick Shot screen, which the sim tests don't load.
func test_trick_shot_scene_loads() -> void:
	var scene: PackedScene = load("res://game/trick_shot.tscn")
	check(scene != null and scene.can_instantiate(), "trick_shot.tscn should load")
	check(load("res://game/trick_shot.gd").can_instantiate(), "trick_shot.gd should compile")
