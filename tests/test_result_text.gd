extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Relay := preload("res://sim/relay.gd")
const ResultText := preload("res://game/result_text.gd")

const NAMES := ["You", "The foe"]


## Two plain balls about to meet head on, with the given HP.
func _clash(hp_a: float, hp_b: float, extra := {}) -> MatchSim:
	var cfg := {"seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null]}
	cfg.merge(extra)
	var sim := MatchSim.new(cfg)
	var a := sim.balls[0]
	var b := sim.balls[1]
	a.hp = hp_a
	b.hp = hp_b
	a.pos = Vector2(400, 500)
	b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
	a.vel = Vector2(a.speed, 0)
	b.vel = Vector2(-b.speed, 0)
	sim.step()
	return sim


## Newms's fight: both on 0 HP at 34.9s used to read "YOU WIN!" with no reason.
func test_reported_double_knockout_says_double_ko() -> void:
	var sim := MatchSim.new({"seed": 80003, "p1": "vampire", "p2": "laser", "angles": [-450, null], "seek": 0.0, "family_edges": false})
	sim.run_to_end()
	check_eq(sim.end_reason, "double_knockout")
	var r := ResultText.describe(sim, NAMES)
	check_eq(r.headline, "DOUBLE KO!")
	check(r.detail.contains("going in"), "explains the tiebreak: " + r.detail)
	check_eq(r.tone, "win" if sim.winner == 0 else "lose")


func test_double_knockout_records_hp_going_in() -> void:
	var sim := _clash(3.0, 2.0)
	check(sim.finished, "both out")
	check_eq(sim.end_reason, "double_knockout")
	check_eq(sim.winner, 0)
	check_near(sim.ko_hp[0], 3.0, 0.0001, "your hp going in")
	check_near(sim.ko_hp[1], 2.0, 0.0001, "foe hp going in")
	var r := ResultText.describe(sim, NAMES)
	check_eq(r.tone, "win")
	check(r.detail.contains("3 vs 2 HP going in"), r.detail)


func test_even_double_knockout_is_a_draw() -> void:
	var sim := _clash(2.0, 2.0)
	check_eq(sim.winner, -1)
	var r := ResultText.describe(sim, NAMES)
	check_eq(r.headline, "DRAW")
	check_eq(r.tone, "draw")
	check_eq(r.color, ResultText.DRAW)


## Newms 2026-10-26: outside Quick fight a tie is the player's win, and in a
## relay leg a double KO knocks out both critters.
func test_tie_to_settles_a_double_knockout() -> void:
	var sim := _clash(2.0, 3.0, {"tie_to": 0})
	check_eq(sim.end_reason, "double_knockout")
	check_eq(sim.winner, 0, "your win even with less HP going in")
	var r := ResultText.describe(sim, NAMES)
	check_eq(r.headline, "Victory!")
	check_eq(r.tone, "win")
	var leg := _clash(2.0, 3.0, {"tie_to": -1})
	check_eq(leg.winner, -1, "a relay leg's double KO has no winner")


func test_relay_double_knockout_knocks_out_both() -> void:
	var relay := Relay.new({"seed": 1, "sides": [["plain", "plain"], ["plain"]], "tie_to": 0})
	check_eq(relay.leg_config().tie_to, -1, "legs never break a double KO by HP")
	var sim := _clash(2.0, 3.0, relay.leg_config())
	relay.record_leg(sim)
	check_eq(relay.slot, [1, 1] as Array[int], "both critters out")
	check(relay.finished, "the foe has no critters left")
	check_eq(relay.winner, 0, "you still had a critter")
	var even := Relay.new({"seed": 1, "sides": [["plain"], ["plain"]], "tie_to": 0})
	even.record_leg(_clash(2.0, 3.0, even.leg_config()))
	check_eq(even.winner, 0, "both sides out together: the attacker takes it")


func test_close_hp_shows_a_decimal() -> void:
	var sim := _clash(2.4, 2.2)
	var r := ResultText.describe(sim, NAMES)
	check(r.detail.contains("2.4") and r.detail.contains("2.2"), r.detail)


func test_replay_names_the_critters() -> void:
	var sim := _clash(3.0, 2.0)
	var r := ResultText.describe(sim, ["Plain", "Plain"], true)
	check_eq(r.headline, "DOUBLE KO!")
	check(r.detail.ends_with("Plain takes it."), r.detail)


func test_knockout_keeps_plain_headline() -> void:
	var sim := _clash(100.0, 1.0)
	check_eq(sim.end_reason, "knockout")
	var r := ResultText.describe(sim, NAMES)
	check_eq(r.headline, "Victory!")
	check_eq(r.detail, "")
