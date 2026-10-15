## Headless balance sim: runs many seeded fights for every pairing and prints a
## win-rate matrix, fight-length stats and balance flags as Markdown. The
## targets it checks are the ones in BALANCE.md.
## Usage: godot --headless --script res://tools/balance.gd -- [--fights=200] [--power-step] [--strict]
##        [--modifier=<id> | --modifiers]
##   --fights=N    seeds per pairing; each seed is fought from both corners (2N fights)
##   --power-step  also fights every ball one power step up against every ball,
##                 checking that power beats counters (slow: n^2 pairings)
##   --strict      exit 1 when a check fails beyond sampling noise
##   --modifier=ID run every check under one Chaos Weekend modifier (sim/modifiers.gd)
##   --modifiers   also run the equal-power checks under every modifier
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Modifiers := preload("res://sim/modifiers.gd")

## Targets from BALANCE.md.
const EQUAL_POWER_MAX := 0.65 ## No equal-power matchup above this.
const POWER_STEP_MIN := 0.70 ## One power step up wins at least this into anything.
const POWER_STEP := 1.25 ## One tier ~ +25% power (power-progression.md).
const MEDIAN_LENGTH := [20.0, 60.0] ## Seconds.
const Z95 := 1.96

var fights := 200
var durations: Array[float] = []
var timeouts := 0
var failures := 0
var modifier := Modifiers.NONE


func _init() -> void:
	var strict := false
	var power_step := false
	var all_modifiers := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
		elif arg == "--strict":
			strict = true
		elif arg == "--power-step":
			power_step = true
		elif arg.begins_with("--modifier="):
			modifier = arg.split("=")[1]
			if not Modifiers.has(modifier):
				printerr("Unknown modifier: %s (known: %s)" % [modifier, ", ".join(Modifiers.DEFS.keys())])
				quit(2)
				return
		elif arg == "--modifiers":
			all_modifiers = true
	var ids: Array = BallDefs.DEFS.keys().filter(func(id): return not BallDefs.DEFS[id].get("tutorial", false))
	var lines: Array[String] = []
	lines.append_array(_equal_power(ids))
	if power_step:
		lines.append("")
		lines.append_array(_power_step(ids))
	if all_modifiers:
		for id in Modifiers.DEFS:
			modifier = id
			durations.clear()
			timeouts = 0
			lines.append("")
			lines.append_array(_equal_power(ids))
	print("\n".join(lines))
	quit(1 if strict and failures > 0 else 0)


## Every unordered pairing once, each seed fought from both corners, so the
## matrix is exactly complementary (row + column = 100%).
func _equal_power(ids: Array) -> Array[String]:
	var rate := {}
	for i in ids.size():
		for j in range(i, ids.size()):
			var a: String = ids[i]
			var b: String = ids[j]
			var r := _win_rate(a, 1.0, b)
			rate[a + ":" + b] = r
			rate[b + ":" + a] = 1.0 - r
	var lines: Array[String] = []
	lines.append("### Balance sim, equal power%s (%d fights per pairing, both corners)" % [_modifier_suffix(), fights * 2])
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


## Each playable ball one power step up against every playable ball at base
## power, mirror included. The worst result per ball must still clear the bar.
func _power_step(ids: Array) -> Array[String]:
	var playable: Array = BallDefs.PLAYABLE
	var lines: Array[String] = []
	lines.append("### Power step%s (row at x%.2f power vs column at base, %d fights per pairing)" % [_modifier_suffix(), POWER_STEP, fights * 2])
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
			var sim := MatchSim.new({"seed": 1000 + i, "p1": a if a_index == 0 else b, "p2": b if a_index == 0 else a, "angles": [null, null], "modifier": modifier})
			if a_power != 1.0:
				_boost(sim.balls[a_index], a_power)
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


## Stand-in for one tier until tiers exist in the sim: HP and every damage
## stat each scale by sqrt(power), so HP x damage scales by `power`.
static func _boost(ball, power: float) -> void:
	var k := sqrt(power)
	ball.hp *= k
	ball.max_hp *= k
	ball.contact_damage *= k
	var def: Dictionary = ball.def.duplicate()
	for key in def:
		if String(key).ends_with("_damage"):
			def[key] *= k
	ball.def = def


func _modifier_suffix() -> String:
	return "" if modifier == Modifiers.NONE else ", " + Modifiers.display_name(modifier)


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
