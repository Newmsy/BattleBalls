## Boss win rates (design/bosses.md): every live critter fights a boss at a
## player power and a boss power, over a spread of seeds, and the win rate,
## average time and the best/worst critters print out.
## godot --headless --script res://tools/boss_difficulty.gd -- [--boss=anvil_king] [--you=1.9] [--foe=1.3] [--fights=20]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Bosses := preload("res://sim/bosses.gd")


func _init() -> void:
	var boss := "anvil_king"
	var you := 1.0
	var foe := 1.0
	var fights := 10
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		match kv[0]:
			"boss": boss = kv[1]
			"you": you = float(kv[1])
			"foe": foe = float(kv[1])
			"fights": fights = int(kv[1])
	var rows := []
	var wins := 0
	var total := 0
	var secs := 0.0
	for id in BallDefs.PLAYABLE:
		var w := 0
		for k in fights:
			var cfg := {"seed": 1000 + k * 7919, "p1": id, "p2": boss, "arena": Bosses.DEFS[boss].arena,
				"angles": [null, null], "powers": [you, foe]}
			var s := MatchSim.new(cfg).run_to_end()
			if s.winner == 0:
				w += 1
			secs += s.time
		rows.append([id, w * 100.0 / fights])
		wins += w
		total += fights
	rows.sort_custom(func(a, b): return a[1] > b[1])
	print("%s  you x%.2f vs boss x%.2f: win %.0f%%, avg %.1fs" % [boss, you, foe, wins * 100.0 / total, secs / total])
	print("best:  ", rows.slice(0, 6).map(func(r): return "%s %d%%" % [r[0], r[1]]))
	print("worst: ", rows.slice(rows.size() - 6).map(func(r): return "%s %d%%" % [r[0], r[1]]))
	quit(0)
