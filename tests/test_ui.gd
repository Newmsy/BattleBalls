## Menus: the sample profile's fusion rules and that every screen builds.
extends "res://tests/test_case.gd"

const Roster := preload("res://game/ui/roster.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const CritterArt := preload("res://game/ui/critter_art.gd")
const Shell := preload("res://game/ui/shell.gd")
const Summon := preload("res://game/ui/summon.gd")


func test_fusing_three_copies_makes_one_of_the_next_tier() -> void:
	var p = UiProfile.sample()
	var before: int = p.total_copies("speedster")
	check(p.can_fuse("speedster", 1), "3 T1 Zips are ready")
	var r: Dictionary = p.fuse("speedster", 1)
	check_eq(r.tier, 2, "result tier")
	check_eq(p.total_copies("speedster"), before - 2, "3 copies became 1")
	check_eq(p.best("speedster").tier, 2, "best Zip is now T2")
	check(not p.can_fuse("speedster", 1), "no T1 Zips left to fuse")


func test_fusion_keeps_the_highest_level() -> void:
	var p = UiProfile.sample()
	# Count Nibbles: T1 x3 at Lv 6, and an existing T2 at Lv 14.
	var r: Dictionary = p.fuse("vampire", 1)
	check_eq(r.level, 14, "level kept")
	check_eq(p.copies("vampire")[-1].count, 2, "now two T2 copies")


func test_cannot_fuse_without_three_or_past_tier_five() -> void:
	var p = UiProfile.sample()
	check(not p.can_fuse("laser", 1), "only 2 Optics")
	check(p.fuse("laser", 1).is_empty(), "fuse refuses")
	p.stacks.append({"id": "laser", "tier": 5, "count": 3, "level": 50})
	check(not p.can_fuse("laser", 5), "T5 is the top")


func test_power_grows_about_a_quarter_per_tier() -> void:
	var t1 := Roster.power("vampire", 1, 1)
	var t2 := Roster.power("vampire", 2, 1)
	check_near(float(t2) / t1, 1.25, .01, "one tier")
	check(Roster.power("blackhole", 1, 1) > t1, "Legendary base is higher")
	check(t2 > Roster.power("blackhole", 1, 1), "a tier beats a rarity step")


func test_every_critter_has_art_and_a_full_ladder() -> void:
	check_eq(Roster.CRITTERS.size(), 15, "roster size")
	for c in Roster.CRITTERS:
		check_eq(c.ladder.size(), Roster.MAX_TIER, c.id + " ladder")
		check(CritterArt.EYES.has(c.id), c.id + " has a face")


func test_a_ten_pull_always_has_a_rare_or_better() -> void:
	var rng := RandomNumberGenerator.new()
	for seed in 200:
		rng.seed = seed
		var ids: Array = Summon.pull(UiProfile.sample(), 10, rng)
		check_eq(ids.size(), 10, "ten critters")
		check(ids.any(func(id): return Summon.rarity_of(id) != "common"), "seed %d has a Rare+" % seed)


func test_pity_guarantees_a_legendary() -> void:
	var p = UiProfile.sample()
	p.legendary_pity = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var got_legendary := false
	for i in 40:
		for id in Summon.pull(p, 1, rng):
			got_legendary = got_legendary or Summon.rarity_of(id) == "legendary"
		if got_legendary:
			break
	check(got_legendary, "first Rare+ roll at pity 1 is Legendary")
	check(p.legendary_pity > 100, "pity resets after a Legendary")


func test_equipping_gear_replaces_the_same_slot() -> void:
	var p = UiProfile.sample()
	p.equip(5, "vampire") # A second Iron Shell onto Count Nibbles.
	var shells: Array = p.gear_on("vampire").filter(func(g): return g.slot == "Shell")
	check_eq(shells.size(), 1, "one shell on")
	check_eq(shells[0].uid, 5, "the new one")


func test_every_screen_builds() -> void:
	var shell = Shell.new()
	shell.build()
	for t in ["play", "critters", "fuse", "bag", "summon"]:
		shell.show_tab(t)
		check_eq(shell.current, t, "tab " + t)
	for c in Roster.CRITTERS:
		if shell.profile.owns(c.id):
			shell.go("detail", {"id": c.id})
			check_eq(shell.current, "detail", "detail " + c.id)
	shell.back()
	check_eq(shell.current, "detail", "back goes to the previous detail")
	shell.open_tab("fuse", {"id": "speedster", "tier": 1})
	check_eq(shell.current_params.id, "speedster", "fuse opens on the picked critter")
	shell.free()
