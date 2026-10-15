extends "res://tests/test_case.gd"

const BounceRun := preload("res://sim/bounce_run.gd")
const Boons := preload("res://sim/boons.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")


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
			check_eq(foe.boons.size(), f + 1, "day %d floor %d boon count" % [day, f + 1])
			var ability: String = BallDefs.get_def(foe.critter).ability
			for id in foe.boons:
				check(Boons.applies_to(id, ability), "day %d floor %d: %s is useless on %s" % [day, f + 1, id, foe.critter])
		for c in setup.cards:
			check(Boons.applies_to(c.boon, BallDefs.get_def(c.critter).ability), "day %d card boon fits its critter" % day)
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
	var run := BounceRun.new_run(setup, [0, 1, 2])
	for f in BounceRun.FLOORS - 1:
		run.floor = f + 1
		var offer := BounceRun.offer(setup, run)
		check_eq(offer.size(), BounceRun.OFFER, "floor %d offer size" % (f + 1))
		for id in offer:
			check(not id in run.boons, "offer repeats an owned boon")
		run.boons.append(offer[0])
	check_eq(BounceRun.offer(setup, run), BounceRun.offer(setup, run), "offers are seeded")


func test_a_loss_costs_the_fighter_and_three_end_the_run() -> void:
	var setup := BounceRun.generate(1)
	var run := BounceRun.new_run(setup, [0, 2, 4])
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
	var run := BounceRun.new_run(setup, [0, 1, 2])
	for f in BounceRun.FLOORS:
		BounceRun.record(setup, run, 0, 0, 0, 100)
		if not run.over:
			check_eq(run.offer.size(), BounceRun.OFFER, "a win deals an offer")
			BounceRun.take_boon(run, run.offer[0])
	check(run.over, "eight wins end the run")
	check_eq(BounceRun.score(run), {"floors": 8, "lives": 3, "ticks": 800}, "perfect run")
	check_eq(run.boons.size(), BounceRun.FLOORS - 1, "a boon after every win but the last")


func test_scores_rank_floors_then_lives_then_time() -> void:
	check(BounceRun.better({"floors": 5, "lives": 1, "ticks": 9000}, {"floors": 4, "lives": 3, "ticks": 100}), "floors first")
	check(BounceRun.better({"floors": 5, "lives": 2, "ticks": 9000}, {"floors": 5, "lives": 1, "ticks": 100}), "then lives")
	check(BounceRun.better({"floors": 5, "lives": 2, "ticks": 100}, {"floors": 5, "lives": 2, "ticks": 200}), "then faster")


## A played run replays to the same score from its log alone.
func test_runs_replay_from_their_log() -> void:
	var setup := BounceRun.generate(4)
	var run := BounceRun.new_run(setup, [1, 2, 3])
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
