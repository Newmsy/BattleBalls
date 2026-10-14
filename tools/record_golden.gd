## Re-records tests/golden_replays.json. Run only for an intended sim change,
## and say so in the PR.
## Usage: godot --headless --script res://tools/record_golden.gd
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const GoldenCases := preload("res://tests/golden_cases.gd")


func _init() -> void:
	var out: Array = []
	for cfg in GoldenCases.CASES:
		var s := MatchSim.new(cfg).run_to_end()
		out.append({"config": cfg, "winner": s.winner, "reason": s.reason, "ticks": s.ticks, "hash": s.hash})
		print("%s -> winner %d (%s) at %.2fs" % [cfg, s.winner, s.reason, s.time])
	var f := FileAccess.open("res://tests/golden_replays.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  ") + "\n")
	quit(0)
