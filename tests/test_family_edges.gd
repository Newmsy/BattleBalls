## Family edges (sim/families.gd, design/type-advantage.md): the chart's
## shape and the extra damage an edge hit deals.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Families := preload("res://sim/families.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


func _member(family: String) -> String:
	return Families.MEMBERS[family][0]


## Each family beats as many families as beat it, so none is stronger on
## the chart, and every family has at least one of each.
func test_every_family_wins_as_often_as_it_loses() -> void:
	for a in Families.ids():
		var counts := {2: 0, 1: 0, 0: 0, -1: 0, -2: 0}
		for b in Families.ids():
			if a != b:
				counts[Families.edge(_member(a), _member(b))] += 1
		check_eq(counts[2], counts[-2], "%s wins as often as it loses" % a)
		check(counts[2] >= 1, "%s beats someone" % a)
		check_eq(counts[1] + counts[-1], 0, "%s has no half edges" % a)


func test_chart_is_a_mirror() -> void:
	for a in Families.ids():
		for b in Families.ids():
			check_eq(Families.edge(_member(a), _member(b)), -Families.edge(_member(b), _member(a)), "%s vs %s" % [a, b])


## The themed headliners (Pokemon starters and friends) read the right way.
func test_themed_matchups() -> void:
	for pair in [["sea", "fire"], ["fire", "nature"], ["nature", "sea"], ["fire", "frost"], ["fire", "sweet"], ["frost", "sea"], ["sea", "tech"], ["spooky", "toybox"], ["toybox", "fire"]]:
		check_eq(Families.edge(_member(pair[0]), _member(pair[1])), 2, "%s beats %s" % pair)


func test_plain_bosses_and_own_family_are_even() -> void:
	check_eq(Families.edge("plain", "laser"), 0, "Plain has no family")
	check_eq(Families.edge("speedster", "sooty"), 0, "Fire vs Fire")
	check_eq(Families.edge_mult("speedster", "frost"), 1.1, "advantage is +10%")
	check_eq(Families.edge_mult("frost", "speedster"), 0.9, "weakness is -10%")


## One head-on contact hit each, no rolls: Fire (very good on Frost) hits
## 10% harder, Frost 10% softer, and the edge is on the damage event.
func test_edge_hit_deals_extra_damage() -> void:
	var dealt := {}
	for edges in [true, false]:
		var sim := MatchSim.new({"seek": 0.0, "rarity_potency": false, "seed": 5, "p1": "speedster", "p2": "frost", "angles": [null, null], "damage_rolls": false, "family_edges": edges})
		var a := sim.balls[0]
		var b := sim.balls[1]
		a.pos = Vector2(400, 500)
		b.pos = Vector2(400 + a.radius + b.radius - 1.0, 500)
		a.vel = Vector2(a.speed, 0)
		b.vel = Vector2(-b.speed, 0)
		sim.step()
		for e in sim.events:
			if e.type == "damage" and e.kind == "contact":
				dealt["%s:%d" % [edges, e.source]] = e.amount
				if edges:
					check_eq(e.edge, 2 if e.source == 0 else 0, "edge on the event")
	check(dealt.has("true:0") and dealt.has("false:0"), "Fire landed a contact hit")
	check_near(dealt.get("true:0", 0.0), dealt.get("false:0", 0.0) * 1.1, 0.001, "Fire hits Frost +10%")
	check_near(dealt.get("true:1", 0.0), dealt.get("false:1", 0.0) * 0.9, 0.001, "Frost hits Fire -10%")
