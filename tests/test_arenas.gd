extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")
const Weight := preload("res://sim/weight.gd")
const CritterDb := preload("res://sim/critter_db.gd")


func _sim(arena: String, p1 := "plain", p2 := "plain", seed_value := 1) -> MatchSim:
	return MatchSim.new({"seek": 0.0, "seed": seed_value, "p1": p1, "p2": p2, "angles": [null, null], "arena": arena})


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
		var wells: Array = Arenas.get_def(id).get("wells", [])
		for w in wells:
			var mirrored: Vector2 = c * 2.0 - w.pos
			var found := wells.any(func(v): return v.pos.distance_to(mirrored) < 0.01 and v.reach == w.reach and v.accel == w.accel)
			check(found, "%s well at %s has no mirror at %s" % [id, w.pos, mirrored])
		var floors: Array = Arenas.get_def(id).get("floors", [])
		for f in floors:
			var here: Vector2 = f.rect.get_center() if f.has("rect") else f.pos
			var mirrored: Vector2 = c * 2.0 - here
			var found := floors.any(func(g):
				var there: Vector2 = g.rect.get_center() if g.has("rect") else g.pos
				return g.kind == f.kind and there.distance_to(mirrored) < 0.01 and (not f.has("dir") or g.dir.is_equal_approx(-f.dir)))
			check(found, "%s %s floor at %s has no mirror" % [id, f.kind, here])
		var cores: Array = Arenas.get_def(id).get("cores", [])
		for k in cores:
			var mirrored: Vector2 = c * 2.0 - k.pos
			check(cores.any(func(v): return v.pos.distance_to(mirrored) < 0.01 and v.radius == k.radius and v.get("kind", "core") == k.get("kind", "core")), "%s core at %s has no mirror" % [id, k.pos])


func test_starts_are_clear_of_every_obstacle_and_corner() -> void:
	var biggest := 0.0
	for id in BallDefs.DEFS:
		biggest = maxf(biggest, BallDefs.get_def(id).radius)
	for id in Arenas.DEFS:
		var sim := _sim(id)
		for start in MatchSim.start_positions(2, sim.arena):
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
	# Each critter against itself or one of its next two neighbours in the
	# list (which one turns with the map), one seed per arena, so the cost
	# grows with roster + maps, not their product.
	var ids: Array = BallDefs.PLAYABLE
	for k in Arenas.PLAYABLE.size():
		var id: String = Arenas.PLAYABLE[k]
		for i in ids.size():
			for step in [k % 3]:
				var a: String = ids[i]
				var b: String = ids[(i + step) % ids.size()]
				for seed_value in [k]:
					var s := _sim(id, a, b, seed_value).run_to_end()
					check(s.time <= MatchSim.TIME_LIMIT + 0.001, "%s %s vs %s seed %d ran past the limit" % [id, a, b, seed_value])
					check(s.reason != "", "%s %s vs %s seed %d has no result" % [id, a, b, seed_value])


func test_sided_arenas_are_point_symmetric_and_contain_the_starts() -> void:
	for id in Arenas.DEFS:
		var def: Dictionary = Arenas.get_def(id)
		if not def.has("sides"):
			continue
		check(int(def.sides.n) % 2 == 0, "%s has an even number of sides" % id)
		var sim := _sim(id)
		var outline := sim.arena_outline()
		check(outline.size() >= 4, "%s has an outline" % id)
		for p in outline:
			check(outline.has(sim.centre * 2.0 - p) or Array(outline).any(func(q): return q.distance_to(sim.centre * 2.0 - p) < 0.01), "%s outline point %s has a mirror" % [id, p])
		for start in MatchSim.start_positions(2, def):
			check(Geometry2D.is_point_in_polygon(start, outline), "%s start %s inside the walls" % [id, start])


func test_a_side_wall_reflects_like_a_cut_corner() -> void:
	var sim := _sim("temple")
	_park(sim)
	var b := sim.balls[0]
	b.pos = Vector2(120, 500) # Just inside the left side wall (460 from the centre).
	b.vel = Vector2.LEFT * b.speed
	var bounced := false
	for i in 30:
		sim.step()
		if b.vel.x > 0.0:
			bounced = true
			break
	check(bounced, "the hexagon's side turns the ball back")
	check(b.pos.x >= 500.0 - 460.0 + b.radius - 1.0, "and keeps it inside (x %.1f)" % b.pos.x)


func test_starts_are_outside_every_well() -> void:
	for id in Arenas.DEFS:
		var sim := _sim(id)
		for start in MatchSim.start_positions(2, sim.arena):
			for w in sim.wells():
				check(start.distance_to(w.pos) >= w.reach + 60.0, "%s start %s inside a well" % [id, start])


## How far a ball heading past a well at (320, 320) is bent in 40 ticks.
func _bend(critter: String) -> float:
	var sim := MatchSim.new({"seed": 1, "p1": critter, "p2": "plain", "angles": [null, null], "arena": "wells"})
	_park(sim)
	sim.balls[1].pos = Vector2(850, 150)
	var b := sim.balls[0]
	b.pos = Vector2(150, 480)
	b.vel = Vector2.RIGHT * b.speed
	for i in 40:
		sim.step()
	return absf(b.vel.angle())


func test_wells_bend_paths_and_light_critters_most() -> void:
	var light := _bend("bubbles")
	var plain := _bend("plain")
	var heavy := _bend("juggernaut")
	check(plain > 0.05, "a well bends a passing ball (%.3f rad)" % plain)
	check(light > plain and plain > heavy, "lighter bends more: bubbles %.3f, plain %.3f, boulder %.3f" % [light, plain, heavy])
	var square := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null]})
	check(square.wells().is_empty(), "no wells on the square")


func test_wells_keep_speed_and_fade_in_overtime() -> void:
	var sim := _sim("wells")
	_park(sim)
	var b := sim.balls[0]
	b.pos = Vector2(150, 480)
	b.vel = Vector2.RIGHT * b.speed
	for i in 40:
		sim.step()
	check_near(b.vel.length(), b.speed, 0.01, "a well turns, never speeds up")
	sim.half_size = MatchSim.ARENA_SIZE / 2.0 * (MatchSim.OBSTACLE_MIN_SCALE - 0.01)
	check(sim.wells().is_empty(), "wells gone near the end of the squeeze")


func test_weight_table() -> void:
	for id in Weight.OVERRIDES:
		check(CritterDb.has(id), "weight override for unknown critter %s" % id)
	check_eq(Weight.of("plain"), 1.0, "Plain weighs 1")
	check_eq(Weight.of("dummy"), 1.0, "tutorial foes weigh 1")
	check(Weight.of("bubbles") < Weight.of("plain") and Weight.of("plain") < Weight.of("juggernaut"), "bubbles < plain < boulder")
	check(Weight.of("plain", 1.3) > Weight.of("plain"), "bigger is heavier")
	for id in CritterDb.ids():
		var w := Weight.of(id)
		check(w >= Weight.MIN and w <= Weight.MAX, "%s weight %s in range" % [id, w])
	var sim := MatchSim.new({"seed": 1, "p1": "bubbles", "p2": "juggernaut", "angles": [null, null]})
	check(sim.balls[0].weight < sim.balls[1].weight, "balls carry their weight")


func test_a_spike_post_nicks_with_a_cooldown_and_a_cap() -> void:
	var sim := _sim("spikes")
	_park(sim)
	sim.balls[1].pos = Vector2(850, 850)
	var b := sim.balls[0]
	b.pos = Vector2(500, 150)
	b.vel = Vector2.DOWN * b.speed
	var spiked := 0
	for i in 40:
		sim.step()
		spiked += sim.events.filter(func(e): return e.type == "spike" and e.ball == 0).size()
		if spiked > 0:
			break
	check_eq(spiked, 1, "one spike hit off the post")
	check(b.vel.y < 0.0, "bounced back off the post")
	check_near(b.hp, b.max_hp - MatchSim.SPIKE_DAMAGE, 0.001, "small flat damage, no rolls")
	check_eq(b.damage_dealt, 0.0, "spikes credit nobody")
	check_eq(sim.balls[1].damage_dealt, 0.0, "not even the foe")
	# Bouncing on the post again and again stops hurting at the cap.
	for i in 20:
		b.spike_ready = 0
		sim._spike(b, b.pos)
	sim._apply_hits(sim._hits)
	check_near(b.max_hp - b.hp, MatchSim.HAZARD_CAP * b.max_hp, 0.01, "capped at HAZARD_CAP of max HP")


func test_spiked_walls_only_in_the_middle() -> void:
	var sim := _sim("spikes")
	_park(sim)
	var b := sim.balls[0]
	b.pos = Vector2(120, 500)
	b.vel = Vector2.LEFT * b.speed
	var hit := false
	for i in 20:
		sim.step()
		hit = hit or sim.events.any(func(e): return e.type == "spike")
	check(hit, "the middle of the left wall is spiked")
	var safe := _sim("spikes")
	_park(safe)
	safe.balls[1].pos = Vector2(500, 850)
	var c := safe.balls[0]
	c.pos = Vector2(120, 200)
	c.vel = Vector2.LEFT * c.speed
	var spiked := false
	for i in 20:
		safe.step()
		spiked = spiked or safe.events.any(func(e): return e.type == "spike")
	check(not spiked, "the ends of the wall are safe")


func test_starts_are_off_every_floor_pad() -> void:
	for id in Arenas.DEFS:
		var sim := _sim(id)
		for start in MatchSim.start_positions(2, sim.arena):
			for f in sim.floors():
				check(not MatchSim.on_floor(f, start, 45.0), "%s start %s on a %s pad" % [id, start, f.kind])


func test_every_playable_arena_has_a_theme_and_pick_is_seeded() -> void:
	var Theme = load("res://game/arena_theme.gd")
	for id in Arenas.PLAYABLE:
		check(Theme.THEMES.has(id), "%s has a theme" % id)
	var seen := {}
	for seed_value in 400:
		var id := Arenas.pick(seed_value)
		check(id in Arenas.PLAYABLE, "pick gives a playable arena")
		check_eq(Arenas.pick(seed_value), id, "same seed, same map")
		seen[id] = true
	check(seen.size() >= Arenas.PLAYABLE.size() - 2, "picks spread over the pool (%d maps seen)" % seen.size())


## A ball parked on one side, flying `dir` from `pos` on `arena`.
func _runner(arena: String, critter: String, pos: Vector2, dir: Vector2) -> MatchSim:
	var sim := MatchSim.new({"seek": 0.0, "seed": 1, "p1": critter, "p2": "plain", "angles": [null, null], "arena": arena})
	_park(sim)
	sim.balls[1].pos = Vector2(880, 120) if pos.y > 500 else Vector2(880, 880)
	var b := sim.balls[0]
	b.pos = pos
	b.vel = dir * b.speed
	return sim


func test_ice_speeds_up_then_lets_go() -> void:
	var sim := _runner("frost", "plain", Vector2(500, 330), Vector2.DOWN)
	var b := sim.balls[0]
	sim.step()
	check_near(b.vel.length(), b.speed * MatchSim.ICE_SPEED, 0.01, "faster on the ice")
	for i in 60:
		sim.step()
	check(not MatchSim.on_floor(sim.floors()[0], b.pos, b.radius * 0.5) or b.vel.length() > b.speed, "consistent")
	sim.balls[0].pos = Vector2(150, 150)
	sim.step()
	check_near(b.vel.length(), b.speed, 0.01, "normal speed off the ice")


func test_goo_slows_and_lava_burns_within_the_hazard_cap() -> void:
	var goo := _runner("hive", "plain", Vector2(300, 300), Vector2.RIGHT)
	var before := goo.balls[0].pos
	goo.step()
	check_near(goo.balls[0].pos.distance_to(before), goo.balls[0].speed * MatchSim.DT * 0.65, 0.01, "honey slows 35%")
	var lava := _runner("magma", "plain", Vector2(160, 160), Vector2.RIGHT)
	var b := lava.balls[0]
	for i in 600:
		b.pos = Vector2(160, 160)
		lava.step()
	check_near(b.max_hp - b.hp, MatchSim.HAZARD_CAP * b.max_hp, 0.01, "lava stops at the hazard cap")


func test_conveyors_carry_light_critters_furthest() -> void:
	var drift := {}
	for critter in ["bubbles", "plain", "juggernaut"]:
		var sim := _runner("factory", critter, Vector2(300, 320), Vector2.DOWN)
		for i in 8:
			sim.step()
		drift[critter] = sim.balls[0].vel.x
	check(drift.plain > 0.0, "the top belt pushes right")
	check(drift.bubbles > drift.plain and drift.plain > drift.juggernaut, "lighter drifts more: %s" % drift)


func test_portals_send_a_ball_across_with_its_velocity() -> void:
	var sim := _runner("arcade", "plain", Vector2(240, 500), Vector2.LEFT)
	var b := sim.balls[0]
	var went := false
	for i in 30:
		sim.step()
		if sim.events.any(func(e): return e.type == "portal"):
			went = true
			break
	check(went, "the ball took the portal")
	check(b.pos.x > 700.0, "came out on the right")
	check(b.vel.x < 0.0, "still heading left")
	for i in 5:
		sim.step()
	check(not sim.events.any(func(e): return e.type == "portal"), "no instant bounce back")


func test_orbiting_moons_move_and_starfall_shrinks_early() -> void:
	var sim := _sim("orbit")
	var start: Vector2 = sim.obstacles()[0].pos
	for i in 60:
		sim.step()
	check(sim.obstacles()[0].pos.distance_to(start) > 50.0, "moons move")
	check_near(sim.obstacles()[0].pos.distance_to(sim.centre), start.distance_to(sim.centre), 0.5, "on a circle round the centre")
	var star := _sim("starfall", "plain", "plain", 3)
	var plain := _sim("square", "plain", "plain", 3)
	for i in 20 * MatchSim.TICK_RATE:
		star.step()
		plain.step()
		if star.finished or plain.finished:
			break
	check(star.half_size < MatchSim.ARENA_SIZE / 2.0, "Starfall Rim closes in by 20s")
	check_eq(plain.half_size, MatchSim.ARENA_SIZE / 2.0, "the square doesn't")
	check(not star.in_overtime(), "but overtime damage waits")


func test_ghost_arena_and_spire_fights_carry_their_map() -> void:
	var Relay = load("res://sim/relay.gd")
	var r = Relay.new({"seed": 5, "sides": [["plain"], ["plain"]], "arena": "magma"})
	check_eq(r.leg_config().arena, "magma", "relay legs fight on the relay's map")
	var Spire = load("res://sim/spire.gd")
	var spec: Dictionary = Spire.floor_def(0, 3)
	check(spec.arena in Arenas.PLAYABLE, "spire floors roll a map")
	check_eq(Spire.relay_config(spec, [{"id": "plain", "power": 1.0}]).arena, spec.arena, "and fight on it")


func test_a_power_core_overcharges_its_taker_then_goes_dark() -> void:
	var sim := MatchSim.new({"seek": 0.0, "seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null], "arena": "arcane", "damage_rolls": false})
	_park(sim)
	check(not sim.cores()[0].lit, "dark at kick-off")
	while sim.tick < int(MatchSim.CORE_FIRST * MatchSim.TICK_RATE):
		sim.step()
	check(sim.cores()[0].lit, "lights after CORE_FIRST")
	var b := sim.balls[0]
	b.pos = Vector2(500, 500)
	sim.step()
	check(sim.events.any(func(e): return e.type == "core" and e.ball == 0), "ball 0 takes it")
	check(sim.overcharged(b) and not sim.overcharged(sim.balls[1]), "only the taker is overcharged")
	check(not sim.cores()[0].lit, "the core goes dark")
	check_near(sim.cores()[0].ready_in, MatchSim.CORE_RESPAWN, 0.05, "for CORE_RESPAWN seconds")
	var foe := sim.balls[1]
	var hp := foe.hp
	sim.add_hit(b, foe, 10.0, "beam", foe.pos)
	sim.step()
	check_near(hp - foe.hp, 10.0 * MatchSim.OVERCHARGE_ABILITY, 0.01, "ability damage is boosted")
	for i in int(MatchSim.OVERCHARGE_SECS * MatchSim.TICK_RATE):
		sim.step()
	check(not sim.overcharged(b), "Overcharge wears off")
	b.pos = Vector2(500, 150)
	for i in int(MatchSim.CORE_RESPAWN * MatchSim.TICK_RATE):
		sim.step()
	check(sim.cores()[0].lit, "lights again")


func test_every_critter_gets_something_from_a_core() -> void:
	# Vampire has no bounce or timed ability, so it gets a Core Nova; Beacon's
	# timed ability fires instead. Both move faster and hit harder for a while.
	for p1 in ["vampire", "beacon"]:
		var sim := _sim("arcane", p1)
		_park(sim)
		while sim.tick < int(MatchSim.CORE_FIRST * MatchSim.TICK_RATE):
			sim.step()
		var b := sim.balls[0]
		var speed := b.speed
		var contact := b.contact_damage
		var foe := sim.balls[1]
		foe.pos = Vector2(500, 620)
		var hp := foe.hp
		b.pos = Vector2(500, 500)
		b.vel = Vector2.ZERO
		sim.step()
		var nova := sim.events.any(func(e): return e.type == "pulse" and e.get("kind", "") == "core_nova")
		check_eq(nova, p1 == "vampire", "%s: a Core Nova only when no ability fires" % p1)
		if p1 == "vampire":
			check(foe.hp < hp and foe.vel.y > 0.0, "the nova nicks and knocks back a foe close by")
		check_near(b.speed, speed * MatchSim.OVERCHARGE_SPEED, 0.01, "%s moves faster" % p1)
		check_near(b.contact_damage, contact * MatchSim.OVERCHARGE_CONTACT, 0.01, "%s bumps harder" % p1)
		for i in int(MatchSim.OVERCHARGE_SECS * MatchSim.TICK_RATE):
			sim.step()
		check_near(b.speed, speed, 0.01, "%s's speed is back to normal" % p1)


func test_a_core_reached_together_overcharges_both() -> void:
	var sim := _sim("nebula")
	_park(sim)
	while sim.tick < int(MatchSim.CORE_FIRST * MatchSim.TICK_RATE):
		sim.step()
	sim.balls[0].pos = Vector2(470, 530)
	sim.balls[1].pos = Vector2(530, 470)
	sim.step()
	check(sim.overcharged(sim.balls[0]) and sim.overcharged(sim.balls[1]), "a dead heat is shared")


func test_crystals_crack_shatter_nick_and_grow_back() -> void:
	var sim := _runner("prism", "plain", Vector2(320, 330), Vector2.DOWN)
	var count := func() -> int: return sim.obstacles().filter(func(o): return o.kind == "crystal").size()
	check_eq(count.call(), 2, "two crystals")
	var cracked := false
	for i in 40:
		sim.step()
		if sim.events.any(func(e): return e.type == "crystal_crack"):
			cracked = true
			break
	check(cracked, "a bounce cracks it")
	var foe := sim.balls[1]
	foe.pos = Vector2(320, 620)
	sim.balls[0].pos = Vector2(150, 150)
	sim.balls[0].vel = Vector2.ZERO
	var idx: int = sim.obstacles().filter(func(o): return o.kind == "crystal" and o.pos.x < 500)[0].crystal
	var hp := foe.hp
	sim.crack_crystal(idx, sim.balls[0], Vector2(320, 500))
	sim.crack_crystal(idx, sim.balls[0], Vector2(320, 500))
	check_eq(count.call(), 1, "the third crack shatters it")
	sim.step()
	check(foe.hp < hp, "shards nick the breaker's foe")
	for i in int(MatchSim.CRYSTAL_REGROW * MatchSim.TICK_RATE) + 2:
		sim.step()
	check_eq(count.call(), 2, "and it grows back")


func test_a_launch_pad_flies_over_balls_and_lands_with_a_pulse() -> void:
	var sim := _runner("toybox", "plain", Vector2(500, 700), Vector2.DOWN)
	var foe := sim.balls[1]
	foe.pos = Vector2(500, 900)
	var b := sim.balls[0]
	var flew := false
	var bumped := false
	var landed := false
	for i in 90:
		sim.step()
		flew = flew or sim.airborne(b)
		if sim.airborne(b) and sim.events.any(func(e): return e.type == "collide"):
			bumped = true
		if sim.events.any(func(e): return e.type == "pulse" and e.kind == "land"):
			landed = true
			break
	check(flew, "the pad throws it")
	check(not bumped, "it flies over the other ball")
	check(landed, "and lands with a pulse")


## Every moving part, sampled over the first minute: the map stays
## point-symmetric, the starts stay clear and parts never come close enough
## to a wall or each other to pin the biggest ball.
func test_moving_parts_stay_symmetric_and_clear() -> void:
	var biggest := 0.0
	for id in BallDefs.DEFS:
		biggest = maxf(biggest, BallDefs.get_def(id).radius)
	var moving := 0
	for id in Arenas.PLAYABLE:
		var sim := _sim(id)
		if not sim.obstacles().any(func(o): return o.has("vel")):
			continue
		moving += 1
		for t in range(0, 60 * MatchSim.TICK_RATE, 7):
			sim.tick = t
			var obs := sim.obstacles()
			for o in obs:
				var mirrored: Vector2 = sim.centre * 2.0 - o.pos
				check(obs.any(func(q): return q.pos.distance_to(mirrored) < 0.01 and q.radius == o.radius), "%s part at %s has no mirror at tick %d" % [id, o.pos, t])
				for start in MatchSim.start_positions(2, sim.arena):
					check(start.distance_to(o.pos) - o.radius - biggest >= 40.0, "%s part sweeps over start %s at tick %d" % [id, start, t])
				if not o.has("vel"):
					continue
				check(o.vel.length() < 260.0, "%s part moves at %d u/s" % [id, o.vel.length()])
				var edge: float = minf(minf(o.pos.x, 1000.0 - o.pos.x), minf(o.pos.y, 1000.0 - o.pos.y)) - o.radius
				for wall in sim.corner_walls():
					edge = minf(edge, wall[0].dot(o.pos - sim.centre) + wall[1] - o.radius)
				check(edge > biggest * 2.0 or edge >= 140.0, "%s part at %s leaves a %d gap to the wall" % [id, o.pos, edge])
				for q in obs:
					if q == o or (q.has("bar") and o.has("bar") and q.bar == o.bar):
						continue
					var gap: float = q.pos.distance_to(o.pos) - q.radius - o.radius
					check(gap > biggest * 2.0 or gap >= 140.0, "%s parts at %s and %s leave a %d gap" % [id, o.pos, q.pos, gap])
	check(moving >= 5, "moving maps: %d" % moving)


func test_a_spinning_bar_bats_a_ball_and_counts_a_bounce() -> void:
	var sim := _sim("windmill")
	var bar := sim.obstacles().filter(func(o): return o.has("bar"))
	check(bar.size() > 10, "the sail is a row of circles")
	var tip: Vector2 = bar[-1].pos
	for i in 30:
		sim.step()
	check(sim.obstacles().filter(func(o): return o.has("bar"))[-1].pos.distance_to(tip) > 20.0, "the sail turns")
	# A still ball in the sail's path gets batted off at its own speed.
	sim = _sim("windmill")
	_park(sim)
	var b := sim.balls[0]
	b.pos = Vector2(620, 440) # Just ahead of the sail sweeping round clockwise (y down).
	b.vel = Vector2(-1, 0) * 400.0
	var hit := false
	for i in 60:
		sim.step()
		if sim.events.any(func(e): return e.type == "bounce" and e.ball == 0):
			hit = true
			break
	check(hit, "the sail counts as a bounce")
	check_near(b.vel.length(), 400.0, 1.0, "a batted ball keeps its speed")


func test_heal_and_shield_pickups() -> void:
	var sim := MatchSim.new({"seek": 0.0, "seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null], "arena": "windmill", "damage_rolls": false})
	_park(sim)
	var kinds := sim.cores().map(func(c): return c.kind)
	check(kinds.has("heal"), "Windmill Hill has heal pickups")
	while sim.tick < int(MatchSim.CORE_FIRST * MatchSim.TICK_RATE):
		sim.step()
	var b := sim.balls[0]
	b.hp = b.max_hp * 0.5
	b.pos = Vector2(140, 500)
	sim.step()
	check_near(b.hp, b.max_hp * (0.5 + MatchSim.HEAL_PICKUP), 0.01, "a heal pickup heals")
	check(sim.events.any(func(e): return e.type == "pickup" and e.kind == "heal"), "and says so")
	check(not sim.cores()[0].lit, "then goes dark")
	check(not sim.overcharged(b), "no Overcharge from a heal")
	# Haunted Manor's wards are shields.
	sim = MatchSim.new({"seek": 0.0, "seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null], "arena": "manor", "damage_rolls": false})
	sim.balls[0].pos = Vector2(150, 150) # Clear of the mirrors.
	sim.balls[1].pos = Vector2(850, 850)
	for p in sim.balls:
		p.vel = Vector2.ZERO
	check(sim.cores().any(func(c): return c.kind == "shield"), "Haunted Manor has shield pickups")
	while sim.tick < int(MatchSim.CORE_FIRST * MatchSim.TICK_RATE):
		sim.step()
	b = sim.balls[0]
	b.pos = Vector2(320, 320)
	sim.step()
	check_near(b.shield, b.max_hp * MatchSim.SHIELD_PICKUP, 0.01, "a shield pickup shields")
