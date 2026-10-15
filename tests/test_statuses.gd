## Batch D statuses: stun (freeze), vulnerable and timed slows, and the
## critters built on them (gumdrop, pucker, zapper, frostfang, painter,
## beacon, bonbon, mammoth, stormwing).
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")


func _sim(p1 := "plain", p2 := "plain", tiers := [1, 1]) -> MatchSim:
	return MatchSim.new({"seed": 1, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false, "tiers": tiers})


## Parks both balls far apart and motionless so a test can stage one event.
func _park(sim: MatchSim) -> void:
	sim.balls[0].pos = Vector2(250, 500)
	sim.balls[1].pos = Vector2(750, 500)
	for b in sim.balls:
		b.vel = Vector2.ZERO


## Sets the two balls up to collide head-on on the next step.
func _ram(sim: MatchSim) -> void:
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)


func test_stun_holds_a_ball_still_then_grants_immunity() -> void:
	var sim := _sim()
	var a := sim.balls[0]
	var b := sim.balls[1]
	b.pos = Vector2(500, 500)
	b.vel = Vector2(b.speed, 0)
	check(sim.stun(a, b, 5.0), "stun lands")
	check_eq(b.stun_until, MatchSim.TICK_RATE * MatchSim.STUN_MAX, "stun is capped at STUN_MAX")
	sim.step()
	check_eq(b.pos, Vector2(500, 500), "a stunned ball doesn't move")
	check(not sim.stun(a, b, 0.3), "no stun while stunned")
	for i in int(MatchSim.STUN_MAX * MatchSim.TICK_RATE):
		sim.step()
	check(not sim.stunned(b), "the stun wears off")
	check(b.pos.x > 500.0, "it moves again")
	check(not sim.stun(a, b, 0.3), "immune right after a stun")
	sim.tick = b.stun_immune_until
	check(sim.stun(a, b, 0.3), "stunnable again after the immunity window")


func test_vulnerable_scales_damage_taken_and_is_capped() -> void:
	var sim := _sim()
	_park(sim)
	var a := sim.balls[0]
	var b := sim.balls[1]
	sim.add_status(a, b, "x", "vulnerable", 0.2, 2.0)
	sim.deal(a, b, 10.0, "test")
	sim.step()
	check_near(b.hp, 100.0 - 12.0, 0.001, "+20% damage taken")
	sim.add_status(a, b, "y", "vulnerable", 0.4, 2.0)
	check_near(sim.vulnerable(b), MatchSim.VULNERABLE_CAP, 0.001, "sources add up to the cap")
	sim.tick += 2 * MatchSim.TICK_RATE
	check_near(sim.vulnerable(b), 0.0, 0.001, "statuses expire")


func test_timed_slow_cuts_movement() -> void:
	var sim := _sim()
	var a := sim.balls[0]
	var b := sim.balls[1]
	b.pos = Vector2(500, 500)
	b.vel = Vector2(b.speed, 0)
	sim.add_status(a, b, "s", "slow", 0.5, 1.0)
	sim.step()
	check_near(b.pos.x, 500.0 + b.speed * MatchSim.DT * 0.5, 0.001, "moves at half speed")


func test_statuses_leave_old_hashes_alone() -> void:
	var s1 := _sim("vampire", "laser")
	var s2 := _sim("vampire", "laser")
	s2.balls[1].statuses = {}
	check_eq(s1.state_hash(), s2.state_hash(), "unused statuses don't change the hash")
	s2.stun(s2.balls[0], s2.balls[1], 0.3)
	check(s1.state_hash() != s2.state_hash(), "a stun shows in the hash")


func test_gumdrop_hits_slow_and_stack_at_t5() -> void:
	var sim := _sim("gumdrop", "plain")
	_ram(sim)
	sim.step()
	check_near(sim.status_amount(sim.balls[1], "slow"), 0.25, 0.001, "T1 slow")
	var t5 := _sim("gumdrop", "plain", [5, 1])
	_ram(t5)
	t5.step()
	t5.tick += MatchSim.TICK_RATE
	_ram(t5)
	t5.step()
	check_near(t5.status_amount(t5.balls[1], "slow"), 0.45, 0.001, "two stacks reach the 45% cap")
	check(not t5.balls[1].dots.is_empty(), "T3+ goo burns")


func test_pucker_makes_the_foe_sour_and_stacks_at_t3() -> void:
	var sim := _sim("pucker", "plain")
	_ram(sim)
	sim.step()
	check_near(sim.vulnerable(sim.balls[1]), 0.15, 0.001, "T1 +15%")
	var t3 := _sim("pucker", "plain", [3, 1])
	_ram(t3)
	t3.step()
	t3.tick += MatchSim.TICK_RATE
	_ram(t3)
	t3.step()
	check_near(t3.vulnerable(t3.balls[1]), 0.25, 0.001, "repeat hits stack to +25%")


func test_zapper_zaps_and_stuns_on_its_timer() -> void:
	var sim := _sim("zapper", "plain")
	_park(sim)
	var p := sim.balls[1]
	var hp := p.hp
	sim.tick = int(4.5 * MatchSim.TICK_RATE)
	sim.step()
	sim.step()
	check_near(p.hp, hp - 4.0, 0.001, "zap damage")
	check(p.stun_until > 0, "zap stuns")


func test_frostfang_freezes_on_the_third_hit() -> void:
	var sim := _sim("frostfang", "plain")
	var p := sim.balls[1]
	for k in 3:
		sim.tick += MatchSim.TICK_RATE
		_ram(sim)
		sim.step()
		if k < 2:
			check_near(sim.status_amount(p, "slow"), 0.1 * (k + 1), 0.001, "frost stacks")
	check(sim.stunned(p), "third hit freezes")
	check_near(sim.status_amount(p, "slow"), 0.0, 0.001, "frost resets")


func test_painter_paint_makes_foes_vulnerable() -> void:
	var sim := _sim("painter", "plain")
	_park(sim)
	sim.step()
	var p := sim.balls[1]
	p.pos = sim.balls[0].pos
	sim.balls[0].pos = Vector2(250, 250)
	sim.deal(sim.balls[0], p, 10.0, "test")
	sim.step()
	check_near(p.hp, 100.0 - 11.0, 0.001, "on paint: +10% damage")
	p.pos = Vector2(750, 750)
	sim.step()
	check_near(sim.vulnerable(p), 0.0, 0.001, "off paint at T1: no linger")


func test_beacon_beam_lights_the_foe_up() -> void:
	var sim := _sim("beacon", "plain")
	var bc := sim.balls[0]
	var p := sim.balls[1]
	bc.pos = Vector2(200, 500)
	bc.vel = Vector2(bc.speed, 0)
	p.pos = Vector2(700, 500)
	p.vel = Vector2.ZERO
	p.speed = 0.0
	sim.tick = int(4.0 * MatchSim.TICK_RATE)
	sim.step()
	sim.step()
	check(p.hp < 100.0, "the beam hits")
	check_near(sim.vulnerable(p), 0.2, 0.001, "lit foes take +20%")


func test_bonbon_wraps_holds_and_softens() -> void:
	var sim := _sim("bonbon", "plain")
	_park(sim)
	var p := sim.balls[1]
	sim.tick = int(6.0 * MatchSim.TICK_RATE)
	sim.step()
	check(sim.stunned(p), "wrapped foes are held")
	check_near(sim.vulnerable(p), 0.2, 0.001, "and take +20%")
	sim.tick += int(2.3 * MatchSim.TICK_RATE)
	check_near(sim.vulnerable(p), 0.2, 0.001, "for 2s after the pop")


func test_mammoth_slam_freezes_and_shatters_at_t5() -> void:
	var sim := _sim("mammoth", "plain", [5, 1])
	var m := sim.balls[0]
	var p := sim.balls[1]
	m.pos = Vector2(800, 500)
	p.pos = Vector2(800 + m.radius + p.radius - 1.0, 500)
	m.vel = Vector2(m.speed, 0)
	p.vel = Vector2(-p.speed, 0)
	var froze := false
	for i in 30:
		sim.step()
		froze = froze or sim.stunned(p)
	check(froze, "a shoved foe that slams the wall freezes")
	check(sim.zones.any(func(z): return z.kind == "ice"), "T3+ leaves an icy patch")


func test_stormwing_spends_sparks_as_lightning() -> void:
	var sim := _sim("stormwing", "plain")
	var s := sim.balls[0]
	s.state.sparks = [Vector2(0, 300), Vector2(1000, 300)]
	_ram(sim)
	sim.step()
	check(sim.stunned(sim.balls[1]), "the hit stuns")
	check_eq(sim.beams.size(), 2, "one beam per spark")
	check(s.state.sparks.is_empty(), "sparks are spent")
