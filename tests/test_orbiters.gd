## Batch E critters (orbiters and attachments): Glowbug, Jawbreaker, Wrecker,
## Swarm, Kraken, Quasar, Yo-Yo and Leviathan, and the shared orbiter pieces.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Abilities := preload("res://sim/abilities.gd")


func _sim(p1: String, p2 := "plain", tier := 1) -> MatchSim:
	return MatchSim.new({"seed": 1, "p1": p1, "p2": p2, "angles": [null, null], "damage_rolls": false, "tiers": [tier, 1]})


## Parks both balls far apart and motionless so a test can stage one event.
func _park(sim: MatchSim) -> void:
	sim.balls[0].pos = Vector2(300, 300)
	sim.balls[1].pos = Vector2(800, 800)
	for b in sim.balls:
		b.vel = Vector2.ZERO


func _damage(sim: MatchSim, target: int, kind: String) -> float:
	var total := 0.0
	for e in sim.events:
		if e.type == "damage" and e.target == target and e.kind == kind:
			total += e.amount
	return total


## Steps until `kind` damage lands on ball 1 (or `ticks` pass); returns it.
func _until_damage(sim: MatchSim, kind: String, ticks: int) -> float:
	for i in ticks:
		sim.step()
		var d := _damage(sim, 1, kind)
		if d > 0.0:
			return d
	return 0.0


func test_orbit_moons_still_bonk_and_are_drawn() -> void:
	var sim := _sim("gravity")
	_park(sim)
	sim.balls[0].def = sim.balls[0].def.duplicate()
	sim.balls[0].def.pull_range = 1.0 # No pull, so only the moon moves.
	sim.balls[1].pos = sim.balls[0].pos + Vector2(64 + 40 + 60, 0)
	check_near(_until_damage(sim, "moon", 200), 5.0, 0.001, "Orbit's moon hits for moon_damage")
	check_eq(Abilities.orb_items(sim, sim.balls[0]).size(), 1, "one moon is published for the renderer")


func test_glowbug_t5_bugs_flare() -> void:
	var sim := _sim("glowbug", "plain", 5)
	_park(sim)
	var flares := 0
	for i in 6 * 60 + 1:
		sim.step()
		for e in sim.events:
			if e.type == "pulse" and e.get("kind", "") == "bugflare":
				flares += 1
	check_eq(flares, 2, "both bugs flare at 6s")


func test_jawbreaker_hits_add_candies_up_to_max_and_big_hits_knock_one_off() -> void:
	var sim := _sim("jawbreaker")
	var b := sim.balls[0]
	check_eq(int(b.def.candy_start), 0, "T1 starts with none")
	for i in 5:
		sim.abilities.fire(sim, "hit", b, {"target": sim.balls[1], "amount": 5.0, "heals": []})
	check_eq(b.state.candies, 3, "capped at candy_max")
	sim.abilities.fire(sim, "hurt", b, {"source": sim.balls[1], "amount": 6.0, "kind": "contact"})
	check_eq(b.state.candies, 3, "a small hit leaves them")
	sim.abilities.fire(sim, "hurt", b, {"source": sim.balls[1], "amount": 12.0, "kind": "contact"})
	check_eq(b.state.candies, 2, "a 10+ hit knocks one off")
	var t3 := _sim("jawbreaker", "plain", 3)
	t3.step()
	check_eq(t3.balls[0].state.candies, 1, "T3 starts with a candy")


func test_jawbreaker_t5_full_set_cracks_in_a_blast() -> void:
	var sim := _sim("jawbreaker", "plain", 5)
	_park(sim)
	var b := sim.balls[0]
	b.state.candies = 4
	sim.balls[1].pos = b.pos + Vector2(150, 0)
	sim.abilities.fire(sim, "hit", b, {"target": sim.balls[1], "amount": 5.0, "heals": []})
	check_eq(b.state.candies, 0, "the set starts over")
	sim.step()
	check(_damage(sim, 1, "candy") >= 12.0, "the sugar blast hits a foe in reach")


func test_wrecker_ball_knocks_foes_and_sets_up_a_slam() -> void:
	var sim := _sim("wrecker")
	_park(sim)
	sim.balls[1].pos = sim.balls[0].pos + Vector2(64 + 66 + 20, 0) # Just past the ball at tick 0.
	sim.step()
	check_near(_damage(sim, 1, "wreck"), 9.0, 0.001, "the ball hits for 9")
	check(sim.balls[1].vel.x > 0.0, "and knocks the foe away")
	check(sim.balls[1].state.has("slam"), "a wall within 0.5s will slam it")


func test_wrecker_t3_chain_beam_and_t5_windup() -> void:
	var sim := _sim("wrecker", "plain", 5)
	_park(sim)
	sim.step()
	check_eq(sim.beams.size(), 1, "the chain is a beam")
	for i in 8 * 60:
		sim.step()
	check(sim.balls[0].state.get("windup", false), "the wind-up lap starts at 8s")
	var item: Dictionary = Abilities.orb_items(sim, sim.balls[0])[0]
	check_near(item.pos.distance_to(sim.balls[0].pos), 260.0, 0.5, "at the long reach")


func test_swarm_launches_a_homing_bee_that_respawns() -> void:
	var sim := _sim("swarm")
	_park(sim)
	for i in 8 * 60 + 1:
		sim.step()
	check_eq(sim.balls[0].state.bees_out.size(), 1, "one bee flies off at 8s")
	var gone: Array = sim.balls[0].state.bee_ready.filter(func(t): return t > sim.tick)
	check_eq(gone.size(), 1, "its slot is empty until it hatches again")
	check(_until_damage(sim, "bee", 180) > 0.0, "the bee homes in and stings")


func test_swarm_t5_whole_swarm_launches_below_half() -> void:
	var sim := _sim("swarm", "plain", 5)
	_park(sim)
	sim.balls[0].hp = sim.balls[0].max_hp * 0.4
	sim.step()
	check_eq(sim.balls[0].state.bees_out.size(), 4, "all four bees launch")


func test_kraken_slams_leave_ink_and_t5_hugs() -> void:
	var sim := _sim("kraken", "plain", 5)
	_park(sim)
	for i in 6 * 60 + 1:
		sim.step()
	check_eq(sim.zones.filter(func(z): return z.kind == "inkpool").size(), 4, "an ink puddle at each tentacle")
	for i in 12 * 60:
		sim.step()
	check(sim.balls[0].state.has("hug_until"), "the third slam is a hug")


func test_quasar_beams_spin_and_flare_to_the_walls() -> void:
	var sim := _sim("quasar", "plain", 5)
	_park(sim)
	sim.step()
	check_eq(sim.beams.size(), 2, "two jets")
	check_near(sim.beams[0].a.distance_to(sim.beams[0].b), 300.0, 0.01, "300 long at T4+")
	var before: float = sim.balls[0].state.quasar_angle
	for i in 6 * 60:
		sim.step()
	sim.step()
	check_eq(sim.beams.size(), 4, "T5 flare adds the cross")
	check(sim.beams[0].a.distance_to(sim.beams[0].b) > 300.0, "flared jets reach the walls")
	check(sim.balls[0].state.quasar_angle > before, "they turned")
	check_eq(sim.balls[0].state.quasar_dir, -1.0, "T3+ reverse after the flare")


func test_yoyo_swings_on_its_third_bounce_and_t3_flings() -> void:
	var sim := _sim("yoyo", "plain", 3)
	_park(sim)
	var b := sim.balls[0]
	b.state.yoyo_bounces = 2
	b.pos = Vector2(b.radius + 2.0, 500)
	b.vel = Vector2(-b.speed, b.speed * 0.2).normalized() * b.speed
	sim.step()
	check(b.state.has("anchor"), "the third bounce pins the string")
	for i in 40:
		sim.step()
	check_eq(sim.beams.size(), 1, "the string is a beam while it swings")
	check_near(b.pos.distance_to(b.state.anchor), 180.0, 12.0, "swinging out at the string's length")
	check_near(b.vel.length(), b.speed, 0.01, "at its usual speed")
	for i in 30:
		sim.step()
	check(sim.beams.is_empty(), "the string goes when the swing ends")
	check(b.vel.length() > b.speed * 1.1, "T3 flings it at the foe")


func test_yoyo_t5_second_string_mirrors_inside_the_arena() -> void:
	var sim := _sim("yoyo", "plain", 5)
	_park(sim)
	var b := sim.balls[0]
	b.state.yoyo_bounces = 1
	b.pos = Vector2(b.radius + 2.0, 500)
	b.vel = Vector2(-b.speed, b.speed * 0.3).normalized() * b.speed
	for i in 30:
		sim.step()
	check_eq(sim.beams.size(), 2, "two strings")
	var mirror: Dictionary = Abilities.orb_items(sim, b)[0]
	check(mirror.pos.x > 0.0, "the mirrored yo-yo stays inside the arena")
	check_near(mirror.pos.distance_to(b.state.anchor), b.pos.distance_to(b.state.anchor), 8.0, "as far from the anchor as the yo-yo")
	check(signf(mirror.pos.y - 500.0) != signf(b.pos.y - 500.0), "on the other side of it")


func test_leviathan_tail_stings_and_the_dive_erupts_under_the_foe() -> void:
	var sim := _sim("leviathan")
	sim.balls[1].vel = Vector2.ZERO
	var waves := 0.0
	for i in 9 * 60:
		sim.step()
	check_eq(Abilities.orb_items(sim, sim.balls[0]).size(), 3, "three tail segments")
	sim.step()
	check(sim.balls[0].state.has("dive_until"), "it dives at 9s")
	_park(sim)
	var target := sim.balls[1].pos
	for i in 75:
		sim.step()
		waves += _damage(sim, 1, "wave")
	check(waves >= 16.0 * 0.4, "the wave hits a foe that stood still")
	check(sim.balls[0].pos.distance_to(target) < 200.0, "it burst up by the foe")

