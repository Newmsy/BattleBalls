extends "res://tests/test_case.gd"

const ArenaBoosts := preload("res://sim/arena_boosts.gd")
const Families := preload("res://sim/families.gd")
const Lineup := preload("res://sim/lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Shell := preload("res://game/ui/shell.gd")
## Per process: tests/run.sh runs one process per core, and they share user://.
var TEST_SAVE := "user://test_arena_boosts_%d.cfg" % OS.get_process_id()


func _fresh_store():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	return ArenaStore.open(TEST_SAVE)


func test_every_playable_critter_has_one_family() -> void:
	var seen := {}
	for fam in Families.MEMBERS:
		for id in Families.MEMBERS[fam]:
			check(not seen.has(id), "%s in one family only" % id)
			seen[id] = fam
	for id in BallDefs.PLAYABLE:
		if id != "plain":
			check(Families.of(id) != "", "%s has a family" % id)
	check_eq(Families.FAMILIES.size(), 9, "nine families")


func test_a_full_family_is_a_small_boost() -> void:
	var full := {}
	for line in ArenaBoosts.ORDER:
		full[line] = ArenaBoosts.MAX_LEVEL
	var p := ArenaBoosts.power(ArenaBoosts.stats(full))
	check(p >= 0.05 and p <= 0.08, "full family is +5-8%% power (%.3f)" % p)
	check(p < 0.25, "less than one tier step")
	check_eq(ArenaBoosts.stats({"health": 9}), {"health": ArenaBoosts.LINES.health.max}, "levels capped")
	check_eq(ArenaBoosts.text("speed", 5), "+2.1% move speed", "text")


func test_trophies_won_earn_points_and_losses_cost_none() -> void:
	var s = _fresh_store()
	var cards: Array[Dictionary] = s.offers(20261014)
	s.start_attack("harder", cards[2].bot.id, 42)
	s.finish_attack(true)
	check_eq(s.points, 35, "a point per trophy won")
	s.start_attack("even", cards[1].bot.id, 43)
	s.finish_attack(false)
	check_eq(s.points, 35, "a loss keeps points")
	check_eq(ArenaStore.open(TEST_SAVE).points, 35, "points saved")


func test_buying_a_level_spends_points_and_boosts_the_family() -> void:
	var s = _fresh_store()
	s.points = 60
	check(s.upgrade("spooky", "attack"), "level 1")
	check_eq(s.points, 60 - ArenaBoosts.cost(1), "paid")
	check(s.upgrade("spooky", "attack"), "level 2")
	check(not s.upgrade("spooky", "attack"), "can't afford level 3")
	check(not s.upgrade("nope", "attack"), "unknown family")
	check_near(s.boost_of("vampire").attack, ArenaBoosts.LINES.attack.max * 2 / 5, 0.00001, "vampire is Spooky")
	check(s.boost_of("laser").is_empty(), "Tech isn't boosted")
	var again = ArenaStore.open(TEST_SAVE)
	check_eq(again.level_of("spooky", "attack"), 2, "levels saved")
	check_eq(again.reset_boosts(), ArenaBoosts.cost(1) + ArenaBoosts.cost(2), "reset refunds")
	check_eq(again.points, 60, "all points back")


func test_old_saves_start_with_a_point_per_trophy() -> void:
	var s = _fresh_store()
	s.trophies = 640
	var f := ConfigFile.new()
	f.load(TEST_SAVE)
	f.set_value("arena", "trophies", 640)
	for key in ["points", "points_earned"]:
		if f.has_section_key("arena", key):
			f.erase_section_key("arena", key)
	f.save(TEST_SAVE)
	check_eq(ArenaStore.open(TEST_SAVE).points, 640, "retro points")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_boost_rides_in_the_slot_and_reaches_the_ball() -> void:
	var s = _fresh_store()
	s.trio = ["vampire", "laser", "vampire"]
	s.points = 2000
	for line in ArenaBoosts.ORDER:
		for i in ArenaBoosts.MAX_LEVEL:
			s.upgrade("spooky", line)
	var slots: Array = s.slots()
	check(slots[0].has("boost") and not slots[1].has("boost"), "only Spooky slots carry it")
	var lineup: Dictionary = GhostLineup.make(slots, [])
	check_eq(lineup.slots[0].boost, slots[0].boost, "published defence keeps it")
	var tampered := Lineup.clean({"critter": "vampire", "boost": {"attack": 5.0, "laser": 1.0}})
	check_eq(tampered.boost, {"attack": ArenaBoosts.LINES.attack.max}, "tampered boost clamped")
	check(not Lineup.clean({"critter": "vampire"}).has("boost"), "no boost, no key")
	var cfg := {"seed": 7, "angles": [-450, null]}
	Lineup.apply(cfg, 0, slots[0])
	Lineup.apply(cfg, 1, Lineup.make("laser"))
	var a := MatchSim.new(cfg)
	var bare := MatchSim.new(cfg.merged({"gear": [[], []]}, true))
	check(a.balls[0].max_hp > bare.balls[0].max_hp, "health boost reaches the ball")
	check(a.balls[0].attack > bare.balls[0].attack, "attack boost reaches the ball")
	a.run_to_end()
	var b := MatchSim.new(cfg.duplicate(true))
	b.run_to_end()
	check_eq(a.summary(), b.summary(), "replays from the slots")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_boosts_screen_builds_and_buys() -> void:
	var s = _fresh_store()
	s.points = 100
	var shell = Shell.new()
	shell.build()
	shell.go("arena", {"store": s})
	check(shell._marks.has("arena_boosts"), "arena links to boosts")
	shell.go("boosts", {"store": s})
	check_eq(shell.current, "boosts", "boosts screen")
	shell._marks["boost_sea_health"].pressed.emit()
	check_eq(s.level_of("sea", "health"), 1, "tap buys a level")
	check_eq(s.points, 100 - ArenaBoosts.cost(1), "and spends")
	shell.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
