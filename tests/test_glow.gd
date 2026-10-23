## Glow Pass, cosmetics shop and the fake store: money never buys power,
## nothing paid is random, cosmetics never touch the sim, and the pass and
## shop rules from design/monetisation.md.
extends "res://tests/test_case.gd"

const Catalog := preload("res://game/glow/catalog.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const Store := preload("res://game/glow/store.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const LiveOps := preload("res://game/liveops.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Shell := preload("res://game/ui/shell.gd")
const ShopScreen := preload("res://game/ui/screens/shop_screen.gd")
const PassScreen := preload("res://game/ui/screens/pass_screen.gd")

## Per process: tests/run.sh runs shards side by side.
var TEST_SAVE := "user://test_glow_save_%d.json" % OS.get_process_id()


func _schedule() -> Dictionary:
	return {"version": 1, "revision": 1, "chaos": [], "fights": [], "seasons": [
		{"name": "Season A", "start": "2026-10-12", "weeks": 7, "debut": "bomber"},
		{"name": "Season B", "start": "2026-11-30", "weeks": 7},
	]}


func _t(date: String, hour := 12) -> int:
	return LiveOps.date_unix(date) + hour * 3600


func _fresh():
	LiveOps.use(_schedule())
	var store := Store.new()
	return GlowState.new(SaveGame.new(TEST_SAVE), UiProfile.sample(), store)


func _done() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


# --- The firewall ----------------------------------------------------------------

func test_money_only_buys_gems_cosmetics_and_the_pass() -> void:
	for p in Catalog.PRODUCTS:
		check(p.kind in ["gems", "pass", "unlock"], "%s is gems, the pass or an unlock" % p.id)
		for k in p:
			check(k in ["id", "kind", "gems", "usd", "name", "items"], "%s has no other grants (%s)" % [p.id, k])
		for id in p.get("items", []):
			check(not Catalog.item(id).is_empty(), "%s gives a real cosmetic" % p.id)


func test_premium_track_has_no_power_and_free_track_has_it_all() -> void:
	var free_kinds := {}
	var free_gems := 0
	var paid_gems := 0
	var orbs := 0
	for l in range(1, GlowPass.LEVELS + 1):
		var p := GlowPass.premium_reward(l)
		if not p.is_empty():
			check(p.kind in ["cosmetic", "gems"], "premium L%d is a cosmetic or gems, not %s" % [l, p.kind])
			if p.kind == "gems":
				paid_gems += int(p.n)
			else:
				check_eq(Catalog.item(p.id).where, "pass_premium", "premium L%d cosmetic is a pass exclusive" % l)
		var f := GlowPass.free_reward(l, "bomber")
		free_kinds[f.kind] = true
		if f.kind == "gems":
			free_gems += int(f.n)
		if f.kind == "orbs":
			orbs += int(f.n)
		if f.kind == "cosmetic":
			check_eq(Catalog.item(f.id).where, "pass_free", "free L%d cosmetic is a free-track exclusive" % l)
	for k in Catalog.POWER_KINDS:
		check(free_kinds.has(k), "free track has %s" % k)
	check_eq(free_gems, 100, "free track gems")
	check_eq(paid_gems, 400, "premium track gems")
	check(orbs >= 24 and orbs <= 36, "about 30 Summon Orbs on the free track (%d)" % orbs)
	check(GlowPass.free_reward(10, "").kind == "orbs", "no debut critter: orbs instead of copies")


func test_shop_prices_are_fixed_gems_or_coins() -> void:
	var ids := {}
	for it in Catalog.ITEMS:
		check(not ids.has(it.id), "unique id " + it.id)
		ids[it.id] = true
		check(it.slot in Catalog.SLOTS, "%s has a known slot" % it.id)
		match it.where:
			"shop":
				check(it.has("gems") and not it.has("coins") and int(it.gems) > 0, "%s has a gem price" % it.id)
			"basic":
				check(it.has("coins") and not it.has("gems"), "%s has a coin price" % it.id)
			_:
				check(not it.has("gems") and not it.has("coins"), "%s (%s) is never sold" % [it.id, it.where])
	for b in Catalog.BUNDLES:
		check(int(b.gems) < Catalog.bundle_full_price(b), "%s is cheaper than its parts" % b.id)
		for id in b.items:
			check_eq(Catalog.item(id).get("where"), "shop", "%s holds shop items only" % b.id)


func test_cosmetics_stay_clear_of_the_team_ring_colours() -> void:
	for it in Catalog.ITEMS:
		for i in it.colors.size():
			var c := Catalog.color(it, i)
			for team in ArenaView.TEAM_COLORS:
				var d := Vector3(c.r - team.r, c.g - team.g, c.b - team.b).length()
				check(d > 0.25, "%s colour %d is too close to a team ring" % [it.id, i])


# --- Cosmetics never touch the sim ---------------------------------------------------

func test_cosmetics_do_not_change_a_fight() -> void:
	var config := {"seed": 4242, "p1": "vampire", "p2": "laser", "angles": [-450, 1350]}
	var plain := MatchSim.new(config)
	while not plain.finished:
		plain.step()
	var dressed := MatchSim.new(config.duplicate(true))
	var view := ArenaView.new()
	view.sim = dressed
	view.loadouts = [{"hat": "hat_crown", "trail": "trail_rainbow", "spark": "spark_pow", "ko": "ko_confetti"},
		{"hat": "hat_phones", "trail": "trail_pixel", "spark": "spark_glitch", "ko": "ko_disco"}]
	while not dressed.finished:
		dressed.step()
		view.consume_events(dressed.events)
		view.advance_effects(MatchSim.DT)
	check_eq(dressed.state_hash(), plain.state_hash(), "same fight with or without cosmetics")
	check_eq(dressed.tick, plain.tick, "same length")
	view.free()


func test_sim_never_reads_cosmetics() -> void:
	for f in DirAccess.get_files_at("res://sim"):
		if f.ends_with(".gd"):
			# Glowbug is a critter (sim/families.gd), not a cosmetic.
			var src := FileAccess.get_file_as_string("res://sim/" + f).replace("glowbug", "")
			check(not src.contains("glow") and not src.contains("cosmetic"), "sim/%s doesn't know about cosmetics" % f)


func test_rings_draw_after_cosmetics() -> void:
	var src := FileAccess.get_file_as_string("res://game/arena_view.gd")
	var draw := src.substr(src.find("func _draw() -> void:"))
	draw = draw.substr(0, draw.find("\nfunc ", 10))
	check(draw.rfind("_draw_overlay(") > draw.rfind("CosmeticArt.draw_ko("), "overlay after KO effects")
	check(draw.rfind("_draw_overlay(") > draw.rfind("_draw_critter("), "overlay after critters (and their hats)")


# --- Store and shop ---------------------------------------------------------------------

func test_fake_store_grants_each_purchase_once() -> void:
	var g = _fresh()
	g.store.purchase("gems_450")
	check_eq(g.gems(), 450, "gems arrive")
	check(not g.apply_purchase("gems_450", g.g().txns[-1]), "same transaction ignored")
	check_eq(g.gems(), 450, "no double grant")
	g.store.purchase("founder")
	check_eq(g.gems(), 1050, "founder gems")
	check(g.owns("hat_founder"), "founder hat")
	g.store.restore()
	check_eq(g.gems(), 1050, "restore doesn't re-grant gems")
	check(not g.apply_purchase("founder", "another-txn"), "founder is one time")
	_done()


func test_buying_items_and_bundles() -> void:
	var g = _fresh()
	check_eq(g.buy_item("hat_party"), "Not enough Glow Gems.", "can't afford")
	check(not g.owns("hat_party"), "not owned")
	g.apply_purchase("gems_950", "t1")
	check_eq(g.buy_item("hat_party"), "", "bought")
	check_eq(g.gems(), 700, "250 spent")
	check_eq(g.buy_item("hat_party"), "You already own it.", "no rebuy")
	check_eq(g.buy_item("hat_halo"), "That isn't for sale.", "pass exclusives aren't sold")
	var party := Catalog.bundle("bundle_party")
	check_eq(g.bundle_price(party), 950 - 250, "bundle drops by what you own")
	check_eq(g.buy_bundle("bundle_party"), "", "700 gems is exactly enough")
	check_eq(g.gems(), 0, "all spent")
	check(g.owns("trail_sparkle") and g.owns("ko_confetti"), "bundle items owned")
	check_eq(g.buy_bundle("bundle_party"), "You already own everything in it.", "no rebuy")
	_done()


func test_coin_items_spend_coins() -> void:
	var g = _fresh()
	var coins: int = g.profile.coins
	check_eq(g.buy_item("hat_beanie"), "", "bought with coins")
	check_eq(g.profile.coins, coins - 1500, "coins spent")
	check_eq(g.gems(), 0, "no gems involved")
	check(g.equip("hat_beanie"), "equip")
	check_eq(g.loadout(), {"hat": "hat_beanie"}, "loadout")
	check(not g.equip("hat_crown"), "can't wear what you don't own")
	g.unequip("hat")
	check(g.loadout().is_empty(), "taken off")
	_done()


func test_ledger_records_every_grant_and_spend() -> void:
	var g = _fresh()
	g.apply_purchase("gems_80", "t1")
	g.buy_item("spark_stars")
	var whats: Array = g.g().ledger.map(func(e): return e.what)
	check("gems" in whats, "gem grant logged")
	check("coins" in whats, "coin spend logged")
	check("cosmetic spark_stars" in whats, "cosmetic logged")
	_done()


# --- The Glow Pass ------------------------------------------------------------------------

func test_pass_levels_come_from_play_and_claims_need_the_level() -> void:
	var g = _fresh()
	var t := _t("2026-10-14")
	check_eq(g.pass_level(t), 0, "start at 0")
	check(not g.can_claim(1, "free", t), "level 1 not reached")
	g.add_xp(2500, "test", t)
	check_eq(g.pass_level(t), 2, "2,500 XP is level 2")
	var orbs: int = g.profile.orbs
	check_eq(g.claim(1, "free", t), {"kind": "orbs", "n": 2}, "claim L1")
	check_eq(g.profile.orbs, orbs + 2, "orbs land in the profile")
	check(g.claim(1, "free", t).is_empty(), "only once")
	check(not g.can_claim(1, "premium", t), "premium needs the pass")
	_done()


func test_buying_late_unlocks_everything_reached() -> void:
	var g = _fresh()
	var t := _t("2026-11-10")
	g.add_xp(12000, "test", t)
	check_eq(g.buy_pass_with_gems(t), "Not enough Glow Gems.", "need 500 gems")
	g.apply_purchase("gems_950", "t1", t)
	check_eq(g.buy_pass_with_gems(t), "", "unlocked with gems")
	check(g.pass_state(t).premium, "premium on")
	for l in range(1, 13):
		if not GlowPass.premium_reward(l).is_empty():
			check(g.can_claim(l, "premium", t), "premium L%d claimable at once" % l)
	var got: Array = g.claim_all(t)
	check(got.size() >= 12 + 6, "claim all takes both tracks (%d)" % got.size())
	check(g.owns("hat_halo") and g.owns("spark_neon"), "premium cosmetics granted")
	check(g.owns("hat_cap"), "free cosmetic granted")
	check_eq(g.profile.total_copies("bomber"), 2, "debut critter copy from the free track (sample owns 1)")
	check_eq(g.claimable_count(t), 0, "nothing left")
	check(not g.apply_purchase("glow_pass", "t2", t), "can't buy the pass twice in a season")
	_done()


func test_new_season_resets_the_pass_but_keeps_everything_earned() -> void:
	var g = _fresh()
	var a := _t("2026-10-20")
	g.add_xp(6000, "test", a)
	g.apply_purchase("glow_pass", "t1", a)
	g.claim_all(a)
	var gems: int = g.gems()
	var b := _t("2026-12-02")
	check_eq(g.season(b).name, "Season B", "season B")
	check_eq(g.pass_xp(b), 0, "fresh pass")
	check(not g.pass_state(b).premium, "premium is per season")
	check(g.owns("hat_halo"), "cosmetics stay")
	check_eq(g.gems(), gems, "gems stay")
	check(g.apply_purchase("glow_pass", "t2", b), "can buy the new season's pass")
	_done()


func test_bonus_boxes_after_level_50_are_capped() -> void:
	var g = _fresh()
	var t := _t("2026-10-20")
	g.add_xp(50000 + 2000 * 15, "test", t)
	check_eq(g.pass_level(t), 50, "level 50 is the top")
	check_eq(g.boxes_ready(t), GlowPass.BONUS_MAX, "10 boxes at most")
	g.claim_all(t)
	check_eq(g.boxes_ready(t), 0, "all opened")
	_done()


func test_finale_weekend_doubles_pass_xp() -> void:
	var g = _fresh()
	check_eq(g.add_xp(100, "test", _t("2026-11-25")), 100, "week 7 midweek: normal")
	check_eq(g.add_xp(100, "test", _t("2026-11-28")), 200, "finale Saturday: double")
	check_eq(g.add_xp(100, "test", _t("2026-11-01")), 100, "week 3 Sunday: normal")
	_done()


func test_no_season_no_pass() -> void:
	var g = _fresh()
	var gap := _t("2027-03-01")
	check(g.season(gap).is_empty(), "no season")
	check_eq(g.add_xp(500, "test", gap), 0, "no XP banked")
	check(not g.apply_purchase("glow_pass", "t1", gap), "can't buy a pass for no season")
	_done()


# --- Bounties ---------------------------------------------------------------------------

func test_three_different_bounties_every_day() -> void:
	for day in 120:
		var b := GlowPass.bounties_for(day)
		check_eq(b.size(), GlowPass.BOUNTIES_PER_DAY, "3 bounties")
		var kinds := {}
		for x in b:
			kinds[x.kind] = true
		check_eq(kinds.size(), 3, "day %d: three different kinds" % day)


func test_fights_fill_bounties_and_the_weekly_chest() -> void:
	var g = _fresh()
	var t := _t("2026-10-14")
	var xp := 0
	for i in 8:
		xp += g.record_fight(0, 250.0, t)
	var done: Array = g.bounties(t).filter(func(b): return b.done)
	check(done.size() >= 2, "8 wins with damage finish the fight bounties (%d)" % done.size())
	check(xp >= 8 * 30 + 2 * GlowPass.BOUNTY_XP, "XP from fights and bounties (%d)" % xp)
	g.record_trick(t)
	check_eq(g.week_state(t).count, g.bounties(t).filter(func(b): return b.done).size(), "week counts today's bounties")
	g.g().week.count = GlowPass.CHEST_AFTER
	check(g.chest_ready(t), "chest opens after 12")
	var before: int = g.pass_xp(t)
	check(g.open_chest(t), "opened")
	check_eq(g.pass_xp(t), before + GlowPass.CHEST_XP, "chest XP")
	check(not g.open_chest(t), "once a week")
	check_eq(g.bounties(t + 86400).filter(func(b): return b.progress > 0).size(), 0, "fresh bounties tomorrow")
	_done()


# --- Saves and screens -----------------------------------------------------------------

func test_glow_survives_the_save_and_a_cloud_adopt() -> void:
	var g = _fresh()
	g.apply_purchase("gems_80", "t1")
	g.save.save_local()
	var again := SaveGame.new(TEST_SAVE)
	again.load_local()
	var g2 = GlowState.new(again)
	check_eq(g2.gems(), 80, "gems persisted")
	var t := _t("2026-10-14")
	g2.add_xp(1000, "test", t)
	g2.claim(1, "free", t)
	again.save_local()
	var third := SaveGame.new(TEST_SAVE)
	third.load_local()
	var g3 = GlowState.new(third)
	check(g3.claimed(1, "free", t), "claims survive a JSON round trip")
	check(not g3.can_claim(1, "free", t), "and can't be claimed twice")
	check(SaveGame.progress(again.data) > 0, "a purchase alone counts as progress to sync")
	# A cloud copy from an older client has no glow key at all.
	again.adopt(5, {"picks": {"player": "laser"}}, "someone")
	check_eq(g2.gems(), 0, "adopted copy wins")
	check_eq(g2.pass_xp(), 0, "and is filled in with defaults")
	_done()


func test_liveops_debut_must_be_a_critter() -> void:
	var d := _schedule()
	check(LiveOps.validate(d).is_empty(), "valid: %s" % [LiveOps.validate(d)])
	d.seasons[0].debut = "nobody"
	check(not LiveOps.validate(d).is_empty(), "unknown debut caught")


func test_shop_and_pass_screens_build() -> void:
	LiveOps.use(_schedule())
	LiveOps.now_override = _t("2026-10-14")
	var shell = Shell.new()
	shell.build()
	shell.glow.apply_purchase("gems_2000", "s1")
	shell.go("shop")
	check_eq(shell.current, "shop", "shop")
	check_eq(ShopScreen.daily_items(LiveOps.now()).size(), ShopScreen.DAILY_SLOTS, "six daily items")
	ShopScreen.item_sheet(shell, "hat_crown")
	ShopScreen.gem_sheet(shell)
	shell.glow.buy_item("hat_crown")
	shell.glow.equip("hat_crown")
	shell.refresh()
	shell.go("pass")
	check_eq(shell.current, "pass", "pass")
	shell.glow.add_xp(5000, "test")
	shell.glow.buy_pass_with_gems()
	shell.refresh()
	check(shell.glow.claimable_count() > 0, "rewards to claim")
	shell.show_tab("play")
	shell.free()
	LiveOps.now_override = 0
	_done()
