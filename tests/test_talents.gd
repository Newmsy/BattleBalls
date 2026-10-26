extends "res://tests/test_case.gd"

const Talents := preload("res://sim/talents.gd")
const Lineup := preload("res://sim/lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Profile := preload("res://meta/profile.gd")

const T0 := 1_800_000_000


func test_every_critter_has_a_faction() -> void:
	for id in BallDefs.PLAYABLE:
		if id != "plain":
			check(Talents.faction_of(id) in Talents.FACTIONS, "%s has a faction" % id)
	var seen := {}
	for f in Talents.MEMBERS:
		for id in Talents.MEMBERS[f]:
			check(not seen.has(id), "%s is in one faction only" % id)
			seen[id] = true
	check_eq(Talents.faction_of("plain"), "", "Plain has no faction")


func test_every_tree_has_the_same_shape() -> void:
	for f in Talents.FACTIONS:
		var t := Talents.tree(f)
		check_eq(t.size(), 13, "%s: 12 nodes and a capstone" % f)
		var cost := 0
		for n in t:
			cost += int(n.max) * int(n.cost)
			check(Talents.describe(n, 1) != "", "%s.%s has text" % [f, n.id])
		check_eq(cost, 40, "%s: 40 points of options" % f)
		check_eq(Talents.spent(f, Talents.suggested(f)), Talents.MAX_POINTS, "%s: the suggested build spends all 30" % f)


func test_picks_are_cleaned_to_the_rules() -> void:
	var f := "fire"
	check_eq(Talents.clean(f, {"kindling": 9, "laser_eyes": 3}), {"kindling": 3}, "rank capped, unknown nodes dropped")
	check_eq(Talents.clean(f, {"flashpoint": 3}), {}, "row 3 stays shut with nothing below it")
	var greedy := {}
	for n in Talents.tree(f):
		greedy[n.id] = 3
	check_eq(Talents.spent(f, Talents.clean(f, greedy)), Talents.MAX_POINTS, "at most 30 points")
	var full := Talents.suggested(f)
	var t1 := Talents.clean(f, full, 1)
	for id in t1:
		check_eq(Talents.node(f, id).row, 1, "a T1 critter only uses row 1")
	check(Talents.clean(f, full, 5).has("wildfire"), "a T5 critter gets the capstone")
	check(not Talents.clean(f, full, 4).has("wildfire"), "a T4 critter doesn't")
	check_eq(Talents.clean(f, t1, 1), t1, "cleaning is idempotent")


func test_slots_carry_talents_and_rate_higher() -> void:
	var bare := Lineup.make("vampire", 5, 50)
	var full := Lineup.make("vampire", 5, 50, [], Talents.suggested("spooky"))
	check(not bare.has("talents"), "no talents key when there are none")
	check_eq(full.talents, Talents.suggested("spooky"), "slot keeps the tree")
	check_eq(Lineup.clean(full), full, "re-cleaning a slot changes nothing")
	check_near(float(Lineup.rating(full)) / Lineup.rating(bare), 1.0 + Talents.POINT_POWER * 30, 0.002, "full tree is about +40% Power Rating")
	var wrong := Lineup.make("vampire", 5, 50, [], {"kindling": 3})
	check(not wrong.has("talents"), "another faction's own nodes are dropped")


func _cfg(seed: int, talents) -> Dictionary:
	var cfg := {"seed": seed, "p2": "vampire", "angles": [null, null]}
	Lineup.apply(cfg, 0, Lineup.make("juggernaut", 5, 1, [], talents))
	Lineup.apply(cfg, 1, Lineup.make("vampire", 5, 1))
	return cfg


func test_fights_with_talents_replay_and_without_are_unchanged() -> void:
	var a := MatchSim.new(_cfg(7, Talents.suggested("nature")))
	var b := MatchSim.new(_cfg(7, Talents.suggested("nature")))
	a.run_to_end()
	b.run_to_end()
	check_eq(a.state_hash(), b.state_hash(), "same slots and seed, same fight")
	var plain := {"seed": 7, "p1": "juggernaut", "p2": "vampire", "angles": [null, null], "tiers": [5, 5], "powers": [Lineup.power(Lineup.make("juggernaut", 5)), Lineup.power(Lineup.make("vampire", 5))], "gear": [[], []]}
	var c := MatchSim.new(plain)
	var d := MatchSim.new(_cfg(7, {}))
	c.run_to_end()
	d.run_to_end()
	check_eq(c.state_hash(), d.state_hash(), "an empty tree fights exactly like no tree")
	check(a.state_hash() != d.state_hash(), "a full tree changes the fight")


func test_every_faction_tree_fights() -> void:
	# Each faction's suggested build on one of its critters runs clean.
	for f in Talents.FACTIONS:
		var id: String = Talents.MEMBERS[f][0]
		var cfg := {"seed": 3, "angles": [null, null]}
		Lineup.apply(cfg, 0, Lineup.make(id, 5, 1, [], Talents.suggested(f)))
		Lineup.apply(cfg, 1, Lineup.make("vampire", 5, 1))
		var sim := MatchSim.new(cfg)
		var sum := sim.run_to_end()
		check(sim.finished, "%s (%s) finishes" % [f, id])
		check(not sim.balls[0].tal.is_empty(), "%s talents reach the ball" % f)


func test_points_come_from_play_and_respecs_are_free() -> void:
	var p = Profile.new_game(T0, "vampire")
	check_eq(p.faction_rank("spooky"), 0, "no points at the start")
	p.fight_faction_xp(["vampire"], 0)
	p.fight_faction_xp(["vampire"], 0)
	check_eq(p.faction_rank("spooky"), 1, "two wins make a point")
	p.stacks.append({"id": "ghost", "tier": 3, "count": 1, "level": 1, "xp": 0})
	check_eq(p.faction_rank("spooky"), 3, "a T3 Spooky critter adds T2 and T3 milestones")
	check(not p.add_talent("spooky", "fright"), "row 3 is shut")
	check(p.add_talent("spooky", "siphon"), "row 1 node")
	check(p.add_talent("spooky", "siphon"), "second rank")
	check(p.add_talent("spooky", "launch_kick"), "third point")
	check(not p.add_talent("spooky", "spark"), "no points left")
	check_eq(p.slot_of("vampire").talents, {"siphon": 2, "launch_kick": 1}, "owned slots carry the tree")
	var back = Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), T0)
	check_eq(back.talent_picks("spooky"), {"siphon": 2, "launch_kick": 1}, "saved and loaded")
	check(back.power_of("vampire") > Profile.from_dict(JSON.parse_string(JSON.stringify(Profile.new_game(T0, "vampire").to_dict())), T0).power_of("vampire"), "talents raise Power Rating")
	p.reset_talents("spooky")
	check_eq(p.talent_points_free("spooky"), 3, "reset gives every point back")


func test_every_fight_gives_faction_xp() -> void:
	var p = Profile.new_game(T0, "vampire")
	p.add_xp("vampire", 500)
	check_eq(int(p.factions.get("spooky", {}).get("xp", 0)), 0, "critter XP alone gives no Faction XP")
	p.fight_faction_xp(["vampire"], 1)
	p.fight_faction_xp(["vampire"], -1)
	check_eq(int(p.factions.spooky.xp), Profile.FACTION_FIGHT_XP.loss + Profile.FACTION_FIGHT_XP.draw, "a loss and a draw still pay")
	var gains: Array = p.take_faction_gains()
	check_eq(gains.size(), 1, "one entry per family")
	check_eq(int(gains[0].xp), 30, "gains add up until shown")
	check(p.take_faction_gains().is_empty(), "taking them clears them")
	# A team shares one fight's XP across its families.
	var fam := Talents.faction_of("vampire")
	var other := ""
	for f in Talents.FACTIONS:
		if f != fam:
			other = f
			break
	var q = Profile.new_game(T0, "vampire")
	q.fight_faction_xp(["vampire", "vampire", Talents.MEMBERS[other][0]], 0)
	check_eq(int(q.factions[fam].xp), 20, "two of three fighters: two thirds")
	check_eq(int(q.factions[other].xp), 10, "one of three: a third")
	q.take_faction_gains()
	q.fight_faction_xp(["vampire"], 0)
	q.fight_faction_xp(["vampire"], 0)
	var g: Dictionary = q.take_faction_gains()[0]
	check_eq([g.from_rank, g.from_xp, g.to_rank, g.to_xp], [0, 20, 1, 40], "a rank-up keeps the before and after")


func test_removing_a_point_keeps_open_rows_valid() -> void:
	var p = Profile.new_game(T0, "vampire")
	p.factions["spooky"] = {"xp": 100000, "picks": {}}
	for id in ["siphon", "siphon", "siphon", "launch_kick", "launch_kick"]:
		p.add_talent("spooky", id)
	check(p.add_talent("spooky", "haunt"), "row 2 opens at 5 spent")
	check(not p.remove_talent("spooky", "siphon"), "can't pull a point row 2 depends on")
	check(p.remove_talent("spooky", "haunt"), "top points come out")
