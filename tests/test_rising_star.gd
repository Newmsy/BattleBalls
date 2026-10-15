## Rising Star catch-up XP (meta/rising_star.gd): who gets it, how much, when
## it stops, and the server's median arriving.
extends "res://tests/test_case.gd"

const Profile := preload("res://meta/profile.gd")
const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")
const RisingStar := preload("res://meta/rising_star.gd")

const T0 := 1_800_000_000
const DAY := 86400


func _win() -> Dictionary:
	return {"winner": 0, "hp": [90.0, 0.0], "time": 20.0, "max_hp": 100.0}


func test_a_new_account_below_the_median_is_boosted() -> void:
	var p = Profile.new_game(T0)
	check(RisingStar.active(p, T0), "new account")
	check_eq(RisingStar.days_left(p, T0), RisingStar.WINDOW_DAYS, "full window")
	check_eq(RisingStar.account_xp(p, 6, T0), 12, "double account XP")
	check_eq(RisingStar.critter_xp(p, 10, T0), 15, "+50% critter XP")
	check_eq(RisingStar.critter_xp(p, 3, T0), 5, "rounds up")
	check(RisingStar.banner_text(p, T0).contains("level %d" % RisingStar.FALLBACK_MEDIAN), "banner names the target")


func test_it_stops_at_the_median_level() -> void:
	var p = Profile.new_game(T0)
	p.rising_median = 9
	p.account_level = 9
	check(not RisingStar.active(p, T0), "caught up")
	check_eq(RisingStar.account_xp(p, 6, T0), 6, "normal XP")
	check_eq(RisingStar.banner_text(p, T0), "", "no banner")


func test_it_stops_after_thirty_days() -> void:
	var p = Profile.new_game(T0)
	check(RisingStar.active(p, T0 + 29 * DAY + 100), "day 30 still counts")
	check_eq(RisingStar.days_left(p, T0 + 29 * DAY + 100), 1, "last day")
	check(not RisingStar.active(p, T0 + 30 * DAY), "window over")
	check_eq(RisingStar.days_left(p, T0 - DAY), RisingStar.WINDOW_DAYS, "clock behind the start counts as day 1")


func test_an_unknown_start_is_never_boosted() -> void:
	var p = Profile.new_game(T0)
	p.started = 0
	check(not RisingStar.active(p, T0), "sample/demo profiles show no banner")


func test_campaign_xp_is_boosted_while_active() -> void:
	var fresh = Profile.new_game(T0)
	var veteran = Profile.new_game(T0)
	veteran.started = T0 - 40 * DAY
	for p in [fresh, veteran]:
		Campaign.start(p, 0, 0, "vampire", T0)
	var a: Dictionary = Campaign.finish(fresh, 0, 0, "vampire", _win(), T0)
	var b: Dictionary = Campaign.finish(veteran, 0, 0, "vampire", _win(), T0)
	check(a.rising_star and not b.rising_star, "flagged on the result")
	check_eq(fresh.account_xp, 2 * veteran.account_xp, "double account XP")
	check_eq(a.xp, ceili(b.xp * RisingStar.CRITTER_XP_MULT), "+50% critter XP")
	check(not b.has("error"), "veteran ran normally")


func test_server_median_and_join_date_apply() -> void:
	var p = Profile.new_game(T0)
	check(RisingStar.needs_refresh(p, T0), "never fetched")
	RisingStar.apply_server(p, {"median": 4, "players": 120, "joined": T0 - 10 * DAY}, T0)
	check_eq(RisingStar.target_level(p), 4, "server median")
	check_eq(p.started, T0 - 10 * DAY, "the older account date wins")
	check_eq(RisingStar.days_left(p, T0), 20, "window counts from joining")
	check(not RisingStar.needs_refresh(p, T0 + 60), "fresh")
	check(RisingStar.needs_refresh(p, T0 + RisingStar.STALE_SECONDS), "stale after a while")
	RisingStar.apply_server(p, {"median": null, "players": 3, "joined": T0}, T0)
	check_eq(RisingStar.target_level(p), 4, "too few players keeps the cached median")
	check_eq(p.started, T0 - 10 * DAY, "a later join date doesn't restart the window")


func test_offline_falls_back_to_the_cached_then_default_median() -> void:
	var p = Profile.new_game(T0)
	check_eq(RisingStar.target_level(p), RisingStar.FALLBACK_MEDIAN, "default before any fetch")
	p.rising_median = 22
	var q = Profile.from_dict(JSON.parse_string(JSON.stringify(p.to_dict())), T0 + DAY)
	check_eq(RisingStar.target_level(q), 22, "cached median survives the save")
	check_eq(q.started, T0, "start survives the save")


func test_old_saves_start_the_window_on_load() -> void:
	var d: Dictionary = Profile.new_game(T0).to_dict()
	d.erase("started")
	var q = Profile.from_dict(d, T0 + 5 * DAY)
	check_eq(q.started, T0 + 5 * DAY, "window starts when the update first loads")
