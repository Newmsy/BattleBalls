## Bracket of Legends: the bracket is the seed's alone (sim/bracket.gd), byes
## go to the top seeds, series are first to 2 (final first to 3), and the
## event timeline (game/legends.gd) puts one round a day with the final on
## Sunday.
extends "res://tests/test_case.gd"

const Bracket := preload("res://sim/bracket.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Legends := preload("res://game/legends.gd")
const LiveOps := preload("res://game/liveops.gd")
const Shell := preload("res://game/ui/shell.gd")


func _at(date: String, hour := 12) -> int:
	return LiveOps.date_unix(date) + hour * 3600


func test_seed_order_keeps_top_seeds_apart() -> void:
	check_eq(Bracket.seed_order(2), [1, 2], "2")
	check_eq(Bracket.seed_order(4), [1, 4, 2, 3], "4")
	check_eq(Bracket.seed_order(8), [1, 8, 4, 5, 2, 7, 3, 6], "8")
	var o := Bracket.seed_order(64)
	check_eq(o.size(), 64, "64 slots")
	check(o.find(1) < 32 and o.find(2) >= 32, "1 and 2 in opposite halves")


func test_same_seed_same_bracket() -> void:
	var cfg := {"seed": 77, "entrants": BallDefs.PLAYABLE.slice(0, Bracket.MAX_ENTRANTS)}
	var a := Bracket.new(cfg)
	var b := Bracket.new(cfg)
	check_eq(a.draw, b.draw, "same draw")
	check_eq(a.state_hash(), b.state_hash(), "same fights")
	check_eq(a.champion(), b.champion(), "same champion")
	var draws := {}
	for s in 12:
		draws[str(Bracket.new({"seed": s, "entrants": ["a", "b", "c", "d", "e"]}).draw)] = true
	check(draws.size() > 3, "different seeds shuffle the draw")


func test_byes_go_to_the_top_seeds() -> void:
	var ids := ["a", "b", "c", "d", "e"]
	var b := Bracket.new({"seed": 5, "entrants": ids})
	check_eq(b.size, 8, "5 entrants -> 8 slots")
	check_eq(b.rounds, 3, "3 rounds")
	check_eq(b.slots.count(""), 3, "3 byes")
	for m in [0, 1, 2, 3]:
		var a: String = b.slots[m * 2]
		var c: String = b.slots[m * 2 + 1]
		if a == "" or c == "":
			var other := a if c == "" else c
			check(b.seed_of(other) <= 3, "bye for seed %d" % b.seed_of(other))
	check_eq(b.round_name(0), "Quarter-finals", "round names")
	check_eq(Bracket.new({"seed": 1, "entrants": range(64).map(func(i): return "x%d" % i)}).round_name(0), "Round of 64", "64")


func test_series_are_real_fights() -> void:
	var b := Bracket.new({"seed": 2026, "entrants": BallDefs.PLAYABLE.slice(0, Bracket.MAX_ENTRANTS)})
	var final: Dictionary = b.get_match(b.rounds - 1, 0)
	var need := Bracket.FINAL_WINS_NEEDED
	check(final.wins.max() == need or final.games.size() > 2 * need, "series played to %d wins: %s" % [need, final.wins])
	check_eq(b.champion(), final.winner, "champion is the final's winner")
	check(b.champion() in BallDefs.PLAYABLE, "a real critter wins")
	for g in final.games.size():
		var game: Dictionary = final.games[g]
		check_eq(game.p1, final.a if g % 2 == 0 else final.b, "sides swap each game")
		# Replaying a game from what the bracket shows gives the same fight.
		var sim := MatchSim.new({"seed": game.seed, "p1": game.p1, "p2": game.p2, "angles": game.angles})
		check_eq(sim.run_to_end().hash, game.hash, "game %d replays" % (g + 1))
	check_eq(b.reached(b.champion()), b.rounds, "champion reached the end")


func test_timeline_puts_the_final_on_sunday() -> void:
	var ev := {"id": "t", "name": "T", "week": LiveOps.date_unix("2026-10-19"), "seed": 1, "entrants": range(64).map(func(i): return "x%d" % i)}
	check_eq(Legends.round_count(ev), 6, "64 -> 6 rounds")
	check_eq(Legends.reveal_at(ev, 0), LiveOps.date_unix("2026-10-20"), "64: first round Tuesday")
	check_eq(Legends.reveal_at(ev, 5), LiveOps.date_unix("2026-10-25"), "final Sunday")
	check_eq(Legends.opens(ev), LiveOps.date_unix("2026-10-12"), "picks open the Monday before")
	ev.entrants = ["vampire", "laser"]
	check_eq(Legends.locks(ev), LiveOps.date_unix("2026-10-25"), "2 entrants: just the final, Sunday")
	check_eq(Legends.phase(ev, _at("2026-10-24")), "picks", "Saturday: picks open")
	check_eq(Legends.phase(ev, _at("2026-10-25")), "done", "Sunday: final out")
	ev.entrants = ["a", "b", "c", "d", "e"]
	check_eq(Legends.reveal_at(ev, 0), LiveOps.date_unix("2026-10-23"), "8 slots: Friday")
	check_eq(Legends.rounds_out(ev, _at("2026-10-24")), 2, "two rounds out Saturday")
	check_eq(Legends.phase(ev, _at("2026-10-24")), "live", "live mid-week")


func test_schedule_and_fallback_events() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	check_eq(LiveOps.validate(LiveOps.data()), [], "bundled schedule valid")
	var ev := Legends.current(_at("2026-10-14"))
	check(not ev.is_empty(), "a bracket is open for picks now")
	check_eq(ev.entrants.size(), mini(BallDefs.PLAYABLE.size(), Legends.FIELD_SIZE), "every playable critter enters by default, up to FIELD_SIZE")
	check(ev.entrants.all(func(id): return id in BallDefs.PLAYABLE and ev.entrants.count(id) == 1), "different playable critters")
	check_eq(Legends.phase(ev, _at("2026-10-14")), "picks", "picks phase")
	# A season without its own entry gets one in its last week.
	LiveOps.use({"version": 1, "revision": 1, "seasons": [{"name": "S9", "start": "2027-01-04", "weeks": 7}]})
	var all := Legends.events()
	check_eq(all.size(), 1, "one fallback event")
	check_eq(all[0].week, LiveOps.date_unix("2027-02-15"), "in the season's last week")
	check_eq(Legends.events()[0].seed, all[0].seed, "fallback seed is stable")
	var bad := {"version": 1, "revision": 1, "brackets": [{"week": "2026-10-20", "seed": 1}, {"week": "2026-10-19"},
		{"week": "2026-10-19", "seed": 1, "entrants": ["laser", "laser"]}, {"week": "2026-10-19", "seed": 1, "entrants": ["laser", "nobody"]}]}
	check_eq(LiveOps.validate(bad).size(), 4, "one problem per bad bracket: %s" % [LiveOps.validate(bad)])
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))


func test_picks_lock_and_results_stay_hidden_until_seen() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	var ev := Legends.current(_at("2026-10-14"))
	ev = ev.merged({"id": "test-%d" % Time.get_ticks_usec()})
	var pick: String = ev.entrants[0]
	check(Legends.set_pick(ev, pick, _at("2026-10-14")), "pick before the lock")
	check_eq(Legends.pick_of(ev), pick, "stored")
	check(not Legends.set_pick(ev, ev.entrants[1], Legends.locks(ev)), "refused at the lock")
	check(not Legends.set_pick(ev, "nobody", _at("2026-10-14")), "only entrants")
	check_eq(Legends.pick_of(ev), pick, "unchanged")
	var last := Legends.bracket(ev).rounds - 1
	var day := Legends.reveal_at(ev, last) + 3600
	check(not Legends.shows_result(ev, last, 0, Legends.reveal_at(ev, last) - 1), "not out yet")
	check(not Legends.shows_result(ev, last, 0, day), "today's round hidden")
	Legends.mark_seen(ev, last, 0)
	check(Legends.shows_result(ev, last, 0, day), "shown once opened")
	var cfg := ConfigFile.new()
	cfg.load(Legends.SAVE_PATH)
	cfg.erase_section_key("picks", ev.id)
	cfg.erase_section_key("seen", "%s:%d:0" % [ev.id, last])
	cfg.save(Legends.SAVE_PATH)


func test_bracket_screen_builds_in_every_phase() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	var shell = Shell.new()
	shell.build()
	for day in ["2026-10-14", "2026-10-25", "2026-11-01", "2026-12-20"]:
		LiveOps.now_override = _at(day)
		shell.go("week")
		check_eq(shell.current, "week", "board on " + day)
		shell.go("bracket")
		check_eq(shell.current, "bracket", "bracket on " + day)
		shell.refresh_with({"round": 0})
	LiveOps.now_override = 0
	shell.free()


func test_fighting_a_bit_at_a_time_gives_the_same_bracket() -> void:
	var cfg := {"seed": 4242, "entrants": BallDefs.PLAYABLE.slice(0, 6)}
	var whole := Bracket.new(cfg)
	var bits := Bracket.new(cfg)
	var calls := 0
	var budget := [0]
	# Stop after every few ticks, so every series is resumed mid-game.
	while not bits.work(bits.rounds - 1, func(): budget[0] += 1; return budget[0] % 3 == 0):
		calls += 1
	check(calls > 10, "it really stopped part-way (%d calls)" % calls)
	check_eq(bits.state_hash(), whole.state_hash(), "same fights")
	check_eq(bits.champion(), whole.champion(), "same champion")
	check_eq(bits.progress(bits.rounds - 1), [bits.size - 1, bits.size - 1], "all done")


func test_saved_results_come_back_the_same() -> void:
	var cfg := {"seed": 99, "entrants": BallDefs.PLAYABLE.slice(0, 5)}
	var a := Bracket.new(cfg)
	a.work(0, func(): return false)
	var saved = JSON.parse_string(JSON.stringify(a.results()))
	var b := Bracket.new(cfg)
	b.load_results(saved)
	check(b.ready_through(0), "round 1 restored without fighting")
	check_eq(b.get_match(0, 0).games.map(func(g): return g.angles), a.get_match(0, 0).games.map(func(g): return g.angles), "angles come back as ints")
	check_eq(typeof(b.get_match(0, 0).games[0].angles[0]) if not b.get_match(0, 0).bye else TYPE_INT, TYPE_INT, "int angles")
	check_eq(b.state_hash(), Bracket.new(cfg).state_hash(), "rest fights out the same")
	var other := Bracket.new({"seed": 100, "entrants": cfg.entrants})
	other.load_results(saved)
	check(not other.has_match(0, 0) or other.is_bye(0, 0), "another bracket's results are ignored")
