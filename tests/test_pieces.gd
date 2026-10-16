## Batch H: arena pieces (MatchSim.add_piece) and the critters that place
## them or run set pieces: Sprout, Ivy, Glacia, Old Oak, Clockwork, Foxfire,
## Jackpot, Disco, Ripple and Zigzag.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Abilities := preload("res://sim/abilities.gd")

const BATCH := ["sprout", "ivy", "glacia", "old_oak", "clockwork", "foxfire", "jackpot", "disco", "ripple", "zigzag"]


func _sim(p1: String, p2 := "plain", tiers := [1, 1]) -> MatchSim:
	return MatchSim.new({"seek": 0.0, "seed": 5, "p1": p1, "p2": p2, "angles": [0, 1800], "tiers": tiers, "damage_rolls": false})


## Parks both balls (zero speed keeps them put) so a test controls the geometry.
func _park(sim: MatchSim, a: Vector2, b: Vector2) -> void:
	sim.balls[0].pos = a
	sim.balls[1].pos = b
	for ball in sim.balls:
		ball.vel = Vector2.ZERO


func test_batch_is_live_and_replays_exactly() -> void:
	for id in BATCH:
		var a := MatchSim.new({"seed": 77, "p1": id, "p2": "vampire", "angles": [null, null]}).run_to_end()
		var b := MatchSim.new({"seed": 77, "p1": id, "p2": "vampire", "angles": [null, null]}).run_to_end()
		check_eq(a.hash, b.hash, id + " replays from the seed")
		var t5 := MatchSim.new({"seed": 78, "p1": id, "p2": "laser", "angles": [null, null], "tiers": [5, 1]}).run_to_end()
		check(t5.ticks > 0, id + " fights at T5")


func test_piece_waits_until_clear_then_blocks() -> void:
	var sim := _sim("plain")
	_park(sim, Vector2(500, 500), Vector2(820, 820))
	var p = sim.add_piece(sim.balls[0], Vector2(540, 500), {"radius": 30.0, "life": 2.0})
	sim.step()
	check(not p.blocking, "a piece under a ball doesn't block (it would shove the ball)")
	sim.balls[0].pos = Vector2(300, 300)
	sim.step()
	check(p.blocking, "it blocks once the ball has moved off it")
	check_eq(sim.obstacles().size(), 1, "a blocking piece is an obstacle")
	# A ball rolling into it bounces off.
	sim.balls[1].pos = Vector2(540, 620)
	sim.balls[1].vel = Vector2(0, -400)
	for i in 30:
		sim.step()
	check(sim.balls[1].vel.y > 0.0, "the ball bounced off the piece")
	for i in 120:
		sim.step()
	check(sim.pieces.is_empty(), "the piece is gone when its life runs out")


func test_piece_near_the_edge_snaps_onto_it() -> void:
	var sim := _sim("plain")
	var p = sim.add_piece(sim.balls[0], Vector2(80, 500), {"radius": 30.0})
	check_near(p.pos.x, 0.0, 0.01, "no ball-wide gap is left behind a pillar")
	var q = sim.add_piece(sim.balls[0], Vector2(500, 500), {"radius": 30.0})
	check_eq(q.pos, Vector2(500, 500), "a piece in the open stays put")


func test_sprout_plants_seeds_on_edge_bounces_only() -> void:
	var sim := _sim("sprout")
	sim.abilities.fire(sim, "wall", sim.balls[0], {"point": Vector2(0, 500)})
	check_eq(sim.pieces_of(sim.balls[0], "seed").size(), 1, "a wall bounce plants a seed")
	for y in [200, 300, 400, 600]:
		sim.abilities.fire(sim, "wall", sim.balls[0], {"point": Vector2(0, y)})
	check_eq(sim.pieces_of(sim.balls[0], "seed").size(), int(sim.balls[0].def.seed_max), "at most seed_max stand")
	var before := sim.pieces.size()
	sim.pieces[0].blocking = true
	sim.abilities.fire(sim, "wall", sim.balls[0], {"point": sim.pieces[0].pos + Vector2(sim.pieces[0].radius, 0)})
	check_eq(sim.pieces.size(), before, "bouncing off its own pillar plants nothing")


func test_ivy_lashes_the_foe_then_snaps() -> void:
	var sim := _sim("ivy")
	_park(sim, Vector2(200, 200), Vector2(600, 600))
	sim.balls[1].vel = Vector2(400, 0)
	sim.abilities.call("fx_vine", sim, sim.balls[0], {})
	var lash: Dictionary = sim.balls[0].state.lash
	var anchor: Vector2 = lash.anchors[0].piece.pos
	var length: float = lash.anchors[0].length
	var hp: float = sim.balls[1].hp
	for i in 50:
		sim.step()
		check(sim.balls[1].pos.distance_to(anchor) <= length + 8.0, "the lashed foe stays within its vine")
	for i in 20:
		sim.step()
	check(not sim.balls[0].state.has("lash"), "the vine snaps after the lash")
	check(sim.balls[1].hp < hp, "the snap bursts the foe")


func test_glacia_shards_fly_at_the_ring_centre() -> void:
	var sim := _sim("glacia")
	_park(sim, Vector2(150, 150), Vector2(500, 500))
	sim.abilities.call("fx_ice_ring", sim, sim.balls[0], {})
	check_eq(sim.pieces_of(sim.balls[0], "ice").size(), 5, "five ice pillars")
	var hp: float = sim.balls[1].hp
	for i in int(sim.balls[0].def.ring_life * 60.0) + 2:
		sim.step()
	check_near(hp - sim.balls[1].hp, sim.balls[0].def.shard_hits * sim.balls[0].def.shard_damage, 0.01, "shard_hits shards hit a foe that stayed in the middle")
	check(sim.pieces_of(sim.balls[0], "ice").is_empty(), "the ring has shattered")


func test_old_oak_takes_root_and_regrows() -> void:
	var sim := _sim("old_oak")
	_park(sim, Vector2(500, 500), Vector2(850, 850))
	var oak := sim.balls[0]
	oak.vel = Vector2(400, 0)
	oak.hp = oak.max_hp * 0.45
	sim.step()
	check_eq(sim.pieces_of(oak, "root").size(), 4, "four root pillars")
	var where := oak.pos
	var hp := oak.hp
	for i in 90:
		sim.step()
	check(oak.pos.distance_to(where) < 0.01, "taking root, it holds still")
	check_near(oak.hp - hp, 1.5 * oak.def.root_regen, 0.6, "it regrows root_regen HP a second")


func test_clockwork_rewinds_its_hp() -> void:
	var sim := _sim("clockwork")
	_park(sim, Vector2(200, 200), Vector2(800, 800))
	var cw := sim.balls[0]
	for i in 200:
		sim.step()
	cw.hp = cw.max_hp * 0.2
	sim.step()
	check_near(cw.hp, cw.max_hp * 0.2 + cw.max_hp * 0.8 * cw.def.rewind_share, 0.01, "rewind_share of the way back to its HP from 3s ago")
	cw.hp = cw.max_hp * 0.2
	sim.step()
	check_near(cw.hp, cw.max_hp * 0.2, 0.01, "the rewind happens once")


func test_foxfire_illusions_burst_when_touched() -> void:
	var sim := _sim("foxfire")
	_park(sim, Vector2(200, 200), Vector2(700, 700))
	sim.abilities.call("fx_illusions", sim, sim.balls[0], {})
	var ills := sim.pieces_of(sim.balls[0], "illusion")
	check_eq(ills.size(), 2, "two illusions")
	check(sim.obstacles().is_empty(), "illusions don't block")
	ills[0].vel = Vector2.ZERO
	ills[0].pos = sim.balls[1].pos + Vector2(60, 0)
	var hp: float = sim.balls[1].hp
	sim.step()
	sim.step()
	check_eq(sim.pieces_of(sim.balls[0], "illusion").size(), 1, "the touched illusion burst")
	check(sim.balls[1].hp < hp, "the burst hurt the foe")
	check(not sim.balls[1].dots.is_empty(), "and set it burning")


func test_jackpot_prizes_come_from_the_seed() -> void:
	var prizes := func(seed_value: int) -> Array:
		var out := []
		var sim := MatchSim.new({"seed": seed_value, "p1": "jackpot", "p2": "plain", "angles": [null, null], "tiers": [3, 1]})
		while not sim.finished and sim.tick < 60 * 60:
			sim.step()
			for e in sim.events:
				if e.type == "spin":
					out.append_array(e.prizes)
		return out
	check_eq(prizes.call(3), prizes.call(3), "the same seed spins the same prizes")
	var seen := {}
	for s in [1, 2, 3, 4, 5, 6]:
		for p in prizes.call(s):
			seen[p] = true
	check(seen.size() >= 3, "different seeds land different prizes: %s" % [seen.keys()])


func test_disco_rays_hit_and_slow() -> void:
	var sim := _sim("disco")
	_park(sim, Vector2(300, 500), Vector2(300 + 64 + 66 + 120, 500))
	sim.balls[0].state.flashes = -1 # The first flash then has a ray at angle 0.
	sim.abilities.call("fx_disco", sim, sim.balls[0], {})
	var hp: float = sim.balls[1].hp
	sim.step()
	check_near(hp - sim.balls[1].hp, sim.balls[0].def.disco_damage, 0.01, "a ray hits once")
	check_near(sim.balls[1].slow, sim.balls[0].def.disco_slow, 0.001, "and slows")


func test_ripple_runs_along_the_wall() -> void:
	var sim := _sim("ripple")
	_park(sim, Vector2(500, 934), Vector2(500, 300))
	sim.abilities.fire(sim, "wall", sim.balls[0], {"point": Vector2(500, 1000)})
	check_eq(sim.beams.size(), 2, "one ripple each way")
	for beam in sim.beams:
		check_near(beam.a.y, 1000.0, 0.01, "along the wall")
		check_near(beam.b.y, 1000.0, 0.01, "along the wall")
		check_near(absf(beam.b.x - beam.a.x), sim.balls[0].def.ripple_reach, 0.01, "ripple_reach long")


func test_ripple_t5_turns_corners() -> void:
	var sim := _sim("ripple", "plain", [5, 1])
	_park(sim, Vector2(900, 934), Vector2(500, 300))
	sim.abilities.fire(sim, "wall", sim.balls[0], {"point": Vector2(900, 1000)})
	var up := sim.beams.filter(func(b): return absf(b.a.x - 1000.0) < 0.01 and absf(b.b.x - 1000.0) < 0.01)
	check_eq(up.size(), 1, "the ripple that hit the corner runs up the next wall")


func test_zigzag_charges_its_path_after_a_hit() -> void:
	var sim := _sim("zigzag")
	var zz := sim.balls[0]
	zz.pos = Vector2(400, 500)
	sim.abilities.fire(sim, "hit", zz, {"target": sim.balls[1], "amount": 1.0, "heals": []})
	sim.abilities.fire(sim, "wall", zz, {"point": Vector2(1000, 500)})
	check_eq(sim.beams.size(), 1, "the path from the hit to the wall crackles")
	sim.abilities.fire(sim, "wall", zz, {"point": Vector2(1000, 800)})
	check_eq(sim.beams.size(), 1, "only until the next bounce at T1")


func test_timed_slows_expire() -> void:
	var sim := _sim("disco")
	Abilities.slow_for(sim, sim.balls[1], 0.3, 0.5)
	sim.step()
	check_near(sim.balls[1].slow, 0.3, 0.001, "slowed")
	for i in 40:
		sim.step()
	check_near(sim.balls[1].slow, 0.0, 0.001, "the slow wore off")
