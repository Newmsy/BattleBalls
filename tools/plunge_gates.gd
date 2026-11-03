## Does the starting gate matter? Races every Plunge course many times and
## reports, per course and field size, each gate's win share and mean place
## (a knocked-out racer places last). Fields are drawn and gates shuffled by
## the seed as in a real race, so critter strength averages out over the
## gates; --same=<id> races a field of one critter instead.
## Each section is mirrored on a seeded coin flip, so gate g and its mirror
## (n-1-g) should match; the "pair" columns pool them (half the noise).
## Usage:
## godot --headless --script res://tools/plunge_gates.gd -- --races=200 --n=8 --jobs=4
## (--n=all for 4, 6 and 8; --courses=a,b limits courses; --base=1000 other
## seeds; --json prints the raw tallies too; --check exits 1 when a course's
## worst pair is past PLACE_WARN places or WIN_WARN x fair wins;
## --calibrate rewrites sim/plunge_gate_delays.gd from the run, so each gate
## pair's mean place matches the field's: run it, then run again on
## other seeds (--base=5001) to check.)
extends SceneTree

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const GateDelays := preload("res://sim/plunge_gate_delays.gd")
const DELAYS_PATH := "res://sim/plunge_gate_delays.gd"
const DELAY_STEP := 0.05 ## Delays are rounded to this (3 ticks).
const DAMP := 0.4 ## A place is worth more time at the gate than between finishers: 0.8 overshot about 2x.

## A gate pair whose mean place is this far behind (or ahead of) the field's
## mean, or whose win share is past this multiple of fair, is flagged.
const PLACE_WARN := 0.35
const WIN_WARN := 1.4


func _init() -> void:
	var races := 200
	var sizes := [8]
	var base := 1
	var jobs := 1
	var same := ""
	var as_json := false
	var check := false
	var calibrate := false
	var delays: Dictionary = GateDelays.DELAYS.duplicate(true)
	var courses: Array = PlungeCourse.COURSES.map(func(c): return c.id)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--worker="):
			_work(a.get_slice("=", 1))
			return
		if a.begins_with("--races="):
			races = int(a.get_slice("=", 1))
		if a.begins_with("--n="):
			sizes = Plunge.FIELD_SIZES if a.get_slice("=", 1) == "all" else [int(a.get_slice("=", 1))]
		if a.begins_with("--base="):
			base = int(a.get_slice("=", 1))
		if a.begins_with("--jobs="):
			jobs = int(a.get_slice("=", 1))
		if a.begins_with("--same="):
			same = a.get_slice("=", 1)
		if a.begins_with("--courses="):
			courses = Array(a.get_slice("=", 1).split(","))
		if a == "--json":
			as_json = true
		if a == "--check":
			check = true
		if a == "--calibrate":
			calibrate = true
	var failed := []
	for n in sizes:
		var t0 := Time.get_ticks_msec()
		var all := _run_jobs(n, races, base, courses, same, jobs)
		print("--- %d racers, %d races a course, %d s" % [n, races, (Time.get_ticks_msec() - t0) / 1000])
		print("course     worst  | mean place by gate (fair %.2f)          | win %% by gate (fair %.1f%%)" % [(n + 1) / 2.0, 100.0 / n])
		var pooled := _empty(n)
		for id in courses:
			var t: Dictionary = all[id]
			_add(pooled, t)
			var line := _line(id, t, n)
			print(line.text)
			if line.bad:
				failed.append("%s/%d" % [id, n])
			if as_json:
				print("JSON ", JSON.stringify({"course": id, "n": n, "tally": t}))
			if calibrate:
				if not delays.has(id):
					delays[id] = {}
				delays[id][n] = _recalibrate(t, n, id)
		print(_line("ALL", pooled, n).text)
	if calibrate:
		_write_delays(delays)
	if check:
		print("CHECK %s %s" % ["ok" if failed.is_empty() else "FAILED", failed])
	quit(1 if check and not failed.is_empty() else 0)


## One course's row: worst gate pair, then each gate's mean place and win %.
static func _line(id: String, t: Dictionary, n: int) -> Dictionary:
	var races: int = t.races
	var fair := (n + 1) / 2.0
	var worst := 0.0
	var worst_win := 1.0
	for g in n / 2:
		var place := float(t.place[g] + t.place[n - 1 - g]) / (2 * races)
		var win := float(t.wins[g] + t.wins[n - 1 - g]) / (2 * races) * n
		if absf(place - fair) > absf(worst):
			worst = place - fair
		if absf(win - 1.0) > absf(worst_win - 1.0):
			worst_win = win
	var places := []
	var wins := []
	for g in n:
		places.append("%.2f" % (float(t.place[g]) / races))
		wins.append("%4.1f" % (100.0 * t.wins[g] / races))
	var bad := absf(worst) > PLACE_WARN or worst_win > WIN_WARN or worst_win < 1.0 / WIN_WARN
	return {"bad": bad, "text": "%-9s %+.2f %.2fx | %s | %s%s" % [id, worst, worst_win, " ".join(places), " ".join(wins), "  <--" if bad else ""]}


## New delays for one course and size: each gate pair's mean place pulled
## to the field's, a place being worth the mean time between finishers
## (DAMP of it, so passes converge); the earliest gate opens on GO. Mean
## place, not mean finish time: a few racers caught in a machine for ages
## would swamp the times.
static func _recalibrate(t: Dictionary, n: int, id: String) -> Array:
	var gap := float(t.gap) / maxf(t.gaps, 1.0) / Plunge.TICK_RATE
	var fair := (n + 1) / 2.0
	var out := []
	for g in n / 2:
		var place: float = float(t.place[g] + t.place[n - 1 - g]) / (2.0 * t.races)
		out.append(GateDelays.delay(id, n, g) - DAMP * (place - fair) * gap)
	var low: float = out.min()
	return out.map(func(d): return snappedf(d - low, DELAY_STEP))


## Rewrites DELAYS in sim/plunge_gate_delays.gd (courses sorted, pairs
## outermost first; all-zero entries dropped).
static func _write_delays(delays: Dictionary) -> void:
	var path := ProjectSettings.globalize_path(DELAYS_PATH)
	var src := FileAccess.get_file_as_string(path)
	var lines := []
	var ids: Array = delays.keys()
	ids.sort()
	for id in ids:
		var parts := []
		var sizes: Array = delays[id].keys()
		sizes.sort()
		for n in sizes:
			var pairs: Array = delays[id][n]
			if pairs.any(func(d): return d > 0.0):
				parts.append("%d: [%s]" % [n, ", ".join(pairs.map(func(d): return "%.2f" % d))])
		if not parts.is_empty():
			lines.append('\t"%s": {%s},' % [id, ", ".join(parts)])
	var a := src.find("const DELAYS := {")
	var b := src.find("\n}\n", a)
	src = src.substr(0, a) + "const DELAYS := {\n" + "\n".join(lines) + ("\n" if not lines.is_empty() else "") + src.substr(b + 1)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(src)
	f.close()
	print("wrote %s (%d courses)" % [DELAYS_PATH, lines.size()])


static func _empty(n: int) -> Dictionary:
	var place := []
	place.resize(n)
	place.fill(0)
	return {"races": 0, "place": place, "wins": place.duplicate(), "fin": place.duplicate(), "ticks": place.duplicate(), "gap": 0, "gaps": 0}


static func _add(a: Dictionary, b: Dictionary) -> void:
	a.races += int(b.races)
	for g in a.place.size():
		for key in ["place", "wins", "fin", "ticks"]:
			a[key][g] += int(b[key][g])
	a.gap += int(b.gap)
	a.gaps += int(b.gaps)


## Raw counts for each course: `races` races from seed `base`.
static func tally(n: int, races: int, base: int, courses: Array, same := "") -> Dictionary:
	var out := {}
	for id in courses:
		var t := _empty(n)
		for seed in range(base, base + races):
			var field: Array = Plunge.draw_field(seed, n)
			if same != "":
				field = field.map(func(_x): return same)
			var p := Plunge.new({"seed": seed, "racers": field, "tiers": field.map(func(_x): return 1), "course": id})
			p.run()
			t.races += 1
			# The mean time between one place and the next, for --calibrate.
			var done: Array = p.order.filter(func(i): return p.finish_ticks[i] >= 0)
			if done.size() >= 2:
				t.gap += (p.finish_ticks[done[-1]] - p.finish_ticks[done[0]]) / (done.size() - 1)
				t.gaps += 1
			for i in p.starters:
				t.place[p.lanes[i]] += p.places[i]
				if p.places[i] == 1:
					t.wins[p.lanes[i]] += 1
				if p.finish_ticks[i] >= 0:
					t.fin[p.lanes[i]] += 1
					t.ticks[p.lanes[i]] += p.finish_ticks[i]
		out[id] = t
	return out


## Splits the courses' seeds over `jobs` Godot processes.
func _run_jobs(n: int, races: int, base: int, courses: Array, same: String, jobs: int) -> Dictionary:
	jobs = clampi(jobs, 1, races)
	if jobs == 1:
		return tally(n, races, base, courses, same)
	var stem := "user://plunge_gates_%d_" % OS.get_process_id()
	var running := []
	var from := base
	for w in jobs:
		var count := races / jobs + (1 if w < races % jobs else 0)
		var path := ProjectSettings.globalize_path(stem + str(w) + ".bin")
		DirAccess.remove_absolute(path + ".out")
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_var({"n": n, "races": count, "base": from, "courses": courses, "same": same})
		f.close()
		from += count
		var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--quiet", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tools/plunge_gates.gd", "--", "--worker=" + path])
		running.append([pid, path])
	var total := {}
	for r in running:
		while OS.is_process_running(r[0]):
			OS.delay_msec(200)
		var f := FileAccess.open(r[1] + ".out", FileAccess.READ)
		if f == null:
			push_error("plunge_gates worker %d wrote nothing" % r[0])
			continue
		var t: Dictionary = f.get_var()
		f.close()
		for id in t:
			if not total.has(id):
				total[id] = _empty(n)
			_add(total[id], t[id])
		DirAccess.remove_absolute(r[1])
		DirAccess.remove_absolute(r[1] + ".out")
	return total


func _work(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	var job: Dictionary = f.get_var()
	f.close()
	var o := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	o.store_var(tally(job.n, job.races, job.base, job.courses, job.same))
	o.close()
	DirAccess.rename_absolute(path + ".tmp", path + ".out")
	quit(0)
