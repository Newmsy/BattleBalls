extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const FightLink := preload("res://game/fight_link.gd")


func test_replay_code_round_trips() -> void:
	var code := FightLink.replay_code("vampire", "laser", 4242, -450, 1337)
	check_eq(code, "1.vampire.laser.4242.-450.1337", "code")
	check_eq(FightLink.parse_replay(code), {"p1": "vampire", "p2": "laser", "seed": 4242, "angles": [-450, 1337]}, "parsed")


func test_replayed_link_reproduces_the_fight() -> void:
	var cfg := {"seed": 77, "p1": "laser", "p2": "vampire", "angles": [-300, null]}
	var original := MatchSim.new(cfg)
	var result := original.run_to_end()
	var code := FightLink.replay_code(cfg.p1, cfg.p2, cfg.seed, original.launch_angles[0], original.launch_angles[1])
	var replay := MatchSim.new(FightLink.parse_replay(code))
	check_eq(replay.run_to_end().hash, result.hash, "replay hash")


func test_challenge_code_round_trips() -> void:
	var code := FightLink.challenge_code("laser", 9, -612)
	check_eq(code, "1.laser.9.-612", "code")
	check_eq(FightLink.parse_challenge(code), {"ball": "laser", "seed": 9, "aim": -612}, "parsed")


func test_mirrored_shot_aims_the_same_way_from_the_other_corner() -> void:
	check_eq(FightLink.mirror_angle(MatchSim.AIM_AT_CENTRE[0]), MatchSim.AIM_AT_CENTRE[1], "centre shot")
	check_eq(FightLink.mirror_angle(0), -1800, "right becomes left")
	check_eq(FightLink.mirror_angle(-900), 900, "up becomes down")
	check_eq(FightLink.mirror_angle(FightLink.mirror_angle(-450)), -450, "mirror twice")


func test_bad_codes_are_rejected() -> void:
	for code in ["", "1", "2.vampire.laser.1.0.0", "1.vampire.ghost.1.0.0", "1.vampire.laser.x.0.0",
			"1.vampire.laser.1.0", "1.vampire.laser.-5.0.0", "1.vampire.laser.1.99999.0"]:
		check_eq(FightLink.parse_replay(code), {}, "replay " + code)
	for code in ["", "1.vampire.1", "1.ghost.1.0", "1.vampire.1.0.0", "0.vampire.1.0"]:
		check_eq(FightLink.parse_challenge(code), {}, "challenge " + code)
