## Bounce Derby (sim/derby.gd, game/derby.gd): races replay exactly from the
## seed, every race ends, the course never traps a racer, the race tricks win
## a fair share, and liveops can schedule a derby event.
extends "res://tests/test_case.gd"

const Derby := preload("res://sim/derby.gd")
const LiveOps := preload("res://game/liveops.gd")
const Roster := preload("res://game/ui/roster.gd")


func _race(cfg: Dictionary) -> Dictionary:
	var d := Derby.new(cfg)
	var res := d.run()
	res.ticks = d.tick
	res.positions = d.racers.map(func(r): return r.pos)
	return res


func test_races_replay_from_the_seed() -> void:
	check_eq(_race({"seed": 77}), _race({"seed": 77}), "same seed, same race")
	check(_race({"seed": 77}).order != _race({"seed": 78}).order or _race({"seed": 77}).ticks != _race({"seed": 78}).ticks, "seeds differ")
	var ids := ["ghost", "speedster", "juggernaut"]
	check_eq(_race({"seed": 5, "racers": ids}), _race({"seed": 5, "racers": ids}), "pinned racers replay too")


## A pinned race. If a deliberate change moves it, update this and bump
## Derby.RULES_VERSION (old share links then say so).
func test_golden_race() -> void:
	var d := Derby.new({"seed": 2026})
	check_eq(d.racers.map(func(r): return r.id), ["juggernaut", "blackhole", "laser", "phoenix", "speedster", "bomber"], "racers")
	var res := d.run()
	check_eq(res.order, [2, 3, 5, 0, 4, 1], "finishing order")
	check_eq(d.tick, 2235, "race length in ticks")


func test_racers_are_six_different_critters_with_art() -> void:
	for seed in range(1, 40):
		var ids := Derby.draw_racers(seed)
		check_eq(ids.size(), Derby.RACERS, "seed %d racer count" % seed)
		for id in ids:
			check_eq(ids.count(id), 1, "seed %d repeats %s" % [seed, id])
			check(Roster.ids().has(id), "%s has roster art" % id)
	for c in Roster.CRITTERS:
		check(Derby.TRICKS.has(c.id), "%s has a race trick" % c.id)


## Pegs either leave a racer-wide gap to a wall or the divider, never a slot
## a racer could wedge in.
func test_course_has_no_wedges() -> void:
	for seed in range(1, 60):
		var d := Derby.new({"seed": seed})
		for p in d.pegs:
			var gap: float = minf(p.pos.x, Derby.WIDTH - p.pos.x) - p.r
			check(gap >= 2.0 * Derby.RADIUS + 4.0, "seed %d peg at %s is %.0f from a wall" % [seed, p.pos, gap])
		check(d.finish_y > 3000.0 and d.finish_y < 7000.0, "seed %d course length %.0f" % [seed, d.finish_y])


## Races end with a winner in watchable time, and nearly everyone finishes.
## The tricks win a fair share: each trick's racers win close to 1 in 6.
func test_races_are_watchable_and_fair() -> void:
	var wins := {}
	var starts := {}
	var times: Array = []
	var finished := 0
	var total := 0
	for seed in range(1, 61):
		var d := Derby.new({"seed": seed})
		var res := d.run()
		check_eq(res.order.size(), Derby.RACERS, "seed %d places everyone" % seed)
		check(res.win_time < Derby.TIME_LIMIT, "seed %d has a winner before the time limit" % seed)
		times.append(res.win_time)
		var w := d.racers[res.order[0]]
		wins[w.trick] = wins.get(w.trick, 0) + 1
		for r in d.racers:
			starts[r.trick] = starts.get(r.trick, 0) + 1
			total += 1
			if r.finish_tick >= 0:
				finished += 1
	times.sort()
	check(times[30] >= 12.0 and times[30] <= 45.0, "median winning time %.1fs" % times[30])
	check(float(finished) / total >= 0.7, "%d of %d racers finished" % [finished, total])
	for t in starts:
		var share: float = float(wins.get(t, 0)) / starts[t]
		check(share >= 0.09 and share <= 0.26, "trick %s wins %.0f%% of its races" % [t, share * 100.0])


func test_daily_derby_is_shared_and_events_take_over() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	var a := LiveOps.derby(LiveOps.date_unix("2026-10-20") + 3600)
	var b := LiveOps.derby(LiveOps.date_unix("2026-10-20") + 80000)
	check_eq(a, b, "one race per day")
	check_eq(a.number, 7, "numbered from launch day")
	check(LiveOps.derby(LiveOps.date_unix("2026-10-21")).seed != a.seed, "a new race tomorrow")
	check(not a.event, "an ordinary day")
	var spooky := LiveOps.derby(LiveOps.date_unix("2026-10-31") + 3600)
	check(spooky.event, "Halloween weekend is an event")
	check_eq(spooky.title, "Spooky Derby", "event title")
	check_eq(spooky.theme, "spooky", "event theme")
	check_eq(spooky.racers, ["ghost", "blackhole", "vampire", "bomber", "thorns", "phoenix"], "pinned racers")
	check_eq(spooky.ends, LiveOps.date_unix("2026-11-02"), "ends after the last day")


func test_validation_catches_bad_derbies() -> void:
	var base := {"version": 1, "revision": 1}
	var bad := [
		{"title": "No start"},
		{"start": "2026-10-30", "title": ""},
		{"start": "2026-10-30", "end": "2026-10-29", "title": "Backwards"},
		{"start": "2026-10-30", "title": "Odd theme", "theme": "lava"},
		{"start": "2026-10-30", "title": "Nobody", "racers": ["ghost", "nobody"]},
		{"start": "2026-10-30", "title": "Twins", "racers": ["ghost", "ghost"]},
		{"start": "2026-10-30", "title": "Solo", "racers": ["ghost"]},
	]
	check_eq(LiveOps.validate(base.merged({"derbies": bad})).size(), bad.size(), "one problem per bad derby: %s" % [LiveOps.validate(base.merged({"derbies": bad}))])
	var good := [{"start": "2026-12-24", "end": "2026-12-26", "title": "Festive Derby", "theme": "festive", "seed": 12, "racers": ["frost", "prism"]}]
	check_eq(LiveOps.validate(base.merged({"derbies": good})), [], "a good derby passes")


## The screen runs a practice race to the end without saving anything.
func test_screen_runs_a_race() -> void:
	var scene = load("res://game/derby.tscn").instantiate()
	runner.root.add_child(scene)
	# The test runner works before the tree's first frame, so _ready may wait.
	if scene.view == null:
		scene._ready()
	scene._use_practice(42)
	scene.pick = 1
	scene._show_pick()
	scene._start()
	check_eq(scene.state, scene.State.RACE, "racing")
	scene._cheer()
	scene._skip()
	check_eq(scene.state, scene.State.RESULT, "result shown")
	check(scene.share_text().contains("?mode=derby&race=42"), "share links the practice race: " + scene.share_text())
	scene.free()
