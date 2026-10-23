extends "res://tests/test_case.gd"

const Families := preload("res://sim/families.gd")
const FamilyEdges := preload("res://game/family_edges.gd")
const MatchSim := preload("res://sim/match_sim.gd")


func test_every_edge_has_a_kickoff_line() -> void:
	for a in Families.EDGES:
		for t in Families.EDGES[a]:
			check(FamilyEdges.LINES.has(a + ">" + t), "%s > %s has a kick-off line" % [a, t])
	var pairs := 0
	for a in Families.EDGES:
		pairs += Families.EDGES[a].size()
	check_eq(FamilyEdges.LINES.size(), pairs, "no lines for matchups without an edge")


func test_matchup_reads_from_side_zero() -> void:
	var sim = MatchSim.new({"seed": 1, "p1": "sooty", "p2": "sprout"})
	var m := FamilyEdges.matchup(sim)
	check_eq(m.get("edge", 0), 2, "Fire on Nature is very good")
	check_eq(m.get("line", ""), "Fire burns Nature!", "the edge side's line")
	sim = MatchSim.new({"seed": 1, "p1": "sprout", "p2": "sooty"})
	m = FamilyEdges.matchup(sim)
	check_eq(m.get("edge", 0), -2, "Nature on Fire is very bad")
	check_eq(m.get("adv", ""), "fire", "the edge side is still Fire")
	sim = MatchSim.new({"seed": 1, "p1": "sprout", "p2": "bubbles"})
	check(FamilyEdges.matchup(sim).is_empty(), "Nature and Sea are across the wheel: no banner")
