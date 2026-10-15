## Headless balance sim: runs many seeded fights for every pairing and prints a
## win-rate matrix, fight-length stats and balance flags as Markdown. The
## targets it checks are the ones in BALANCE.md.
## Usage: godot --headless --script res://tools/balance.gd -- [--fights=200] [--power-step] [--strict] [--arena=square]
##   --fights=N    seeds per pairing; each seed is fought from both corners (2N fights)
##   --power-step  also fights every ball one power step up against every ball,
##                 checking that power beats counters (slow: n^2 pairings)
##   --strict      exit 1 when a check fails beyond sampling noise
##   --arena=ID    arena from sim/arenas.gd, or "all" for every playable arena;
##                 non-square arenas also get a tilt check against the square
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Arenas := preload("res://sim/arenas.gd")

## Targets from BALANCE.md.
const EQUAL_POWER_MAX := 0.65 ## No equal-power matchup above this.
const POWER_STEP_MIN := 0.70 ## One power step up wins at least this into anything.
const POWER_STEP := 1.25 ## One tier ~ +25% power (power-progression.md).
const MEDIAN_LENGTH := [20.0, 60.0] ## Seconds.
const Z95 := 1.96
## A map may move a matchup this far from its square result (design/arenas.md):
## WARN beyond TILT_WARN, FAIL beyond TILT_MAX when clear of sampling noise.
const TILT_WARN := 0.10
const TILT_MAX := 0.15

var fights := 200
var durations: Array[float] = []
var timeouts := 0
var failures := 0
var arena_id := "square"


func _init() -> void:
	var strict := false
	var power_step := false
	var arena_arg := "square"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
		elif arg == "--strict":
			strict = true
		elif arg == "--power-step":
			power_step = true
		elif arg.begins_with("--arena="):
			arena_arg = arg.split("=")[1]
	var arenas: Array = Arenas.PLAYABLE if arena_arg == "all" else [arena_arg]
	if not arenas.has("square") and arenas.size() > 0:
		arenas = ["square"] + arenas # The tilt check needs the square as reference.
	var ids: Array = BallDefs.DEFS.keys().filter(func(id): return not BallDefs.DEFS[id].get("tutorial", false))
	var lines: Array[String] = []
	var square_rates := {}
	for id in arenas:
		if not Arenas.DEFS.has(id):
			push_error("Unknown arena: %s" % id)
			quit(2)
			return
		arena_id = id
		durations.clear()
		timeouts = 0
		var rates := {}
		if not lines.is_empty():
			lines.append("")
		if id == "square" and arena_arg != "square" and arena_arg != "all":
			_equal_power(ids, rates) # Reference only; not reported.
		else:
			lines.append_array(_equal_power(ids, rates))
			if id != "square":
				lines.append_array(_tilt(rates, square_rates))
			if power_step:
				lines.append("")
				lines.append_array(_power_step(ids))
		if id == "square":
			square_rates = rates
	print("\n".join(lines))
	quit(1 if strict and failures > 0 else 0)


## Every unordered pairing once, each seed fought from both corners, so the
## matrix is exactly complementary (row + column = 100%).
func _equal_power(ids: Array, rate: Dictionary) -> Array[String]:
	for i in ids.size():
		for j in range(i, ids.size()):
			var a: String = ids[i]
			var b: String = ids[j]
			var r := _win_rate(a, 1.0, b)
			rate[a + ":" + b] = r
			rate[b + ":" + a] = 1.0 - r
	var lines: Array[String] = []
	lines.append("### Balance sim, equal power, %s arena (%d fights per pairing, both corners)" % [Arenas.get_def(arena_id).display_name, fights * 2])
	lines.append("")
	lines.append("| Row beats column | " + " | ".join(ids) + " |")
	lines.append("|---".repeat(ids.size() + 1) + "|")
	for a in ids:
		var row: Array[String] = [a]
		for b in ids:
			row.append("%d%%" % roundi(100.0 * rate[a + ":" + b]))
		lines.append("| " + " | ".join(row) + " |")
	durations.sort()
	var median := durations[durations.size() / 2]
	var mean := 0.0
	for d in durations:
		mean += d
	mean /= durations.size()
	lines.append("")
	lines.append("Fight length: mean %.1fs, median %.1fs, p10 %.1fs, p90 %.1fs. Time-limit endings: %d of %d." % [
		mean, median, durations[durations.size() / 10], durations[durations.size() * 9 / 10], timeouts, durations.size()])
	lines.append("")
	var flags: Array[String] = []
	for i in BallDefs.PLAYABLE.size():
		for j in range(i + 1, BallDefs.PLAYABLE.size()):
			var a: String = BallDefs.PLAYABLE[i]
			var b: String = BallDefs.PLAYABLE[j]
			var r: float = rate[a + ":" + b]
			var top := a if r >= 0.5 else b
			var low := b if r >= 0.5 else a
			var p := maxf(r, 1.0 - r)
			if p > EQUAL_POWER_MAX:
				flags.append(_flag(_lower_bound(p, fights * 2) > EQUAL_POWER_MAX,
					"%s beats %s %d%% at equal power (limit %d%%)" % [top, low, roundi(100 * p), roundi(100 * EQUAL_POWER_MAX)]))
	if median < MEDIAN_LENGTH[0] or median > MEDIAN_LENGTH[1]:
		flags.append("WARN: median fight length %.1fs is outside %d-%ds" % [median, MEDIAN_LENGTH[0], MEDIAN_LENGTH[1]])
	if timeouts > 0:
		flags.append("WARN: %d fights hit the time limit" % timeouts)
	lines.append("**Checks:** " + ("all equal-power matchups within %d%%, fight length on target." % roundi(100 * EQUAL_POWER_MAX) if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## How far each playable matchup moved from its square result. Mirrors are
## included: they must stay near 50% on a symmetric arena.
func _tilt(rate: Dictionary, square: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var flags: Array[String] = []
	var worst := 0.0
	var n := fights * 2
	for i in BallDefs.PLAYABLE.size():
		for j in range(i, BallDefs.PLAYABLE.size()):
			var a: String = BallDefs.PLAYABLE[i]
			var b: String = BallDefs.PLAYABLE[j]
			var key := a + ":" + b
			var now: float = rate[key]
			var before: float = square[key]
			var delta := now - before
			worst = maxf(worst, absf(delta))
			if absf(delta) <= TILT_WARN:
				continue
			var se := sqrt(now * (1.0 - now) / n + before * (1.0 - before) / n)
			var text := "%s vs %s moved %+d points from the square (%d%% -> %d%%, limit %d)" % [
				a, b, roundi(100 * delta), roundi(100 * before), roundi(100 * now), roundi(100 * TILT_MAX)]
			if absf(delta) - Z95 * se > TILT_MAX:
				failures += 1
				flags.append("FAIL: " + text)
			else:
				flags.append("WARN: " + text)
	lines.append("")
	lines.append("**Tilt vs square:** largest move %d points." % roundi(100 * worst) + (" Within %d." % roundi(100 * TILT_WARN) if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## Each playable ball one power step up against every playable ball at base
## power, mirror included. The worst result per ball must still clear the bar.
func _power_step(ids: Array) -> Array[String]:
	var playable: Array = BallDefs.PLAYABLE
	var lines: Array[String] = []
	lines.append("### Power step, %s arena (row at x%.2f power vs column at base, %d fights per pairing)" % [Arenas.get_def(arena_id).display_name, POWER_STEP, fights * 2])
	lines.append("")
	lines.append("| Stronger row beats column | " + " | ".join(playable) + " | worst |")
	lines.append("|---".repeat(playable.size() + 2) + "|")
	var flags: Array[String] = []
	for a in playable:
		var row: Array[String] = [a]
		var worst := 1.0
		var worst_id := ""
		for b in playable:
			var r := _win_rate(a, POWER_STEP, b)
			row.append("%d%%" % roundi(100.0 * r))
			if r < worst:
				worst = r
				worst_id = b
		row.append("%d%%" % roundi(100.0 * worst))
		lines.append("| " + " | ".join(row) + " |")
		if worst < POWER_STEP_MIN:
			flags.append(_flag(_upper_bound(worst, fights * 2) < POWER_STEP_MIN,
				"%s one step up only beats %s %d%% (needs %d%%)" % [a, worst_id, roundi(100 * worst), roundi(100 * POWER_STEP_MIN)]))
	lines.append("")
	lines.append("**Checks:** " + ("one power step beats every counter." if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## Share of fights `a` (at `a_power`) wins against `b` at base power; draws
## count half. Each seed is played with `a` in both corners.
func _win_rate(a: String, a_power: float, b: String) -> float:
	var wins := 0.0
	for i in fights:
		for a_index in 2:
			var powers := [a_power, 1.0] if a_index == 0 else [1.0, a_power]
			var sim := MatchSim.new({"seed": 1000 + i, "p1": a if a_index == 0 else b, "p2": b if a_index == 0 else a, "angles": [null, null], "powers": powers, "arena": arena_id})
			var s := sim.run_to_end()
			if s.winner == a_index:
				wins += 1.0
			elif s.winner == -1:
				wins += 0.5
			if a_power == 1.0:
				durations.append(s.time)
				if s.reason == "time_limit":
					timeouts += 1
	return wins / (fights * 2)


## FAIL when the miss is clear of sampling noise, WARN otherwise.
func _flag(certain: bool, text: String) -> String:
	if certain:
		failures += 1
		return "FAIL: " + text
	return "WARN: %s; within sampling noise, rerun with more fights" % text


## Wilson score interval bounds for a win rate over n fights.
static func _lower_bound(p: float, n: int) -> float:
	return _wilson(p, n, -1.0)


static func _upper_bound(p: float, n: int) -> float:
	return _wilson(p, n, 1.0)


static func _wilson(p: float, n: int, sign_: float) -> float:
	var z2 := Z95 * Z95
	var centre := p + z2 / (2.0 * n)
	var spread := Z95 * sqrt(p * (1.0 - p) / n + z2 / (4.0 * n * n))
	return (centre + sign_ * spread) / (1.0 + z2 / n)
