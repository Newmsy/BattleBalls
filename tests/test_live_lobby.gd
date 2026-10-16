extends "res://tests/test_case.gd"
## The live-fight referee (server/live_lobby.gd) and the shared config builder
## (sim/live_match.gd) both phones use.

const Lobby := preload("res://server/live_lobby.gd")
const LiveMatch := preload("res://sim/live_match.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Lineup := preload("res://sim/lineup.gd")

var _seed := 100


func _lobby() -> Lobby:
	return Lobby.new(_next_seed)


func _next_seed() -> int:
	_seed += 1
	return _seed


func _to(out: Array, pid: String, t: String) -> Dictionary:
	for m in out:
		if m[0] == pid and m[1].t == t:
			return m[1]
	return {}


func test_two_close_players_are_paired_and_the_server_referees() -> void:
	var l := _lobby()
	l.join("a", "1v1", [Lineup.make("bomber", 3)], 0.0)
	l.join("b", "1v1", [Lineup.make("laser", 3)], 0.5)
	var out := l.tick(1.0)
	var ma := _to(out, "a", "matched")
	var mb := _to(out, "b", "matched")
	check(not ma.is_empty() and not mb.is_empty(), "both told about the match")
	check_eq([ma.side, mb.side], [0, 1], "sides")
	check_eq(ma.seed, mb.seed, "same seed for both")
	check(l.aim("a", ma.match, -450, 2.0).is_empty(), "nothing until both aimed")
	out = l.aim("b", mb.match, 900, 3.0)
	var go := _to(out, "a", "go")
	check_eq(go.angles, [-450, 900], "both angles sent")
	var mine := MatchSim.new(LiveMatch.config(ma.seed, ma.sides, go.angles)).run_to_end()
	check_eq(mine.hash, go.hash, "a phone replaying the inputs gets the server's fight")
	check_eq(mine.winner, go.winner, "and its winner")
	check_eq(_to(out, "b", "go").hash, go.hash, "both get the same result")


func test_far_apart_players_wait_then_get_a_ghost() -> void:
	var l := _lobby()
	l.join("weak", "1v1", [Lineup.make("vampire", 1)], 0.0)
	l.join("strong", "1v1", [Lineup.make("vampire", 5)], 0.0)
	check(_to(l.tick(1.0), "weak", "matched").is_empty(), "T1 vs T5 not paired at once")
	var out := l.tick(Lobby.GHOST_AFTER)
	check(not _to(out, "weak", "ghost").is_empty(), "ghost offered after the wait")
	check(l.queue.is_empty(), "both left the queue")


func test_the_band_widens_with_waiting() -> void:
	var l := _lobby()
	l.join("a", "1v1", [Lineup.make("vampire", 3)], 0.0) # Common...
	l.join("b", "1v1", [Lineup.make("frost", 3)], 0.0) # ...vs Uncommon: x1.118 Power, outside ±10%.
	check(_to(l.tick(1.0), "a", "matched").is_empty(), "not at first")
	check(not _to(l.tick(Lobby.BAND_STEP), "a", "matched").is_empty(), "paired once the band reaches 15%")


func test_a_missing_angle_comes_from_the_seed_at_the_deadline() -> void:
	var l := _lobby()
	l.join("a", "1v1", [Lineup.make("bomber", 2)], 0.0)
	l.join("b", "1v1", [Lineup.make("laser", 2)], 0.0)
	var m := _to(l.tick(0.0), "a", "matched")
	l.aim("a", m.match, 300, 1.0)
	check(_to(l.tick(5.0), "a", "go").is_empty(), "still aiming")
	var go := _to(l.tick(Lobby.AIM_SECONDS), "a", "go")
	check_eq(go.angles, [300, null], "the quiet player's ball is aimed by the seed")
	check_eq(MatchSim.new(LiveMatch.config(m.seed, m.sides, go.angles)).run_to_end().hash, go.hash, "replays the same")


func test_2v2_and_modes_never_mix() -> void:
	var l := _lobby()
	l.join("solo", "1v1", [Lineup.make("vampire", 3)], 0.0)
	l.join("a", "2v2", [Lineup.make("vampire", 3), Lineup.make("laser", 3)], 0.0)
	l.join("b", "2v2", [Lineup.make("vampire", 3), Lineup.make("bomber", 3)], 0.0)
	var out := l.tick(1.0)
	check(_to(out, "solo", "matched").is_empty(), "1v1 player not put in a 2v2")
	var m := _to(out, "a", "matched")
	check_eq(_to(out, "b", "matched").match, m.match, "the 2v2 players meet")
	var go := _to(l.aim("b", m.match, 100, 2.0) + l.aim("a", m.match, -100, 2.0), "a", "go")
	var cfg := LiveMatch.config(m.seed, m.sides, go.angles)
	check_eq([cfg.p1, cfg.p2, cfg.p3, cfg.p4], ["vampire", "vampire", "laser", "bomber"], "teams")
	check_eq(MatchSim.new(cfg).run_to_end().hash, go.hash, "replays the same")


func test_bad_setups_are_refused() -> void:
	var l := _lobby()
	for bad in [[], [{"critter": "not_a_critter"}], [Lineup.make("vampire"), Lineup.make("vampire")]]:
		var mode := "2v2" if bad.size() == 2 else "1v1"
		check(not _to(l.join("x", mode, bad, 0.0), "x", "error").is_empty(), "refused: %s" % str(bad))
	check(not _to(l.join("x", "3v3", [Lineup.make("vampire")], 0.0), "x", "error").is_empty(), "unknown mode")
	check(l.queue.is_empty(), "none queued")


## The setup and result travel as JSON: gear numbers must survive exactly.
func test_config_survives_the_wire() -> void:
	var slot := Lineup.make("vampire", 4, 31, [{"slot": "Shell", "tier": 4, "stats": {"attack": 0.0371234567891, "health": 0.0123}}])
	var sides := [[slot], [Lineup.make("laser", 4)]]
	var wire = JSON.parse_string(JSON.stringify({"sides": sides, "angles": [-450, null]}, "", true, true))
	var here := MatchSim.new(LiveMatch.config(77, sides, [-450, null])).run_to_end()
	var there := MatchSim.new(LiveMatch.config(77, wire.sides, wire.angles)).run_to_end()
	check_eq(there.hash, here.hash, "same fight after a JSON round trip")


func test_a_different_phone_hash_is_logged() -> void:
	var l := _lobby()
	l.join("a", "1v1", [Lineup.make("bomber", 3)], 0.0)
	l.join("b", "1v1", [Lineup.make("laser", 3)], 0.0)
	var m := _to(l.tick(0.0), "a", "matched")
	var go := _to(l.aim("a", m.match, 0, 1.0) + l.aim("b", m.match, 0, 1.0), "a", "go")
	l.report("a", m.match, go.hash)
	l.report("b", m.match, "edited")
	check_eq(l.mismatches.size(), 1, "one mismatch")
	check_eq(l.mismatches[0].player, "b", "the right player")
