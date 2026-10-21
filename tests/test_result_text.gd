extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const ResultText := preload("res://game/result_text.gd")

const NAMES := ["You", "The foe"]


## Two plain balls about to meet head on, with the given HP.
func _clash(hp_a: float, hp_b: float) -> MatchSim:
	var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "angles": [null, null]})
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
	var sim := MatchSim.new({"seed": 80006, "p1": "vampire", "p2": "laser", "angles": [-450, null], "seek": 0.0})
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
	check_eq(r.headline, "YOU WIN!")
	check_eq(r.detail, "")
