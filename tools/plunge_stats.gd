## Headless Critter Plunge stats (sim/plunge.gd): knockout rate, race length,
## and how often each starting gate and each race verb wins. Fair is 1.0x
## (wins exactly 1 race in n). Usage:
## godot --headless --script res://tools/plunge_stats.gd -- --races=400 --n=8
## (--n=all runs 4, 6 and 8; --base=1000 starts at another seed.)
extends SceneTree

const Plunge := preload("res://sim/plunge.gd")


func _init() -> void:
	var races := 400
	var sizes := [8]
	var base := 1
	var as_json := false
	for a in OS.get_cmdline_user_args():
		if a == "--json":
			as_json = true
		if a.begins_with("--races="):
			races = int(a.get_slice("=", 1))
		if a.begins_with("--n="):
			sizes = Plunge.FIELD_SIZES if a.get_slice("=", 1) == "all" else [int(a.get_slice("=", 1))]
		if a.begins_with("--base="):
			base = int(a.get_slice("=", 1))
	for n in sizes:
		if as_json:
			print("JSON ", JSON.stringify(measure(n, races, base)))
		else:
			_report(n, races, base)
	quit(0)


func _report(n: int, races: int, base: int) -> void:
	var t0 := Time.get_ticks_msec()
	var s := measure(n, races, base)
	print("--- %d racers, %d races in %d ms (damage x%.2f)" % [n, races, Time.get_ticks_msec() - t0, Plunge.field_damage(n)])
	print("knocked out %.1f%% · winning time median %.1fs p90 %.1fs · never finished %d" % [100.0 * s.ko_rate, s.median, s.p90, s.stuck])
	var gates := []
	for g in n:
		gates.append("%.1f%%" % (100.0 * s.gate_wins[g] / races))
	print("gate wins (fair %.1f%%): %s" % [100.0 / n, " ".join(gates)])
	for v in s.verbs:
		var d: Dictionary = s.verbs[v]
		print("%-7s win %.2fx  KO %4.1f%%  (%d entries)" % [v, d.share, 100.0 * d.ko, d.entries])


## The numbers above as data (tests use it too).
static func measure(n: int, races: int, base := 1) -> Dictionary:
	var gate_wins := []
	gate_wins.resize(n)
	gate_wins.fill(0)
	var entries := {}
	var wins := {}
	var knocked := {}
	var kos := 0
	var stuck := 0
	var times: Array = []
	for seed in range(base, base + races):
		var p := Plunge.new({"seed": seed, "racers": Plunge.draw_field(seed, n)})
		var res := p.run()
		var w: Plunge.Racer = p.racers[res.order[0]]
		gate_wins[w.lane] += 1
		kos += res.kos.size()
		times.append(res.win_time)
		for r in p.racers:
			entries[r.verb] = entries.get(r.verb, 0) + 1
			if r == w:
				wins[r.verb] = wins.get(r.verb, 0) + 1
			if r.ko_tick >= 0:
				knocked[r.verb] = knocked.get(r.verb, 0) + 1
			elif r.finish_tick < 0:
				stuck += 1
	times.sort()
	var verbs := {}
	for v in Plunge.VERB_STATS:
		if entries.has(v):
			verbs[v] = {"share": float(wins.get(v, 0)) / entries[v] * n, "ko": float(knocked.get(v, 0)) / entries[v], "entries": entries[v]}
	return {"n": n, "races": races, "kos": kos, "entries": entries, "wins": wins, "knocked": knocked, "times": times,
		"ko_rate": float(kos) / (races * n), "median": times[races / 2], "p90": times[races * 9 / 10], "stuck": stuck,
		"gate_wins": gate_wins, "verbs": verbs}
