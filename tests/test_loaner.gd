## Try-a-Critter days (game/loaner.gd, LiveOps.loaner()): one critter a day,
## from the schedule or the rotation, lent only to players who don't own it and
## only in the casual modes.
extends "res://tests/test_case.gd"

const LiveOps := preload("res://game/liveops.gd")
const Loaner := preload("res://game/loaner.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const TrickShot := preload("res://sim/trick_shot.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const Shell := preload("res://game/ui/shell.gd")


func _at(date: String, hour := 12) -> int:
	return LiveOps.date_unix(date) + hour * 3600


func _reset() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	LiveOps.now_override = 0


## A profile that owns only Count Nibbles.
func _newcomer():
	var p = UiProfile.new()
	p.stacks.append({"id": "vampire", "tier": 1, "count": 1, "level": 1})
	return p


func test_bundled_loaners_are_playable() -> void:
	_reset()
	for l in LiveOps.data().get("loaners", []):
		check(l.critter in BallDefs.PLAYABLE, "bundled loaner %s must be playable in this build" % l.critter)


func test_schedule_picks_the_day_and_rotation_fills_gaps() -> void:
	LiveOps.use({"version": 1, "revision": 1, "loaners": [{"date": "2026-10-20", "critter": "laser", "blurb": "Beams!"}]})
	var l := LiveOps.loaner(_at("2026-10-20", 23))
	check_eq([l.critter, l.blurb, l.date], ["laser", "Beams!", "2026-10-20"], "scheduled day")
	check_eq(l.ends, LiveOps.date_unix("2026-10-21"), "ends at UTC midnight")
	# Every day has one, and over a pool's worth of days the rotation lends each playable critter.
	var seen := {}
	var pool := LiveOps.loaner_pool()
	for d in pool.size():
		var id: String = LiveOps.loaner(_at("2027-01-04") + d * LiveOps.DAY).critter
		check(id in BallDefs.PLAYABLE, "rotation lends a playable critter")
		seen[id] = true
	check_eq(seen.size(), pool.size(), "rotation covers the pool")
	check_eq(LiveOps.loaner(_at("2027-01-04")).critter, LiveOps.loaner(_at("2027-01-04", 23)).critter, "one pick all day")
	_reset()


## A newer schedule may name a critter this build can't play: it validates, and
## that day falls back to the rotation.
func test_unplayable_pick_falls_back() -> void:
	var d := {"version": 1, "revision": 1, "loaners": [{"date": "2026-10-20", "critter": "phoenix"}]}
	check_eq(LiveOps.validate(d), [], "known critter validates")
	check_eq(LiveOps.validate({"version": 1, "revision": 1, "loaners": [{"date": "2026-10-20", "critter": "nobody"}]}).size(), 1, "unknown critter rejected")
	LiveOps.use(d)
	check(LiveOps.loaner(_at("2026-10-20")).critter in BallDefs.PLAYABLE, "falls back to a playable critter")
	_reset()


func test_only_non_owners_borrow_and_only_in_casual_modes() -> void:
	# The next day lends someone else, so the check below doesn't depend on the fallback rotation.
	LiveOps.use({"version": 1, "revision": 1, "loaners": [{"date": "2026-10-20", "critter": "laser"}, {"date": "2026-10-21", "critter": "magnet"}]})
	var t := _at("2026-10-20")
	var p = _newcomer()
	var l := Loaner.today(p, t)
	check(l.on_loan and not l.owned, "Optic is on loan to a newcomer")
	check(Loaner.is_loan(p, "laser", t), "is_loan")
	for mode in ["quick", "challenge", "trickshot", "bounce_run"]:
		check(Loaner.can_use(p, "laser", mode, t), "loaner allowed in " + mode)
	for mode in ["ghost_arena", "campaign"]:
		check(not Loaner.can_use(p, "laser", mode, t), "loaner never counts for " + mode)
		check(Loaner.can_use(p, "vampire", mode, t), "owned critters still play " + mode)
	check(not Loaner.can_use(p, "laser", "quick", _at("2026-10-21")), "the loan ends with the day")
	var owner = _newcomer()
	owner.add_copies(["laser"])
	check(not Loaner.today(owner, t).on_loan, "no loan for someone who owns it")
	check(not Loaner.is_loan(owner, "laser", t), "owned is not a loan")
	_reset()


## The Critter Shot is its own puzzle, shot by the loaner; the main daily shot is unchanged.
func test_critter_shot_is_a_separate_fair_puzzle() -> void:
	for day in [1, 2, 30]:
		var main := TrickShot.generate(day)
		check_eq(main, TrickShot.generate(day, ""), "main puzzle unchanged")
		for id in BallDefs.PLAYABLE:
			var shot := TrickShot.generate(day, id)
			check_eq(shot.p1, id, "the loaner shoots")
			check(shot.starts != main.starts or shot.walls != main.walls, "a different puzzle from the main one")
			check(not shot.solutions.is_empty(), "solvable")
			check_eq(TrickShot.judge(shot, shot.solutions[0]).result, TrickShot.SOLVED, "a listed solution solves it")
			check_eq(shot, TrickShot.generate(day, id), "deterministic")


func test_board_shows_the_loaner_and_preselects_it() -> void:
	LiveOps.use({"version": 1, "revision": 1, "loaners": [{"date": "2026-10-20", "critter": "laser"}]})
	LiveOps.now_override = _at("2026-10-20")
	var shell = Shell.new()
	shell.profile = _newcomer()
	shell.build()
	shell.go("week")
	check(shell._marks.has("try_shot") and shell._marks.has("try_fight"), "Try-a-Critter card on the board")
	var got := []
	shell.play_requested.connect(func(): got.append(shell.play_with))
	shell._marks.try_fight.pressed.emit()
	check_eq(got, ["laser"], "Quick fight picks the loaner")
	shell.free()
	_reset()
