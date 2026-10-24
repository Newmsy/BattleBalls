## Live-ops schedule (game/liveops.gd, liveops/liveops.json): the bundled file
## is valid, dates resolve to the right week and weekend, fallbacks cover the
## gaps, and the Fight of the Day is a real, repeatable fight.
extends "res://tests/test_case.gd"

const LiveOps := preload("res://game/liveops.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Summon := preload("res://game/ui/summon.gd")
const Shell := preload("res://game/ui/shell.gd")


func _at(date: String, hour := 12) -> int:
	return LiveOps.date_unix(date) + hour * 3600


func _reset() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	LiveOps.now_override = 0


func test_bundled_schedule_is_valid() -> void:
	_reset()
	var d := LiveOps._read(LiveOps.BUNDLED)
	check(not d.is_empty(), "liveops.json parses")
	check_eq(LiveOps.validate(d), [], "no problems")


func test_validation_catches_mistakes() -> void:
	var bad := {"version": 1, "revision": 1, "seasons": [{"name": "S", "start": "2026-10-13", "weeks": 7}],
		"chaos": [{"weekend": "2026-10-17", "modifier": "big_head"}], "loaners": [{"date": "x"}],
		"fights": [{"date": "2026-02-30", "p1": "vampire", "p2": "laser", "seed": 1}, {"date": "2026-10-14", "p1": "boulder", "p2": "laser", "seed": 1}]}
	check_eq(LiveOps.validate(bad).size(), 3, "one problem per bad entry, old chaos/loaners lists ignored: %s" % [LiveOps.validate(bad)])
	check(not LiveOps.validate({"seasons": "x"}).is_empty(), "lists must be lists")


func test_dates_land_in_the_right_week() -> void:
	_reset()
	var wed := _at("2026-10-14")
	check_eq(LiveOps.season(wed).week, 1, "preseason week 1")
	check_eq(LiveOps.season(_at("2026-11-30")).name, "Season 1: Neon Nights", "Season 1 follows preseason")
	check_eq(LiveOps.season(_at("2027-01-18")), {}, "after the last season")
	check_eq(LiveOps.countdown(0, LiveOps.DAY + 7200), "1d 2h", "countdown")


## With no schedule the clock rotation takes over.
func test_fallbacks_need_no_schedule() -> void:
	LiveOps.use({})
	var t := _at("2027-03-03")
	check_eq(LiveOps.season(t), {}, "no season")
	check(LiveOps.fight_of_the_day(t).winner >= 0, "a fight")


func test_fight_of_the_day_replays_exactly() -> void:
	_reset()
	var t := _at("2026-10-20")
	var f := LiveOps.fight_of_the_day(t)
	check_eq(f.date, "2026-10-20", "date")
	check(f.p1 != f.p2, "a cross matchup")
	var sim := MatchSim.new({"seed": f.seed, "p1": f.p1, "p2": f.p2, "angles": f.angles})
	while not sim.finished:
		sim.step()
	check_eq(sim.winner, f.winner, "the arena replay ends the same way")
	LiveOps.use({})
	check_eq(LiveOps.fight_of_the_day(t).seed, f.seed, "generated from the date alone")
	var picked := {"version": 1, "revision": 1, "fights": [{"date": "2026-10-20", "p1": "laser", "p2": "laser", "seed": 42, "angles": [-450, 1350], "title": "Mirror night"}]}
	LiveOps.use(picked)
	var g := LiveOps.fight_of_the_day(t)
	check_eq([g.p1, g.seed, g.angles, g.title], ["laser", 42, [-450, 1350], "Mirror night"], "scheduled fight wins")
	_reset()


func test_board_builds_and_starts_the_fight() -> void:
	_reset()
	var shell = Shell.new()
	shell.build()
	for date in ["2026-10-14", "2026-10-17"]:
		LiveOps.now_override = _at(date)
		shell.go("week")
		check_eq(shell.current, "week", "board on " + date)
		check(shell._marks.has("week_quests"), "Quests door on the board")
		check(not shell._marks.has("week_chaos") and not shell._marks.has("try_shot"), "no Chaos or Try-a-Critter cards")
	var got := []
	shell.watch_requested.connect(func(f): got.append(f))
	var f := LiveOps.fight_of_the_day(LiveOps.now())
	shell.watch(f.merged({"pick": 1}))
	check_eq(got.size(), 1, "watch emitted")
	check_eq(got[0].pick, 1, "with the pick")
	shell.free()
	_reset()
