## The projectile primitive (MatchSim.add_shot / add_lob) and the batch C
## critters built on it: Pip, Zing, Clam, Mortar, Pollen, Megabot, Brewster.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Gear := preload("res://sim/gear.gd")


func _sim(p1 := "plain", p2 := "plain", tiers := [1, 1]) -> MatchSim:
	return MatchSim.new({"seed": 3, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false, "tiers": tiers})


## Parks both balls far apart and motionless so a test can stage one event.
func _park(sim: MatchSim) -> void:
	sim.balls[0].pos = Vector2(200, 200)
	sim.balls[1].pos = Vector2(800, 800)
	for b in sim.balls:
		b.vel = Vector2.ZERO


func _steps(sim: MatchSim, n: int) -> void:
	for i in n:
		sim.step()


func test_straight_shot_hits_the_foe_once_and_never_its_owner() -> void:
	var sim := _sim()
	_park(sim)
	var foe := sim.balls[1]
	foe.pos = Vector2(600, 200)
	sim.add_shot(sim.balls[0], Vector2(300, 200), Vector2(600, 0), {"damage": 7.0})
	_steps(sim, 60)
	check_near(foe.hp, 93.0, 0.001, "one hit for its damage")
	check_eq(sim.shots.size(), 0, "the shot is spent")
	check_near(sim.balls[0].hp, 100.0, 0.001, "owner untouched")


func test_shot_bounces_then_vanishes_and_can_split() -> void:
	var sim := _sim()
	_park(sim)
	sim.add_shot(sim.balls[0], Vector2(900, 500), Vector2(600, 0), {"bounces": 1})
	_steps(sim, 20)
	check_eq(sim.shots.size(), 1, "bounced off the wall")
	check(sim.shots[0].vel.x < 0.0, "heading back")
	_steps(sim, 120)
	check_eq(sim.shots.size(), 0, "gone after the second wall")
	sim.add_shot(sim.balls[0], Vector2(900, 500), Vector2(600, 0), {"split": 3, "damage": 8.0})
	_steps(sim, 20)
	check_eq(sim.shots.size(), 3, "split into 3 off the wall")
	check_near(sim.shots[0].damage, 4.0, 0.001, "split shots hit for half")


func test_homing_shot_turns_toward_the_foe() -> void:
	var sim := _sim()
	_park(sim)
	sim.balls[1].pos = Vector2(500, 800)
	var s := sim.add_shot(sim.balls[0], Vector2(500, 200), Vector2(450, 0), {"homing": 3.0, "life": 5.0})
	_steps(sim, 20)
	check(s.vel.y > 0.0, "turned toward the foe below")
	check_near(s.vel.length(), 450.0, 0.01, "keeps its speed")


func test_slowing_shot_holds_the_foe_for_a_second() -> void:
	var sim := _sim()
	_park(sim)
	var foe := sim.balls[1]
	foe.pos = Vector2(400, 200)
	sim.add_shot(sim.balls[0], Vector2(300, 200), Vector2(600, 0), {"slow": 0.15})
	_steps(sim, 10)
	check(foe.state.has("shot_slow"), "slowed")
	sim.step()
	check_near(foe.slow, 0.15, 0.001, "slow applied before it moves")
	_steps(sim, MatchSim.TICK_RATE + 2)
	check(not foe.state.has("shot_slow"), "slow wears off")


func test_lob_lands_inside_the_arena_and_leaves_a_puddle() -> void:
	var sim := _sim()
	_park(sim)
	var foe := sim.balls[1]
	foe.pos = Vector2(500, 500)
	var s := sim.add_lob(sim.balls[0], Vector2(1400, 500), 1.0, {"damage": 12.0, "land_radius": 90.0})
	check(s.land.x < MatchSim.ARENA_SIZE, "landing kept inside")
	s.land = Vector2(500, 500)
	sim.add_lob(sim.balls[0], Vector2(500, 500), 1.0, {"zone": {"kind": "fire", "radius": 70.0, "life": 3.0, "dps": 4.0}})
	_steps(sim, MatchSim.TICK_RATE - 2)
	check_near(foe.hp, 100.0, 0.001, "nothing until it lands")
	for i in 5:
		if not sim.shots.is_empty():
			sim.step()
	check_near(foe.hp, 88.0, 0.001, "landing blast")
	check_eq(sim.zones.size(), 1, "puddle left behind")
	check_eq(sim.shots.size(), 0, "both landed")


func test_pip_spits_along_its_heading_and_t5_triples() -> void:
	var sim := _sim("pip", "plain")
	_park(sim)
	sim.balls[0].vel = Vector2(0, 400)
	var every := int(round(BallDefs.get_def("pip").fire_cooldown * MatchSim.TICK_RATE))
	_steps(sim, every + 1)
	check_eq(sim.shots.size(), 1, "one pea")
	check(sim.shots[0].vel.normalized().is_equal_approx(sim.balls[0].vel.normalized()), "along its heading")
	var t5 := _sim("pip", "plain", [5, 1])
	_park(t5)
	t5.balls[0].pos = Vector2(500, 500)
	t5.balls[0].vel = Vector2(0, 1)
	var volleys := 0
	for i in 3:
		volleys = t5.shots.size()
		t5.balls[0].state.erase("fire_ready")
		t5.abilities.fx_shoot(t5, t5.balls[0], {})
	check_eq(t5.shots.size() - volleys, 3, "every third shot is a triple")


func test_zing_bounce_fires_a_homing_stinger_at_the_foe() -> void:
	var sim := _sim("zing", "plain")
	_park(sim)
	sim._on_wall_bounce(sim.balls[0], Vector2(0, 200))
	check_eq(sim.shots.size(), 1, "one stinger")
	check(sim.shots[0].homing > 0.0, "it homes")
	check(sim.shots[0].vel.dot(sim.balls[1].pos - sim.balls[0].pos) > 0.0, "aimed at the foe")


func test_clam_shuts_for_armour_then_fires_its_pearl() -> void:
	var sim := _sim("clam", "plain")
	_park(sim)
	var c := sim.balls[0]
	var def := BallDefs.get_def("clam")
	sim.abilities.fx_shut(sim, c, {})
	sim.deal(sim.balls[1], c, 10.0, "contact")
	sim.step()
	check_near(c.hp, def.hp - 10.0 * (1.0 - def.shut_armor), 0.001, "shut takes less")
	check_eq(sim.shots.size(), 0, "no pearl while shut")
	_steps(sim, int(round(def.shut_secs * MatchSim.TICK_RATE)))
	check_eq(sim.shots.size(), 1, "pearl when it pops open")
	sim.deal(sim.balls[1], c, 10.0, "contact")
	var before := c.hp
	sim.step()
	check_near(c.hp, before - 10.0, 0.001, "open takes full damage")


func test_megabot_every_third_hit_fires_a_salvo_and_shields() -> void:
	var sim := _sim("megabot", "plain")
	_park(sim)
	var m := sim.balls[0]
	var def := BallDefs.get_def("megabot")
	for i in 2:
		sim.abilities.fire(sim, "hit", m, {"target": sim.balls[1], "amount": 1.0})
	check_eq(sim.shots.size(), 0, "no salvo yet")
	sim.abilities.fire(sim, "hit", m, {"target": sim.balls[1], "amount": 1.0})
	check_eq(sim.shots.size(), int(def.shot_count), "rockets on the 3rd hit")
	check_near(m.shield, def.salvo_shield, 0.001, "shield up")
	sim.shots.clear()
	_steps(sim, int(round(def.salvo_shield_secs * MatchSim.TICK_RATE)) + 1)
	check_near(m.shield, 0.0, 0.001, "shield drops after its time")


func test_megabot_mega_mode_counts_hits_double() -> void:
	var sim := _sim("megabot", "plain", [5, 1])
	_park(sim)
	var m := sim.balls[0]
	m.hp = m.max_hp * 0.25
	sim.step()
	check(m.state.has("mega_until"), "Mega Mode below 30% HP")
	sim.abilities.fire(sim, "hit", m, {"target": sim.balls[1], "amount": 1.0})
	sim.abilities.fire(sim, "hit", m, {"target": sim.balls[1], "amount": 1.0})
	check(sim.shots.size() > 0, "two hits fill the salvo")


func test_pollen_puffs_a_ring_of_seeds_with_a_cooldown() -> void:
	var sim := _sim("pollen", "plain")
	_park(sim)
	var p := sim.balls[0]
	sim.deal(sim.balls[1], p, 5.0, "contact")
	sim.step()
	check_eq(sim.shots.size(), int(BallDefs.get_def("pollen").shot_count), "a ring of seeds")
	sim.deal(sim.balls[1], p, 5.0, "contact")
	sim.step()
	check_eq(sim.shots.size(), int(BallDefs.get_def("pollen").shot_count), "cooldown holds the next puff")


func test_mortar_leads_the_foe() -> void:
	var sim := _sim("mortar", "plain")
	_park(sim)
	sim.balls[1].pos = Vector2(500, 500)
	sim.balls[1].vel = Vector2(100, 0)
	sim.abilities.fx_lob(sim, sim.balls[0], {})
	check_eq(sim.shots.size(), 1, "one shell")
	check(sim.shots[0].land.is_equal_approx(Vector2(600, 500)), "lands where the foe will be")


func test_brewster_puddles_land_near_the_foe_and_alternate() -> void:
	var sim := _sim("brewster", "plain")
	_park(sim)
	var foe := sim.balls[1]
	foe.pos = Vector2(500, 500)
	var def := BallDefs.get_def("brewster")
	sim.abilities.fx_brew(sim, sim.balls[0], {})
	check_eq(sim.shots.size(), int(def.brew_count), "one blob each")
	var kinds := {}
	for s in sim.shots:
		check(s.land.distance_to(foe.pos) <= def.brew_spread + 0.01, "near the foe")
		kinds[s.zone.kind] = true
	check(kinds.has("fire") and kinds.has("goo"), "burning and slowing puddles")


func test_cooldown_gear_speeds_up_named_timers() -> void:
	var def := Gear.apply_def(BallDefs.get_def("pip"), {"cooldown": 0.25})
	check_near(def.fire_cooldown, 3.0 / 1.25, 0.001, "fire_cooldown scales")
	check_eq(def.effects[0].secs, "fire_cooldown", "a named every-timer keeps its name")


func test_shots_replay_identically() -> void:
	for id in ["pip", "zing", "clam", "mortar", "pollen", "megabot", "brewster"]:
		var a := MatchSim.new({"seed": 77, "p1": id, "p2": "vampire", "tiers": [5, 5]}).run_to_end()
		var b := MatchSim.new({"seed": 77, "p1": id, "p2": "vampire", "tiers": [5, 5]}).run_to_end()
		check_eq(a.hash, b.hash, "%s replays" % id)
