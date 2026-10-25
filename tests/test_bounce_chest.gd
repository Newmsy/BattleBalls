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
	check_eq(BounceChest.tier_for(0), -1, "no chest below floor 4")
	check_eq(BounceChest.tier_for(3), -1, "nor on floor 3")
	check_eq(BounceChest.tier_for(4), 0, "floor 4: Bronze")
	check_eq(BounceChest.tier_for(11), 1, "floor 11: Silver")
	check_eq(BounceChest.tier_for(12), 2, "floor 12: Gold")
	check_eq(BounceChest.tier_for(19), 3, "floor 19: Crystal")
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
	var best := {10: 3, 11: 13, 12: 20}
	check_eq(BounceChest.pending(best, 0, 11), {}, "floor 3 earns nothing, today's climb isn't done")
	check_eq(BounceChest.pending(best, 0, 12), {"day": 11, "floor": 13, "tier": 2}, "yesterday's floor 13: Gold")
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
	var view = load("res://game/ui/bounce_chest_open.gd").show_on(shell, {"day": 50, "floor": 20, "tier": 4})
	check(shell.overlay_open(), "opens over the shell")
	check_eq(view._cards.size(), 5, "a card for each reward")
	view._open_now()
	check(view._collect.visible, "Collect shows once it's open")
	view._on_collect()
	check_eq(p.coins, coins + 450, "collected")
	check_eq(p.bounce_chest, 50, "and marked opened")
	check(not shell.overlay_open(), "and closed")
	shell.free()
