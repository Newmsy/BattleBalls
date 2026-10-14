extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const GoldenCases := preload("res://tests/golden_cases.gd")


func test_same_config_gives_identical_fight_every_tick() -> void:
	var cfg := {"seed": 99, "p1": "vampire", "p2": "laser", "angles": [null, null]}
	var a := MatchSim.new(cfg)
	var b := MatchSim.new(cfg)
	while not a.finished:
		a.step()
		b.step()
		if a.state_hash() != b.state_hash():
			runner.fail("fights diverged at tick %d" % a.tick)
			return
	check(b.finished, "both fights end together")
	check_eq(a.winner, b.winner, "same winner")


func test_different_seeds_give_different_fights() -> void:
	var hashes := {}
	for seed_value in 10:
		hashes[MatchSim.new({"seed": seed_value, "p1": "vampire", "p2": "laser", "angles": [null, null]}).run_to_end().hash] = true
	check(hashes.size() >= 9, "seeds should produce distinct fights, got %d unique of 10" % hashes.size())


func test_golden_replays_are_unchanged() -> void:
	var text := FileAccess.get_file_as_string("res://tests/golden_replays.json")
	var golden: Array = JSON.parse_string(text)
	check_eq(golden.size(), GoldenCases.CASES.size(), "golden file covers every case; re-run tools/record_golden.gd")
	for i in mini(golden.size(), GoldenCases.CASES.size()):
		var g: Dictionary = golden[i]
		var s := MatchSim.new(GoldenCases.CASES[i]).run_to_end()
		var label := str(GoldenCases.CASES[i])
		check_eq(s.winner, int(g.winner), label + " winner")
		check_eq(s.ticks, int(g.ticks), label + " length")
		check_eq(s.hash, g.hash, label + " final state")
