## Menus: the sample profile's fusion rules and that every screen builds.
extends "res://tests/test_case.gd"

const Roster := preload("res://game/ui/roster.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")

const Shell := preload("res://game/ui/shell.gd")
const Summon := preload("res://game/ui/summon.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const SummonScreen := preload("res://game/ui/screens/summon_screen.gd")


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
	check(not p.can_fuse("bomber", 1), "only 1 Fuse")
	check(p.fuse("bomber", 1).is_empty(), "fuse refuses")
	p.stacks.append({"id": "laser", "tier": 5, "count": 3, "level": 50})
	check(not p.can_fuse("laser", 5), "T5 is the top")


func test_power_grows_about_a_quarter_per_tier() -> void:
	var t1 := Roster.power("vampire", 1, 1)
	var t2 := Roster.power("vampire", 2, 1)
	check_near(float(t2) / t1, 1.25, .01, "one tier")
	check(Roster.power("blackhole", 1, 1) > t1, "Legendary base is higher")
	check_near(float(Roster.power("laser", 1, 1)) / t1, 1.25, .01, "two rarity steps (Common to Rare) are one tier")
	check_near(float(Roster.power("blackhole", 1, 1)) / t1, 1.5625, .01, "a Legendary starts two tiers above a Common")


func test_every_critter_has_art_and_a_full_ladder() -> void:
	check_eq(Roster.CRITTERS.size(), CritterDb.ids().size() - 1, "every critter but Plain")
	for c in Roster.CRITTERS:
		check_eq(c.ladder.size(), Roster.MAX_TIER, c.id + " ladder")
		check(not CritterDb.get_critter(c.id).art.get("eyes", {}).is_empty(), c.id + " has a face")


func test_a_ten_pull_always_has_a_rare_or_better() -> void:
	var rng := RandomNumberGenerator.new()
	for seed in 200:
		rng.seed = seed
		var ids: Array = Summon.pull(UiProfile.sample(), 10, rng)
		check_eq(ids.size(), 10, "ten critters")
		check(ids.any(func(id): return Roster.RARITIES.find(Summon.rarity_of(id)) >= Roster.RARITIES.find("rare")), "seed %d has a Rare+" % seed)


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
	check_eq(p.legendary_pity, Summon.PITY_RESET, "pity resets after a Legendary")


func test_wishlist_holds_three_and_toggles() -> void:
	var p = UiProfile.sample()
	for id in ["laser", "speedster", "blackhole"]:
		check(p.toggle_wishlist(id), "add " + id)
	check(not p.toggle_wishlist("ghost"), "a fourth pick is refused")
	check_eq(p.wishlist.size(), 3, "still three")
	check(p.toggle_wishlist("laser"), "tapping a pick removes it")
	check(not p.on_wishlist("laser"), "laser removed")
	check(p.toggle_wishlist("ghost"), "room again")


func test_wishlisted_critters_come_up_twice_as_often() -> void:
	var p = UiProfile.sample()
	var commons: Array = Roster.CRITTERS.filter(func(c): return c.rarity == "common" and c.id != Summon.featured()).map(func(c): return c.id)
	var wished: String = commons[0]
	var other: String = commons[1]
	p.toggle_wishlist(wished)
	check_near(Summon.share_in_rarity(p, wished), 2.0 * Summon.share_in_rarity(p, other), 1e-9, "double weight")
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var got := {wished: 0, other: 0}
	var n := 40000
	for i in n:
		var id := Summon.pick_in_rarity(p, "common", rng)
		if got.has(id):
			got[id] += 1
	check_near(float(got[wished]) / n, Summon.share_in_rarity(p, wished), .01, "rolls match the shown share")
	check_near(float(got[other]) / n, Summon.share_in_rarity(p, other), .01, "others keep the rest")


func test_wishlist_never_changes_rarity_odds_or_pity() -> void:
	var p = UiProfile.sample()
	for id in ["vampire", "laser", "phoenix"]:
		p.toggle_wishlist(id)
	for r in Roster.RARITIES:
		if not Roster.CRITTERS.any(func(c): return c.rarity == r):
			continue # No critters of this rarity yet: its rolls go a rarity down.
		var share := 0.0
		for c in Roster.CRITTERS:
			if c.rarity == r:
				share += Summon.share_in_rarity(p, c.id)
		check_near(share, 1.0, 1e-9, r + " shares add up to the rarity")
	var plain = UiProfile.sample()
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 5
	b.seed = 5
	for i in 50:
		var x: Array = Summon.pull(p, 10, a).map(Summon.rarity_of)
		var y: Array = Summon.pull(plain, 10, b).map(Summon.rarity_of)
		check_eq(x, y, "same rarities with and without a wishlist, pull %d" % i)
	check_eq(p.legendary_pity, plain.legendary_pity, "same pity")


func test_equipping_gear_replaces_the_same_slot() -> void:
	var p = UiProfile.sample()
	p.equip(5, "vampire") # A spare Bubble Shell onto Count Nibbles.
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
	shell.profile.toggle_wishlist("blackhole")
	shell.show_tab("summon")
	SummonScreen._open_picker(shell)
	check_eq(shell.profile.wishlist.size(), 1, "picker opens without changing picks")
	shell.open_tab("fuse", {"id": "speedster", "tier": 1})
	check_eq(shell.current_params.id, "speedster", "fuse opens on the picked critter")
	shell.go("campaign", {"zone": 0, "notice": "Won"})
	check_eq(shell.current, "campaign", "campaign map")
	shell.free()


func test_a_new_game_builds_every_screen() -> void:
	var shell = Shell.new()
	shell.profile = preload("res://meta/profile.gd").new_game(1_800_000_000)
	shell.build()
	for t in ["play", "critters", "fuse", "bag", "summon"]:
		shell.show_tab(t)
		check_eq(shell.current, t, "tab " + t)
	shell.go("campaign", {"zone": 0})
	check_eq(shell.current, "campaign", "campaign map")
	shell.free()


func test_the_world_map_opens_zones_and_shows_coming_ones() -> void:
	var shell = Shell.new()
	shell.profile = preload("res://meta/profile.gd").new_game(1_800_000_000)
	shell.build()
	shell.show_tab("play")
	shell._marks.campaign.pressed.emit()
	check_eq(shell.current, "world", "Open the map goes to the world map")
	check(shell._marks.has("zone_7"), "all seven zones are on the map")
	check(shell._footer.is_ancestor_of(shell._marks.enter_zone), "the way in is pinned")
	shell._marks.zone_2.pressed.emit()
	check_eq(shell.current, "world", "a coming zone stays on the map")
	shell._marks.zone_1.pressed.emit()
	check_eq(shell.current, "campaign", "zone 1 opens its stages")
	shell.back()
	check_eq(shell.current, "world", "Back returns to the world map")
	shell.free()


func test_main_actions_are_pinned_and_detail_sits_behind_an_i() -> void:
	var shell = Shell.new()
	shell.build()
	shell.open_tab("fuse", {"id": "speedster", "tier": 1})
	check(shell._footer.visible, "the Fuse button sits under the screen")
	check(shell._footer.is_ancestor_of(shell._marks.fuse), "it is the Fuse button")
	check(shell._marks.has("fuse_result_info"), "the full fuse result is behind an i")
	shell.show_tab("summon")
	check(shell._footer.is_ancestor_of(shell._marks.pull10), "x10 is pinned")
	check(shell._marks.has("summon_info"), "odds and pity are behind an i")
	shell.show_tab("critters")
	check(not shell._footer.visible, "a screen without a main action has no footer")
	shell.info("Title", ["One", "Two"])
	check(shell.overlay_open(), "the i opens a sheet")
	shell.free()


func test_home_groups_every_mode_as_a_tile() -> void:
	var shell = Shell.new()
	shell.build()
	shell.show_tab("play")
	for m in ["thisweek", "campaign", "quickfight", "trickshot", "bouncerun", "spire", "arena", "friends", "glowpass", "shop"]:
		check(shell._marks.has(m), "home has " + m)
	shell.free()



func test_lineup_tags_show_the_same_power_as_the_critter_screen() -> void:
	var FighterTag = load("res://game/ui/fighter_tag.gd")
	var p = UiProfile.sample()
	for id in ["vampire", "speedster"]:
		check_eq(FighterTag.rating(p.slot_of(id)), p.power_of(id), "%s tag power" % id)
	check_eq(FighterTag.rating({"critter": "vampire", "tier": 1, "level": 1, "gear": []}), Roster.power("vampire", 1, 1), "bare slot")
	var tag: Control = FighterTag.of_slot(p.slot_of("vampire"), 80)
	check(tag.get_child(0).get_child(0).get_child(0).count == 2, "two tier stars above the critter")
	tag.free()


func test_a_sweep_shows_a_results_popup() -> void:
	var shell = Shell.new()
	shell.profile = preload("res://meta/profile.gd").new_game(1_800_000_000)
	shell.profile.stars["1-1"] = 3
	shell.build()
	shell.go("campaign", {"zone": 0})
	shell._marks.sweep_1_1.pressed.emit()
	check(shell.overlay_open(), "the sweep result is a popup")
	check(shell._marks.has("result_continue"), "it has Continue")
	check_eq(shell.current_params.get("focus", -1), 0, "the list stays on the swept stage")
	shell._marks.result_continue.pressed.emit()
	check(not shell.overlay_open(), "Continue closes it")
	shell.free()
