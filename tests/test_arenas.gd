extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")


func _sim(arena: String, p1 := "plain", p2 := "plain", seed_value := 1) -> MatchSim:
	return MatchSim.new({"seed": seed_value, "p1": p1, "p2": p2, "angles": [null, null], "arena": arena})


func _park(sim: MatchSim) -> void:
	sim.balls[0].pos = Vector2(500, 150)
	sim.balls[1].pos = Vector2(500, 850)
	for b in sim.balls:
		b.vel = Vector2.ZERO


func test_square_is_the_default_arena() -> void:
	var cfg := {"seed": 5, "p1": "vampire", "p2": "laser", "angles": [null, null]}
	var with_arena := cfg.duplicate()
	with_arena.arena = "square"
	check_eq(MatchSim.new(cfg).run_to_end().hash, MatchSim.new(with_arena).run_to_end().hash, "square matches the default")


func test_every_arena_is_point_symmetric() -> void:
	var c := Vector2(500, 500)
	for id in Arenas.DEFS:
		var obstacles: Array = Arenas.get_def(id).obstacles
		for o in obstacles:
			var mirrored: Vector2 = c * 2.0 - o.pos
			var found := obstacles.any(func(p): return p.pos.distance_to(mirrored) < 0.01 and p.radius == o.radius and p.kind == o.kind)
			check(found, "%s obstacle at %s has no mirror at %s" % [id, o.pos, mirrored])


func test_starts_are_clear_of_every_obstacle_and_corner() -> void:
	var biggest := 0.0
	for id in BallDefs.DEFS:
		biggest = maxf(biggest, BallDefs.get_def(id).radius)
	for id in Arenas.DEFS:
		var sim := _sim(id)
		for start in MatchSim.START_CORNERS:
			for o in sim.obstacles():
				check(start.distance_to(o.pos) - o.radius - biggest >= 40.0, "%s start %s too close to an obstacle" % [id, start])
			for wall in sim.corner_walls():
				check(wall[0].dot(start - sim.centre) + wall[1] >= biggest + 10.0, "%s start %s too close to a cut corner" % [id, start])


func test_cut_corner_reflects_and_counts_as_bounce() -> void:
	var sim := _sim("rink")
	_park(sim)
	var b := sim.balls[0]
	# Head straight into the top-left cut corner.
	b.pos = Vector2(200, 200)
	b.vel = Vector2(-1, -1).normalized() * b.speed
	var bounced := false
	for i in 60:
		sim.step()
		bounced = bounced or sim.events.any(func(e): return e.type == "bounce" and e.ball == 0)
		if bounced:
			break
	check(bounced, "ball should bounce off the cut corner")
	check(b.vel.x > 0.0 and b.vel.y > 0.0, "diagonal hit should send it straight back, got %s" % b.vel)
	check_near(b.vel.length(), b.speed, 0.001, "speed kept")
	for wall in sim.corner_walls():
		check(wall[0].dot(b.pos - sim.centre) + wall[1] >= b.radius - 0.001, "ball stays inside the octagon")


func test_pillar_bounce_counts_as_wall_bounce_for_laser() -> void:
	var sim := _sim("pillars", "laser", "plain")
	_park(sim)
	sim.balls[1].pos = Vector2(800, 850)
	var b := sim.balls[0]
	b.pos = Vector2(300, 650)
	b.vel = Vector2(0, -1) * b.speed
	b.has_bounce = true
	b.last_bounce = Vector2(300, 1000)
	var beam := false
	for i in 30:
		sim.step()
		beam = sim.events.any(func(e): return e.type == "beam" and e.owner == 0)
		if beam:
			break
	check(beam, "bouncing off a pillar should fire a beam")
	check(b.vel.y > 0.0, "ball reflected off the pillar")
	check(b.pos.distance_to(Vector2(300, 500)) >= b.radius + 60.0 - 0.001, "ball outside the pillar")


func test_bumper_boosts_speed_then_wears_off() -> void:
	var sim := _sim("bumpers")
	_park(sim)
	var b := sim.balls[0]
	b.pos = Vector2(500, 330)
	b.vel = Vector2(0, 1) * b.speed
	var boosted := false
	for i in 30:
		sim.step()
		if b.boost_ticks > 0:
			boosted = true
			break
	check(boosted, "bumper should boost the ball")
	check_near(b.vel.length(), b.speed * MatchSim.BUMPER_BOOST, 0.01, "boosted speed")
	for i in int(MatchSim.BUMPER_BOOST_TIME * MatchSim.TICK_RATE) + 2:
		sim.step()
	check_near(b.vel.length(), b.speed, 0.01, "speed back to normal after the boost")


func test_obstacles_shrink_then_vanish_in_overtime() -> void:
	var sim := _sim("pillars")
	check_eq(sim.obstacles().size(), 2, "two pillars at the start")
	sim.half_size = MatchSim.ARENA_SIZE / 2.0 * 0.8
	var first: Dictionary = sim.obstacles()[0]
	check(first.pos.distance_to(sim.centre) < Vector2(300, 500).distance_to(sim.centre), "pillars move toward the centre")
	check(first.radius < 60.0, "pillars shrink")
	sim.half_size = MatchSim.ARENA_SIZE / 2.0 * (MatchSim.OBSTACLE_MIN_SCALE - 0.01)
	check(sim.obstacles().is_empty(), "pillars gone near the end of the squeeze")


func test_mirror_fights_are_even_on_every_arena() -> void:
	# Same ball both sides: a symmetric arena gives neither corner an edge.
	for id in Arenas.PLAYABLE:
		var wins := [0, 0]
		for seed_value in 60:
			var s := _sim(id, "plain", "plain", seed_value).run_to_end()
			if s.winner >= 0:
				wins[s.winner] += 1
		var total: int = wins[0] + wins[1]
		check(total > 0 and absf(float(wins[0]) / total - 0.5) <= 0.2, "%s corner split %s" % [id, wins])


func test_every_critter_finishes_on_every_arena() -> void:
	# Each critter against itself and its next two neighbours in the list, so
	# the cost grows with the roster rather than its square.
	var ids: Array = BallDefs.PLAYABLE
	for id in Arenas.PLAYABLE:
		for i in ids.size():
			for step in 3:
				var a: String = ids[i]
				var b: String = ids[(i + step) % ids.size()]
				for seed_value in 3:
					var s := _sim(id, a, b, seed_value).run_to_end()
					check(s.time <= MatchSim.TIME_LIMIT + 0.001, "%s %s vs %s seed %d ran past the limit" % [id, a, b, seed_value])
					check(s.reason != "", "%s %s vs %s seed %d has no result" % [id, a, b, seed_value])
