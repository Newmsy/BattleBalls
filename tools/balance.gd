## Headless balance sim: runs many seeded fights for every pairing and prints a
## win-rate matrix, fight-length stats and balance flags as Markdown. The
## targets it checks are the ones in BALANCE.md.
## Usage: godot --headless --script res://tools/balance.gd -- [--fights=200] [--power-step] [--gear] [--strict] [--arena=square]
##        [--modifier=<id> | --modifiers] [--variant-fights=N] [--only=id,id | --only=@sample]
##        [--shard=k/n] [--out=file.json] [--from=dir] [--no-equal] [--workers=N]
##        [--edge-warn | --edge-strict]
##   --fights=N    seeds per pairing; each seed is fought from both corners (2N fights)
##   --power-step  also fights every ball one power step up against every ball,
##                 checking that power beats counters (slow: n^2 pairings)
##   --gear        fights every playable ball wearing one Legendary piece of each
##                 gear stat line against itself bare, so the lines stay even
##   --strict      exit 1 when a check fails beyond sampling noise
##   --edge-warn   report equal-power and tilt misses on non-square arenas and
##                 under Chaos Weekend modifiers ("edge cells") as WARN, not
##                 FAIL, so they don't fail --strict. The square matchups and
##                 the power step still FAIL. On by default when
##                 GITHUB_EVENT_NAME is "pull_request" (the PR gate); the
##                 weekly audit stays strict on every cell.
##   --edge-strict edge cells FAIL as usual, even on a pull request
##   --arena=ID    arena from sim/arenas.gd, or "all" for every playable arena;
##                 non-square arenas also get a tilt check against the square
##   --modifier=ID run every check under one Chaos Weekend modifier (sim/modifiers.gd)
##   --modifiers   also run the equal-power checks under every modifier
##   --variant-fights=N  seeds for non-square arenas and modifiers (default --fights)
##   --only=IDS    only pairings that involve these critters (each against the
##                 whole field). "@sample" adds a fixed spread of live critters.
##   --shard=k/n   play only every n-th pairing, starting at the k-th, so CI can
##                 split one run across n machines. Checks cover that shard.
##   --out=FILE    also write the raw results as JSON (for --from)
##   --from=DIR    fight nothing: rebuild the report from the --out files in DIR
##   --no-equal    skip the equal-power matrices (for a power-step or gear run
##                 alongside a separate equal-power run)
##   --workers=N   fight in N separate processes (default: one per CPU core).
##                 Every fight is seeded, so the report is the same for any N.
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Modifiers := preload("res://sim/modifiers.gd")
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
## Above this many critters a matrix is unreadable: print one row per critter.
const MATRIX_MAX := 16
## Critters in "--only=@sample", spread evenly over the live roster.
const SAMPLE_SIZE := 8

var failures := 0
## Edge cells (non-square arena or Chaos modifier) WARN instead of FAIL.
var edge_warn := OS.get_environment("GITHUB_EVENT_NAME") == "pull_request"
## Edge-cell misses that would have been a FAIL under --edge-strict.
var edge_misses := 0
var only := [] ## Empty: every pairing.
## Finished pairings, job key -> {wins, n, durations, timeouts}.
var results := {}


func _init() -> void:
	var fights := 200
	var variant_fights := -1
	var strict := false
	var power_step := false
	var all_modifiers := false
	var gear := false
	var no_equal := false
	var arena_arg := "square"
	var modifier := Modifiers.NONE
	var shard := [1, 1]
	var out_path := ""
	var from_dir := ""
	var workers := OS.get_processor_count()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--worker-jobs="):
			_work(arg.split("=")[1])
			return
		elif arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
		elif arg.begins_with("--variant-fights="):
			variant_fights = int(arg.split("=")[1])
		elif arg == "--strict":
			strict = true
		elif arg == "--edge-warn":
			edge_warn = true
		elif arg == "--edge-strict":
			edge_warn = false
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
		elif arg == "--gear":
			gear = true
		elif arg == "--no-equal":
			no_equal = true
		elif arg.begins_with("--arena="):
			arena_arg = arg.split("=")[1]
		elif arg.begins_with("--only="):
			only = _only(arg.split("=")[1])
		elif arg.begins_with("--shard="):
			var parts := arg.split("=")[1].split("/")
			shard = [int(parts[0]), int(parts[1])]
			if shard[1] < 1 or shard[0] < 1 or shard[0] > shard[1]:
				printerr("Bad --shard, want k/n with 1 <= k <= n: %s" % arg)
				quit(2)
				return
		elif arg.begins_with("--out="):
			out_path = arg.split("=")[1]
		elif arg.begins_with("--from="):
			from_dir = arg.split("=")[1]
		elif arg.begins_with("--workers="):
			workers = int(arg.split("=")[1])
	if variant_fights < 0:
		variant_fights = fights
	var arenas: Array = Arenas.PLAYABLE if arena_arg == "all" else [arena_arg]
	if not arenas.has("square") and arenas.size() > 0:
		arenas = ["square"] + arenas # The tilt check needs the square as reference.
	for id in arenas:
		if not Arenas.DEFS.has(id):
			push_error("Unknown arena: %s" % id)
			quit(2)
			return

	# What to report, in order. Each section lists the pairings it reads.
	var ids: Array = BallDefs.DEFS.keys().filter(func(id): return not BallDefs.DEFS[id].get("tutorial", false))
	var sections := []
	var square: Dictionary = {}
	for id in arenas:
		var n := fights if id == "square" and modifier == Modifiers.NONE else variant_fights
		var eq := {"kind": "equal", "arena": id, "modifier": modifier, "fights": n,
			"report": not (id == "square" and arena_arg != "square" and arena_arg != "all")}
		var shown: bool = eq.report
		if no_equal:
			eq.report = false
		eq.jobs = [] if no_equal else _equal_jobs(ids, eq)
		if id == "square":
			square = eq
		else:
			eq.square = square
		sections.append(eq)
		if power_step and shown:
			var ps := {"kind": "power", "arena": id, "modifier": modifier, "fights": n, "report": true}
			ps.jobs = _power_jobs(ps)
			sections.append(ps)
	if all_modifiers:
		# Every twist on the square: arenas and twists don't stack in the game yet.
		for id in Modifiers.DEFS:
			var eq := {"kind": "equal", "arena": "square", "modifier": id, "fights": variant_fights, "report": true}
			eq.jobs = _equal_jobs(ids, eq)
			sections.append(eq)
	if gear:
		var g := {"kind": "gear", "arena": "square", "modifier": modifier, "fights": fights, "report": true}
		g.jobs = _gear_jobs(g)
		sections.append(g)

	if from_dir != "":
		if not _load_results(from_dir):
			quit(2)
			return
	else:
		var all_jobs := []
		var seen := {}
		for s in sections:
			for job in s.jobs:
				var key := _key(job)
				if not seen.has(key):
					seen[key] = true
					all_jobs.append(job)
		var mine := []
		for k in all_jobs.size():
			if k % shard[1] == shard[0] - 1:
				mine.append(all_jobs[k])
		if not _run_jobs(mine, workers):
			quit(2)
			return
		if out_path != "":
			var f := FileAccess.open(out_path, FileAccess.WRITE)
			f.store_string(JSON.stringify(results, "", true, true))
			f.close()

	var lines: Array[String] = []
	if edge_warn:
		lines.append("_Edge cells (other arenas, Chaos Weekend twists) report `WARN (audit FAIL)` instead of failing this run; the square matchups and power step still fail. The weekly Balance audit is strict on every cell (BALANCE.md)._")
		lines.append("")
	if shard[1] > 1:
		lines.append("_Shard %d of %d: checks below cover %d of this run's pairings._" % [shard[0], shard[1], results.size()])
		lines.append("")
	if not only.is_empty():
		lines.append("_Only pairings involving: %s._" % ", ".join(only))
		lines.append("")
	for s in sections:
		if not s.report:
			continue
		if not lines.is_empty() and lines[-1] != "":
			lines.append("")
		match s.kind:
			"equal":
				lines.append_array(_equal_power(ids, s))
				if s.arena != "square":
					lines.append_array(_tilt(s, s.square))
			"power":
				lines.append_array(_power_step(s))
			"gear":
				lines.append_array(_gear_lines(s))
	if edge_misses > 0:
		lines.append("")
		lines.append("**Edge cells:** %d miss(es) reported as `WARN (audit FAIL)` above. They don't block this PR, but the weekly audit will fail on them: fix them in a follow-up." % edge_misses)
	print("\n".join(lines))
	quit(1 if strict and failures > 0 else 0)


## The ids `--only` names. "@sample" adds a fixed spread of live critters
## (evenly over Critterpedia order), so an engine change is checked across the
## roster without fighting every pairing.
static func _only(value: String) -> Array:
	var picked := []
	for id in value.split(",", false):
		if id == "@sample":
			var live: Array = BallDefs.PLAYABLE
			for k in mini(SAMPLE_SIZE, live.size()):
				var pick = live[k * live.size() / mini(SAMPLE_SIZE, live.size())]
				if not picked.has(pick):
					picked.append(pick)
		elif BallDefs.DEFS.has(id) and not picked.has(id):
			picked.append(id)
	return picked


func _involved(a: String, b: String) -> bool:
	return only.is_empty() or only.has(a) or only.has(b)


## Job: [arena, modifier, a, a_power, b, gear_line, fights].
static func _key(job: Array) -> String:
	return "%s|%s|%s|%s|%s|%s|%d" % job


func _equal_jobs(ids: Array, s: Dictionary) -> Array:
	var jobs := []
	for i in ids.size():
		for j in range(i, ids.size()):
			if _involved(ids[i], ids[j]):
				jobs.append([s.arena, s.modifier, ids[i], 1.0, ids[j], "", s.fights])
	return jobs


func _power_jobs(s: Dictionary) -> Array:
	var jobs := []
	for a in BallDefs.PLAYABLE:
		for b in BallDefs.PLAYABLE:
			if _involved(a, b):
				jobs.append([s.arena, s.modifier, a, POWER_STEP, b, "", s.fights])
	return jobs


func _gear_jobs(s: Dictionary) -> Array:
	var jobs := []
	for line in Gear.ORDER:
		for a in BallDefs.PLAYABLE:
			if not _involved(a, a):
				continue
			# Cooldown speed only reaches critters with ability timers.
			var def := BallDefs.get_def(a)
			if line == "cooldown" and Gear.apply_def(def, _kit(line)) == def:
				continue
			jobs.append([s.arena, s.modifier, a, 1.0, a, line, s.fights])
	return jobs


## One Legendary piece of `line`. Crit damage rides on Crit, so it comes as a pair.
static func _kit(line: String) -> Dictionary:
	var kit := {line: Gear.value(line, "legendary")}
	if line == "crit_damage":
		kit.crit_chance = Gear.value("crit_chance", "legendary")
	return kit


## Win rate of the job's `a` (draws count half), or -1 when this run didn't
## play it (another shard, or outside --only).
func _rate(job: Array) -> float:
	var r = results.get(_key(job))
	return -1.0 if r == null else float(r.wins) / float(r.n)


## Equal-power rate of a over b from the one job that played the pair.
func _pair_rate(s: Dictionary, a: String, b: String) -> float:
	var r := _rate([s.arena, s.modifier, a, 1.0, b, "", s.fights])
	if r >= 0.0:
		return r
	r = _rate([s.arena, s.modifier, b, 1.0, a, "", s.fights])
	return -1.0 if r < 0.0 else 1.0 - r


## Every unordered pairing once, each seed fought from both corners, so the
## matrix is exactly complementary (row + column = 100%).
func _equal_power(ids: Array, s: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("### Balance sim, equal power, %s arena%s (%d fights per pairing, both corners)" % [Arenas.get_def(s.arena).display_name, _modifier_suffix(s.modifier), s.fights * 2])
	lines.append("")
	var rows: Array = ids if only.is_empty() else ids.filter(func(id): return only.has(id))
	if ids.size() <= MATRIX_MAX:
		lines.append("| Row beats column | " + " | ".join(ids) + " |")
		lines.append("|---".repeat(ids.size() + 1) + "|")
		for a in rows:
			var row: Array[String] = [a]
			for b in ids:
				row.append(_pct(_pair_rate(s, a, b)))
			lines.append("| " + " | ".join(row) + " |")
	else:
		lines.append_array(_field_table(rows, ids, func(a, b): return _pair_rate(s, a, b), "vs field"))
	var durations: Array[float] = []
	var timeouts := 0
	for job in s.jobs:
		var r = results.get(_key(job))
		if r == null:
			continue
		for d in r.durations:
			durations.append(int(d) * MatchSim.DT)
		timeouts += int(r.timeouts)
	var length_flags: Array[String] = []
	if not durations.is_empty():
		durations.sort()
		var median := durations[durations.size() / 2]
		var mean := 0.0
		for d in durations:
			mean += d
		mean /= durations.size()
		lines.append("")
		lines.append("Fight length: mean %.1fs, median %.1fs, p10 %.1fs, p90 %.1fs. Time-limit endings: %d of %d." % [
			mean, median, durations[durations.size() / 10], durations[durations.size() * 9 / 10], timeouts, durations.size()])
		if median < MEDIAN_LENGTH[0] or median > MEDIAN_LENGTH[1]:
			length_flags.append("WARN: median fight length %.1fs is outside %d-%ds" % [median, MEDIAN_LENGTH[0], MEDIAN_LENGTH[1]])
		if timeouts > 0:
			length_flags.append("WARN: %d fights hit the time limit" % timeouts)
	lines.append("")
	var flags: Array[String] = []
	var playable: Array = BallDefs.PLAYABLE
	for i in playable.size():
		for j in range(i + 1, playable.size()):
			var a: String = playable[i]
			var b: String = playable[j]
			var r := _pair_rate(s, a, b)
			if r < 0.0:
				continue
			var top := a if r >= 0.5 else b
			var low := b if r >= 0.5 else a
			var p := maxf(r, 1.0 - r)
			if p > EQUAL_POWER_MAX:
				flags.append(_flag(_lower_bound(p, s.fights * 2) > EQUAL_POWER_MAX, _is_edge(s),
					"%s beats %s %d%% at equal power (limit %d%%)" % [top, low, roundi(100 * p), roundi(100 * EQUAL_POWER_MAX)]))
	flags.append_array(length_flags)
	lines.append("**Checks:** " + ("all equal-power matchups within %d%%, fight length on target." % roundi(100 * EQUAL_POWER_MAX) if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## How far each playable matchup moved from its square result. Mirrors are
## included: they must stay near 50% on a symmetric arena.
func _tilt(s: Dictionary, square: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var flags: Array[String] = []
	var worst := 0.0
	var n_now: int = s.fights * 2
	var n_before: int = square.fights * 2
	var playable: Array = BallDefs.PLAYABLE
	for i in playable.size():
		for j in range(i, playable.size()):
			var a: String = playable[i]
			var b: String = playable[j]
			var now := _pair_rate(s, a, b)
			var before := _pair_rate(square, a, b)
			if now < 0.0 or before < 0.0:
				continue
			var delta := now - before
			worst = maxf(worst, absf(delta))
			if absf(delta) <= TILT_WARN:
				continue
			var se := sqrt(now * (1.0 - now) / n_now + before * (1.0 - before) / n_before)
			var text := "%s vs %s moved %+d points from the square (%d%% -> %d%%, limit %d)" % [
				a, b, roundi(100 * delta), roundi(100 * before), roundi(100 * now), roundi(100 * TILT_MAX)]
			if absf(delta) - Z95 * se > TILT_MAX:
				flags.append(_flag(true, _is_edge(s), text))
			else:
				flags.append("WARN: " + text)
	lines.append("")
	lines.append("**Tilt vs square:** largest move %d points." % roundi(100 * worst) + (" Within %d." % roundi(100 * TILT_WARN) if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## Each playable ball one power step up against every playable ball at base
## power, mirror included. The worst result per ball must still clear the bar.
func _power_step(s: Dictionary) -> Array[String]:
	var playable: Array = BallDefs.PLAYABLE
	var rate := func(a, b): return _rate([s.arena, s.modifier, a, POWER_STEP, b, "", s.fights])
	var lines: Array[String] = []
	lines.append("### Power step, %s arena%s (row at x%.2f power vs column at base, %d fights per pairing)" % [Arenas.get_def(s.arena).display_name, _modifier_suffix(s.modifier), POWER_STEP, s.fights * 2])
	lines.append("")
	if playable.size() <= MATRIX_MAX:
		lines.append("| Stronger row beats column | " + " | ".join(playable) + " | worst |")
		lines.append("|---".repeat(playable.size() + 2) + "|")
		for a in playable:
			var row: Array[String] = [a]
			for b in playable:
				row.append(_pct(rate.call(a, b)))
			row.append(_pct(_worst(a, playable, rate)[1]))
			lines.append("| " + " | ".join(row) + " |")
	else:
		var rows: Array = playable if only.is_empty() else playable.filter(func(id): return only.has(id))
		lines.append_array(_field_table(rows, playable, rate, "one step up vs field"))
	# Every played cell counts, including those where the stronger row is
	# outside --only and the --only critter is the one being beaten.
	var flags: Array[String] = []
	for a in playable:
		var w := _worst(a, playable, rate)
		if w[0] != "" and w[1] < POWER_STEP_MIN:
			flags.append(_flag(_upper_bound(w[1], s.fights * 2) < POWER_STEP_MIN, false,
				"%s one step up only beats %s %d%% (needs %d%%)" % [a, w[0], roundi(100 * w[1]), roundi(100 * POWER_STEP_MIN)]))
	lines.append("")
	lines.append("**Checks:** " + ("one power step beats every counter." if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## [opponent, rate] of a's lowest played cell, or ["", -1] if none was played.
static func _worst(a: String, field: Array, rate: Callable) -> Array:
	var worst := ["", -1.0]
	for b in field:
		var r: float = rate.call(a, b)
		if r >= 0.0 and (worst[0] == "" or r < worst[1]):
			worst = [b, r]
	return worst


## Each playable ball wearing one Legendary piece of a single stat line,
## against the same ball bare. Lines should be worth about the same.
func _gear_lines(s: Dictionary) -> Array[String]:
	var playable: Array = BallDefs.PLAYABLE
	var lines: Array[String] = []
	lines.append("### Gear lines (row: one Legendary piece vs the same ball bare, %d fights per cell)" % (s.fights * 2))
	lines.append("")
	var wide := playable.size() > MATRIX_MAX
	lines.append("| Line | mean |" if wide else "| Line | " + " | ".join(playable) + " | mean |")
	lines.append("|---|---|" if wide else "|---".repeat(playable.size() + 2) + "|")
	var flags: Array[String] = []
	for line in Gear.ORDER:
		var row: Array[String] = ["crit_chance + crit_damage" if line == "crit_damage" else line]
		var band: Array = GEAR_PAIR_RANGE if line == "crit_damage" else GEAR_LINE_RANGE
		var mean := 0.0
		var cells := 0
		for a in playable:
			var r := _rate([s.arena, s.modifier, a, 1.0, a, line, s.fights])
			if not wide:
				row.append("n/a" if r < 0.0 else _pct(r))
			if r >= 0.0:
				mean += r
				cells += 1
		if cells == 0:
			continue
		mean /= cells
		row.append(_pct(mean))
		lines.append("| " + " | ".join(row) + " |")
		if mean < band[0] or mean > band[1]:
			flags.append("WARN: %s averages %d%% (aim %d-%d%%)" % [row[0], roundi(100 * mean), roundi(100 * band[0]), roundi(100 * band[1])])
	lines.append("")
	lines.append("**Checks:** " + ("every gear line within range." if flags.is_empty() else ""))
	for f in flags:
		lines.append("- " + f)
	return lines


## One row per critter for rosters too big for a matrix: its mean against the
## field, and its worst and best matchups.
static func _field_table(rows: Array, field: Array, rate: Callable, what: String) -> Array[String]:
	var lines: Array[String] = []
	lines.append("| Critter | %s | worst | best |" % what)
	lines.append("|---|---|---|---|")
	for a in rows:
		var sum := 0.0
		var cells := 0
		var worst := ["", 2.0]
		var best := ["", -1.0]
		for b in field:
			if b == a:
				continue
			var r: float = rate.call(a, b)
			if r < 0.0:
				continue
			sum += r
			cells += 1
			if r < worst[1]:
				worst = [b, r]
			if r > best[1]:
				best = [b, r]
		if cells == 0:
			continue
		lines.append("| %s | %s | %s %s | %s %s |" % [a, _pct(sum / cells), worst[0], _pct(worst[1]), best[0], _pct(best[1])])
	return lines


static func _pct(r: float) -> String:
	return "·" if r < 0.0 else "%d%%" % roundi(100.0 * r)


## Plays one pairing: every seed from both corners.
static func _fight(job: Array) -> Dictionary:
	var a: String = job[2]
	var a_power: float = job[3]
	var b: String = job[4]
	var a_kit = null if job[5] == "" else _kit(job[5])
	var out := {"wins": 0.0, "n": 0, "durations": [], "timeouts": 0}
	for i in int(job[6]):
		for a_index in 2:
			var gear := [null, null]
			gear[a_index] = a_kit
			var powers := [a_power, 1.0] if a_index == 0 else [1.0, a_power]
			var sim := MatchSim.new({"seed": 1000 + i, "p1": a if a_index == 0 else b, "p2": b if a_index == 0 else a, "angles": [null, null], "powers": powers, "gear": gear, "arena": job[0], "modifier": job[1]})
			var s := sim.run_to_end()
			out.n += 1
			if s.winner == a_index:
				out.wins += 1.0
			elif s.winner == -1:
				out.wins += 0.5
			# Only bare equal-power fights count towards fight length.
			if a_power == 1.0 and a_kit == null:
				out.durations.append(s.ticks) # Whole ticks, so --out/--from round-trips exactly.
				if s.reason == "time_limit":
					out.timeouts += 1
	return out


## Fills `results` for every job, split round-robin over separate Godot
## processes (the sim is not thread-safe; processes share nothing). Returns
## false when a worker died without writing its results.
func _run_jobs(jobs: Array, workers: int) -> bool:
	workers = clampi(workers, 1, maxi(1, jobs.size()))
	if workers == 1:
		for job in jobs:
			results[_key(job)] = _fight(job)
		return true
	var base := "user://balance_%d_" % OS.get_process_id()
	var running := []
	for w in workers:
		var mine := []
		for k in range(w, jobs.size(), workers):
			mine.append(jobs[k])
		var path := ProjectSettings.globalize_path(base + str(w) + ".bin")
		DirAccess.remove_absolute(path + ".out")
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_var(mine)
		f.close()
		var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--quiet", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tools/balance.gd", "--", "--worker-jobs=" + path])
		if pid <= 0:
			push_error("Could not start balance worker %d" % w)
			return false
		running.append([pid, path])
	var ok := true
	for p in running:
		while OS.is_process_running(p[0]):
			OS.delay_msec(100)
		var f := FileAccess.open(p[1] + ".out", FileAccess.READ)
		if f == null:
			push_error("Balance worker %d wrote no results" % p[0])
			ok = false
			continue
		results.merge(f.get_var())
		f.close()
		DirAccess.remove_absolute(p[1])
		DirAccess.remove_absolute(p[1] + ".out")
	return ok


## Worker process: play the jobs in `path`, write their results to path.out.
func _work(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	var jobs: Array = f.get_var()
	f.close()
	var out := {}
	for job in jobs:
		out[_key(job)] = _fight(job)
	var o := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	o.store_var(out)
	o.close()
	DirAccess.rename_absolute(path + ".tmp", path + ".out")
	quit(0)


## Reads every .json file --out wrote under `dir` (one level of subfolders,
## the way CI downloads shard artifacts).
func _load_results(dir: String) -> bool:
	var files := []
	var d := DirAccess.open(dir)
	if d == null:
		push_error("No results folder: %s" % dir)
		return false
	for name in d.get_files():
		if name.ends_with(".json"):
			files.append(dir.path_join(name))
	for sub in d.get_directories():
		for name in DirAccess.get_files_at(dir.path_join(sub)):
			if name.ends_with(".json"):
				files.append(dir.path_join(sub).path_join(name))
	if files.is_empty():
		push_error("No .json results in %s" % dir)
		return false
	for path in files:
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(data) != TYPE_DICTIONARY:
			push_error("Not a results file: %s" % path)
			return false
		results.merge(data)
	return true


static func _modifier_suffix(id: String) -> String:
	return "" if id == Modifiers.NONE else ", " + Modifiers.display_name(id)


## True for a section off the plain square: another arena or a Chaos modifier.
static func _is_edge(s: Dictionary) -> bool:
	return s.arena != "square" or s.modifier != Modifiers.NONE


## FAIL when the miss is clear of sampling noise, WARN otherwise. An edge
## cell under --edge-warn says WARN (audit FAIL) and doesn't count as a failure.
func _flag(certain: bool, edge: bool, text: String) -> String:
	if certain and edge and edge_warn:
		edge_misses += 1
		return "WARN (audit FAIL): " + text
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
