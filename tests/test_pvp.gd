extends "res://tests/test_case.gd"

const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const ArenaTeams := preload("res://game/pvp/arena_teams.gd")
const Families := preload("res://sim/families.gd")
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
const UiProfile := preload("res://game/ui/ui_profile.gd")
const ArenaScreen := preload("res://game/ui/screens/arena_screen.gd")
## Per process: tests/run.sh runs shards side by side.
var TEST_SAVE := "user://test_ghost_arena_%d.cfg" % OS.get_process_id()


func _fresh_store():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	return ArenaStore.open(TEST_SAVE)


func test_store_applies_trophies_and_saves() -> void:
	var s = _fresh_store()
	var cards: Array[Dictionary] = s.offers(null, 20261014)
	s.start_attack("harder", cards[2].bot, 42)
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
	var before: Array[Dictionary] = s.offers(null, 7)
	check(s.refresh(7), "first refresh")
	check(not s.refresh(7), "second refused")
	check_eq(s.refreshes_left(8), 1, "new day")
	check_eq(s.offers(null, 8), ArenaTeams.offers(s.trophies, s.power(), 8, 0), "new day starts fresh")
	check(before.size() == 3, "three cards")


func test_ranked_trio_uses_owned_critters_only() -> void:
	var s = _fresh_store()
	s.trio = ["vampire", "flux", "laser"]
	check(s.fit_to(["laser", "vampire"]), "unowned slot swapped")
	check_eq(s.trio, ["vampire", "vampire", "laser"], "with only two owned, a repeat is the only way to fill three")
	check(not s.fit_to(["laser", "vampire"]), "owned trio unchanged")
	var p = UiProfile.new()
	p.stacks.append({"id": "laser", "tier": 1, "count": 1, "level": 1})
	check_eq(ArenaScreen.owned_critters(p), ["laser"], "only owned critters can be picked")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_trio_never_holds_a_critter_twice() -> void:
	var s = _fresh_store()
	s.trio = ["laser", "vampire", "laser"]
	check(s.fit_to(["spiker", "laser", "vampire", "speedster"]), "duplicate repaired")
	check_eq(s.trio, ["laser", "vampire", "spiker"], "repeat becomes the strongest critter not in the trio")
	s.set_slot(0, "spiker")
	check_eq(s.trio, ["spiker", "vampire", "laser"], "picking a trio member swaps the two slots")
	s.set_slot(1, "speedster")
	check_eq(s.trio, ["spiker", "speedster", "laser"], "picking a new critter replaces the slot")
	s.fill_best(["laser", "vampire", "spiker", "speedster"])
	check_eq(s.trio, ["laser", "vampire", "spiker"], "best trio = strongest three")
	check_eq(ArenaStore.best_trio(["laser"]), ["laser", "laser", "laser"], "one critter owned fills all three")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_trio_slot_opens_the_picker() -> void:
	var s = _fresh_store()
	var shell = Shell.new()
	shell.build()
	for id in ["laser", "vampire", "spiker", "speedster"]:
		shell.profile.stacks.append({"id": id, "tier": 1, "count": 1, "level": 1})
	shell.go("arena", {"store": s})
	var trio: Array = s.trio.duplicate()
	check_eq(trio.size(), 3, "three slots")
	check(trio[0] != trio[1] and trio[1] != trio[2] and trio[0] != trio[2], "trio is three different critters")
	shell._marks["arena_slot_0"].pressed.emit()
	check(shell._marks.has("pick_" + trio[1]), "picker lists owned critters")
	var spare: String = ["laser", "vampire", "spiker", "speedster"].filter(func(id): return not id in trio)[0]
	check(not shell._marks.pick_confirm.disabled, "the current trio is full, so it can be confirmed")
	shell._marks["pick_" + spare].pressed.emit() # the team is full: no change
	shell._marks["pick_" + trio[0]].pressed.emit() # take slot 1 out
	check(shell._marks.pick_confirm.disabled, "a missing slot can't be confirmed")
	shell._marks["pick_" + spare].pressed.emit() # now it fits, last in
	shell._marks.pick_confirm.pressed.emit()
	check_eq(s.trio, [trio[1], trio[2], spare], "the picks fight in tap order")
	shell._marks["arena_best_trio"].pressed.emit()
	check_eq(s.trio, ArenaStore.best_trio(ArenaScreen.owned_critters(shell.profile)), "Best trio fills the strongest three")
	shell.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_themed_teams_match_your_power_and_grow_with_trophies() -> void:
	for mine in [3000, 6000, 12000]:
		var cards := ArenaTeams.offers(0, mine, 20261015)
		check_eq(cards.size(), 3, "three cards")
		var fams := {}
		for c in cards:
			var team: Dictionary = c.bot
			fams[team.family] = true
			var ids := ArenaGhosts.critters(team.lineup)
			check(ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2], "three different critters")
			for id in ids:
				check_eq(Families.of(id), team.family, "%s fits the %s theme" % [id, team.family])
			var want := ArenaTeams.target(mine, 0, c.card)
			check(absf(ArenaTeams.rating(team) - want) <= want * 0.12, "%s team near %d (got %d)" % [c.card, want, ArenaTeams.rating(team)])
		check_eq(fams.size(), 3, "three different themes")
		check(ArenaTeams.rating(cards[0].bot) < ArenaTeams.rating(cards[2].bot), "easier is weaker than harder")
	check(ArenaTeams.target(5000, 2000, "even") > ArenaTeams.target(5000, 0, "even"), "teams grow with trophies")
	check_eq(ArenaTeams.offers(300, 5000, 9), ArenaTeams.offers(300, 5000, 9), "same day, same teams")


func test_attacks_earn_coins_and_the_bazaar_spends_them() -> void:
	var s = _fresh_store()
	var cards: Array[Dictionary] = s.offers(null, 20261014)
	s.start_attack("harder", cards[2].bot, 42)
	s.finish_attack(true)
	check_eq(s.coins, ArenaStore.COINS_WIN.harder, "win coins")
	s.start_attack("even", cards[1].bot, 43)
	s.finish_attack(false)
	check_eq(s.coins, ArenaStore.COINS_WIN.harder + ArenaStore.COINS_LOSS, "loss coins")
	var p = UiProfile.new()
	var stock: Array = s.bazaar(5)
	check_eq(stock.size(), 5, "five items")
	check(not s.buy(p, 3, 5), "too few coins for an orb")
	s.coins = 1000
	var orbs: int = p.orbs
	check(s.buy(p, 3, 5), "orb bought")
	check_eq(p.orbs, orbs + 1, "orb added")
	check(not s.buy(p, 3, 5), "sold once a day")
	var gear_before: int = p.gear.size()
	check(s.buy(p, 0, 5), "gear bought")
	check_eq(p.gear.size(), gear_before + 1, "gear added")
	check_eq(p.gear[-1].type, stock[0].type, "the piece on sale")
	check_eq(s.coins, 1000 - stock[3].price - stock[0].price, "paid")
	check(s.buy(p, 3, 6), "new stock next day")
	check_eq(ArenaStore.open(TEST_SAVE).coins, s.coins, "coins saved")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_daily_raids_fight_your_defence_once_and_replay() -> void:
	var s = _fresh_store()
	s.trophies = 600
	s.peak = 600
	s.defence = ["vampire", "laser", "spiker"]
	var raids: Array = s.run_raids(null, 11)
	check_eq(raids.size(), ArenaStore.RAIDS_PER_DAY, "three raids")
	check(s.run_raids(null, 11).is_empty(), "once a day")
	var t: int = s.trophies
	var other = _fresh_store()
	other.trophies = 600
	other.peak = 600
	other.defence = ["vampire", "laser", "spiker"]
	check_eq(other.run_raids(null, 11), raids, "raids replay from the day's seed")
	check_eq(other.trophies, t, "same trophies")
	var held := raids.filter(func(r): return r.held).size()
	check_eq(s.coins, held * ArenaStore.COINS_DEFENCE, "coins per raid held")
	s.set_slot(0, "laser", "defence")
	check_eq(s.defence, ["laser", "vampire", "spiker"], "defence swaps like the trio")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func test_arena_hub_opens_its_rooms() -> void:
	var s = _fresh_store()
	var shell = Shell.new()
	shell.build()
	for id in ["laser", "vampire", "spiker", "speedster"]:
		shell.profile.stacks.append({"id": id, "tier": 1, "count": 1, "level": 1})
	shell.go("arena", {"store": s})
	for room in [["arena_boosts", "boosts"], ["arena_bazaar", "bazaar"], ["arena_defence", "defence"]]:
		shell.go("arena", {"store": s})
		shell._marks[room[0]].pressed.emit()
		check_eq(shell.current, room[1], room[1])
	check(shell._marks.has("defence_slot_0"), "defence trio picker")
	shell.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


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
