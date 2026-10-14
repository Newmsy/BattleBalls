## Headless balance sim: runs many seeded fights for every pairing and prints a
## win-rate matrix plus fight-length stats as Markdown.
## Usage: godot --headless --script res://tools/balance.gd -- [--fights=200]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


func _init() -> void:
	var fights := 200
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
	var ids: Array = BallDefs.DEFS.keys()
	var lines: Array[String] = []
	lines.append("### Balance sim (%d fights per pairing, both sides swapped)" % fights)
	lines.append("")
	lines.append("| Row beats column | " + " | ".join(ids) + " |")
	lines.append("|---" .repeat(ids.size() + 1) + "|")
	var durations: Array[float] = []
	var timeouts := 0
	var total := 0
	for a in ids:
		var row: Array[String] = [a]
		for b in ids:
			var wins := 0.0
			for i in fights:
				# Alternate sides so corner position can't bias the result.
				var a_first := i % 2 == 0
				var sim := MatchSim.new({"seed": 1000 + i, "p1": a if a_first else b, "p2": b if a_first else a, "angles": [null, null]})
				var s := sim.run_to_end()
				var a_index := 0 if a_first else 1
				if s.winner == a_index:
					wins += 1.0
				elif s.winner == -1:
					wins += 0.5
				durations.append(s.time)
				total += 1
				if s.reason == "time_limit":
					timeouts += 1
			row.append("%d%%" % roundi(100.0 * wins / fights))
		lines.append("| " + " | ".join(row) + " |")
	durations.sort()
	var mean := 0.0
	for d in durations:
		mean += d
	mean /= durations.size()
	lines.append("")
	lines.append("Fight length: mean %.1fs, median %.1fs, p10 %.1fs, p90 %.1fs. Time-limit endings: %d of %d." % [
		mean, durations[durations.size() / 2], durations[durations.size() / 10], durations[durations.size() * 9 / 10], timeouts, total])
	print("\n".join(lines))
	quit(0)
