extends "res://tests/test_case.gd"

const BounceRun := preload("res://sim/bounce_run.gd")
const Boons := preload("res://sim/boons.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const BounceBot := preload("res://tools/bounce_bot.gd")
const Rng := preload("res://sim/rng.gd")


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
	check_eq(BounceRun.generate(5, 0), BounceRun.generate(5), "seed 0 is the day's own tower")
	check(BounceRun.generate(5, 4242).cards != BounceRun.generate(5).cards, "a practice seed draws a fresh tower")
	check_eq(BounceRun.generate(5, 4242), BounceRun.generate(5, 4242), "a practice seed replays")
	var setup := BounceRun.generate(5, 4242)
	check_eq(BounceRun.new_run(setup, [0, 1, 2], setup.start_offer.slice(0, BounceRun.START_BOONS)).seed, 4242, "the run keeps its seed")


## A new run on day `day` with the first three cards and starting boons.
static func _new(day: int) -> Array:
	var setup := BounceRun.generate(day)
	return [setup, BounceRun.new_run(setup, [0, 1, 2], _start(setup))]


## Every map has the same shape rules: a 20-floor climb, links only to the
## next floor, no crossings, fixed rows, and the Champion on top.
func test_maps_follow_the_rules() -> void:
	for day in range(1, 50):
		var setup := BounceRun.generate(day)
		var nodes: Dictionary = setup.nodes
		var rows := {}
		for id in nodes:
			var n: Dictionary = nodes[id]
			rows[n.row] = rows.get(n.row, 0) + 1
			for k in n.kids:
				check_eq(nodes[k].row, n.row + 1, "day %d: links go up one floor" % day)
			if n.row < BounceRun.FLOORS - 1:
				check(not n.kids.is_empty(), "day %d: no dead ends" % day)
			match n.row:
				0:
					check_eq(n.type, "fight", "floor 1 is all fights")
				BounceRun.CHEST_ROW:
					check_eq(n.type, "chest", "the middle floor is all chests")
				BounceRun.REST_ROW:
					check_eq(n.type, "rest", "Charge Pads before the Champion")
				BounceRun.FLOORS - 1:
					check_eq(n.type, "boss", "the Champion on top")
			if n.type == "elite":
				check(n.row >= 4, "day %d: no early elites" % day)
			if n.type in ["fight", "elite", "boss"]:
				check(n.foe.boons.is_empty(), "day %d: foes get no boons" % day)
		check_eq(rows.size(), BounceRun.FLOORS, "day %d: every floor has nodes" % day)
		check_eq(rows[BounceRun.FLOORS - 1], 1, "one Champion")
		check(rows[0] >= 2, "day %d: a choice of start" % day)
		var links := 0
		var froms := 0
		for id in nodes:
			check(nodes[id].row == 0 or not BounceRun._parents(nodes, id).is_empty(), "day %d: every node has a way in" % day)
			for k in nodes[id].kids:
				check(nodes[k].row == nodes[id].row + 1, "day %d: links go up one floor" % day)
				check(nodes[k].col < 0 or absi(nodes[k].col - nodes[id].col) <= 4, "day %d: links stay short" % day)
			if nodes[id].row < BounceRun.FLOORS - 2:
				links += nodes[id].kids.size()
				froms += 1
		var ways := float(links) / froms
		check(ways > 1.6 and ways < 1.95, "day %d: about 1.8 ways on from a node (%.2f)" % [day, ways])
		# No two links cross between the same floors.
		for a in nodes:
			for b in nodes:
				if nodes[a].row != nodes[b].row or a >= b or nodes[a].row >= BounceRun.FLOORS - 2:
					continue
				for ka in nodes[a].kids:
					for kb in nodes[b].kids:
						var left: bool = nodes[a].col < nodes[b].col
						check(nodes[ka].col <= nodes[kb].col if left else nodes[ka].col >= nodes[kb].col, "day %d: links cross" % day)
		check_eq(setup.cards.size(), BounceRun.DRAFT, "draft size")
		for id in setup.start_offer:
			check(id in Boons.GENERAL and setup.start_offer.count(id) == 1, "day %d start offer: %s is a general boon, once" % [day, id])


## You can only step to nodes linked from where you are, starting on floor 1.
func test_you_walk_the_links() -> void:
	var p := _new(3)
	var setup: Dictionary = p[0]
	var run: Dictionary = p[1]
	var first := BounceRun.next_nodes(setup, run)
	check(first.all(func(id): return setup.nodes[id].row == 0), "start on floor 1")
	BounceRun.go(setup, run, first[0])
	check_eq(BounceRun.phase(setup, run), "fight", "floor 1 is a fight")
	check_eq(BounceRun.next_nodes(setup, run), [], "no moving mid-fight")
	BounceRun.record(setup, run, 0, -450, 0, 300, 0.0)
	check_eq(run.floor, 1, "a win clears the floor")
	check_eq(run.buttons, BounceRun.PAY.fight, "and pays Buttons")
	check_eq(BounceRun.phase(setup, run), "boon", "then a boon pick")
	BounceRun.take_boon(run, run.offer[0])
	check_eq(BounceRun.next_nodes(setup, run), setup.nodes[first[0]].kids, "then the linked nodes above")


func test_a_loss_costs_the_fighter_and_three_end_the_run() -> void:
	var p := _new(1)
	var setup: Dictionary = p[0]
	var run: Dictionary = p[1]
	BounceRun.go(setup, run, BounceRun.next_nodes(setup, run)[0])
	BounceRun.record(setup, run, 1, 0, 1, 600, 20.0)
	check(run.out[1] and not run.over, "first loss knocks out the fighter only")
	check_eq(run.floor, 0, "a loss doesn't climb")
	check_eq(BounceRun.fight_config(setup, run, 0, -450).hp, [null, 20.0], "the foe keeps its damage")
	BounceRun.record(setup, run, 0, 0, -1, 600)
	check(run.out[0], "a draw is not a win")
	BounceRun.record(setup, run, 2, 0, 1, 600)
	check(run.over, "trio out ends the run")
	check_eq(BounceRun.score(run), {"floors": 0, "lives": 0, "ticks": 1800}, "score")


## Elites and the Champion are bigger and stronger than a floor's normal foe.
func test_elites_are_bigger_and_tougher() -> void:
	var seen := false
	for day in range(1, 20):
		var setup := BounceRun.generate(day)
		for id in setup.nodes:
			var n: Dictionary = setup.nodes[id]
			if n.type == "elite":
				seen = true
				check_eq(n.foe.size, BounceRun.ELITE_SIZE, "elites are bigger")
				check_near(n.foe.power, BounceRun.FOE_POWER[n.row] * BounceRun.ELITE_POWER, 0.0001, "and stronger")
			if n.type == "boss":
				check_eq(n.foe.size, BounceRun.BOSS_SIZE, "the Champion is big")
	check(seen, "elites turn up")


## A hatched egg critter fights beside you as p3: a 2v1, small and a tier down.
func test_the_hatchling_makes_it_two_on_one() -> void:
	var p := _new(2)
	var setup: Dictionary = p[0]
	var run: Dictionary = p[1]
	run.hatchling = "spiker"
	run.floor = 8
	var row8: Array = setup.nodes.keys().filter(func(id): return setup.nodes[id].row == 8 and setup.nodes[id].type == "fight")
	if row8.is_empty():
		return
	run.at = row8[0]
	run.done = false
	var cfg := BounceRun.fight_config(setup, run, 0, -450)
	check_eq(cfg.p3, "spiker", "the hatchling joins")
	check(cfg.has("p4") and cfg.p4 == null, "nobody joins the foe")
	var sim := MatchSim.new(cfg)
	check_eq(sim.balls.size(), 3, "three balls")
	check_eq(sim.balls[2].team, 0, "on your side")
	check(sim.balls[2].radius < sim.balls[0].radius, "and smaller")
	check_eq(cfg.tiers[2], BounceRun.tier_at(8) - 1, "a tier down")
	var result := sim.run_to_end()
	check(result.winner in [-1, 0, 1], "the fight ends with a team winning")


## The trader's critters lean rare: over many maps, most offers are Rare or better.
func test_the_trader_offers_rarer_critters() -> void:
	var counts := {}
	var n := 0
	for day in range(1, 120):
		var p := _new(day)
		var setup: Dictionary = p[0]
		var run: Dictionary = p[1]
		for id in setup.nodes:
			if setup.nodes[id].get("event", "") == "tide_pool_trader":
				run.at = id
				run.done = false
				var offer := BounceRun.trade_offer(setup, run)
				check_eq(offer.size(), 2, "two critters")
				for c in offer:
					check(not c in run.critters, "never one you have")
					var r: String = BallDefs.DEFS[c].get("rarity", "common")
					counts[r] = counts.get(r, 0) + 1
					n += 1
	var rare_up: int = counts.get("rare", 0) + counts.get("epic", 0) + counts.get("legendary", 0)
	check(n > 20 and rare_up * 100 / n >= 70, "mostly Rare or better: %s" % [counts])


## Every event choice works from a run that can take it, and the shop, Charge
## Pad and Glitches do what they say.
func test_events_shops_and_rests() -> void:
	var p := _new(5)
	var setup: Dictionary = p[0]
	var run: Dictionary = p[1]
	var node_id: int = setup.nodes.keys().filter(func(id): return setup.nodes[id].type != "boss")[0]
	for ev in BounceRun.EVENT_IDS:
		for c in BounceRun.EVENTS[ev].choices:
			var r := run.duplicate(true)
			r.buttons = 100
			r.out = [false, true, false]
			r.boons.append("glitch_singed")
			var s := setup.duplicate(true)
			s.nodes[node_id].type = "mystery"
			s.nodes[node_id].holds = "event"
			s.nodes[node_id].event = ev
			r.at = node_id
			r.done = false
			check(BounceRun.can_choose(s, r, c.id), "%s/%s can be taken" % [ev, c.id])
			var args := BounceRun.choice_args(s, r, c)
			BounceRun.choose(s, r, c.id, args[0] if not args.is_empty() else null)
			check(r.done or r.rival, "%s/%s finishes the event" % [ev, c.id])
			match c.id:
				"hatch":
					check(r.hatchling != "" and BallDefs.DEFS[r.hatchling].rarity == "common", "a Common hatchling")
				"sell":
					check_eq(r.buttons, 140, "sold for 40")
				"drink":
					check(not r.out[1], "revived")
				"smash":
					check(not "glitch_singed" in r.boons, "Glitch cleaned")
				"dash":
					check(r.dash and "glitch_singed" in r.boons, "dashed with a Glitch")
	# Shop.
	var r := run.duplicate(true)
	var shop_id: int = node_id
	var s2 := setup.duplicate(true)
	s2.nodes[shop_id].type = "shop"
	s2.nodes[shop_id].erase("holds")
	r.at = -1
	r.done = true
	s2.nodes[shop_id].row = 0
	BounceRun.go(s2, r, shop_id)
	check_eq(BounceRun.phase(s2, r), "shop", "in the shop")
	check(not BounceRun.can_buy(s2, r, "boon:0"), "no Buttons, no boon")
	r.buttons = 200
	var bought: String = r.shop.stock[2]
	BounceRun.buy(s2, r, "boon:2")
	check(bought in r.boons and r.buttons == 200 - BounceRun.price(s2, r, "boon:2"), "bought a boon")
	check(not BounceRun.can_buy(s2, r, "boon:2"), "sold out")
	check(not BounceRun.can_buy(s2, r, "revive"), "nobody to revive")
	BounceRun.leave(s2, r)
	check(r.done and r.floor == 1, "leaving clears the floor")


func test_floors_get_harder() -> void:
	check_eq(BounceRun.FOE_POWER.size(), BounceRun.FLOORS, "a power per floor")
	check(BounceRun.FOE_POWER[0] < 1.0 and BounceRun.FOE_POWER[BounceRun.FLOORS - 1] > 1.0, "easy start, hard top")
	for f in range(1, BounceRun.FLOORS):
		check(BounceRun.FOE_POWER[f] > BounceRun.FOE_POWER[f - 1], "floor %d is harder than the one before" % (f + 1))
	check_eq(range(BounceRun.FLOORS).map(func(f): return BounceRun.tier_at(f)), [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5], "tiers by floor")


func test_scores_rank_floors_then_lives_then_time() -> void:
	check(BounceRun.better({"floors": 5, "lives": 1, "ticks": 9000}, {"floors": 4, "lives": 3, "ticks": 100}), "floors first")
	check(BounceRun.better({"floors": 5, "lives": 2, "ticks": 9000}, {"floors": 5, "lives": 1, "ticks": 100}), "then lives")
	check(BounceRun.better({"floors": 5, "lives": 2, "ticks": 100}, {"floors": 5, "lives": 2, "ticks": 200}), "then faster")


## Random played runs replay to the same run from their log alone, and average
## about ten fights.
func test_runs_replay_from_their_log() -> void:
	var fights := 0
	for i in 6:
		var rng := Rng.new(i * 977 + 5)
		var setup := BounceRun.generate(10 + i)
		var run := BounceBot.start(setup, rng)
		fights += BounceBot.play(setup, run, rng).fights.size()
		check(run.over, "run %d ended" % i)
		var again := BounceRun.replay(setup, run)
		check_eq(BounceRun.score(again), BounceRun.score(run), "replayed score")
		check_eq(again.boons, run.boons, "replayed boons")
		check_eq(again.buttons, run.buttons, "replayed Buttons")
		check_eq(again.log, run.log, "replayed log")
	check(fights >= 6 * 4, "runs have real fights in them (%d)" % fights)


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


func test_glitches_are_bad_and_never_offered() -> void:
	for id in Boons.GLITCHES:
		check(Boons.is_glitch(id) and not id in Boons.ALL, "%s stays out of offers" % id)
		var def := Boons.apply_to_def(BallDefs.get_def("vampire"), [id])
		var base := BallDefs.get_def("vampire")
		check(def.hp <= base.hp and def.speed <= base.speed, "%s only hurts" % id)


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


## Events from a fight where ball 0 holds `boons`, for up to `secs` seconds.
func _boon_events(boons: Array, secs := 40.0, seed := 3) -> Array:
	var sim := MatchSim.new({"seed": seed, "p1": "plain", "p2": "plain", "boons": [boons, []]})
	var out: Array = []
	while not sim.finished and sim.time() < secs:
		sim.step()
		out.append_array(sim.events)
	return out


func test_mechanic_boons_go_off() -> void:
	var ev := _boon_events(["ember_rim"])
	check(ev.any(func(e): return e.type == "damage" and e.kind == "burn" and e.target == 1), "Ember Rim burns the foe")
	ev = _boon_events(["rebound_bolt"])
	check(ev.any(func(e): return e.type == "shot" and e.kind == "boon_bolt" and e.ball == 0), "Rebound Bolt fires off walls")
	check(ev.any(func(e): return e.type == "damage" and e.kind == "shot" and e.source == 0), "and the spark lands")
	ev = _boon_events(["bounce_mine"])
	check(ev.any(func(e): return e.type == "boom" and e.ball == 0), "Bounce Mine mines go off")
	ev = _boon_events(["zap_collar"])
	check(ev.any(func(e): return e.type == "stun" and e.source == 0), "Zap Collar stuns")
	ev = _boon_events(["pinball"], 60.0, 5)
	check(ev.any(func(e): return e.type == "boon" and e.id == "pinball"), "Pinball slams a foe into a wall")
	ev = _boon_events(["storm_heart"], 11.0)
	check(ev.filter(func(e): return e.type == "boon" and e.id == "storm_heart").size() == 2, "Storm Heart strikes every 5s")
	ev = _boon_events(["payback"])
	check(ev.any(func(e): return e.type == "boon" and e.id == "payback" and e.ball == 0), "Payback hits back")


func test_frost_rim_slows_and_titan_belt_grows() -> void:
	var sim := MatchSim.new({"seed": 1, "p1": "plain", "p2": "plain", "boons": [["frost_rim", "titan_belt"], []],
		"starts": [Vector2(400, 500), Vector2(600, 500)], "angles": [0, 1800]})
	check_near(sim.balls[0].radius, sim.balls[1].radius * 1.25, 0.01, "Titan Belt: 25% bigger")
	var flung := false
	while not sim.finished and sim.time() < 1.0:
		sim.step()
		if sim.events.any(func(e): return e.type == "damage" and e.target == 1 and e.kind == "contact"):
			check(sim.balls[1].slow_amount > 0.0 and sim.tick < sim.balls[1].slow_until, "chilled")
			flung = sim.balls[1].boost_ticks > 0
			break
	check(flung, "flung")


func test_second_wind_and_fever_fire_once() -> void:
	var sim := MatchSim.new({"seed": 3, "p1": "plain", "p2": "plain", "boons": [["second_wind", "fever"], []], "powers": [0.7, 1.4]})
	var winds := 0
	var fevers := 0
	while not sim.finished:
		sim.step()
		for e in sim.events:
			if e.type == "boon" and e.ball == 0:
				winds += int(e.id == "second_wind")
				fevers += int(e.id == "fever")
	check_eq(winds, 1, "Second Wind once")
	check(fevers <= 1, "Fever at most once")


func test_every_boon_has_text_and_a_badge() -> void:
	var src: String = FileAccess.get_file_as_string("res://game/ui/boon_icon.gd")
	for id in Boons.ALL + Boons.LEGENDARY:
		for r in ["common", "rare", "epic"] if not id in Boons.LEGENDARY else ["legendary"]:
			var def := Boons.get_def(Boons.with_rarity(id, r))
			check(not "{" in def.text and def.text.length() < 70, "%s %s text: %s" % [id, r, def.text])
		check('"%s"' % Boons.get_def(id).icon in src, "%s has a drawn badge" % id)
	check(Boons.get_def("ember_rim:epic").b_burn > Boons.get_def("ember_rim").b_burn, "mechanic boons scale with rarity")
	check(Boons.get_def("ember_rim:epic").text != Boons.get_def("ember_rim").text, "and their text shows it")


# --- The scene ---------------------------------------------------------------

## Plays a whole run through the scene's own flow, headless, skipping fights
## and taking the first option everywhere.
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
	var steps := 0
	var seen := {}
	while scene.state != scene.State.OVER and steps < 200:
		steps += 1
		seen[scene.state] = true
		match scene.state:
			scene.State.MAP:
				scene._go_node(BounceRun.next_nodes(scene.setup, scene.run)[0])
			scene.State.FLOOR:
				scene._choose_fighter(BounceRun.living(scene.run)[0])
				scene._launch()
				scene._skip()
				scene._process(0.016)
				check_eq(scene.state, scene.State.RESULT, "result after a fight")
				scene._after_result()
			scene.State.BOON:
				scene._take_boon(scene.run.offer[0])
			scene.State.EVENT:
				if BounceRun.phase(scene.setup, scene.run) == "event":
					var ev := BounceRun.event(scene.setup, scene.run)
					var c: Dictionary = ev.choices[-1] # Leave / the safe option.
					scene._apply(func(): BounceRun.choose(scene.setup, scene.run, c.id), c.name)
				else:
					scene._show_next()
			scene.State.SHOP:
				BounceRun.leave(scene.setup, scene.run)
				scene._show_next()
			scene.State.REST:
				scene._rest("pass")
				if scene.state == scene.State.EVENT:
					scene._show_next()
	check(scene.run.over, "the run ended (state %d, phase %s, steps %d)" % [scene.state, BounceRun.phase(scene.setup, scene.run), steps])
	check(seen.has(scene.State.MAP), "the map showed")
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
	scene._go_node(BounceRun.next_nodes(scene.setup, scene.run)[0])
	scene._choose_fighter(0)
	scene._launch()
	var again = load("res://game/bounce_run.tscn").instantiate()
	again.save_path = path
	runner.root.add_child(again)
	again._ready()
	check_eq(again.run.log.filter(func(e): return e.t == "fight").size(), 1, "the abandoned fight was recorded")
	check(not again.run.has("launched"), "and cleared")
	scene.queue_free()
	again.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
