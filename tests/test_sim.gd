extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


## Damage rolls are off so mechanics tests can check exact numbers;
## test_damage.gd covers the rolls.
func _sim(p1 := "plain", p2 := "plain", seed_value := 1) -> MatchSim:
	return MatchSim.new({"seed": seed_value, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false})


## Parks both balls far apart and motionless so a test can stage one event.
func _park(sim: MatchSim) -> void:
	sim.balls[0].pos = Vector2(200, 200)
	sim.balls[1].pos = Vector2(800, 800)
	for b in sim.balls:
		b.vel = Vector2.ZERO


func test_rng_is_repeatable() -> void:
	var a := Rng.new(42)
	var b := Rng.new(42)
	var c := Rng.new(43)
	var same := true
	var differs := false
	for i in 100:
		var x := a.next_u32()
		same = same and x == b.next_u32()
		differs = differs or x != c.next_u32()
	check(same, "same seed should give the same sequence")
	check(differs, "different seeds should give different sequences")


func test_rng_range_stays_in_bounds() -> void:
	var r := Rng.new(7)
	for i in 1000:
		var v := r.range_int(-3, 3)
		check(v >= -3 and v <= 3, "range_int out of bounds: %d" % v)
		var f := r.next_float()
		check(f >= 0.0 and f < 1.0, "next_float out of bounds: %f" % f)


func test_wall_bounce_reflects_and_keeps_speed() -> void:
	var sim := _sim()
	_park(sim)
	var b := sim.balls[0]
	b.pos = Vector2(b.radius + 2.0, 500)
	b.vel = Vector2(-400, 100)
	sim.step()
	check(b.vel.x > 0.0, "x velocity should flip after hitting the left wall")
	check_near(b.vel.y, 100.0, 0.001, "y velocity unchanged")
	check(b.pos.x - b.radius >= 0.0, "ball must stay inside the arena")
	check(sim.events.any(func(e): return e.type == "bounce"), "bounce event emitted")


func test_ball_collision_keeps_each_ball_at_its_own_speed() -> void:
	var sim := _sim("vampire", "laser")
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 2.0, 510)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)
	sim.step()
	check_near(a.vel.length(), a.speed, 0.01, "vampire speed")
	check_near(b.vel.length(), b.speed, 0.01, "laser speed")
	check(a.vel.x < 0.0 and b.vel.x > 0.0, "balls should bounce apart")


func test_contact_damage_hits_both_balls_once_per_cooldown() -> void:
	var sim := _sim("plain", "plain")
	var a := sim.balls[0]
	var b := sim.balls[1]
	var dmg: float = BallDefs.get_def("plain").contact_damage
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)
	sim.step()
	check_near(a.hp, 100.0 - dmg, 0.001, "first ball hp")
	check_near(b.hp, 100.0 - dmg, 0.001, "second ball hp")
	# Force them straight back together inside the cooldown window.
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)
	b.pos = a.pos + Vector2(a.radius + b.radius - 1.0, 0)
	sim.step()
	check_near(a.hp, 100.0 - dmg, 0.001, "no second hit inside cooldown")


func test_vampire_heals_half_of_damage_dealt() -> void:
	var sim := _sim("vampire", "plain")
	var v := sim.balls[0]
	var p := sim.balls[1]
	var vdef := BallDefs.get_def("vampire")
	var pdef := BallDefs.get_def("plain")
	v.hp = 50.0
	v.pos = Vector2(400, 500)
	p.pos = Vector2(400 + v.radius + p.radius - 1.0, 500)
	v.vel = Vector2(v.speed, 0)
	p.vel = Vector2(-p.speed, 0)
	sim.step()
	var expected: float = 50.0 - pdef.contact_damage + vdef.contact_damage * vdef.heal_ratio
	check_near(v.hp, expected, 0.001, "vampire hp after trade")
	check_near(p.hp, 100.0 - vdef.contact_damage, 0.001, "victim hp")


func test_vampire_heal_is_capped_at_max_hp() -> void:
	var sim := _sim("vampire", "laser")
	var v := sim.balls[0]
	sim.balls[1].contact_damage = 0.0
	v.pos = Vector2(400, 500)
	sim.balls[1].pos = Vector2(400 + v.radius + sim.balls[1].radius - 1.0, 500)
	v.vel = Vector2(v.speed, 0)
	sim.balls[1].vel = Vector2(-sim.balls[1].speed, 0)
	sim.step()
	check_near(v.hp, v.max_hp, 0.001, "full hp vampire stays at max")


func test_lethal_hit_cannot_be_out_healed() -> void:
	var sim := _sim("vampire", "plain")
	var v := sim.balls[0]
	var p := sim.balls[1]
	v.hp = 1.0
	v.pos = Vector2(400, 500)
	p.pos = Vector2(400 + v.radius + p.radius - 1.0, 500)
	v.vel = Vector2(v.speed, 0)
	p.vel = Vector2(-p.speed, 0)
	sim.step()
	check(not v.alive(), "vampire should die despite healing")
	check(sim.finished, "match should end")
	check_eq(sim.winner, 1, "plain wins")


func test_laser_fires_beam_from_second_bounce() -> void:
	var sim := _sim("laser", "plain")
	var l := sim.balls[0]
	sim._on_wall_bounce(l, Vector2(0, 300))
	check_eq(sim.beams.size(), 0, "no beam on first bounce")
	sim._on_wall_bounce(l, Vector2(400, 0))
	check_eq(sim.beams.size(), 1, "beam after second bounce")
	check_eq(sim.beams[0].a, Vector2(0, 300), "beam starts at previous bounce")
	check_eq(sim.beams[0].b, Vector2(400, 0), "beam ends at this bounce")


func test_laser_beam_count_is_capped() -> void:
	var sim := _sim("laser", "plain")
	var l := sim.balls[0]
	var cap: int = BallDefs.get_def("laser").beam_max
	for i in cap + 4:
		sim._on_wall_bounce(l, Vector2(0, 100) if i % 2 == 0 else Vector2(1000, 600))
	check_eq(sim.beams.size(), cap, "beam cap")


func test_beam_damages_enemy_with_cooldown_and_fades() -> void:
	var sim := _sim("laser", "plain")
	_park(sim)
	var ldef := BallDefs.get_def("laser")
	var target := sim.balls[1]
	target.pos = Vector2(500, 500)
	sim.balls[0].has_bounce = true
	sim.balls[0].last_bounce = Vector2(0, 500)
	sim._on_wall_bounce(sim.balls[0], Vector2(1000, 500))
	sim.step()
	check_near(target.hp, 100.0 - ldef.beam_damage, 0.001, "first beam hit")
	var cooldown_ticks := int(round(ldef.beam_hit_cooldown * MatchSim.TICK_RATE))
	for i in cooldown_ticks - 1:
		sim.step()
	check_near(target.hp, 100.0 - ldef.beam_damage, 0.001, "no hit during cooldown")
	sim.step()
	check_near(target.hp, 100.0 - 2.0 * ldef.beam_damage, 0.001, "second hit after cooldown")
	for i in int(ldef.beam_life * MatchSim.TICK_RATE):
		sim.step()
	check_eq(sim.beams.size(), 0, "beam fades after its lifetime")


func test_beam_never_hurts_its_owner() -> void:
	var sim := _sim("laser", "plain")
	_park(sim)
	var l := sim.balls[0]
	l.pos = Vector2(500, 500)
	l.has_bounce = true
	l.last_bounce = Vector2(0, 500)
	sim._on_wall_bounce(l, Vector2(1000, 500))
	for i in 60:
		sim.step()
	check_near(l.hp, 100.0, 0.001, "laser hp")


func test_overtime_shrinks_arena_and_ramps_damage() -> void:
	var sim := _sim()
	_park(sim)
	sim.tick = int(MatchSim.OVERTIME_START * MatchSim.TICK_RATE) - 1
	sim.step()
	check_near(sim.half_size, MatchSim.ARENA_SIZE / 2.0, 0.001, "no shrink before overtime")
	check_near(sim.damage_multiplier(), 1.0, 0.05, "no ramp at overtime start")
	for i in 10 * MatchSim.TICK_RATE:
		sim.step()
	check(sim.half_size < MatchSim.ARENA_SIZE / 2.0, "arena shrinks in overtime")
	check(sim.damage_multiplier() > 1.4, "damage ramps in overtime")
	for i in 60 * MatchSim.TICK_RATE:
		sim.step()
	check(sim.half_size >= MatchSim.MIN_HALF, "arena never shrinks below the minimum")
	for b in sim.balls:
		check(sim.arena_rect().grow(0.01).encloses(Rect2(b.pos - Vector2.ONE * b.radius, Vector2.ONE * b.radius * 2.0)), "balls stay inside the shrunk arena")


func test_double_knockout_goes_to_higher_hp_before_the_hit() -> void:
	var sim := _sim("plain", "plain")
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.hp = 3.0
	b.hp = 2.0
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)
	sim.step()
	check(sim.finished, "match ends")
	check_eq(sim.end_reason, "double_knockout")
	check_eq(sim.winner, 0, "ball with more hp going in wins")


func test_explicit_aim_is_used_and_keeps_rng_stream() -> void:
	var aimed := MatchSim.new({"seed": 9, "p1": "plain", "p2": "plain", "angles": [-300, null]})
	var free := MatchSim.new({"seed": 9, "p1": "plain", "p2": "plain", "angles": [null, null]})
	check_eq(aimed.launch_angles[0], -300, "player aim used")
	check_eq(aimed.launch_angles[1], free.launch_angles[1], "opponent aim unaffected by player aim")


func test_every_critter_always_finishes() -> void:
	# Each critter against itself and its next four neighbours, so the cost
	# grows with the roster rather than its square (the balance matrix covers
	# every pairing).
	var ids: Array = BallDefs.DEFS.keys()
	for i in ids.size():
		for step in 5:
			var a: String = ids[i]
			var b: String = ids[(i + step) % ids.size()]
			for seed_value in 4:
				var s := MatchSim.new({"seed": seed_value, "p1": a, "p2": b, "angles": [null, null]}).run_to_end()
				check(s.time <= MatchSim.TIME_LIMIT + 0.001, "%s vs %s seed %d ran past the limit" % [a, b, seed_value])
				check(s.reason != "", "%s vs %s seed %d has no result" % [a, b, seed_value])


func test_ramming_ball_deals_more_contact_damage() -> void:
	var sim := _sim("plain", "plain")
	var a := sim.balls[0]
	var b := sim.balls[1]
	var dmg: float = BallDefs.get_def("plain").contact_damage
	# a drives into b from behind while b moves away more slowly.
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(b.speed * 0.25, b.speed * 0.968)
	sim.step()
	check(100.0 - b.hp > 100.0 - a.hp, "rammed ball takes more damage")
	check_near((100.0 - a.hp) + (100.0 - b.hp), 2.0 * dmg, 0.001, "total contact damage unchanged")


func test_mirror_matches_rarely_draw() -> void:
	for id in BallDefs.PLAYABLE:
		var draws := 0
		for seed_value in 40:
			if MatchSim.new({"seed": seed_value, "p1": id, "p2": id, "angles": [null, null]}).run_to_end().winner == -1:
				draws += 1
		check(draws <= 2, "%s mirror drew %d of 40 fights" % [id, draws])


func test_magnet_pull_turns_the_foe_toward_it() -> void:
	var sim := _sim("magnet", "plain")
	_park(sim)
	var m := sim.balls[0]
	var foe := sim.balls[1]
	m.pos = Vector2(300, 500)
	foe.pos = Vector2(600, 500)
	foe.vel = Vector2(0, -400)
	sim.step()
	check(sim.balls[0].state.get("pulling", true), "the field starts on Pull")
	check(foe.vel.x < 0.0, "Pull steers the foe toward the magnet")
	check_near(foe.vel.length(), foe.speed, 0.001, "steering keeps the foe's speed")


func test_magnet_flips_to_a_weaker_push() -> void:
	var sim := _sim("magnet", "plain")
	_park(sim)
	var m := sim.balls[0]
	var foe := sim.balls[1]
	m.pos = Vector2(300, 500)
	foe.pos = Vector2(600, 500)
	sim.tick = int(m.def.field_period * MatchSim.TICK_RATE)
	foe.vel = Vector2(0, -400)
	sim.step()
	check(not m.state.pulling, "the field flips to Push after one period")
	check(sim.events.any(func(e): return e.type == "flip" and not e.pulling), "flip event emitted")
	var push_turn := foe.vel.x
	check(push_turn > 0.0, "Push steers the foe away")
	# Same setup on Pull: Push turns the foe less sharply.
	var pull_sim := _sim("magnet", "plain")
	_park(pull_sim)
	pull_sim.balls[0].pos = Vector2(300, 500)
	pull_sim.balls[1].pos = Vector2(600, 500)
	pull_sim.balls[1].vel = Vector2(0, -400)
	pull_sim.step()
	check(push_turn < absf(pull_sim.balls[1].vel.x), "Push is weaker than Pull")


func test_magnet_field_fades_out_of_range() -> void:
	var sim := _sim("magnet", "plain")
	_park(sim)
	var foe := sim.balls[1]
	sim.balls[0].pos = Vector2(150, 150)
	foe.pos = Vector2(850, 850)
	foe.vel = Vector2(0, -400)
	sim.step()
	check_near(foe.vel.x, 0.0, 0.0001, "no steering beyond field range")


## Rams the magnet into a parked plain ball and returns the damage dealt.
func _magnet_ram(sim: MatchSim) -> float:
	var m := sim.balls[0]
	var foe := sim.balls[1]
	m.pos = Vector2(400, 500)
	foe.pos = Vector2(400 + m.radius + foe.radius - 2.0, 500)
	m.vel = Vector2(400, 0)
	foe.vel = Vector2.ZERO
	var before := foe.hp
	sim.step()
	return before - foe.hp


func test_magnet_snaps_once_per_pull() -> void:
	var sim := _sim("magnet", "plain")
	_park(sim)
	var first := _magnet_ram(sim)
	check(sim.events.any(func(e): return e.type == "snap"), "first Pull hit snaps")
	sim._contact_cooldown_until.clear()
	var second := _magnet_ram(sim)
	check(not sim.events.any(func(e): return e.type == "snap"), "second hit in the same Pull does not snap")
	check_near(first, second * sim.balls[0].def.snap_mult, 0.01, "snap multiplies contact damage")
	# Push gives no snap; the next Pull re-arms it.
	sim._contact_cooldown_until.clear()
	sim.tick = int(sim.balls[0].def.field_period * MatchSim.TICK_RATE)
	_magnet_ram(sim)
	check(not sim.events.any(func(e): return e.type == "snap"), "no snap on Push")
	sim._contact_cooldown_until.clear()
	sim.tick = int(2 * sim.balls[0].def.field_period * MatchSim.TICK_RATE)
	_magnet_ram(sim)
	check(sim.events.any(func(e): return e.type == "snap"), "next Pull snaps again")
