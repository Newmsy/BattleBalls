extends "res://tests/test_case.gd"

const BounceRun := preload("res://sim/bounce_run.gd")
const Boons := preload("res://sim/boons.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


## The first START_BOONS boons of the day's offer.
static func _start(setup: Dictionary) -> Array:
	return setup.start_offer.slice(0, BounceRun.START_BOONS)


func test_day_numbers_follow_utc_days() -> void:
	check_eq(BounceRun.day_number(BounceRun.EPOCH_UNIX), 1, "launch day")
	check_eq(BounceRun.day_number(BounceRun.EPOCH_UNIX + 86399), 1, "launch day, last second")
	check_eq(BounceRun.day_number(BounceRun.EPOCH_UNIX + 86400), 2, "next day")
	check_eq(BounceRun.day_number(0), 1, "clocks set before launch still get run #1")


func test_runs_are_deterministic_per_day() -> void:
	check_eq(BounceRun.generate(5), BounceRun.generate(5), "same day, same run")
	check(BounceRun.generate(5) != BounceRun.generate(6), "different days should differ")


## Every foe carries exactly as many boons as you can hold on that floor, and
## every boon it carries works for its critter.
func test_foes_are_power_equalised() -> void:
	for day in range(1, 60):
		var setup := BounceRun.generate(day)
		check_eq(setup.cards.size(), BounceRun.DRAFT, "draft size")
		check_eq(setup.floors.size(), BounceRun.FLOORS, "floors")
		for f in BounceRun.FLOORS:
			var foe: Dictionary = setup.floors[f]
			check_eq(foe.boons.size(), BounceRun.START_BOONS + f, "day %d floor %d boon count" % [day, f + 1])
			var ability: String = BallDefs.get_def(foe.critter).ability
			for id in foe.boons:
				check(Boons.applies_to(id, ability), "day %d floor %d: %s is useless on %s" % [day, f + 1, id, foe.critter])
		check_eq(setup.start_offer.size(), BounceRun.START_OFFER, "day %d start offer size" % day)
		for id in setup.start_offer:
			check(id in Boons.GENERAL and setup.start_offer.count(id) == 1, "day %d start offer: %s is a general boon, once" % [day, id])
		var critters: Array = setup.cards.map(func(c): return c.critter)
		# Every critter shows up before any repeats: all of them while the
		# roster fits in one draft, five different ones once it doesn't.
		if BallDefs.PLAYABLE.size() <= BounceRun.DRAFT:
			for id in BallDefs.PLAYABLE:
				check(id in critters, "day %d draft offers every critter (missing %s)" % [day, id])
		else:
			for id in critters:
				check(critters.count(id) == 1, "day %d draft repeats %s" % [day, id])


func test_offers_are_new_usable_boons() -> void:
	var setup := BounceRun.generate(3)
	var run := BounceRun.new_run(setup, [0, 1, 2], _start(setup))
	for f in BounceRun.FLOORS - 1:
		run.floor = f + 1
		var offer := BounceRun.offer(setup, run)
		# Full offers while enough usable boons are left.
		var left := 0
		for id in Boons.ALL:
			if not id in run.boons.map(func(o): return Boons.base_of(o)) and range(BounceRun.PICKS).any(func(s): return Boons.applies_to(id, BallDefs.get_def(BounceRun.card(setup, run, s).critter).ability)):
				left += 1
		check_eq(offer.size(), mini(BounceRun.OFFER, left), "floor %d offer size" % (f + 1))
		check(offer.size() >= 2, "floor %d offers a real choice" % (f + 1))
		for id in offer:
			check(not Boons.base_of(id) in run.boons.map(func(o): return Boons.base_of(o)), "offer repeats an owned boon")
		run.boons.append(offer[0])
	check_eq(BounceRun.offer(setup, run), BounceRun.offer(setup, run), "offers are seeded")


func test_a_loss_costs_the_fighter_and_three_end_the_run() -> void:
	var setup := BounceRun.generate(1)
	var run := BounceRun.new_run(setup, [0, 2, 4], _start(setup))
	BounceRun.record(setup, run, 1, 0, 1, 600)
	check(run.out[1] and not run.over, "first loss knocks out the fighter only")
	check_eq(run.floor, 0, "a loss doesn't climb")
	BounceRun.record(setup, run, 0, 0, -1, 600)
	check(run.out[0], "a draw is not a win")
	BounceRun.record(setup, run, 2, 0, 1, 600)
	check(run.over, "trio out ends the run")
	check_eq(BounceRun.score(run), {"floors": 0, "lives": 0, "ticks": 1800}, "score")


func test_winning_every_floor_clears_the_run() -> void:
	var setup := BounceRun.generate(2)
	var run := BounceRun.new_run(setup, [0, 1, 2], _start(setup))
	for f in BounceRun.FLOORS:
		BounceRun.record(setup, run, 0, 0, 0, 100)
		if not run.over:
			check_eq(run.offer.size(), BounceRun.OFFER, "a win deals a full offer")
			BounceRun.take_boon(run, run.offer[0])
	check(run.over, "the top floor ends the run")
	check_eq(BounceRun.score(run), {"floors": BounceRun.FLOORS, "lives": 3, "ticks": 100 * BounceRun.FLOORS}, "perfect run")
	check_eq(run.boons.size(), BounceRun.START_BOONS + BounceRun.FLOORS - 1, "the starting boons, then one after every win but the last")


## There are enough general boons that every win offers a full choice, even
## on the last floor of a perfect run.
func test_every_offer_is_full() -> void:
	for day in range(1, 40):
		var setup := BounceRun.generate(day)
		var run := BounceRun.new_run(setup, [0, 1, 2], _start(setup))
		while not run.over:
			BounceRun.record(setup, run, 0, 0, 0, 100)
			if not run.over:
				check_eq(run.offer.size(), BounceRun.OFFER, "day %d floor %d offer" % [day, run.floor])
				BounceRun.take_boon(run, run.offer[run.offer.size() - 1])


## Foes start well under your power and end over it.
func test_floors_get_harder() -> void:
	check_eq(BounceRun.FOE_POWER.size(), BounceRun.FLOORS, "a power per floor")
	check(BounceRun.FOE_POWER[0] < 1.0 and BounceRun.FOE_POWER[BounceRun.FLOORS - 1] > 1.0, "easy start, hard top")
	for f in range(1, BounceRun.FLOORS):
		check(BounceRun.FOE_POWER[f] > BounceRun.FOE_POWER[f - 1], "floor %d is harder than the one before" % (f + 1))
	var setup := BounceRun.generate(1)
	var run := BounceRun.new_run(setup, [0, 1, 2], _start(setup))
	check_eq(BounceRun.fight_config(setup, run, 0, -450).powers, [1.0, BounceRun.FOE_POWER[0]], "the fight uses the floor's power")


func test_scores_rank_floors_then_lives_then_time() -> void:
	check(BounceRun.better({"floors": 5, "lives": 1, "ticks": 9000}, {"floors": 4, "lives": 3, "ticks": 100}), "floors first")
	check(BounceRun.better({"floors": 5, "lives": 2, "ticks": 9000}, {"floors": 5, "lives": 1, "ticks": 100}), "then lives")
	check(BounceRun.better({"floors": 5, "lives": 2, "ticks": 100}, {"floors": 5, "lives": 2, "ticks": 200}), "then faster")


## A played run replays to the same score from its log alone.
func test_runs_replay_from_their_log() -> void:
	var setup := BounceRun.generate(4)
	var run := BounceRun.new_run(setup, [1, 2, 3], _start(setup))
	var aims := [-450, -300, -600, -500, -400, -350, -550, -450, -420, -480, -380]
	var i := 0
	while not run.over:
		var slot: int = BounceRun.living(run)[0]
		var aim: int = aims[i % aims.size()]
		i += 1
		var result := MatchSim.new(BounceRun.fight_config(setup, run, slot, aim)).run_to_end()
		BounceRun.record(setup, run, slot, aim, result.winner, result.ticks)
		if not run.offer.is_empty():
			BounceRun.take_boon(run, run.offer[i % run.offer.size()])
	var check_run := BounceRun.replay(setup, run)
	check_eq(BounceRun.score(check_run), BounceRun.score(run), "replayed score")
	check_eq(check_run.log, run.log, "replayed log")


# --- Boons in the sim ----------------------------------------------------------

func test_no_boons_changes_nothing() -> void:
	var a := MatchSim.new({"seed": 9, "p1": "vampire", "p2": "laser"}).run_to_end()
	var b := MatchSim.new({"seed": 9, "p1": "vampire", "p2": "laser", "boons": [[], []]}).run_to_end()
	check_eq(b.hash, a.hash, "empty boon lists")


func test_stat_boons_scale_the_def() -> void:
	var def := Boons.apply_to_def(BallDefs.get_def("laser"), ["thick_shell", "spiky_rim", "prism", "sharper_fangs"])
	check_near(def.hp, BallDefs.get_def("laser").hp * Boons.get_def("thick_shell").hp, 0.001, "hp")
	var base := BallDefs.get_def("laser")
	check_near(def.beam_damage, base.beam_damage * Boons.get_def("spiky_rim").damage, 0.001, "beam damage")
	check_eq(def.beam_max, base.beam_max + Boons.get_def("prism").beam_max, "prism adds beams")
	check(not def.has("heal_ratio"), "vampire boon does nothing for a laser")


func test_overtime_bubble_absorbs_damage() -> void:
	var sim := MatchSim.new({"seed": 3, "p1": "plain", "p2": "plain", "boons": [["overtime_bubble"], []]})
	while sim.tick <= int(MatchSim.OVERTIME_START * MatchSim.TICK_RATE) and not sim.finished:
		sim.step()
	if sim.finished:
		return
	check_near(sim.balls[0].shield, Boons.get_def("overtime_bubble").overtime_shield, 0.001, "bubble on at overtime")
	check_eq(sim.balls[1].shield, 0.0, "foe has no bubble")


func test_opening_bite_lands_on_the_first_hit_only() -> void:
	var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "boons": [["opening_bite"], []],
		"starts": [Vector2(400, 500), Vector2(600, 500)], "angles": [0, 1800], "damage_rolls": false})
	var hits: Array = []
	while hits.size() < 2 and not sim.finished:
		sim.step()
		for e in sim.events:
			if e.type == "damage" and e.source == 0:
				hits.append(e.amount)
	check(hits.size() == 2, "two hits landed")
	# Head-on, both balls ram equally hard: base contact damage is 10.
	check_near(hits[0], 10.0 + Boons.get_def("opening_bite").first_strike, 0.01, "first hit")
	check(hits[1] <= 15.0, "later hits are normal")


func test_trio_goes_up_a_tier_every_two_floors() -> void:
	check_eq(range(BounceRun.FLOORS).map(func(f): return BounceRun.tier_at(f)), [1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "tiers by floor")
	var setup := BounceRun.generate(2)
	var run := BounceRun.new_run(setup, [0, 1, 2], _start(setup))
	run.floor = 6
	check_eq(BounceRun.fight_config(setup, run, 0, 0).tiers, [4, 1], "floor 7 fights at T4")


func test_rarer_boons_have_bigger_numbers() -> void:
	var common := Boons.get_def("thick_shell")
	var rare := Boons.get_def("thick_shell:rare")
	var epic := Boons.get_def("thick_shell:epic")
	check_eq([common.rarity, rare.rarity, epic.rarity], ["common", "rare", "epic"], "rarities")
	check(common.hp < rare.hp and rare.hp < epic.hp, "Epic > Rare > Common")
	check(rare.text != common.text and "%" in rare.text, "rarer text shows its numbers: %s" % rare.text)
	check_eq(Boons.get_def("phoenix_feather").rarity, "legendary", "legendaries are their own boons")
	for id in Boons.ALL:
		for r in ["rare", "epic"]:
			check(Boons.get_def(Boons.with_rarity(id, r)).text.length() > 5, "%s %s has text" % [id, r])


func test_offers_roll_seeded_rarities() -> void:
	var seen := {}
	for day in range(1, 40):
		var setup := BounceRun.generate(day)
		var run := BounceRun.new_run(setup, [0, 1, 2], _start(setup))
		for f in range(1, BounceRun.FLOORS):
			run.floor = f
			var offer := BounceRun.offer(setup, run)
			check_eq(offer, BounceRun.offer(setup, run), "seeded")
			for id in offer:
				seen[Boons.rarity_of(id)] = true
			run.boons.append(offer[0])
	check_eq(seen.keys().size(), 4, "every rarity turns up: %s" % [seen.keys()])


func _first_hits(cfg: Dictionary, n: int) -> Array:
	var sim := MatchSim.new(cfg)
	var out: Array = []
	while out.size() < n and not sim.finished:
		sim.step()
		for e in sim.events:
			if e.type == "damage":
				out.append(e)
	return out


func test_overcharge_doubles_every_third_bump() -> void:
	var cfg := {"seed": 1, "p1": "plain", "p2": "plain", "boons": [["overcharge"], []],
		"starts": [Vector2(400, 500), Vector2(600, 500)], "angles": [0, 1800], "damage_rolls": false}
	var mine: Array = _first_hits(cfg, 12).filter(func(e): return e.source == 0).map(func(e): return e.amount)
	check(mine.size() >= 3, "three hits")
	check_near(mine[2], mine[1] * 2.0, 0.5, "third hit doubles: %s" % [mine])


func test_thorn_crown_hits_back() -> void:
	var cfg := {"seed": 1, "p1": "plain", "p2": "plain", "boons": [[], ["thorn_crown"]],
		"starts": [Vector2(400, 500), Vector2(600, 500)], "angles": [0, 1800], "damage_rolls": false}
	var hits := _first_hits(cfg, 3)
	check(hits.any(func(e): return e.kind == "thorns" and e.source == 1), "thorns land: %s" % [hits])


func test_vampire_kiss_heals_and_phoenix_rises() -> void:
	var sim := MatchSim.new({"seed": 3, "p1": "plain", "p2": "plain", "boons": [["vampire_kiss", "phoenix_feather"], []], "powers": [0.6, 1.4]})
	var healed := false
	var rose := false
	while not sim.finished:
		sim.step()
		for e in sim.events:
			healed = healed or (e.type == "heal" and e.target == 0)
			rose = rose or (e.type == "revive" and e.ball == 0)
	check(healed, "Vampire Kiss heals on bumps")
	check(rose, "Phoenix Feather brings the ball back once")


# --- The scene ---------------------------------------------------------------

## Plays a whole run through the scene's own flow, headless, skipping fights.
func test_scene_plays_a_run_to_the_end() -> void:
	var path := "user://test_bounce_run.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://game/bounce_run.tscn").instantiate()
	scene.save_path = path
	runner.root.add_child(scene)
	scene._ready() # The test runner's tree isn't processing, so _ready hasn't run.
	check_eq(scene.state, scene.State.DRAFT, "opens on the draft")
	for i in [0, 2, 4]:
		scene._toggle_pick(i)
	scene._show_start_boons()
	for i in [0, 2, 4]:
		scene._toggle_start_boon(i)
	scene._start_run()
	var fights := 0
	while scene.state != scene.State.OVER and fights < 20:
		fights += 1
		check_eq(scene.state, scene.State.FLOOR, "floor screen before fight %d" % fights)
		scene._choose_fighter(BounceRun.living(scene.run)[0])
		scene._launch()
		scene._skip()
		scene._process(0.016)
		check_eq(scene.state, scene.State.RESULT, "result after fight %d" % fights)
		scene._after_result()
		if scene.state == scene.State.BOON:
			scene._take_boon(scene.run.offer[0])
	check(scene.run.over, "the run ended")
	check_eq(BounceRun.replay(scene.setup, scene.run).log, scene.run.log, "the played run replays")
	# Reopening the scene shows the finished ranked run, not a new draft.
	var again = load("res://game/bounce_run.tscn").instantiate()
	again.save_path = path
	runner.root.add_child(again)
	again._ready()
	check_eq(again.state, again.State.OVER, "finished run is remembered")
	check(again.ranked, "still the ranked run")
	again._practice()
	check(not again.ranked and again.state == again.State.DRAFT, "practice starts a fresh, unranked draft")
	scene.queue_free()
	again.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Closing the app mid-fight doesn't undo the fight: it's settled on reopen.
func test_a_fight_left_mid_way_still_counts() -> void:
	var path := "user://test_bounce_run_quit.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene = load("res://game/bounce_run.tscn").instantiate()
	scene.save_path = path
	runner.root.add_child(scene)
	scene._ready()
	for i in [0, 1, 2]:
		scene._toggle_pick(i)
	scene._show_start_boons()
	for i in [0, 2, 4]:
		scene._toggle_start_boon(i)
	scene._start_run()
	scene._choose_fighter(0)
	scene._launch()
	var again = load("res://game/bounce_run.tscn").instantiate()
	again.save_path = path
	runner.root.add_child(again)
	again._ready()
	check_eq(again.run.log.size(), 1, "the abandoned fight was recorded")
	check(not again.run.has("launched"), "and cleared")
	scene.queue_free()
	again.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
