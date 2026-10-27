extends "res://tests/test_case.gd"

const Families := preload("res://sim/families.gd")
const FamilyEdges := preload("res://game/family_edges.gd")
const MatchSim := preload("res://sim/match_sim.gd")


func test_matchup_reads_from_side_zero() -> void:
	var sim = MatchSim.new({"seed": 1, "p1": "sooty", "p2": "frost"})
	var m := FamilyEdges.matchup(sim)
	check_eq(m.get("edge", 0), 2, "Fire on Frost is very good")
	check_eq(m.get("line", ""), "Fire has type advantage!", "the edge side's line")
	sim = MatchSim.new({"seed": 1, "p1": "frost", "p2": "sooty"})
	m = FamilyEdges.matchup(sim)
	check_eq(m.get("edge", 0), -2, "Frost on Fire is very bad")
	check_eq(m.get("adv", ""), "fire", "the edge side is still Fire")
	sim = MatchSim.new({"seed": 1, "p1": "sprout", "p2": "static"})
	check(FamilyEdges.matchup(sim).is_empty(), "Nature and Tech are even: no banner")
