## Headless boon check for Bounce Run: every boon, held by one ball against
## the same matchup without it, over every ordered pairing of playable balls,
## each seed fought from both corners. A boon should be a tilt, not a verdict
## (BALANCE.md rule 2): it must win BOON_MIN to BOON_MAX at equal power.
## --runs=N instead plays N whole daily runs with random picks and aims, and
## reports the win rate per floor and the floor each run ended on: the
## FOE_POWER curve in sim/bounce_run.gd aims for easy early floors and a
## median run that ends around floor 7. --runs-from=K (before --runs) starts
## at run K, to split the runs over processes.
## Usage: godot --headless --script res://tools/boon_balance.gd -- [--fights=100] [--strict] [--only=<id>] [--runs-from=K] [--runs=N]
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const Rng := preload("res://sim/rng.gd")

const BOON_MIN := 0.52 ## Below this a boon is a dud pick.
const BOON_MAX := 0.62 ## Above this a boon decides fights. 0.65 is a FAIL.
const BOON_FAIL := 0.65
const Z95 := 1.96
const FIGHT_BUDGET := 640 ## Most fights per boon (a CI time limit).

var fights := 100
var only := "" ## --only=<boon id> checks just that boon.
var runs_from := 0 ## --runs-from=K starts at run K, to split --runs over machines.


func _init() -> void:
	var strict := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
		elif arg == "--strict":
			strict = true
		elif arg.begins_with("--only="):
			only = arg.split("=")[1]
		elif arg.begins_with("--runs-from="):
			runs_from = int(arg.split("=")[1])
		elif arg.begins_with("--runs="):
			print(_random_runs(int(arg.split("=")[1]), runs_from))
			quit(0)
			return
	var failures := 0
	var lines: Array[String] = []
	lines.append("### Bounce Run boons at equal power (up to %d fights per pairing and %d per boon, both corners)" % [fights * 2, FIGHT_BUDGET])
	lines.append("")
	lines.append("| Boon | Win rate with it | Flag |")
	lines.append("|---|---|---|")
	for id in Boons.ALL:
		if only != "" and id != only:
			continue
		var r := boon_win_rate(id, fights)
		var flag := ""
		var lo := _wilson(r.rate, r.n, -1.0)
		var hi := _wilson(r.rate, r.n, 1.0)
		if lo > BOON_FAIL:
			flag = "FAIL: over %d%%" % roundi(BOON_FAIL * 100)
			failures += 1
		elif r.rate > BOON_MAX or r.rate < BOON_MIN:
			flag = "WARN: outside %d-%d%%" % [roundi(BOON_MIN * 100), roundi(BOON_MAX * 100)]
		if hi < 0.5:
			flag = "FAIL: hurts its holder"
			failures += 1
		lines.append("| %s | %.1f%% | %s |" % [Boons.get_def(id).name, r.rate * 100.0, flag])
	print("\n".join(lines))
	quit(1 if strict and failures > 0 else 0)


## Win rate of a ball holding `id` against the same ball types without it.
## Ability boons only count pairings where the holder has that ability.
## `seeds` is per pairing, capped so one boon plays at most FIGHT_BUDGET
## fights: the roster grows, the run time doesn't. Past one seed per pairing,
## an evenly spread, fixed sample of the pairings is fought instead.
static func boon_win_rate(id: String, seeds: int) -> Dictionary:
	var score := 0.0
	var n := 0
	var pairs: Array = []
	for a in BallDefs.PLAYABLE:
		if not Boons.applies_to(id, BallDefs.get_def(a).ability):
			continue
		for b in BallDefs.PLAYABLE:
			pairs.append([a, b])
	var most: int = FIGHT_BUDGET / 2
	if pairs.size() > most:
		var sample: Array = []
		for i in most:
			sample.append(pairs[i * pairs.size() / most])
		pairs = sample
	seeds = clampi(FIGHT_BUDGET / (2 * maxi(1, pairs.size())), 1, seeds)
	for pair in pairs:
		var a: String = pair[0]
		var b: String = pair[1]
		for s in seeds:
			for side in 2:
				var cfg := {"seed": 1000 + s, "p1": a, "p2": b, "boons": [[id], []], "family_edges": false}
				if side == 1:
					cfg = {"seed": 1000 + s, "p1": b, "p2": a, "boons": [[], [id]], "family_edges": false}
				var w: int = MatchSim.new(cfg).run_to_end().winner
				score += 0.5 if w == -1 else (1.0 if w == side else 0.0)
				n += 1
	return {"rate": score / maxf(1.0, n), "n": n}


static func _wilson(p: float, n: int, sign: float) -> float:
	var z2 := Z95 * Z95
	var centre := (p + z2 / (2.0 * n)) / (1.0 + z2 / n)
	var half := Z95 * sqrt(p * (1.0 - p) / n + z2 / (4.0 * n * n)) / (1.0 + z2 / n)
	return centre + sign * half


## Plays whole runs with random drafts, fighters, aims and boon picks.
static func _random_runs(count: int, from := 0) -> String:
	var wins: Array = []
	var played: Array = []
	for f in BounceRun.FLOORS:
		wins.append(0)
		played.append(0)
	var cleared := 0
	var floors_total := 0
	var ended: Array = [] ## Floor each run ended on (FLOORS + 1 = cleared).
	for f in BounceRun.FLOORS + 1:
		ended.append(0)
	for r in range(from, from + count):
		var rng := Rng.new(r * 31 + 7)
		var setup := BounceRun.generate(1 + r % 60)
		var picks: Array = []
		while picks.size() < BounceRun.PICKS:
			var c := rng.range_int(0, BounceRun.DRAFT - 1)
			if not c in picks:
				picks.append(c)
		var start: Array = []
		while start.size() < BounceRun.START_BOONS:
			var b: String = setup.start_offer[rng.range_int(0, setup.start_offer.size() - 1)]
			if not b in start:
				start.append(b)
		var run := BounceRun.new_run(setup, picks, start)
		while not run.over:
			var living := BounceRun.living(run)
			var slot: int = living[rng.range_int(0, living.size() - 1)]
			var aim := -450 + rng.range_int(-400, 400)
			var result := MatchSim.new(BounceRun.fight_config(setup, run, slot, aim)).run_to_end()
			played[run.floor] += 1
			if result.winner == 0:
				wins[run.floor] += 1
			BounceRun.record(setup, run, slot, aim, result.winner, result.ticks, result.hp[1])
			if not run.offer.is_empty():
				BounceRun.take_boon(run, run.offer[rng.range_int(0, run.offer.size() - 1)])
		floors_total += run.floor
		ended[run.floor] += 1
		if run.floor >= BounceRun.FLOORS:
			cleared += 1
	var lines: Array[String] = []
	lines.append("### Bounce Run, %d random runs" % count)
	lines.append("")
	lines.append("| Floor | Fights | Win rate |")
	lines.append("|---|---|---|")
	for f in BounceRun.FLOORS:
		if played[f] > 0:
			lines.append("| %d | %d | %.1f%% |" % [f + 1, played[f], 100.0 * wins[f] / played[f]])
	lines.append("")
	lines.append("Average floors cleared %.2f, full clears %.1f%%." % [float(floors_total) / count, 100.0 * cleared / count])
	lines.append("")
	lines.append("| Run ended on | Runs |")
	lines.append("|---|---|")
	var median := -1
	var seen := 0
	for f in ended.size():
		seen += ended[f]
		if median < 0 and seen * 2 >= count:
			median = f
		var label := "cleared" if f == BounceRun.FLOORS else "floor %d" % (f + 1)
		lines.append("| %s | %.1f%% |" % [label, 100.0 * ended[f] / count])
	lines.append("")
	lines.append("RUN_ENDS %s" % ",".join(ended.map(func(n): return str(n))))
	lines.append("RUN_FLOORS %s" % ",".join(range(BounceRun.FLOORS).map(func(f): return "%d/%d" % [wins[f], played[f]])))
	lines.append("Median run ends on %s." % ("a full clear" if median == BounceRun.FLOORS else "floor %d" % (median + 1)))
	return "\n".join(lines)
