extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Relay := preload("res://sim/relay.gd")


func _cfg(seed_value: int) -> Dictionary:
	return {"seed": seed_value, "sides": [["vampire", "laser", "vampire"], ["laser", "laser", "vampire"]],
		"aims": [[-450, -300, null], [1350, null, 1500]]}


func test_relay_is_deterministic() -> void:
	for s in [1, 7, 99]:
		check_eq(Relay.new(_cfg(s)).run_to_end(), Relay.new(_cfg(s)).run_to_end(), "seed %d" % s)


func test_relay_ends_with_one_side_out_of_balls() -> void:
	for s in 20:
		var relay := Relay.new(_cfg(s))
		var result := relay.run_to_end()
		check(relay.legs.size() >= 3 and relay.legs.size() <= 5, "3-5 legs, got %d" % relay.legs.size())
		if result.winner == -1:
			check(relay.slot[0] >= 3 and relay.slot[1] >= 3, "a draw only when both sides are out")
		else:
			check_eq(relay.slot[1 - result.winner], 3, "loser has no balls left")
			check(relay.slot[result.winner] < 3, "winner still has a ball in")


func test_winner_stays_in_with_its_hp() -> void:
	var relay := Relay.new(_cfg(3))
	var sim := MatchSim.new(relay.leg_config())
	sim.run_to_end()
	relay.record_leg(sim)
	var w := sim.winner
	if w == -1:
		check_eq(relay.slot, [1, 1] as Array[int], "draw knocks out both")
		return
	check_eq(relay.slot[w], 0, "winner stays in")
	check_eq(relay.slot[1 - w], 1, "loser's next ball comes out")
	var next := relay.leg_config()
	check_near(float(next.hp[w]), sim.balls[w].hp, 0.0001, "winner carries its HP")
	check_eq(next.hp[1 - w], null, "new ball starts full")
	var leg2 := MatchSim.new(next)
	check_near(leg2.balls[w].hp, sim.balls[w].hp, 0.0001, "HP applied in the next leg")
	check_eq(leg2.balls[w].max_hp, sim.balls[w].max_hp, "max HP unchanged")


func test_driving_leg_by_leg_matches_run_to_end() -> void:
	var a := Relay.new(_cfg(11))
	var expected := a.run_to_end()
	var b := Relay.new(_cfg(11))
	while not b.finished:
		var sim := MatchSim.new(b.leg_config())
		while not sim.finished:
			sim.step()
		b.record_leg(sim)
	check_eq(b.summary(), expected, "same relay")


func test_single_ball_relay_matches_a_plain_fight_winner() -> void:
	var relay := Relay.new({"seed": 5, "sides": [["vampire"], ["laser"]], "aims": [[-450], [1350]]})
	relay.run_to_end()
	var leg: Dictionary = relay.legs[0]
	var plain := MatchSim.new({"seed": leg.seed, "p1": "vampire", "p2": "laser", "angles": [-450, 1350]}).run_to_end()
	check_eq(leg.hash, plain.hash, "one leg is one ordinary fight")
	check_eq(relay.winner, plain.winner, "winner")
