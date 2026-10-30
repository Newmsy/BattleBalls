## Headless Critter Plunge stats (sim/plunge.gd): knockout rate, race length,
## how often each starting gate and each racing critter wins, and each
## course's knockouts and length. Fair is 1.0x
## (wins exactly 1 race in n). Usage:
## godot --headless --script res://tools/plunge_stats.gd -- --races=400 --n=8
## (--n=all runs 4, 6 and 8; --base=1000 starts at another seed; --tier=5
## races the whole field at T5; --course=icicles races one course only;
## --jobs=4 splits the races over 4 Godot processes; --check exits 1 when
## the balance bands below fail; --you=3 --field=5 gives racer 1 every race
## talent of its family at rank 3 and the rest at rank 5, the way a league
## does (meta/plunge_league.gd), and reports how racer 1 does.)
## It warns about any gate or racer outside its band, and about racers still
## on the course 12 s after the winner (placed by height).
extends SceneTree

const Plunge := preload("res://sim/plunge.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")

## Warn past these (fair 1.0x).
const GATE_WARN := 1.4
const RACER_LOW := 0.6
const RACER_HIGH := 1.6
## --check fails when a racer's win share over every size run is outside
## this (looser than fights: a race can be a bit unbalanced), or a gate is
## over GATE_WARN. Run it with --n=all and 600+ races a size whenever racers
## or courses change: a fair share needs ~700 entries a racer to measure.
const CHECK_LOW := 0.5
const CHECK_HIGH := 1.8


func _init() -> void:
	var races := 400
	var sizes := [8]
	var base := 1
	var as_json := false
	var tier := 1
	var jobs := 1
	var course := ""
	var check := false
	var ranks := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--worker="):
			_work(a.get_slice("=", 1))
			return
		if a == "--check":
			check = true
		if a == "--json":
			as_json = true
		if a.begins_with("--races="):
			races = int(a.get_slice("=", 1))
		if a.begins_with("--n="):
			sizes = Plunge.FIELD_SIZES if a.get_slice("=", 1) == "all" else [int(a.get_slice("=", 1))]
		if a.begins_with("--base="):
			base = int(a.get_slice("=", 1))
		if a.begins_with("--tier="):
			tier = int(a.get_slice("=", 1))
		if a.begins_with("--jobs="):
			jobs = int(a.get_slice("=", 1))
		if a.begins_with("--course="):
			course = a.get_slice("=", 1)
		if a.begins_with("--you="):
			ranks = [int(a.get_slice("=", 1)), ranks[1] if ranks.size() > 1 else 0]
		if a.begins_with("--field="):
			ranks = [ranks[0] if ranks.size() > 0 else 0, int(a.get_slice("=", 1))]
	var won := {}
	var fair := {}
	var gates_ok := true
	for n in sizes:
		var t0 := Time.get_ticks_msec()
		var s := _measure_jobs(n, races, base, tier, course, jobs, ranks)
		if as_json:
			print("JSON ", JSON.stringify(s))
		else:
			_report(s, Time.get_ticks_msec() - t0)
		if not ranks.is_empty():
			print("racer 1 at rank %d, the field at rank %d: wins %.1f%% (fair %.1f%%), %.2f league points a race" % [ranks[0], ranks[1],
				100.0 * s.you_wins / races, 100.0 / n, float(s.you_points) / races])
		for id in s.entries:
			won[id] = won.get(id, 0.0) + s.wins.get(id, 0)
			fair[id] = fair.get(id, 0.0) + float(s.entries[id]) / n
		for g in s.gate_wins:
			gates_ok = gates_ok and float(g) / races * n <= GATE_WARN
	# Every size pooled: the balance check (--check fails outside it).
	var ids: Array = won.keys()
	ids.sort_custom(func(a, b): return won[a] / fair[a] > won[b] / fair[b])
	var bad := ids.filter(func(id): return won[id] / fair[id] < CHECK_LOW or won[id] / fair[id] > CHECK_HIGH)
	print("pooled win share: %s" % " ".join(ids.map(func(id): return "%s %.2f" % [id, won[id] / fair[id]])))
	if check:
		print("CHECK %s: racers outside %.1f-%.1fx %s, gates %s" % ["ok" if bad.is_empty() and gates_ok else "FAILED", CHECK_LOW, CHECK_HIGH, bad, "ok" if gates_ok else "over %.1fx" % GATE_WARN])
	quit(1 if check and not (bad.is_empty() and gates_ok) else 0)


func _report(s: Dictionary, ms: int) -> void:
	var n: int = s.n
	var races: int = s.races
	print("--- %d racers, %d races in %d ms (damage x%.2f)" % [n, races, ms, Plunge.field_damage(n)])
	print("knocked out %.1f%% · winning time median %.1fs p90 %.1fs · never finished %d" % [100.0 * s.ko_rate, s.median, s.p90, s.stuck])
	var gates := []
	for g in n:
		gates.append("%.1f%%" % (100.0 * s.gate_wins[g] / races))
	print("gate wins (fair %.1f%%): %s" % [100.0 / n, " ".join(gates)])
	for g in n:
		if float(s.gate_wins[g]) / races * n > GATE_WARN:
			print("WARNING gate %d wins %.2fx fair" % [g + 1, float(s.gate_wins[g]) / races * n])
	var ids: Array = s.critters.keys()
	ids.sort_custom(func(a, b): return s.critters[a].share > s.critters[b].share)
	for id in ids:
		var d: Dictionary = s.critters[id]
		var flag := "  <-- out of band" if d.share < RACER_LOW or d.share > RACER_HIGH else ""
		print("%-10s win %.2fx  KO %4.1f%%  (%d entries)%s" % [id, d.share, 100.0 * d.ko, d.entries, flag])
	var cids: Array = s.courses.keys()
	cids.sort()
	for id in cids:
		var c: Dictionary = s.courses[id]
		print("%-9s KO %4.1f%%  winning time %.1fs  unfinished %d  (%d races)" % [id, 100.0 * c.kos / (c.races * n), c.time / c.races, c.get("stuck", 0), c.races])
	if not s.stuck_at.is_empty():
		print("unfinished racers (course, section): %s" % [s.stuck_at])


## The numbers above as data (tests use it too).
static func measure(n: int, races: int, base := 1, tier := 1, course := "") -> Dictionary:
	return summarize(tally(n, races, base, tier, course))


## Raw counts for `races` races from seed `base`: they add up across runs
## (merge), so a run can be split over processes.
## `ranks`: [racer 1's talent rank, the rest's], or [] for none.
static func tally(n: int, races: int, base := 1, tier := 1, course := "", ranks := []) -> Dictionary:
	var gate_wins := []
	gate_wins.resize(n)
	gate_wins.fill(0)
	var entries := {}
	var wins := {}
	var knocked := {}
	var kos := 0
	var stuck := 0
	var stuck_at := {}
	var times: Array = []
	var courses := {}
	var you_wins := 0
	var you_points := 0
	for seed in range(base, base + races):
		var field: Array = Plunge.draw_field(seed, n)
		var cfg := {"seed": seed, "racers": field, "tiers": field.map(func(_id): return tier)}
		if course != "":
			cfg.course = course
		if not ranks.is_empty():
			cfg.boosts = []
			for k in n:
				cfg.boosts.append(PlungeTalents.at_rank(field[k], ranks[0] if k == 0 else ranks[1]))
		var p := Plunge.new(cfg)
		var res := p.run()
		var w: int = res.order[0]
		if w == 0:
			you_wins += 1
		if p.ko_ticks[0] < 0:
			you_points += PlungeTalents.VALUE.get(CritterPlunge.medal_for(p.places[0], n), 0)
		gate_wins[p.lanes[w]] += 1
		kos += res.kos.size()
		times.append(res.win_time)
		var c: Dictionary = courses.get(p.course.info.id, {"races": 0, "kos": 0, "time": 0.0, "stuck": 0})
		c.races += 1
		c.kos += res.kos.size()
		c.time += res.win_time
		for i in p.starters:
			var id: String = p.balls[i].type_id
			entries[id] = entries.get(id, 0) + 1
			if i == w:
				wins[id] = wins.get(id, 0) + 1
			if p.ko_ticks[i] >= 0:
				knocked[id] = knocked.get(id, 0) + 1
			elif p.finish_ticks[i] < 0:
				stuck += 1
				c.stuck += 1
				var where := "%s/%s" % [p.course.info.id, _section_at(p, p.balls[i].pos.y)]
				stuck_at[where] = stuck_at.get(where, 0) + 1
		courses[p.course.info.id] = c
	return {"n": n, "races": races, "kos": kos, "entries": entries, "wins": wins, "knocked": knocked, "times": times,
		"stuck": stuck, "stuck_at": stuck_at, "gate_wins": gate_wins, "courses": courses, "you_wins": you_wins, "you_points": you_points}


static func _section_at(p, y: float) -> String:
	for s in p.course.sections:
		if y >= s.y0 and y < s.y1:
			return s.kind
	return "end"


## Adds tally `b` into tally `a`.
static func merge(a: Dictionary, b: Dictionary) -> void:
	a.races += int(b.races)
	a.kos += int(b.kos)
	a.stuck += int(b.stuck)
	a.you_wins += int(b.you_wins)
	a.you_points += int(b.you_points)
	a.times.append_array(b.times)
	for g in a.gate_wins.size():
		a.gate_wins[g] += int(b.gate_wins[g])
	for key in ["entries", "wins", "knocked", "stuck_at"]:
		for id in b[key]:
			a[key][id] = a[key].get(id, 0) + int(b[key][id])
	for id in b.courses:
		var c: Dictionary = a.courses.get(id, {"races": 0, "kos": 0, "time": 0.0, "stuck": 0})
		for k in c:
			c[k] += b.courses[id][k]
		a.courses[id] = c


static func summarize(t: Dictionary) -> Dictionary:
	var n: int = t.n
	var races: int = t.races
	var times: Array = t.times.duplicate()
	times.sort()
	var critters := {}
	for id in t.entries:
		critters[id] = {"share": float(t.wins.get(id, 0)) / t.entries[id] * n, "ko": float(t.knocked.get(id, 0)) / t.entries[id], "entries": t.entries[id]}
	var out := t.duplicate()
	out.merge({"times": times, "ko_rate": float(t.kos) / (races * n), "median": times[races / 2], "p90": times[races * 9 / 10],
		"critters": critters}, true)
	return out


## Splits the races over `jobs` Godot processes (the sim is not thread-safe;
## processes share nothing), each a run of seeds.
func _measure_jobs(n: int, races: int, base: int, tier: int, course: String, jobs: int, ranks: Array) -> Dictionary:
	jobs = clampi(jobs, 1, races)
	if jobs == 1:
		return summarize(tally(n, races, base, tier, course, ranks))
	var stem := "user://plunge_stats_%d_" % OS.get_process_id()
	var running := []
	var from := base
	for w in jobs:
		var count := races / jobs + (1 if w < races % jobs else 0)
		var path := ProjectSettings.globalize_path(stem + str(w) + ".bin")
		DirAccess.remove_absolute(path + ".out")
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_var({"n": n, "races": count, "base": from, "tier": tier, "course": course, "ranks": ranks})
		f.close()
		from += count
		var pid := OS.create_process(OS.get_executable_path(), ["--headless", "--quiet", "--path", ProjectSettings.globalize_path("res://"),
			"--script", "res://tools/plunge_stats.gd", "--", "--worker=" + path])
		running.append([pid, path])
	var total := {}
	for r in running:
		while OS.is_process_running(r[0]):
			OS.delay_msec(200)
		var f := FileAccess.open(r[1] + ".out", FileAccess.READ)
		if f == null:
			push_error("plunge_stats worker %d wrote nothing" % r[0])
			continue
		var t: Dictionary = f.get_var()
		f.close()
		if total.is_empty():
			total = t
		else:
			merge(total, t)
		DirAccess.remove_absolute(r[1])
		DirAccess.remove_absolute(r[1] + ".out")
	return summarize(total)


## Worker process: the tally for the job in `path`, written to path.out.
func _work(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	var job: Dictionary = f.get_var()
	f.close()
	var o := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	o.store_var(tally(job.n, job.races, job.base, job.tier, job.course, job.ranks))
	o.close()
	DirAccess.rename_absolute(path + ".tmp", path + ".out")
	quit(0)
