extends "res://tests/test_case.gd"

const Analytics := preload("res://game/online/analytics.gd")
const Stats := preload("res://game/stats/stats.gd")

const TEST_STATE := "user://test_analytics.json"


func _fresh() -> Analytics:
	if FileAccess.file_exists(TEST_STATE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_STATE))
	return Analytics.new(TEST_STATE)


func test_events_queue_and_survive_a_restart() -> void:
	var a := _fresh()
	a.add("fight_end", {"mode": "normal", "result": "win"})
	a.add("screen", {"name": "play"})
	var b := Analytics.new(TEST_STATE)
	b.load_state()
	check_eq(b.queue.size(), 2, "queued")
	check_eq(b.queue[0].name, "fight_end", "order kept")
	check(int(b.queue[0].t) > 1700000000000, "unix ms timestamp")
	a.free()
	b.free()


func test_queue_is_capped_keeping_the_newest() -> void:
	var a := _fresh()
	for i in Analytics.MAX_QUEUE + 7:
		a.queue.append({"name": "x", "props": {"i": i}, "t": 0})
	a.add("last")
	check_eq(a.queue.size(), Analytics.MAX_QUEUE, "capped")
	check_eq(a.queue[-1].name, "last", "newest kept")
	a.free()


func test_opting_out_clears_and_stops_tracking() -> void:
	var a := _fresh()
	a.add("screen", {"name": "play"})
	a.set_opted_out(true)
	check(a.queue.is_empty(), "queue cleared")
	a.add("screen", {"name": "bag"})
	check(a.queue.is_empty(), "nothing tracked while opted out")
	var b := Analytics.new(TEST_STATE)
	b.load_state()
	check(b.opt_out, "choice remembered")
	b.apply_privacy_signals({"analytics": "on"})
	check(not b.opt_out, "?analytics=on opts back in")
	a.free()
	b.free()


func test_sent_events_are_removed_by_number() -> void:
	var a := _fresh()
	for i in 5:
		a.add("e%d" % i)
	var last := int(a.queue[2].i)
	a.queue = a.queue.slice(1) # Trimmed while the batch of three was in flight.
	a.add("late")
	a.drop_sent(last)
	check_eq(a.queue.map(func(e): return e.name), ["e3", "e4", "late"], "unsent ones kept")
	var b := Analytics.new(TEST_STATE)
	b.load_state()
	b.add("next")
	check(int(b.queue[-1].i) > int(a.queue[-1].i), "numbers keep rising after a restart")
	a.free()
	b.free()


func test_opt_out_waits_to_delete_until_it_can() -> void:
	var a := _fresh()
	a.set_opted_out(true)
	check(a.forget_pending, "delete owed with no session yet")
	var b := Analytics.new(TEST_STATE)
	b.load_state()
	check(b.forget_pending, "still owed after a restart")
	a.free()
	b.free()


func test_no_backend_means_no_send() -> void:
	var a := _fresh()
	a.add("screen", {"name": "play"})
	a.flush()
	check_eq(a.queue.size(), 1, "kept for later")
	a.free()


func test_result_names() -> void:
	check_eq([Analytics.result_of(0), Analytics.result_of(1), Analytics.result_of(-1)], ["win", "loss", "draw"])


func test_stats_key_prefers_the_fragment() -> void:
	check_eq(Stats.key_from("#k=abc123"), "abc123", "fragment")
	check_eq(Stats.key_from("#x=1&k=abc"), "abc", "among other params")
	check_eq(Stats.key_from("#other=1"), "", "no key")


func test_retention_counts_only_mature_cohorts() -> void:
	var r := Stats.retention_rates([
		{"day": "2026-10-14", "size": 4, "d1": null, "d3": null, "d7": null},
		{"day": "2026-10-13", "size": 10, "d1": 5, "d3": null, "d7": null},
		{"day": "2026-10-10", "size": 10, "d1": 3, "d3": 2, "d7": null},
	])
	check_eq(r.d1, {"back": 8, "base": 20}, "d1")
	check_eq(r.d3, {"back": 2, "base": 10}, "d3")
	check_eq(r.d7.base, 0, "d7 not measurable yet")


func test_funnel_and_critter_rows() -> void:
	var f := Stats.funnel_rows({"starters": 10, "steps": [{"step": "cold_open", "players": 9, "median_ms": 100}, {"step": "starter", "players": 4, "median_ms": null}]})
	check_near(f[0].frac, 0.9, 0.001, "reached cold open")
	check_eq(f[1].median_ms, -1.0, "no timing")
	var c := Stats.critter_rows({"fights": 8, "rows": [{"critter": "vampire", "picks": 6, "wins": 3, "losses": 2, "draws": 1}, {"critter": "laser", "picks": 2}]})
	check_near(c[0].pick_frac, 0.75, 0.001, "pick share")
	check_near(c[0].win_frac, 0.5, 0.001, "win rate")
	check_eq(c[1].win_frac, -1.0, "no decided fights")
