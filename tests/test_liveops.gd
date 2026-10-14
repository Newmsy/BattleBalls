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
		"spotlight": [{"week": "2026-10-12", "critter": "nobody"}],
		"chaos": [{"weekend": "2026-10-17", "modifier": "big_head"}, {"weekend": "2026-10-16", "modifier": "moon_gravity"}],
		"fights": [{"date": "2026-02-30", "p1": "vampire", "p2": "laser", "seed": 1}, {"date": "2026-10-14", "p1": "boulder", "p2": "laser", "seed": 1}]}
	check_eq(LiveOps.validate(bad).size(), 6, "one problem per bad entry: %s" % [LiveOps.validate(bad)])
	check(not LiveOps.validate({"seasons": "x"}).is_empty(), "lists must be lists")


func test_dates_land_in_the_right_week() -> void:
	_reset()
	var wed := _at("2026-10-14")
	check_eq(LiveOps.season(wed).week, 1, "preseason week 1")
	check_eq(LiveOps.season(_at("2026-11-30")).name, "Season 1: Neon Nights", "Season 1 follows preseason")
	check_eq(LiveOps.spotlight(_at("2026-11-30")).critter, "magnet", "Flux debuts in Season 1 week 1")
	check_eq(LiveOps.season(_at("2027-01-18")), {}, "after the last season")
	check_eq(LiveOps.spotlight(wed).critter, "laser", "Optic week")
	check_eq(LiveOps.spotlight(_at("2026-10-19", 0)).critter, "bomber", "Monday midnight starts the next week")
	var c := LiveOps.chaos(wed)
	check_eq(c.modifier, "closing_walls", "this weekend")
	check(not c.live, "not live on Wednesday")
	check_eq(c.starts, LiveOps.date_unix("2026-10-16"), "starts Friday 00:00 UTC")
	check(LiveOps.chaos(_at("2026-10-16", 0)).live, "live from Friday midnight")
	check(LiveOps.chaos(_at("2026-10-18", 23)).live, "live through Sunday")
	check_eq(LiveOps.chaos(_at("2026-10-19", 0)).modifier, "double_trouble", "next week's twist")
	check_eq(LiveOps.countdown(0, LiveOps.DAY + 7200), "1d 2h", "countdown")


## With no schedule the clock rotation takes over, and it matches the sim's
## Chaos Weekend rotation.
func test_fallbacks_need_no_schedule() -> void:
	LiveOps.use({})
	var t := _at("2027-03-03")
	check(LiveOps.spotlight(t).critter != "", "a spotlight")
	check(LiveOps.chaos(t).name != "", "a chaos weekend")
	check_eq(LiveOps.season(t), {}, "no season")
	check(LiveOps.fight_of_the_day(t).winner >= 0, "a fight")
	if ResourceLoader.exists("res://sim/modifiers.gd"):
		var Modifiers = load("res://sim/modifiers.gd")
		check_eq(LiveOps.CHAOS_ROTATION, Modifiers.ROTATION, "same rotation as the sim")
		check_eq(LiveOps.EPOCH, Modifiers.ROTATION_EPOCH, "same week 0")
	_reset()
	# The bundled schedule agrees with the rotation, so the sim and the board match.
	for w in 7:
		var tw := _at("2026-10-14") + w * LiveOps.WEEK
		LiveOps.use({})
		var rotation: String = LiveOps.chaos(tw).modifier
		_reset()
		check_eq(LiveOps.chaos(tw).modifier, rotation, "week %d" % w)


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


func test_summon_features_the_spotlight() -> void:
	_reset()
	LiveOps.now_override = _at("2026-10-21")
	check_eq(Summon.featured(), "bomber", "Fuse week")
	_reset()


func test_board_builds_and_starts_the_fight() -> void:
	_reset()
	var shell = Shell.new()
	shell.build()
	for date in ["2026-10-14", "2026-10-17"]:
		LiveOps.now_override = _at(date)
		shell.go("week")
		check_eq(shell.current, "week", "board on " + date)
	var got := []
	shell.watch_requested.connect(func(f): got.append(f))
	var f := LiveOps.fight_of_the_day(LiveOps.now())
	shell.watch(f.merged({"pick": 1}))
	check_eq(got.size(), 1, "watch emitted")
	check_eq(got[0].pick, 1, "with the pick")
	shell.free()
	_reset()
