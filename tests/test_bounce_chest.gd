## Bounce Run chests (meta/bounce_chest.gd): the day's best floor opens a
## chest the next day, once, and the Daily board's Bounce Run card opens it.
extends "res://tests/test_case.gd"

const BounceChest := preload("res://meta/bounce_chest.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const Profile := preload("res://meta/profile.gd")
const Shell := preload("res://game/ui/shell.gd")
const Gear := preload("res://sim/gear.gd")


func test_floors_pick_the_chest() -> void:
	check_eq(BounceChest.tier_for(0), -1, "no chest below floor 5")
	check_eq(BounceChest.tier_for(4), -1, "nor on floor 4")
	check_eq(BounceChest.tier_for(5), 0, "floor 5: Bronze")
	check_eq(BounceChest.tier_for(14), 1, "floor 14: Silver")
	check_eq(BounceChest.tier_for(15), 2, "floor 15: Gold")
	check_eq(BounceChest.tier_for(24), 3, "floor 24: Crystal")
	check_eq(BounceChest.tier_for(BounceRun.FLOORS), BounceChest.TIERS.size() - 1, "a clear: Champion")
	check_eq(int(BounceChest.TIERS[-1].floor), BounceRun.FLOORS, "the Champion Chest is for beating the top floor")
	for i in range(1, BounceChest.TIERS.size() - 1):
		check_eq(int(BounceChest.TIERS[i - 1].floor) % BounceRun.FLOORS_PER_TIER, 0, "chests land on tier ups")


func test_better_chests_hold_more() -> void:
	var worth := func(rs: Array) -> int:
		var w := 0
		for r in rs:
			w += {"coins": 1, "orbs": 100, "hammers": 60, "xp_chip": 60, "gear": 200}[r.kind] * int(r.get("n", 1))
		return w
	for i in range(1, BounceChest.TIERS.size()):
		check(worth.call(BounceChest.rewards(i, 9)) > worth.call(BounceChest.rewards(i - 1, 9)), "%s beats %s" % [BounceChest.TIERS[i].id, BounceChest.TIERS[i - 1].id])
	var champ := BounceChest.rewards(BounceChest.TIERS.size() - 1, 9)
	var gear: Array = champ.filter(func(r): return r.kind == "gear")
	check_eq(gear.size(), 1, "only the Champion Chest has gear")
	check(Gear.PIECES.has(gear[0].type), "a real piece")
	check_eq(BounceChest.rewards(4, 9), champ, "the same piece all day")


func test_yesterdays_best_opens_once() -> void:
	var best := {10: 3, 11: 16, 12: 25}
	check_eq(BounceChest.pending(best, 0, 11), {}, "floor 3 earns nothing, today's climb isn't done")
	check_eq(BounceChest.pending(best, 0, 12), {"day": 11, "floor": 16, "tier": 2}, "yesterday's floor 16: Gold")
	check_eq(BounceChest.pending(best, 0, 13).day, 11, "the oldest unopened one first")
	check_eq(BounceChest.pending(best, 11, 13).day, 12, "then the next")
	check_eq(BounceChest.pending(best, 12, 13), {}, "all opened")
	check_eq(BounceChest.pending(best, 0, 30), {}, "old chests are gone")
	var p = UiProfile.sample()
	var coins: int = p.coins
	var orbs: int = p.orbs
	var c := BounceChest.pending(best, p.bounce_chest, 12)
	var got := BounceChest.open(p, c)
	check_eq(got.size(), 3, "Gold: coins, an egg and a hammer")
	check_eq(p.coins, coins + 250, "coins paid")
	check_eq(p.orbs, orbs + 1, "egg paid")
	check_eq(p.bounce_chest, 11, "marked opened")
	check_eq(BounceChest.open(p, c), [], "never twice")
	check_eq(Profile.from_dict(p.to_dict(), 0).bounce_chest, 11, "saved with the profile")


func test_best_floors_come_from_the_run_save() -> void:
	var path := "user://test_bounce_chest_%d.cfg" % OS.get_process_id()
	var cfg := ConfigFile.new()
	cfg.set_value("best", "41", 9)
	cfg.save(path)
	check_eq(BounceChest.best_floors(path), {41: 9}, "read back by day")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check_eq(BounceChest.best_floors(path), {}, "no save, no floors")


func test_opening_screen_collects() -> void:
	var shell = Shell.new()
	shell.build()
	var p = shell.profile
	var coins: int = p.coins
	var view = load("res://game/ui/bounce_chest_open.gd").show_on(shell, {"day": 50, "floor": 25, "tier": 4})
	check(shell.overlay_open(), "opens over the shell")
	check_eq(view._cards.size(), 5, "a card for each reward")
	view._open_now()
	check(view._collect.visible, "Collect shows once it's open")
	view._on_collect()
	check_eq(p.coins, coins + 450, "collected")
	check_eq(p.bounce_chest, 50, "and marked opened")
	check(not shell.overlay_open(), "and closed")
	shell.free()


## Opening Bounce Run (from any button) pops up a waiting chest; Collect
## pays into the game save.
func test_bounce_run_opens_on_a_waiting_chest() -> void:
	var run_path := "user://test_bounce_chest_run_%d.cfg" % OS.get_process_id()
	var game_path := "user://test_bounce_chest_save_%d.json" % OS.get_process_id()
	var today := BounceRun.day_number(Time.get_unix_time_from_system())
	BounceChest.set_best(today - 1, 16, run_path)
	var save = load("res://game/online/save_game.gd").new(game_path)
	var p = UiProfile.sample()
	var coins: int = p.coins
	save.data.profile = p.to_dict()
	save.save_local()
	var scene = load("res://game/bounce_run.tscn").instantiate()
	scene.save_path = run_path
	scene.game_save_path = game_path
	runner.root.add_child(scene)
	scene._ready()
	var views: Array = scene.ui.get_children().filter(func(c): return c.get_script() == load("res://game/ui/bounce_chest_open.gd"))
	check_eq(views.size(), 1, "the chest pops up over the run")
	if views.size() == 1:
		check_eq(views[0].tier.id, "gold", "yesterday's floor 16")
		views[0]._open_now()
		views[0]._on_collect()
		var after = load("res://game/online/save_game.gd").new(game_path)
		after.load_local()
		var q = Profile.from_dict(after.data.profile, 0)
		check_eq(q.bounce_chest, today - 1, "opened in the game save")
		check_eq(q.coins, coins + 250, "and paid")
	scene.queue_free()
	var again = load("res://game/bounce_run.tscn").instantiate()
	again.save_path = run_path
	again.game_save_path = game_path
	runner.root.add_child(again)
	again._ready()
	check(again.ui.get_children().all(func(c): return c.get_script() != load("res://game/ui/bounce_chest_open.gd")), "not again")
	again.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(run_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game_path))


## The cards leap out one by one: a tap while it shakes bursts it open, a
## tap while they fly lands them all, and only then does Collect show.
func test_cards_fly_out_and_a_tap_lands_them() -> void:
	var shell = Shell.new()
	shell.build()
	runner.root.add_child(shell)
	var view = load("res://game/ui/bounce_chest_open.gd").show_on(shell, {"day": 51, "floor": 25, "tier": 4})
	view._open()
	view._burst()
	check_eq(view.phase, view.Phase.SPILLING, "a tap mid-shake bursts it open")
	view._spill()
	check_eq(view._flyers.size(), 5, "every card leaves the chest")
	check(not view._collect.visible, "Collect waits for the cards")
	check(view._cards.all(func(c): return c.modulate.a == 0.0), "no card in its slot yet")
	view._land_all()
	check(view._flyers.is_empty(), "a tap lands them all")
	check(view._cards.all(func(c): return c.modulate.a == 1.0), "each in its slot")
	check(view._collect.visible, "then Collect shows")
	view._on_collect()
	check(not shell.overlay_open(), "and Collect closes it")
	shell.queue_free()
