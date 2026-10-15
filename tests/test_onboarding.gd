## Onboarding (design/onboarding.md): tutorial fights are always won, the cold
## open is a real fight, and the starter profile reaches its first fusion.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Onboarding := preload("res://game/onboarding.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const Shell := preload("res://game/ui/shell.gd")


func test_every_launch_wins_both_tutorial_fights() -> void:
	for starter in Onboarding.STARTERS:
		for f in Onboarding.FIGHTS:
			var losses := []
			for a in range(-1800, 1800, 20):
				var s := MatchSim.new({"seed": Onboarding.TUTORIAL_SEED, "p1": starter, "p2": f.foe, "angles": [a, f.foe_aim]}).run_to_end()
				if s.winner != 0:
					losses.append(a)
			check(losses.is_empty(), "%s vs %s loses at aims %s" % [starter, f.foe, losses])


func test_the_ghost_arrow_wins_quickly() -> void:
	for starter in Onboarding.STARTERS:
		for f in Onboarding.FIGHTS:
			var s := MatchSim.new({"seed": Onboarding.TUTORIAL_SEED, "p1": starter, "p2": f.foe, "angles": [f.ghost, f.foe_aim]}).run_to_end()
			check_eq(s.winner, 0, "%s wins %s on the ghost aim" % [starter, f.foe])
			check(s.time < 30.0, "%s vs %s on the ghost aim took %.1fs" % [starter, f.foe, s.time])


func test_cold_open_is_a_close_fight() -> void:
	var c: Dictionary = Onboarding.COLD_OPEN
	var s := MatchSim.new({"seed": c.seed, "p1": c.p1, "p2": c.p2}).run_to_end()
	check(s.winner >= 0, "cold open has a winner")
	check(s.time > 12.0 and s.time < 35.0, "cold open lasts %.1fs" % s.time)


func test_tutorial_foes_stay_out_of_pickers() -> void:
	for id in ["dummy", "sparring"]:
		check(BallDefs.DEFS[id].get("tutorial", false), id + " is marked tutorial")
		check(id not in BallDefs.PLAYABLE, id + " is not playable")
	for id in Onboarding.STARTERS:
		check(id in BallDefs.PLAYABLE, id + " starter exists in the sim")


func test_two_tutorial_wins_make_a_first_fusion() -> void:
	for id in Onboarding.STARTERS:
		var p = UiProfile.starter(id)
		check_eq(p.total_copies(id), 1, "starts with one copy")
		check(not p.can_fuse(id, 1), "nothing to fuse yet")
		for f in Onboarding.FIGHTS:
			p.add_copies([id])
		check(p.can_fuse(id, 1), "three copies after two wins")
		check_eq(p.fuse(id, 1).tier, 2, "fuses to T2")
		check_eq(p.best(id).tier, 2, "best is T2")


func test_every_screen_builds_for_a_new_player() -> void:
	var shell = Shell.new()
	shell.build()
	shell.set_profile(UiProfile.starter("laser"))
	for t in ["play", "critters", "fuse", "bag", "summon"]:
		shell.show_tab(t)
		check_eq(shell.current, t, "tab " + t)
	shell.go("detail", {"id": "laser"})
	check_eq(shell.current, "detail", "starter detail")
	shell.free()
