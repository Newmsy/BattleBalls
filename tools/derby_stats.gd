## Headless Bounce Derby stats: race length, lead changes and how often each
## critter, trick and gate lane wins. Usage:
## godot --headless --script res://tools/derby_stats.gd -- --races=300
extends SceneTree

const Derby := preload("res://sim/derby.gd")


func _init() -> void:
	var races := 300
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--races="):
			races = int(a.get_slice("=", 1))
	var t0 := Time.get_ticks_msec()
	var wins := {}
	var starts := {}
	var trick_wins := {}
	var trick_starts := {}
	var times: Array = []
	var changes: Array = []
	var stuck := 0
	for seed in range(1, races + 1):
		var d := Derby.new({"seed": seed})
		var leader := -1
		var lead_changes := 0
		while not d.finished:
			d.step()
			if d.tick % 30 == 0 and d.order.is_empty():
				var l: int = d.standings()[0]
				if l != leader:
					lead_changes += 1
					leader = l
		var w := d.racers[d.winner()]
		wins[w.id] = wins.get(w.id, 0) + 1
		trick_wins[w.trick] = trick_wins.get(w.trick, 0) + 1
		for r in d.racers:
			starts[r.id] = starts.get(r.id, 0) + 1
			trick_starts[r.trick] = trick_starts.get(r.trick, 0) + 1
			if r.finish_tick < 0:
				stuck += 1
		times.append(d._win_tick * Derby.DT if d._win_tick >= 0 else d.time())
		changes.append(lead_changes)
	times.sort()
	changes.sort()
	print("races %d in %d ms (%.0f ms each)" % [races, Time.get_ticks_msec() - t0, float(Time.get_ticks_msec() - t0) / races])
	print("winning time p10 %.1fs median %.1fs p90 %.1fs" % [times[races / 10], times[races / 2], times[races * 9 / 10]])
	print("lead changes median %d p90 %d; racers who never finished: %d" % [changes[races / 2], changes[races * 9 / 10], stuck])
	for t in trick_starts:
		print("trick %-6s win share %.1f%% (fair %.1f%%)" % [t, 100.0 * trick_wins.get(t, 0) / trick_starts[t], 100.0 / Derby.RACERS])
	var ids := starts.keys()
	ids.sort_custom(func(a, b): return float(wins.get(a, 0)) / starts[a] > float(wins.get(b, 0)) / starts[b])
	for id in ids:
		print("%-10s %-5s %5.1f%% of %d" % [id, Derby.trick_of(id), 100.0 * wins.get(id, 0) / starts[id], starts[id]])
	quit(0)
