## Batch F movement: teleport, charge, tether and timed slows, and the
## critters built on them (bolt, pixel, hook, puppeteer, pounce, sonar, mole,
## narwhal, gearbox, pinball).
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")


func _sim(p1 := "plain", p2 := "plain", tiers := [1, 1], seed := 1) -> MatchSim:
	return MatchSim.new({"rarity_potency": false, "seed": seed, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false, "tiers": tiers})


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


## Steps until the contact cooldown between the two balls has passed.
func _cool(sim: MatchSim) -> void:
	_park(sim)
	for i in int(MatchSim.CONTACT_COOLDOWN * MatchSim.TICK_RATE) + 1:
		sim.step()


func test_teleport_spot_is_open_far_from_the_foe_and_seeded() -> void:
	for seed in 20:
		var sim := _sim("plain", "plain", [1, 1], seed)
		var a := sim.balls[0]
		var spot := sim.teleport_spot(a, sim.balls[1].pos, 300.0)
		check(spot.distance_to(sim.balls[1].pos) >= 300.0, "seed %d: at least 300 from the foe" % seed)
		check(sim.arena_rect().grow(-a.radius).has_point(spot), "seed %d: inside the walls" % seed)
		var again := _sim("plain", "plain", [1, 1], seed)
		check_eq(again.teleport_spot(again.balls[0], again.balls[1].pos, 300.0), spot, "seed %d: same seed, same spot" % seed)
	var pillars := MatchSim.new({"rarity_potency": false, "seed": 3, "p1": "plain", "p2": "plain", "arena": "pillars"})
	for i in 30:
		var p := pillars.teleport_spot(pillars.balls[0], pillars.balls[1].pos, 250.0)
		for o in pillars.obstacles():
			check(p.distance_to(o.pos) > o.radius + pillars.balls[0].radius, "never lands in a pillar")


func test_a_charge_is_faster_for_its_time_and_survives_bounces() -> void:
	var sim := _sim()
	_park(sim)
	var a := sim.balls[0]
	a.pos = Vector2(200, 300)
	sim.charge(a, Vector2.LEFT, 2.0, 0.5)
	check_near(a.vel.length(), a.speed * 2.0, 0.01, "twice its speed")
	for i in 20:
		sim.step()
	check(a.vel.x > 0.0, "bounced off the left wall")
	check_near(a.vel.length(), a.speed * 2.0, 0.01, "still charging after the bounce")
	for i in 15:
		sim.step()
	check(not sim.charging(a), "the charge runs out after 0.5s")
	check_near(a.vel.length(), a.speed, 0.01, "back to its own speed")


func test_a_tether_drags_the_foe_and_stops_its_charge() -> void:
	var sim := _sim()
	_park(sim)
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.pos = Vector2(300, 500)
	b.pos = Vector2(500, 500)
	a.vel = Vector2(0, -a.speed)
	b.vel = Vector2(b.speed, 0)
	sim.tether(a, b, 100.0, 1.0)
	sim.charge(b, Vector2.RIGHT, 2.0, 2.0)
	for i in 50:
		sim.step()
		check(a.pos.distance_to(b.pos) <= a.radius + b.radius + 100.0 + 0.01, "tick %d: the string holds" % i)
	check(not sim.charging(b), "a tied ball can't charge")
	for i in 15:
		sim.step()
	check(sim.tethers.is_empty(), "the string ends after its time")


func test_a_timed_slow_wears_off() -> void:
	var sim := _sim()
	_park(sim)
	var b := sim.balls[1]
	b.vel = Vector2(0, b.speed)
	sim.slow_for(b, 0.5, 0.5)
	var y := b.pos.y
	sim.step()
	check_near(b.pos.y - y, b.speed * MatchSim.DT * 0.5, 0.01, "half speed while slowed")
	for i in 31:
		sim.step()
	y = b.pos.y
	sim.step()
	check_near(b.pos.y - y, b.speed * MatchSim.DT, 0.01, "full speed afterwards")


func test_bolt_teleports_after_every_second_hit() -> void:
	var sim := _sim("bolt")
	var a := sim.balls[0]
	_ram(sim)
	sim.step()
	check(not sim.events.any(func(e): return e.type == "teleport"), "no teleport on the first hit")
	_cool(sim)
	_ram(sim)
	sim.step()
	check(sim.events.any(func(e): return e.type == "teleport"), "teleports on the second hit")
	var gap := a.pos.distance_to(sim.balls[1].pos)
	check(gap >= a.radius + sim.balls[1].radius and gap <= a.radius + sim.balls[1].radius + a.def.blink_away + 1.0, "lands right behind the foe")
	check(a.vel.dot(sim.balls[1].pos - a.pos) > 0.0, "facing it")
	var t4 := _sim("bolt", "plain", [4, 1])
	_ram(t4)
	t4.step()
	check(t4.events.any(func(e): return e.type == "teleport"), "T4 teleports after every hit")


func test_pixel_blinks_and_leaves_a_bomb_where_it_was() -> void:
	var sim := _sim("pixel")
	_park(sim)
	var a := sim.balls[0]
	a.vel = Vector2(0, -a.speed)
	while sim.tick < int(5.0 * MatchSim.TICK_RATE):
		sim.step()
	var old := a.pos
	sim.step()
	check(sim.events.any(func(e): return e.type == "teleport"), "teleports at 5s")
	check(a.pos.distance_to(old) >= 250.0, "lands at least 250 away")
	var bombs := sim.zones.filter(func(z): return z.kind == "pixel")
	check_eq(bombs.size(), 1, "one bomb")
	check(bombs[0].pos.distance_to(old) < 20.0, "on the spot it left")
	var t5 := _sim("pixel", "plain", [5, 1])
	_park(t5)
	t5.balls[0].vel = Vector2(0, -t5.balls[0].speed)
	while t5.tick <= int(4.0 * MatchSim.TICK_RATE):
		t5.step()
	check_eq(t5.zones.filter(func(z): return z.kind == "pixel").size(), 3, "T5 leaves a line of 3")


func test_hook_yanks_the_foe_closer_but_never_into_itself() -> void:
	var sim := _sim("hook")
	_park(sim)
	var a := sim.balls[0]
	var b := sim.balls[1]
	var gap := a.pos.distance_to(b.pos)
	sim.abilities.fire(sim, "wall", a, {"point": a.pos})
	check_near(gap - a.pos.distance_to(b.pos), 220.0 * 0.25, 0.01, "220 pulls it 55 closer")
	b.pos = a.pos + Vector2(a.radius + b.radius + 10.0, 0)
	sim.abilities.fire(sim, "wall", a, {"point": a.pos})
	check(a.pos.distance_to(b.pos) >= a.radius + b.radius - 0.01, "stops at touching")


func test_puppeteer_strings_the_foe_on_a_hit_with_a_cooldown() -> void:
	var sim := _sim("puppeteer")
	_ram(sim)
	sim.step()
	check_eq(sim.tethers.size(), 1, "a hit ties a string")
	_cool(sim)
	for i in 70:
		sim.step()
	check(sim.tethers.is_empty(), "the string lasts about 1s")
	_ram(sim)
	sim.step()
	check(sim.tethers.is_empty(), "no new string inside the 5s cooldown")


func test_pounce_marks_its_attacker_pounces_and_hits_double() -> void:
	var sim := _sim("pounce")
	var a := sim.balls[0]
	var b := sim.balls[1]
	_ram(sim)
	sim.step()
	check(a.state.has("mark"), "being hurt marks the attacker")
	_park(sim)
	b.pos = Vector2(700, 300)
	var pounced := false
	for i in int(1.0 * MatchSim.TICK_RATE) + 1:
		sim.step()
		pounced = pounced or sim.events.any(func(e): return e.type == "charge" and e.ball == 0)
	check(pounced, "it pounces a second later")
	var hp := b.hp
	_ram(sim)
	sim.step()
	check_near(hp - b.hp, a.contact_damage * 2.0, 0.01, "its hit on the marked foe deals x2")
	check(not a.state.has("mark"), "the mark is spent")


func test_sonar_pings_on_a_bounce_swerving_and_slowing() -> void:
	var sim := _sim("sonar")
	_park(sim)
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.vel = Vector2(a.speed, 0)
	b.pos = a.pos + Vector2(150, 0)
	sim.abilities.fire(sim, "wall", a, {"point": a.pos})
	check(sim.charging(a), "swerves")
	check_near(a.vel.length(), a.speed * 1.4, 0.01, "+40% speed")
	check(b.slow_until > sim.tick, "the ping slows a foe in range")
	sim.abilities.fire(sim, "wall", a, {"point": a.pos})
	check_eq(sim.events.filter(func(e): return e.type == "pulse").size(), 1, "at most one ping a second")


func test_mole_digs_takes_less_damage_and_bursts_up() -> void:
	var sim := _sim("mole")
	_park(sim)
	var a := sim.balls[0]
	while sim.tick <= int(6.0 * MatchSim.TICK_RATE):
		sim.step()
	check(a.state.get("digging", false), "underground at 6s")
	var hp := a.hp
	sim.deal(sim.balls[1], a, 10.0, "test")
	sim.step()
	check_near(hp - a.hp, 3.0, 0.01, "takes 30% underground")
	var burst := false
	for i in int(1.0 * MatchSim.TICK_RATE) + 2:
		sim.step()
		burst = burst or sim.events.any(func(e): return e.type == "pulse" and e.get("kind") == "dirt")
	check(burst, "bursts up after a second")


func test_narwhal_charges_lays_a_lance_and_its_charge_hit_doubles() -> void:
	var sim := _sim("narwhal")
	_park(sim)
	var a := sim.balls[0]
	var b := sim.balls[1]
	b.pos.x = 650.0 # Within one charge's reach.
	sim.abilities.fx_lance(sim, a, {})
	check(sim.charging(a), "charges")
	check(a.vel.normalized().dot((b.pos - a.pos).normalized()) > 0.99, "straight at the foe")
	var hp := b.hp
	b.vel = Vector2.ZERO
	while sim.charging(a):
		sim.step()
	check(b.hp < hp, "the charge hit lands")
	check_near(hp - b.hp, a.contact_damage * (1.0 + MatchSim.IMPACT_SPREAD) * 2.0, 0.01, "x2, rammed at full share")
	sim.step()
	check(not sim.beams.is_empty(), "leaves a beam along its path")


func test_gearbox_shifts_up_then_slams_and_resets() -> void:
	var sim := _sim("gearbox")
	_park(sim)
	var a := sim.balls[0]
	a.vel = Vector2(0, a.speed)
	while sim.tick <= int(9.0 * MatchSim.TICK_RATE):
		sim.step()
	check_eq(a.state.get("gear", 0), 3, "top gear after 9s")
	check_near(a.speed, a.def.speed * 1.45, 0.01, "+15% a gear")
	var hp := sim.balls[1].hp
	_ram(sim)
	sim.step()
	check(sim.events.any(func(e): return e.type == "gear_slam"), "the top-gear hit slams")
	check(hp - sim.balls[1].hp > a.contact_damage * 1.9, "for about double")
	check_eq(a.state.get("gear", -1), 0, "and drops to first")


func test_pinball_cashes_in_its_walls_on_the_next_hit() -> void:
	var sim := _sim("pinball")
	var a := sim.balls[0]
	for i in 7:
		sim.abilities.fire(sim, "wall", a, {"point": a.pos})
	check_eq(a.state.lit, 5, "at most 5 bulbs")
	var hp := sim.balls[1].hp
	_ram(sim)
	sim.step()
	check_near(hp - sim.balls[1].hp, a.contact_damage + 5.0, 0.01, "+1 per wall")
	check_eq(a.state.lit, 0, "spent on the hit")


func test_movement_critters_replay_identically() -> void:
	for id in ["bolt", "pixel", "hook", "puppeteer", "pounce", "sonar", "mole", "narwhal", "gearbox", "pinball"]:
		for tier in [1, 5]:
			var cfg := {"seed": 77, "p1": id, "p2": "vampire", "tiers": [tier, 1]}
			check_eq(MatchSim.new(cfg).run_to_end().hash, MatchSim.new(cfg).run_to_end().hash, "%s T%d replays" % [id, tier])


func test_gentle_pull_curves_balls_toward_each_other_only_when_asked() -> void:
	for seek in [0.0, 400.0]:
		var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null], "damage_rolls": false, "seek": seek})
		sim.balls[0].pos = Vector2(250, 500)
		sim.balls[1].pos = Vector2(750, 300)
		sim.balls[0].vel = Vector2(0, 1) * sim.balls[0].current_speed()
		sim.balls[1].vel = Vector2(0, -1) * sim.balls[1].current_speed()
		var speed := sim.balls[0].vel.length()
		sim.step()
		var turned: bool = sim.balls[0].vel.x > 1.0
		check_eq(turned, seek > 0.0, "seek %d: ball 0 bends toward the foe" % seek)
		check_near(sim.balls[0].vel.length(), speed, 0.5, "and keeps its speed")


func test_a_slowed_ball_hits_softer_and_a_fast_one_no_harder() -> void:
	var sim := _sim()
	var b := sim.balls[0]
	check_near(sim._pace_scale(b), 1.0, 0.001, "normal speed: full damage")
	b.slow = 0.3
	check_near(sim._pace_scale(b), 0.7, 0.001, "30% slowed: 70%")
	b.slow = 0.0
	b.speed = b.def.speed * 1.5
	check_near(sim._pace_scale(b), 1.0, 0.001, "faster than normal: no bonus")
	b.stun_until = sim.tick + 10
	check_near(sim._pace_scale(b), sim.SLOW_HIT_FLOOR, 0.001, "frozen: the floor")
