## The Critter Plunge league (meta/plunge_league.gd): medals climb it, a
## league is never lost, the CPU field races with its family's talents at
## the league's rank, and the prize races pay more as you climb.
extends "res://tests/test_case.gd"

const Plunge := preload("res://sim/plunge.gd")
const CritterPlunge := preload("res://meta/critter_plunge.gd")
const PlungeLeague := preload("res://meta/plunge_league.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const Families := preload("res://sim/families.gd")
const Profile := preload("res://meta/profile.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const A11y := preload("res://game/a11y.gd")

const T0 := 1_800_000_000
const COLUMN := 664.0 ## The phone column: 720 less the side margins.
const ROOM_SMALL := 1048.0 ## The screen's room on a 375x667 phone (shell.gd UI_FIT).


func _with_points(n: int):
	var p = Profile.new_game(T0)
	p.plunge.points = n
	return p


func test_leagues_match_the_arena_and_climb() -> void:
	check_eq(PlungeLeague.LEAGUES.map(func(l): return l.id), Ladder.LEAGUES.map(func(l): return l.id), "the arena's six leagues, in order")
	var last: Dictionary = {}
	for lg in PlungeLeague.LEAGUES:
		if not last.is_empty():
			check(lg.min > last.min and lg.rank > last.rank and lg.coins > last.coins, "%s asks more and gives more" % lg.id)
		last = lg
	check_eq(PlungeLeague.LEAGUES[0].min, 0, "everyone starts in Bronze")
	check_eq(PlungeLeague.LEAGUES[-1].rank, PlungeTalents.MAX_RANK, "Neon's field has every talent maxed")


## About 15 bronze a day: Silver on day 1-2, Gold in about a week, Neon in 6-8 weeks.
func test_thresholds_fit_a_regular_player() -> void:
	var day := 15.0
	var days := func(id: String) -> float:
		return PlungeLeague.LEAGUES.filter(func(l): return l.id == id)[0].min / day
	check(days.call("silver") > 0.5 and days.call("silver") <= 2.0, "Silver on day 1-2: %.1f days" % days.call("silver"))
	check(days.call("gold") >= 5.0 and days.call("gold") <= 9.0, "Gold in about a week: %.1f days" % days.call("gold"))
	check(days.call("neon") >= 42.0 and days.call("neon") <= 56.0, "Neon in 6-8 weeks: %.1f days" % days.call("neon"))


func test_league_from_points() -> void:
	for i in PlungeLeague.LEAGUES.size():
		var lo: int = PlungeLeague.LEAGUES[i].min
		check_eq(PlungeLeague.index_for(lo), i, "%s at its line" % PlungeLeague.LEAGUES[i].id)
		if i > 0:
			check_eq(PlungeLeague.index_for(lo - 1), i - 1, "one short of %s" % PlungeLeague.LEAGUES[i].id)
	check_eq(PlungeLeague.index_for(99999), PlungeLeague.LEAGUES.size() - 1, "Neon has no top")
	check_near(PlungeLeague.progress(0), 0.0, 0.001, "the bar starts empty")
	check_near(PlungeLeague.progress(PlungeLeague.LEAGUES[1].min / 2), 0.5, 0.05, "half way to Silver")
	check_near(PlungeLeague.progress(99999), 1.0, 0.001, "full in Neon")
	check_eq(PlungeLeague.index(null), 0, "no profile: Bronze")


## Points are every medal won (gold 4, silver 2, bronze 1); buying talents
## spends medals but never points, so a league is never lost.
func test_medals_climb_and_never_drop() -> void:
	var p = Profile.new_game(T0)
	check_eq(PlungeTalents.points(p), 0, "a new game has none")
	PlungeTalents.add_medal(p, "gold")
	PlungeTalents.add_medal(p, "silver")
	PlungeTalents.add_medal(p, "bronze")
	check_eq(PlungeTalents.points(p), 7, "4 + 2 + 1")
	for k in 4:
		PlungeTalents.add_medal(p, "gold")
	check_eq(PlungeLeague.index(p), 1, "23 points: Silver")
	var fam := "spooky"
	while PlungeTalents.buy(p, fam, "tough"):
		pass
	check(PlungeTalents.worth(PlungeTalents.medals(p)) < 23, "the medals are spent")
	check_eq(PlungeTalents.points(p), 23, "the points stay")
	check_eq(PlungeLeague.index(p), 1, "still Silver")
	PlungeTalents.add_medal(p, "")
	check_eq(PlungeTalents.points(p), 23, "no medal, no points")


func test_points_save_and_old_saves_count_what_they_had() -> void:
	var p = _with_points(260)
	var back = Profile.from_dict(p.to_dict(), T0)
	check_eq(PlungeTalents.points(back), 260, "saved")
	check_eq(PlungeLeague.league(back).id, "platinum", "and the league with it")
	var d: Dictionary = p.to_dict()
	d.plunge = {"medals": {"gold": 1, "silver": 1, "bronze": 1}, "talents": {"fire": {"tough": 2}}}
	var old = Profile.from_dict(d, T0)
	var spent: int = PlungeTalents.worth(PlungeTalents.PRICES[0]) + PlungeTalents.worth(PlungeTalents.PRICES[1])
	check_eq(PlungeTalents.points(old), 7 + spent, "a save from before the league: medals in hand plus talents bought")
	check_eq(PlungeTalents.clean({"points": -5}).points, 0, "never below 0")


## CPU racers get their own family's tree at the league's rank; yours keeps
## what you bought.
func test_the_field_scales_with_the_league() -> void:
	for i in PlungeLeague.LEAGUES.size():
		var p = _with_points(PlungeLeague.LEAGUES[i].min)
		var cfg := CritterPlunge.race_for(p, p.lineup, 6, 11)
		check_eq(cfg.boosts.size(), 6, "a boost slot per racer")
		check_eq(cfg.boosts[0], PlungeTalents.effects(p, p.lineup), "%s: you race with your own talents" % PlungeLeague.LEAGUES[i].id)
		var r: int = PlungeLeague.LEAGUES[i].rank
		for k in range(1, 6):
			var id: String = cfg.racers[k]
			if r == 0:
				check_eq(cfg.boosts[k], null, "Bronze: no field talents")
				continue
			var fx: Dictionary = cfg.boosts[k]
			check_near(fx.tough, 0.05 * r, 0.001, "%s: %s's HP" % [PlungeLeague.LEAGUES[i].id, id])
			check_near(fx.power, 0.05 * r, 0.001, "%s: %s's damage" % [PlungeLeague.LEAGUES[i].id, id])
			var sig: String = PlungeTalents.signature(Families.of(id)).id
			check_near(fx[sig], float(r) / PlungeTalents.MAX_RANK, 0.001, "%s: %s's own signature" % [PlungeLeague.LEAGUES[i].id, id])
	var neon = _with_points(PlungeLeague.LEAGUES[-1].min)
	var cfg := CritterPlunge.race_for(neon, neon.lineup, 6, 11)
	var race := Plunge.new(cfg)
	var plain := Plunge.new({"seed": 11, "racers": cfg.racers, "tiers": cfg.tiers})
	check_near(race.balls[1].max_hp, plain.balls[1].max_hp * 1.25, 0.01, "Neon: +25% HP in the race")
	check_near(race.balls[0].max_hp, plain.balls[0].max_hp, 0.01, "you: no talents bought, none")


func test_payout_rises_with_the_league() -> void:
	for i in PlungeLeague.LEAGUES.size():
		var k: float = PlungeLeague.LEAGUES[i].coins
		check_eq(CritterPlunge.coins_for(1, 6, i), roundi(CritterPlunge.WIN_COINS * k), "%s: 1st of 6" % PlungeLeague.LEAGUES[i].id)
		check_eq(CritterPlunge.coins_for(8, 8, i), roundi(CritterPlunge.LAST_COINS * CritterPlunge.COINS_8 * k), "%s: last of 8" % PlungeLeague.LEAGUES[i].id)
	var p = _with_points(PlungeLeague.LEAGUES[2].min)
	var coins: int = p.coins
	var r := CritterPlunge.finish(p, p.lineup, 1, 6, false, true, "", T0)
	check_eq(r.coins, CritterPlunge.coins_for(1, 6, 2), "Gold pays its coins")
	check_eq(p.coins, coins + r.coins, "into the profile")
	for k in CritterPlunge.PRIZE_RACES:
		CritterPlunge.finish(p, p.lineup, 1, 6, false, true, "", T0)
	check_eq(CritterPlunge.finish(p, p.lineup, 1, 6, false, true, "", T0).coins, 0, "still only the prize races pay")


func test_finish_reports_points_and_promotion() -> void:
	var p = _with_points(PlungeLeague.LEAGUES[1].min - 1)
	var r := CritterPlunge.finish(p, p.lineup, 2, 6, false, true, "", T0)
	check_eq([r.medal, r.points, r.league, r.promoted], ["silver", 2, 1, true], "a silver reaches Silver")
	r = CritterPlunge.finish(p, p.lineup, 3, 6, false, true, "", T0)
	check_eq([r.points, r.league, r.promoted], [1, 1, false], "a bronze inside it")
	r = CritterPlunge.finish(p, p.lineup, 5, 6, false, true, "", T0)
	check_eq([r.points, r.promoted], [0, false], "no medal, no points")


## The screen builds in every league, with the crest in the medal row, and
## still fits the phone column with Larger text.
func test_screen_shows_the_league_and_fits() -> void:
	var shell = load("res://game/ui/shell.gd").new()
	shell.build()
	shell.profile.lineup = "vampire"
	CritterPlunge.demo(shell.profile)
	A11y.large_text = true
	for i in PlungeLeague.LEAGUES.size():
		shell.profile.plunge.points = PlungeLeague.LEAGUES[i].min
		shell.go("plunge")
		check_eq(shell.current, "plunge", "builds in %s" % PlungeLeague.LEAGUES[i].id)
		check(shell._marks.has("plunge_league"), "the league crest is on screen")
		var margin = shell._scroll.get_child(0)
		var need: Vector2 = margin.get_child(0).get_combined_minimum_size()
		check(need.x <= COLUMN, "%s fits the column with Larger text: %d of %d" % [PlungeLeague.LEAGUES[i].id, need.x, COLUMN])
		check(need.y <= ROOM_SMALL, "and the height: %d of %d" % [need.y, ROOM_SMALL])
	A11y.large_text = false
	shell.free()
