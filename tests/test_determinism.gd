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


func test_dmath_matches_builtins_closely() -> void:
	const DMath := preload("res://sim/dmath.gd")
	var worst := 0.0
	for i in 2001:
		var a := -20.0 + i * 0.02
		worst = maxf(worst, absf(DMath.sin(a) - sin(a)))
		worst = maxf(worst, absf(DMath.cos(a) - cos(a)))
		var y := sin(a * 1.7) * 3.0
		var x := cos(a) * 2.0
		worst = maxf(worst, absf(DMath.atan2(y, x) - atan2(y, x)))
	for x in [-1.0, -0.5, 0.0, 0.3, 0.99, 1.0]:
		worst = maxf(worst, absf(DMath.asin(x) - asin(x)))
	check(worst < 1e-12, "dmath within 1e-12 of the built-ins, worst %s" % worst)
	check_eq(DMath.atan2(0.0, 0.0), 0.0, "atan2(0, 0)")
	check_eq(DMath.ipow(1.25, 3), 1.25 * 1.25 * 1.25, "ipow")


## Built-in sin/cos/atan2/pow and the Vector2 angle methods use each platform's
## maths library, which differs by a bit between desktop, web and phones; that
## was enough for some fights to play out differently on the web. sim/ must use
## sim/dmath.gd instead.
func test_sim_uses_no_platform_maths() -> void:
	var bad := RegEx.create_from_string("(?<![\\w.])(sin|cos|tan|asin|acos|atan|atan2|pow|exp|log|sinh|cosh|tanh)\\(|\\.(from_angle|rotated|angle|angle_to|angle_to_point|slerp)\\(")
	var files: Array[String] = []
	var dirs := ["res://sim"]
	while not dirs.is_empty():
		var d: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(d):
			dirs.append(d + "/" + sub)
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd") and f != "dmath.gd":
				files.append(d + "/" + f)
	check(files.size() > 50, "found the sim files")
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for n in lines.size():
			var code := lines[n].split("#")[0].replace("DMath.", "DMath_")
			if bad.search(code):
				runner.fail("%s:%d uses platform maths, use DMath: %s" % [path, n + 1, lines[n].strip_edges()])
