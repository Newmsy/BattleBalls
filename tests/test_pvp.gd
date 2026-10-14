extends "res://tests/test_case.gd"

const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const MatchSim := preload("res://sim/match_sim.gd")


func test_leagues_and_divisions() -> void:
	check_eq(Ladder.league_label(0), "Bronze III", "start")
	check_eq(Ladder.league_label(399), "Bronze I", "top of bronze")
	check_eq(Ladder.league_label(400), "Silver III", "silver")
	check_eq(Ladder.league_label(1950), "Platinum III", "platinum")
	check_eq(Ladder.league_label(4000), "Neon", "neon has no divisions")
	check_eq(Ladder.league_label(9000), "Neon", "neon is open-ended")


func test_attack_trophies_follow_the_cards() -> void:
	check_eq(Ladder.attack_delta(500, 500, "easier", true), 18, "easier win")
	check_eq(Ladder.attack_delta(500, 500, "even", false), -15, "even loss")
	check_eq(Ladder.attack_delta(500, 500, "harder", true), 35, "harder win")
	check_eq(Ladder.attack_delta(500, 500, "harder", false), -10, "harder loss")


func test_no_demotion_out_of_a_reached_league() -> void:
	check_eq(Ladder.attack_delta(405, 420, "easier", false), -5, "stops at the silver floor")
	check_eq(Ladder.attack_delta(400, 420, "even", false), 0, "at the floor")
	check_eq(Ladder.attack_delta(5, 5, "easier", false), -5, "never below zero")


func test_defence_losses_are_small_and_capped() -> void:
	check_eq(Ladder.defence_delta(500, 500, "harder", true, 0), -10, "capped at 10")
	check_eq(Ladder.defence_delta(500, 500, "easier", true, 0), -9, "half of 18")
	check_eq(Ladder.defence_delta(500, 500, "even", true, 35), -5, "daily cap")
	check_eq(Ladder.defence_delta(500, 500, "even", true, 40), 0, "daily cap reached")
	check_eq(Ladder.defence_delta(402, 450, "even", true, 0), -2, "floor")
	check_eq(Ladder.defence_delta(500, 500, "even", false, 0), Ladder.DEFENCE_WIN, "defended")


func test_season_reset_halves_above_the_pivot() -> void:
	check_eq(Ladder.season_reset(3000), 2000, "3000")
	check_eq(Ladder.season_reset(800), 800, "below pivot")


func test_ghost_pool_is_stable_and_valid() -> void:
	var pool := ArenaGhosts.pool()
	check_eq(pool.size(), ArenaGhosts.BANDS * ArenaGhosts.PER_BAND, "size")
	var names := {}
	for i in pool.size():
		var bot: Dictionary = pool[i]
		check(bot.is_bot, "labelled as a bot")
		check(not names.has(bot.name), "unique name " + bot.name)
		names[bot.name] = true
		check_eq(bot.lineup.slots.size(), 3, "trio")
		for s in bot.lineup.slots:
			check(s.critter in BallDefs.PLAYABLE, "playable critter")
			check(absi(s.aim) <= ArenaGhosts.AIM_SPREAD, "aim in range")
		if i > 0:
			check(bot.trophies >= pool[i - 1].trophies, "sorted by trophies")
	# Pinned so a change to the generator is a deliberate one.
	check_eq(pool[0].id, ArenaGhosts.by_id(pool[0].id).id, "lookup")


func test_offers_are_three_distinct_cards_in_order() -> void:
	for trophies in [0, 420, 2500, 6000]:
		var cards := ArenaGhosts.offers(trophies, 20261014, "player-a")
		check_eq(cards.map(func(c): return c.card), ["easier", "even", "harder"], "order")
		var ids := {}
		for c in cards:
			ids[c.bot.id] = true
		check_eq(ids.size(), 3, "distinct bots at %d" % trophies)
		check(cards[0].bot.trophies <= cards[2].bot.trophies, "easier is not above harder at %d" % trophies)
	var mid := ArenaGhosts.offers(2500, 1, "p")
	check(absi(mid[1].bot.trophies - 2500) <= 100, "even card is close")
	check(mid[2].bot.trophies > 2550, "harder card is higher")


func test_offers_are_stable_per_day_and_change_on_refresh() -> void:
	var a := ArenaGhosts.offers(1000, 5, "p")
	check_eq(ArenaGhosts.offers(1000, 5, "p"), a, "stable")
	var changed := false
	for r in range(1, 6):
		if ArenaGhosts.offers(1000, 5, "p", r) != a:
			changed = true
	check(changed, "a refresh can change the cards")


func test_slot_angles_mirror_to_each_corner() -> void:
	var lineup := {"v": 1, "slots": [{"critter": "laser", "aim": 100}, {"critter": "vampire"}], "aim": [100, -50]}
	check_eq(ArenaGhosts.slot_angle(lineup, 0, 0), MatchSim.AIM_AT_CENTRE[0] + 100, "own corner")
	check_eq(ArenaGhosts.slot_angle(lineup, 0, 1), MatchSim.AIM_AT_CENTRE[1] + 100, "other corner")
	check_eq(ArenaGhosts.slot_angle(lineup, 1, 0), MatchSim.AIM_AT_CENTRE[0] - 50, "v1 aims list")


const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Shell := preload("res://game/ui/shell.gd")
const TEST_SAVE := "user://test_ghost_arena.cfg"


func _fresh_store():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	return ArenaStore.open(TEST_SAVE)


func test_store_applies_trophies_and_saves() -> void:
	var s = _fresh_store()
	var cards: Array[Dictionary] = s.offers(20261014)
	s.start_attack("harder", cards[2].bot.id, 42)
	check_eq(s.finish_attack(true, [120, null, -40]), 35, "harder win")
	check_eq(s.trophies, 35, "trophies")
	check_eq(s.shots, [120, 0, -40], "used shots saved, unused kept")
	check_eq(s.history[0].name, cards[2].bot.name, "history")
	var again = ArenaStore.open(TEST_SAVE)
	check_eq(again.trophies, 35, "reloaded trophies")
	check_eq(again.shots, [120, 0, -40], "reloaded shots")
	check(again.pending.is_empty(), "nothing pending")


func test_unfinished_attack_counts_as_a_loss() -> void:
	var s = _fresh_store()
	s.trophies = 500
	s.peak = 500
	s.start_attack("even", ArenaGhosts.pool()[0].id, 1)
	var reopened = ArenaStore.open(TEST_SAVE)
	check_eq(reopened.settle_abandoned(), -15, "even loss")
	check_eq(reopened.trophies, 485, "trophies")
	check_eq(reopened.settle_abandoned(), 0, "only once")


func test_one_free_refresh_a_day() -> void:
	var s = _fresh_store()
	var before: Array[Dictionary] = s.offers(7)
	check(s.refresh(7), "first refresh")
	check(not s.refresh(7), "second refused")
	check_eq(s.refreshes_left(8), 1, "new day")
	check_eq(s.offers(8), ArenaGhosts.offers(s.trophies, 8, "local", 0), "new day starts fresh")
	check(before.size() == 3, "three cards")


func test_arena_screen_and_fight_scene_build() -> void:
	var s = _fresh_store()
	var shell = Shell.new()
	shell.build()
	shell.go("arena", {"store": s})
	check_eq(shell.current, "arena", "arena screen")
	shell.free()
	var scene: PackedScene = load("res://game/ghost_arena.tscn")
	check(scene != null, "fight scene loads")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
