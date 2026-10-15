## Headless balance sim: runs many seeded fights for every pairing and prints a
## win-rate matrix, fight-length stats and balance flags as Markdown. The
## targets it checks are the ones in BALANCE.md.
## Usage: godot --headless --script res://tools/balance.gd -- [--fights=200] [--power-step] [--gear] [--strict] [--arena=square]
##   --fights=N    seeds per pairing; each seed is fought from both corners (2N fights)
##   --power-step  also fights every ball one power step up against every ball,
##                 checking that power beats counters (slow: n^2 pairings)
##   --gear        fights every playable ball wearing one Legendary piece of each
##                 gear stat line against itself bare, so the lines stay even
##   --strict      exit 1 when a check fails beyond sampling noise
##   --arena=ID    arena from sim/arenas.gd, or "all" for every playable arena;
##                 non-square arenas also get a tilt check against the square
##   --workers=N   fight in N separate processes (default: one per CPU core).
##                 Every fight is seeded, so the report is the same for any N.
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Gear := preload("res://sim/gear.gd")
const Arenas := preload("res://sim/arenas.gd")

## Targets from BALANCE.md.
const EQUAL_POWER_MAX := 0.65 ## No equal-power matchup above this.
const POWER_STEP_MIN := 0.70 ## One power step up wins at least this into anything.
const POWER_STEP := 1.25 ## One tier ~ +25% power (power-progression.md).
const MEDIAN_LENGTH := [20.0, 60.0] ## Seconds.
const Z95 := 1.96
## One Legendary gear piece is ~+7% power; its mirror win rate should land here.
## (Mirrors are touchy: attack and health, the reference lines, sit ~65%.)
const GEAR_LINE_RANGE := [0.58, 0.72]
## Two Legendary lines (Crit + Crit damage) together.
const GEAR_PAIR_RANGE := [0.66, 0.82]
## A map may move a matchup this far from its square result (design/arenas.md):
## WARN beyond TILT_WARN, FAIL beyond TILT_MAX when clear of sampling noise.
const TILT_WARN := 0.10
const TILT_MAX := 0.15

var fights := 200
var durations: Array[float] = []
var timeouts := 0
var failures := 0
var arena_id := "square"
## Finished pairings, "arena|a|power|b|gear" -> {wins, durations, timeouts}.
var results := {}


func _init() -> void:
	var strict := false
	var power_step := false
	var gear := false
	var arena_arg := "square"
	var workers := OS.get_processor_count()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
		elif arg.begins_with("--workers="):
			workers = int(arg.split("=")[1])
		elif arg.begins_with("--worker-jobs="):
			_work(arg.split("=")[1])
			return
		elif arg == "--strict":
			strict = true
		elif arg == "--power-step":
			power_step = true
		elif arg == "--gear":
			gear = true
		elif arg.begins_with("--arena="):
			arena_arg = arg.split("=")[1]
	var arenas: Array = Arenas.PLAYABLE if arena_arg == "all" else [arena_arg]
	if not arenas.has("square") and arenas.size() > 0:
		arenas = ["square"] + arenas # The tilt check needs the square as reference.
	var ids: Array = BallDefs.DEFS.keys().filter(func(id): return not BallDefs.DEFS[id].get("tutorial", false))
	var jobs := []
	for id in arenas:
		if not Arenas.DEFS.has(id):
			push_error("Unknown arena: %s" % id)
			quit(2)
			return
		for i in ids.size():
			for j in range(i, ids.size()):
				jobs.append([id, ids[i], 1.0, ids[j], null])
		if power_step and not (id == "square" and arena_arg != "square" and arena_arg != "all"):
			for a in BallDefs.PLAYABLE:
				for b in BallDefs.PLAYABLE:
					jobs.append([id, a, POWER_STEP, b, null])
	if gear:
		for g in _gear_kits():
			for a in BallDefs.PLAYABLE:
				if _gear_applies(a, g[1]):
					jobs.append(["square", a, 1.0, a, g[1]])
	if not _run_jobs(jobs, workers):
		quit(2)
		return
	var lines: Array[String] = []
	var square_rates := {}
	for id in arenas:
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
	if gear:
		arena_id = "square"
		lines.append("")
		lines.append_array(_gear_lines())
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


## Each gear line's test kit: [label, kit, band]. Crit damage rides on Crit,
## so it is checked as the pair.
static func _gear_kits() -> Array:
	var out := []
	for line in Gear.ORDER:
		var kit := {line: Gear.value(line, "legendary")}
		if line == "crit_damage":
			kit.crit_chance = Gear.value("crit_chance", "legendary")
			out.append(["crit_chance + crit_damage", kit, GEAR_PAIR_RANGE])
		else:
			out.append([line, kit, GEAR_LINE_RANGE])
	return out


## Cooldown speed only reaches critters with ability timers.
static func _gear_applies(a: String, kit: Dictionary) -> bool:
	var def := BallDefs.get_def(a)
	return not (kit.has("cooldown") and Gear.apply_def(def, kit) == def)


## Each playable ball wearing one Legendary piece of a single stat line,
## against the same ball bare. Lines should be worth about the same.
func _gear_lines() -> Array[String]:
	var playable: Array = BallDefs.PLAYABLE
	var lines: Array[String] = []
	lines.append("### Gear lines (row: one Legendary piece vs the same ball bare, %d fights per cell)" % (fights * 2))
	lines.append("")
	lines.append("| Line | " + " | ".join(playable) + " | mean |")
	lines.append("|---".repeat(playable.size() + 2) + "|")
	var flags: Array[String] = []
	for g in _gear_kits():
		var kit: Dictionary = g[1]
		var band: Array = g[2]
		var row: Array[String] = [g[0]]
		var mean := 0.0
		var cells := 0
		for a in playable:
			if not _gear_applies(a, kit):
				row.append("n/a")
				continue
			var r := _win_rate(a, 1.0, a, kit)
			row.append("%d%%" % roundi(100.0 * r))
			mean += r
			cells += 1
		mean /= maxi(1, cells)
		row.append("%d%%" % roundi(100.0 * mean))
		lines.append("| " + " | ".join(row) + " |")
		if mean < band[0] or mean > band[1]:
			flags.append("WARN: %s averages %d%% (aim %d-%d%%)" % [row[0], roundi(100 * mean), roundi(100 * band[0]), roundi(100 * band[1])])
	lines.append("")
	lines.append("**Checks:** " + ("every gear line within range." if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## Share of fights `a` (at `a_power`, wearing `a_gear`) wins against `b` at
## base power; draws count half. Each seed is played with `a` in both corners.
## Read from the results `_run_jobs` collected.
func _win_rate(a: String, a_power: float, b: String, a_gear = null) -> float:
	var r: Dictionary = results[_key([arena_id, a, a_power, b, a_gear])]
	if a_power == 1.0 and a_gear == null:
		for d in r.durations:
			durations.append(float(d))
		timeouts += int(r.timeouts)
	return float(r.wins) / (fights * 2)


static func _key(job: Array) -> String:
	return "%s|%s|%s|%s|%s" % [job[0], job[1], job[2], job[3], job[4]]


## Plays one pairing, [arena, a, a_power, b, a_gear]: every seed from both corners.
func _fight(job: Array) -> Dictionary:
	var a: String = job[1]
	var a_power: float = job[2]
	var b: String = job[3]
	var out := {"wins": 0.0, "durations": [], "timeouts": 0}
	for i in fights:
		for a_index in 2:
			var powers := [a_power, 1.0] if a_index == 0 else [1.0, a_power]
			var gear := [null, null]
			gear[a_index] = job[4]
			var sim := MatchSim.new({"seed": 1000 + i, "p1": a if a_index == 0 else b, "p2": b if a_index == 0 else a, "angles": [null, null], "powers": powers, "gear": gear, "arena": job[0]})
			var s := sim.run_to_end()
			if s.winner == a_index:
				out.wins += 1.0
			elif s.winner == -1:
				out.wins += 0.5
			out.durations.append(s.time)
			if s.reason == "time_limit":
				out.timeouts += 1
	return out


## Fills `results` for every job, split round-robin over separate Godot
## processes (the sim is not thread-safe, processes share nothing). Returns
## false when a worker died without writing its results.
func _run_jobs(jobs: Array, workers: int) -> bool:
	workers = clampi(workers, 1, jobs.size())
	if workers == 1:
		for job in jobs:
			results[_key(job)] = _fight(job)
		return true
	var base := "user://balance_%d_" % OS.get_process_id()
	var pids := []
	for w in workers:
		var mine := []
		for k in range(w, jobs.size(), workers):
			mine.append(jobs[k])
		var path := ProjectSettings.globalize_path(base + str(w) + ".bin")
		DirAccess.remove_absolute(path + ".out")
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_var(mine)
		f.close()
		pids.append(OS.create_process(OS.get_executable_path(), ["--headless", "--quiet", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tools/balance.gd", "--", "--fights=%d" % fights, "--worker-jobs=" + path]))
	while pids.any(func(pid): return OS.is_process_running(pid)):
		OS.delay_msec(100)
	var ok := true
	for w in workers:
		var path := ProjectSettings.globalize_path(base + str(w) + ".bin")
		var f := FileAccess.open(path + ".out", FileAccess.READ)
		var got = f.get_var() if f else null
		if f:
			f.close()
		if got is Dictionary:
			results.merge(got)
		else:
			push_error("Balance worker %d wrote no results" % w)
			ok = false
		DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(path + ".out")
	return ok


## Worker process: plays the jobs in `path` and writes their results next to it.
func _work(path: String) -> void:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	for job in f.get_var():
		out[_key(job)] = _fight(job)
	f.close()
	f = FileAccess.open(path + ".out", FileAccess.WRITE)
	f.store_var(out)
	f.close()
	quit(0)


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
