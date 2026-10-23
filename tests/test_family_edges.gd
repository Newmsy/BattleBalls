## Family edges (sim/families.gd, design/type-advantage.md): the chart's
## shape and the extra damage an edge hit deals.
extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Families := preload("res://sim/families.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


func _member(family: String) -> String:
	return Families.MEMBERS[family][0]


func test_every_family_is_one_very_good_two_good_two_even_two_bad_one_very_bad() -> void:
	for a in Families.ids():
		var counts := {2: 0, 1: 0, 0: 0, -1: 0, -2: 0}
		for b in Families.ids():
			if a != b:
				counts[Families.edge(_member(a), _member(b))] += 1
		check_eq(counts, {2: 1, 1: 2, 0: 2, -1: 2, -2: 1}, "%s's matchups" % a)


func test_chart_is_a_mirror() -> void:
	for a in Families.ids():
		for b in Families.ids():
			check_eq(Families.edge(_member(a), _member(b)), -Families.edge(_member(b), _member(a)), "%s vs %s" % [a, b])


func test_very_good_arrows_make_one_loop() -> void:
	var at := "fire"
	var seen := {}
	for i in 9:
		seen[at] = true
		var next := ""
		for b in Families.EDGES[at]:
			if Families.EDGES[at][b] == 2:
				next = b
		at = next
	check_eq(seen.size(), 9, "the loop visits every family")
	check_eq(at, "fire", "and comes back to the start")


func test_edges_follow_the_wheel() -> void:
	var wheel: Array = Families.WHEEL
	check_eq(wheel.size(), 9, "every family is on the wheel once")
	for i in wheel.size():
		for k in range(1, 9):
			var want: int = [0, 2, 1, 1, 0, 0, -1, -1, -2][k]
			var a: String = wheel[i]
			var t: String = wheel[(i + k) % 9]
			check_eq(Families.edge(_member(a), _member(t)), want, "%s vs %s, %d clockwise" % [a, t, k])


func test_plain_bosses_and_own_family_are_even() -> void:
	check_eq(Families.edge("plain", "laser"), 0, "Plain has no family")
	check_eq(Families.edge("speedster", "sooty"), 0, "Fire vs Fire")
	check_eq(Families.edge_mult("speedster", "juggernaut"), 1.2, "very good is +20%")
	check_eq(Families.edge_mult("juggernaut", "speedster"), 1.0, "no penalty the other way")


## One head-on contact hit each, no rolls: Fire (very good on Nature) hits
## 20% harder, Nature hits normally, and the edge is on the damage event.
func test_edge_hit_deals_extra_damage() -> void:
	var dealt := {}
	for edges in [true, false]:
		var sim := MatchSim.new({"seek": 0.0, "rarity_potency": false, "seed": 5, "p1": "speedster", "p2": "juggernaut", "angles": [null, null], "damage_rolls": false, "family_edges": edges})
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
	check_near(dealt.get("true:0", 0.0), dealt.get("false:0", 0.0) * 1.2, 0.001, "Fire hits Nature +20%")
	check_near(dealt.get("true:1", 0.0), dealt.get("false:1", 0.0), 0.001, "Nature hits Fire normally")
