## Ascension (Newms 2026-11-02): Sparks from weekly Arena chests and daily
## Bounce Run chests; ASCEND_COST of them raise a T5 critter one level (A1-A5);
## each level keeps half its Bounce Run boon in every fight it plays.
extends "res://tests/test_case.gd"

const Boons := preload("res://sim/boons.gd")
const Lineup := preload("res://sim/lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Profile := preload("res://meta/profile.gd")
const BounceChest := preload("res://meta/bounce_chest.gd")
const ArenaChest := preload("res://game/pvp/arena_chest.gd")
const ChestDrops := preload("res://meta/chest_drops.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const SpireScreen := preload("res://game/ui/screens/spire_screen.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const Talents := preload("res://sim/talents.gd")
const Shell := preload("res://game/ui/shell.gd")
const SparkShow := preload("res://game/ui/spark_show.gd")


func test_ascended_boon_scales_by_half_per_level() -> void:
	var a1 := Boons.ascended("juggernaut", 1)
	var a2 := Boons.ascended("juggernaut", 2)
	var a5 := Boons.ascended("juggernaut", 5)
	check_eq(a1.add.rock_max, 1, "A1 Landslide: +1 rock (half of +2)")
	check_eq(a2.add.rock_max, 2, "A2: the full +2")
	check_eq(a5.add.rock_max, 5, "A5: 2.5x")
	check(absf(a1.mul.slam_damage - 1.25) < 0.001, "A1 slams +25%")
	check(not "{" in a1.text, "text filled: %s" % a1.text)
	check(Boons.ascended("juggernaut", 0).is_empty(), "A0 is nothing")
	check(Boons.ascended("plain", 3).is_empty(), "no boon, no Ascension")


## A cut ("more often") scales with the level but never past the boon's own.
func test_cuts_never_pass_the_boon() -> void:
	for cid in Boons.CRITTER.values().map(func(b): return b["for"]):
		var base: Dictionary = Boons.get_def(Boons.for_critter(cid))
		var a5 := Boons.ascended(cid, 5)
		for key in base.get("mul", {}):
			if base.mul[key] < 1.0:
				check(a5.mul[key] >= base.mul[key] - 0.0001, "%s %s cut stays at the boon's" % [cid, key])


func test_slot_keeps_ascension_only_at_t5() -> void:
	check_eq(int(Lineup.make("juggernaut", 5, 50, [], {}, 3).get("ascend", 0)), 3, "T5 keeps A3")
	check_eq(int(Lineup.make("juggernaut", 4, 40, [], {}, 3).get("ascend", 0)), 0, "T4 can't carry it")
	check_eq(int(Lineup.make("juggernaut", 5, 50, [], {}, 9).get("ascend", 0)), 5, "clamped to A5")
	check(Lineup.rating(Lineup.make("juggernaut", 5, 50, [], {}, 2)) > Lineup.rating(Lineup.make("juggernaut", 5, 50)), "Ascension shows in power")
	var cfg := Lineup.apply({"seed": 3}, 0, Lineup.make("juggernaut", 5, 50, [], {}, 2))
	check_eq(int(cfg.ascend[0]), 2, "the fight config carries it")


func test_ascended_fight_differs_and_replays() -> void:
	var cfg := {"seed": 21, "p1": "juggernaut", "p2": "plain", "tiers": [5, 5]}
	var plain := MatchSim.new(cfg.duplicate(true))
	var asc_cfg := cfg.duplicate(true)
	asc_cfg.ascend = [3, 0]
	var asc := MatchSim.new(asc_cfg)
	check(asc.balls[0].def.rock_max > plain.balls[0].def.rock_max, "A3 adds rocks")
	var again := MatchSim.new(asc_cfg.duplicate(true))
	for sim in [asc, again]:
		while not sim.finished and sim.tick < 20000:
			sim.step()
	check_eq(asc.summary(), again.summary(), "same config, same fight")


func test_profile_ascends_with_sparks() -> void:
	var p = Profile.new_game(0)
	p.add_copies(["juggernaut"])
	check_eq(p.ascend_block("juggernaut"), "Needs T5", "T1 can't ascend")
	p.stacks.append({"id": "juggernaut", "tier": 5, "count": 1, "level": 50, "xp": 0})
	p._index_size = -1
	check_eq(p.ascend_block("juggernaut"), "Needs %d" % p.ASCEND_COST, "needs Sparks")
	p.grant({"kind": "spark", "n": 25})
	check_eq(p.ascend("juggernaut"), 1, "A1")
	check_eq(p.ascend("juggernaut"), 2, "A2")
	check_eq(p.ascend("juggernaut"), -1, "out of Sparks")
	check_eq(p.sparks, 5, "10 each")
	check_eq(int(p.slot_of("juggernaut").ascend), 2, "slot carries A2")
	var back = Profile.from_dict(p.to_dict(), 0)
	check_eq(back.ascend_level("juggernaut"), 2, "saved")
	check_eq(back.sparks, 5, "Sparks saved")


func test_spark_drop_rates() -> void:
	var n := [0, 0]
	for d in 4000:
		for r in BounceChest.rewards(4, d):
			if r.kind == "spark":
				n[0] += 1
		for r in ArenaChest.rewards(5, d):
			if r.kind == "spark":
				n[1] += 1
	check(n[0] > 120 and n[0] < 290, "Champion Bounce chest ~5%%: %d / 4000" % n[0])
	check(n[1] > 280 and n[1] < 520, "top Arena chest ~10%%: %d / 4000" % n[1])
	var low := 0
	for d in 4000:
		low += BounceChest.rewards(0, d).filter(func(r): return r.kind == "spark").size()
	check(low < n[0], "lower chests drop fewer")


func test_spire_boss_floors_drop_sparks() -> void:
	var hits := 0
	for w in 2000:
		for f in Spire.BOSS_FLOORS:
			hits += 1 if SpireClimb.spark_drop(w, f) else 0
		check(not SpireClimb.spark_drop(w, 7), "only boss floors")
	check(hits > 800 and hits < 1200, "~10%% of boss clears: %d / 10000" % hits)
	var c = SpireClimb.new()
	c.week = 0
	var w := 0
	while not SpireClimb.spark_drop(w, 10):
		w += 1
	c.week = w
	c.unclaimed = [9, 10]
	var p = UiProfile.new()
	var before: int = p.sparks
	SpireScreen.grant(p, c.take_rewards())
	check_eq(p.sparks, before + 1, "the Spark reaches the profile")


func test_arena_chest_doubled_on_average() -> void:
	# Weekly Arena chests hold twice the old fixed amounts, on average.
	var old := [300, 450, 600, 800, 1000, 1200]
	for i in ArenaChest.CHESTS.size():
		for e in ArenaChest.odds(i):
			if e.kind == "coins":
				check_eq(ChestDrops.mean(e), old[i] * 2.0, "league %d coins doubled" % i)


func test_ascend_red_dot() -> void:
	var p = UiProfile.new()
	p.sparks = 0
	check(not p.can_ascend_any(), "no Sparks, no dot")
	p.sparks = 10
	check_eq(p.can_ascend_any(), p.ascend_block("juggernaut") == "", "a T5 with a boon and 10 Sparks lights it")


func test_talent_ranks_past_30_pay_sparks() -> void:
	var p = Profile.new_game(0)
	p.sparks = 0
	var f := "nature"
	var marks: int = p.faction_marks(f)
	# Exactly to rank 30.
	var to30 := 0
	for r in Talents.MAX_POINTS - marks:
		to30 += Profile.faction_xp_to_next(r)
	p.add_faction_xp(f, to30)
	check_eq(int(p.faction_level(f).level), Talents.MAX_POINTS, "rank 30")
	check_eq(p.sparks, 0, "no Spark at 30")
	p.take_faction_gains()
	p.add_faction_xp(f, Profile.FACTION_OVER_XP - 1)
	check_eq(p.sparks, 0, "not yet")
	p.add_faction_xp(f, 1)
	check_eq(p.sparks, 1, "rank 31 pays a Spark")
	check_eq(p.spark_news, 1, "and it gets its moment")
	var g: Dictionary = p.take_faction_gains()[0]
	check_eq([g.from_level, g.to_level, g.sparks], [30, 31, 1], "the ring shows it")
	p.add_faction_xp(f, Profile.FACTION_OVER_XP * 2)
	check_eq(p.sparks, 3, "one per level")
	var back = Profile.from_dict(p.to_dict(), 0)
	back.add_faction_xp(f, 1)
	check_eq(back.sparks, 3, "never paid twice after a reload")
	check_eq(p.faction_rank(f), Talents.MAX_POINTS, "talent points stay capped at 30")


func test_spark_show_plays_once() -> void:
	var shell = Shell.new()
	shell.build()
	runner.root.add_child(shell)
	shell.profile.add_sparks(2)
	var saves := [0]
	shell.profile.changed.connect(func(): saves[0] += 1)
	shell._spark_check()
	check_eq(shell.profile.spark_news, 0, "celebrated")
	check(saves[0] > 0, "and saved as celebrated, so a reload doesn't play it again")
	check_eq(Profile.from_dict(shell.profile.to_dict(), 0).spark_news, 0, "a reloaded save has no news")
	var shows: Array = shell._fx.get_children().filter(func(c): return c.get_script() == SparkShow)
	check_eq(shows.size(), 1, "one Spark moment")
	shell._spark_check()
	check_eq(shell._fx.get_children().filter(func(c): return c.get_script() == SparkShow).size(), 1, "only once")
	shell.queue_free()
