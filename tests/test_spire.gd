extends "res://tests/test_case.gd"

const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const Relay := preload("res://sim/relay.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Families := preload("res://sim/families.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const SpireScreen := preload("res://game/ui/screens/spire_screen.gd")

const MONDAY := 1767571200 + 40 * 7 * 86400 ## Week 40, Monday 00:00 UTC.
## Per process: tests/run.sh runs shards side by side.
var TMP := "user://test_spire_%d.json" % OS.get_process_id()


func _climb(now := MONDAY):
	var c = SpireClimb.new()
	c.roll_week(now)
	return c


func _relay_for(c, picks: Array) -> Relay:
	var relay := Relay.new(Spire.relay_config(c.floor_spec(), picks))
	relay.run_to_end()
	return relay


func test_week_number_and_reset_time() -> void:
	check_eq(Spire.week_of(MONDAY), 40)
	check_eq(Spire.week_of(MONDAY - 1), 39, "Sunday night is the old week")
	check_eq(Spire.week_of(MONDAY + 7 * 86400 - 1), 40)
	check_eq(Spire.week_end(40), MONDAY + 7 * 86400)


func test_floors_are_the_same_for_everyone_in_a_week() -> void:
	for n in [1, 7, 10, 23, 50]:
		check_eq(Spire.floor_def(40, n), Spire.floor_def(40, n), "floor %d" % n)
	var differs := false
	for n in range(1, 11):
		if Spire.floor_def(40, n).seed != Spire.floor_def(41, n).seed:
			differs = true
	check(differs, "next week is a new tower")


func test_floor_shapes() -> void:
	for n in range(1, Spire.FLOORS + 1):
		var f := Spire.floor_def(3, n)
		check_eq(f.lineup, 1 if n < 5 else (2 if n < 15 else 3), "lineup on floor %d" % n)
		if f.boss:
			check_eq(f.enemies.size(), 1, "a boss fights alone")
			check(f.enemies[0].scale > 1.0, "bosses are big")
		else:
			check_eq(f.enemies.size(), f.lineup, "enemies on floor %d" % n)
		for e in f.enemies:
			check(BallDefs.PLAYABLE.has(e.id), "enemies are playable critters")
			check_eq(Families.of(e.id), f.family, "floor %d foes share its family" % n)
			check_eq(e.tier, Spire.tier_at(n), "floor %d foes' tier" % n)
		if n > 1:
			check(f.family != Spire.floor_def(3, n - 1).family, "each floor moves to another family")
	check_eq([Spire.tier_at(1), Spire.tier_at(10), Spire.tier_at(11), Spire.tier_at(50)], [1, 1, 2, 5], "foes tier up every 10 floors")
	check(Spire.power_at(50) > 4.0 * Spire.power_at(1), "the top is much harder than the bottom")


func test_relay_config_replays_identically() -> void:
	var spec := Spire.floor_def(40, 17)
	var picks := [{"id": "vampire", "power": 2.0}, {"id": "laser", "power": 2.1}, {"id": "vampire", "power": 1.9}]
	var a := Relay.new(Spire.relay_config(spec, picks, [-450, -300, null])).run_to_end()
	var b := Relay.new(Spire.relay_config(spec, picks, [-450, -300, null])).run_to_end()
	check_eq(a, b, "same week, floor, picks and aims")
	var cfg := Spire.relay_config(spec, picks)
	var leg := Relay.new(cfg).leg_config()
	check_eq(leg.powers, [2.0, spec.enemies[0].power], "powers reach the first leg")
	check_eq(leg.sizes, [1.0, spec.enemies[0].scale], "sizes reach the first leg")


func test_relay_without_powers_is_unchanged() -> void:
	var cfg := {"seed": 5, "sides": [["vampire"], ["laser"]], "aims": [[-450], [null]]}
	check(not Relay.new(cfg).leg_config().has("powers"), "older relays keep the old leg config")


func test_picks_are_checked() -> void:
	var c = _climb()
	check(c.check_picks([]) != "", "empty lineup")
	check(c.check_picks([{"id": "vampire", "power": 1.0}, {"id": "laser", "power": 1.0}]) != "", "floor 1 takes one")
	check_eq(c.check_picks([{"id": "vampire", "power": 1.0}]), "")
	c.spent["vampire"] = SpireClimb.STAMINA
	check(c.check_picks([{"id": "vampire", "power": 1.0}]) != "", "tired critters can't go")
	c.cleared = 6
	check(c.check_picks([{"id": "laser", "power": 1.0}, {"id": "laser", "power": 1.0}]) != "", "no duplicates")


func test_every_ball_that_came_out_spends_stamina() -> void:
	var c = _climb()
	c.cleared = 15 # Floor 16: three a side.
	var picks := [{"id": "vampire", "power": 9.0}, {"id": "laser", "power": 9.0}]
	c.begin(picks)
	var relay := _relay_for(c, picks)
	var r: Dictionary = c.settle(relay)
	var came_out := mini(relay.slot[0] + 1, 2)
	check_eq(r.spent.size(), came_out, "spent")
	check_eq(c.stamina("vampire"), SpireClimb.STAMINA - 1, "the lead always comes out")
	if r.won:
		check_eq(c.cleared, 16, "a win clears the floor")
		check_eq(c.unclaimed, [16], "and queues its reward")
		check_eq(c.clears.size(), 1, "and logs the clear")
	check(c.pending.is_empty(), "the attempt is settled")


func test_a_loss_spends_stamina_and_clears_nothing() -> void:
	var c = _climb()
	var picks := [{"id": "vampire", "power": 1.0}]
	c.begin(picks)
	var relay := _relay_for(c, picks)
	relay.winner = 1 # Settle it as a loss whatever happened.
	var r: Dictionary = c.settle(relay)
	check(not r.won, "lost")
	check_eq(c.cleared, 0)
	check_eq(c.stamina("vampire"), SpireClimb.STAMINA - 1)
	check(c.unclaimed.is_empty(), "no reward for a loss")


func test_balls_that_came_out_earn_xp() -> void:
	var c = _climb()
	c.cleared = 9 # Floor 10: a boss.
	var picks := [{"id": "vampire", "power": 1.0}, {"id": "laser", "power": 1.0}]
	c.begin(picks)
	var relay := _relay_for(c, picks)
	relay.winner = 0
	var r: Dictionary = c.settle(relay, 1)
	check_eq(r.xp, Spire.xp(10, true))
	check_eq(c.xp_owed, {"vampire": r.xp}, "only the ball that came out earns XP")
	check(Spire.xp(10, true) > 2 * Spire.xp(9, true) - 10, "boss floors pay double")
	check(Spire.xp(30, true) > Spire.xp(3, true), "higher floors pay more")
	check(Spire.xp(30, false) < Spire.xp(30, true), "a loss pays less")
	c.roll_week(MONDAY + 7 * 86400)
	check_eq(c.xp_owed, {"vampire": r.xp}, "owed XP survives the weekly reset")
	var p = UiProfile.sample()
	var b: Dictionary = p.best("vampire")
	var before := [int(b.level), int(b.get("xp", 0))]
	SpireScreen._collect(FakeShell.new(p), c)
	check(c.xp_owed.is_empty(), "XP is added once")
	check([int(b.level), int(b.get("xp", 0))] != before, "and lands on the critter")


class FakeShell:
	var profile
	func _init(p) -> void:
		profile = p
	func toast(_t: String, _id := "") -> void:
		pass


func test_suggest_prefers_type_advantage() -> void:
	# Sea beats Fire; Frost beats Sea.
	var list := [{"id": "bubbles", "power": 3.0, "stamina": 3}, {"id": "frost", "power": 2.0, "stamina": 3},
		{"id": "laser", "power": 1.9, "stamina": 3}]
	var spec := {"floor": 6, "lineup": 1, "enemies": [{"id": "bubbles"}]}
	check_eq(SpireScreen.suggest(list, spec), ["frost"], "the critter with the edge on the floor's foe")
	spec.enemies = [{"id": "frost"}]
	check_eq(SpireScreen.suggest(list, spec), ["laser"], "never into a bad matchup when a neutral one will do")


func test_giving_up_and_closing_the_app() -> void:
	var c = _climb()
	c.cleared = 20
	var picks := [{"id": "vampire", "power": 3.0}, {"id": "laser", "power": 3.0}]
	c.begin(picks)
	c.settle(Relay.new(Spire.relay_config(c.floor_spec(), picks)), 1)
	check_eq([c.stamina("vampire"), c.stamina("laser")], [2, 3], "only launched balls spend")
	c.begin(picks)
	c.pending.launched = 2
	check_eq(c.abandon(), ["vampire", "laser"], "closing the app mid-floor is a loss")
	check_eq([c.stamina("vampire"), c.stamina("laser")], [1, 2])
	check_eq(c.cleared, 20)


func test_new_week_resets_the_climb_but_keeps_rewards() -> void:
	var c = _climb()
	c.cleared = 12
	c.spent = {"vampire": 3}
	c.unclaimed = [12]
	check(not c.roll_week(MONDAY + 3 * 86400), "same week")
	check(c.roll_week(MONDAY + 7 * 86400), "Monday resets")
	check_eq([c.cleared, c.spent, c.last_week_best, c.unclaimed], [0, {}, 12, [12]])


func test_rewards_are_paid_once() -> void:
	var c = _climb()
	c.unclaimed = [5, 10]
	var t: Dictionary = c.take_rewards()
	check_eq(t.coins, Spire.reward(5).coins + Spire.reward(10).coins)
	check_eq(t.orbs, 2, "orbs every 5th floor")
	check_eq(t.gear, [{"type": Spire.BOSS_GEAR[0][0], "tier": Spire.BOSS_GEAR[0][1]}], "boss gear on floor 10")
	check(c.take_rewards().coins == 0, "nothing left the second time")
	var p = UiProfile.sample()
	var coins: int = p.coins
	var orbs: int = p.orbs
	var gear: int = p.gear.size()
	SpireScreen.grant(p, t)
	check_eq([p.coins, p.orbs, p.gear.size()], [coins + t.coins, orbs + 2, gear + 1])


func test_climb_saves_and_loads() -> void:
	var c = SpireClimb.load_file(MONDAY, TMP)
	c.cleared = 4
	c.spent = {"laser": 2}
	c.unclaimed = [4]
	c.save_file()
	var d = SpireClimb.load_file(MONDAY + 3600, TMP)
	check_eq([d.cleared, d.stamina("laser"), d.unclaimed], [4, 1, [4]])
	var e = SpireClimb.load_file(MONDAY + 8 * 86400, TMP)
	check_eq([e.cleared, e.last_week_best], [0, 4], "a stale file rolls to the new week")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TMP))


func test_suggest_saves_the_strongest() -> void:
	var list := [{"id": "a", "power": 5.0, "stamina": 3}, {"id": "b", "power": 1.5, "stamina": 3},
		{"id": "c", "power": 1.4, "stamina": 0}, {"id": "d", "power": 1.6, "stamina": 1}]
	var spec := {"floor": 6, "lineup": 2}
	check_eq(SpireScreen.suggest(list, spec), ["b", "d"], "weakest fresh critters that match floor 6")
