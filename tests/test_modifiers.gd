extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Modifiers := preload("res://sim/modifiers.gd")


func _sim(modifier: String, seed_value := 5) -> MatchSim:
	return MatchSim.new({"seed": seed_value, "p1": "vampire", "p2": "laser", "angles": [null, null], "modifier": modifier})


func test_no_modifier_matches_a_config_without_one() -> void:
	var plain := MatchSim.new({"seed": 5, "p1": "vampire", "p2": "laser", "angles": [null, null]}).run_to_end()
	check_eq(_sim(Modifiers.NONE).run_to_end().hash, plain.hash, "empty modifier changes nothing")


func test_modifiers_apply_to_both_balls() -> void:
	var big := _sim("big_head")
	for b in big.balls:
		check_near(b.radius, BallDefs.get_def(b.type_id).radius * 1.35, 0.001, "Big Head radius for " + b.type_id)
	var glass := _sim("glass_cannon")
	for b in glass.balls:
		var base := BallDefs.get_def(b.type_id)
		check_near(b.max_hp, base.hp * 0.75, 0.001, "Glass Cannon HP for " + b.type_id)
		check_near(b.contact_damage, base.contact_damage * Modifiers.get_def("glass_cannon").damage, 0.001, "Glass Cannon contact damage for " + b.type_id)
	check_near(glass.balls[1].def.beam_damage, BallDefs.get_def("laser").beam_damage * Modifiers.get_def("glass_cannon").damage, 0.001, "Glass Cannon beam damage")
	var fast := _sim("hyper_speed")
	for b in fast.balls:
		check_near(b.vel.length(), BallDefs.get_def(b.type_id).speed * 1.4, 0.01, "Hyper Speed for " + b.type_id)
	var double := _sim("double_trouble")
	check_near(double.balls[0].def.heal_ratio, 0.5 * sqrt(1.5), 0.001, "Double Trouble heal ratio (square root)")
	check_eq(double.balls[1].def.beam_max, 9, "Double Trouble beam cap")


func test_base_defs_are_not_mutated() -> void:
	_sim("big_head")
	_sim("glass_cannon")
	check_eq(BallDefs.get_def("vampire").radius, 68.0, "Vampire radius")
	check_eq(BallDefs.get_def("laser").hp, 100.0, "Laser HP")


func test_mirror_match_uses_one_seed_picked_ball() -> void:
	var seen := {}
	for seed_value in 6:
		var sim := _sim("mirror_match", seed_value)
		check_eq(sim.balls[0].type_id, sim.balls[1].type_id, "both sides match on seed %d" % seed_value)
		seen[sim.balls[0].type_id] = true
	check_eq(seen.size(), Modifiers.MIRROR_POOL.size(), "every mirror ball comes up")


func test_closing_walls_starts_overtime_early() -> void:
	var sim := _sim("closing_walls")
	while sim.time() < 11.0 and not sim.finished:
		sim.step()
	check(sim.in_overtime(), "overtime by 11s")
	check(sim.half_size < MatchSim.ARENA_SIZE / 2.0, "arena has started shrinking")


func test_a_critters_chaos_block_tunes_only_its_twist() -> void:
	var base := BallDefs.get_def("juggernaut")
	var tuned: Dictionary = base.chaos.big_head
	check_near(Modifiers.apply_to_def(base, "big_head").contact_damage, base.contact_damage * tuned.contact_damage, 0.001, "chaos multiplier applied")
	check_near(Modifiers.apply_to_def(base, "glass_cannon").contact_damage, base.contact_damage * 1.35, 0.001, "other twists untouched")
	check_near(Modifiers.apply_to_def(base, Modifiers.NONE).contact_damage, base.contact_damage, 0.001, "normal rules untouched")


func test_every_modifier_is_deterministic_and_finishes() -> void:
	for id in Modifiers.DEFS:
		var a := _sim(id, 11).run_to_end()
		var b := _sim(id, 11).run_to_end()
		check_eq(a.hash, b.hash, id + " is deterministic")
		check(a.ticks <= int(MatchSim.TIME_LIMIT * MatchSim.TICK_RATE) + 1, id + " finishes")


func test_rotation_only_runs_on_weekends() -> void:
	var monday := Modifiers.ROTATION_EPOCH
	check_eq(Modifiers.weekend_modifier(monday + 3 * Modifiers.DAY + 100), Modifiers.NONE, "Thursday is normal")
	check_eq(Modifiers.weekend_modifier(monday + 4 * Modifiers.DAY), Modifiers.ROTATION[0], "Friday starts week 0's twist")
	check_eq(Modifiers.weekend_modifier(monday + 7 * Modifiers.DAY - 1), Modifiers.ROTATION[0], "Sunday night is still on")
	check_eq(Modifiers.weekend_modifier(monday + Modifiers.WEEK + 5 * Modifiers.DAY), Modifiers.ROTATION[1], "next weekend rotates")
	check_eq(Modifiers.weekend_modifier(monday + Modifiers.ROTATION.size() * Modifiers.WEEK + 5 * Modifiers.DAY), Modifiers.ROTATION[0], "rotation wraps")
	for id in Modifiers.ROTATION:
		check(Modifiers.DEFS.has(id), "rotation entry %s exists" % id)
	check_eq(Modifiers.ROTATION.size(), Modifiers.DEFS.size(), "every modifier is in the rotation")
