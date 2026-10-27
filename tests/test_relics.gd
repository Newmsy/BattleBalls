extends "res://tests/test_case.gd"

const Relics := preload("res://sim/relics.gd")
const Abilities := preload("res://sim/abilities.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const BounceBot := preload("res://tools/bounce_bot.gd")
const Rng := preload("res://sim/rng.gd")


func test_every_relic_is_complete() -> void:
	check_eq(Relics.IDS.size(), 30, "30 relics")
	check_eq(Relics.IDS.size(), Relics.DEFS.size(), "IDS lists every relic once")
	for id in Relics.IDS:
		var r: Dictionary = Relics.DEFS[id]
		check(CritterDb.ids().has(id), "%s is a critter" % id)
		check(r.text.length() > 10 and not "glow" in r.text.to_lower(), "%s: card text, never \"glow\"" % id)
		check(ResourceLoader.exists("res://game/bounce_run/art/relics/relic_%s.png" % id), "%s: painted icon" % id)
		var params: Dictionary = r.get("set", {}).merged(r.get("bump", {})).merged(r.get("of_hp", {}))
		for e in r.entries:
			check(Abilities.TRIGGERS.has(e.on) and Abilities.EFFECTS.has(e.do), "%s: known entry %s" % [id, e])
			if e.on == "every" and e.secs is String:
				check(params.has(e.secs), "%s: has its timer %s" % [id, e.secs])
			var effects: Array = [e.do] + ([params.relic_do] if e.do == "relic_nth" else [])
			for fx in effects:
				for key in Abilities.EFFECTS[fx]:
					check(params.has(key), "%s: %s needs %s" % [id, fx, key])


func test_no_relics_changes_nothing() -> void:
	var a := MatchSim.new({"seed": 9, "p1": "vampire", "p2": "laser"}).run_to_end()
	var b := MatchSim.new({"seed": 9, "p1": "vampire", "p2": "laser", "relics": [[], []]}).run_to_end()
	check_eq(b.hash, a.hash, "empty relic lists")


## Every relic changes the fight, the same way every time (long fights, so
## even the slow relics, every 12s or every 5th bump, go off).
func test_every_relic_does_something() -> void:
	var plain: Array = [31, 32, 33].map(func(seed): return MatchSim.new({"seed": seed, "p1": "bubbles", "p2": "crumb"}).run_to_end().hash)
	for id in Relics.IDS:
		var changed := false
		for k in 3:
			var cfg := {"seed": 31 + k, "p1": "bubbles", "p2": "crumb", "relics": [[id], []]}
			var a := MatchSim.new(cfg).run_to_end()
			changed = changed or a.hash != plain[k]
			if k == 0:
				check_eq(MatchSim.new(cfg).run_to_end().hash, a.hash, "%s is deterministic" % id)
		check(changed, "%s changes the fight" % id)
	for holder in ["pip", "laser", "mirror", "splitter", "bomber"]:
		var all := MatchSim.new({"seed": 5, "p1": holder, "p2": "gravity", "relics": [Relics.IDS, []]}).run_to_end()
		check(all.ticks > 0, "%s fights with every relic at once" % holder)


## A relic's numbers stay out of the holder's own ability, and its damage
## follows the holder's bump.
func test_relic_numbers_stay_apart() -> void:
	var pip := BallDefs.get_def("pip")
	var with := Relics.apply_to_def(pip, ["clam"])
	check_eq(with.def.shot_damage, pip.shot_damage, "Pip's own peas are untouched")
	var rd: Dictionary = with.relic_defs.clam
	check_near(rd.shot_damage, Relics.DEFS.clam.bump.shot_damage * pip.contact_damage, 0.001, "pearls hit for a share of Pip's bump")
	check_eq(rd.shot_kind, "pearl", "and look like pearls")
	check(with.def.effects.size() == pip.effects.size() + 1 and with.def.effects[-1].relic == "clam", "one relic entry added")
	var sim := MatchSim.new({"seed": 2, "p1": "pip", "p2": "pinball", "relics": [["clam"], []]})
	sim.run_to_end()
	check(sim.balls[0].def.has("contact_damage") and not sim.balls[0].def.has("relic_id"), "the ball keeps its own def between relic entries")


func test_your_own_relic_powers_up_your_ability() -> void:
	var fin := BallDefs.get_def("fin")
	var with := Relics.apply_to_def(fin, ["fin"])
	check(with.relic_defs.is_empty() and with.def.effects.size() == fin.effects.size(), "no second copy")
	check_near(with.def.chomp_mult, 1.0 + (fin.chomp_mult - 1.0) * (1.0 + Relics.OWN_BOOST), 0.001, "a bigger bite")


func test_runs_pick_and_drop_relics() -> void:
	var setup := BounceRun.generate(7)
	check_eq(setup.relic_offer.size(), BounceRun.RELIC_OFFER, "three relics offered")
	var first: String = setup.relic_offer[0]
	var run := BounceRun.new_run(setup, [0, 1, 2], setup.start_offer.slice(0, BounceRun.START_BOONS), first)
	check_eq(run.relics, [first], "starts with the picked relic")
	# An elite always drops one.
	var elite: int = setup.nodes.keys().filter(func(id): return setup.nodes[id].type == "elite")[0]
	var r := run.duplicate(true)
	r.at = elite
	r.done = false
	check_eq(BounceRun.fight_config(setup, r, 0, 0).relics[0], [first], "the trio fights with its relics")
	BounceRun.record(setup, r, 0, 0, 0, 600)
	check(r.relics.size() == 2 and r.dropped == r.relics[1] and r.dropped != first, "an elite win drops a new relic")
	# So does the chest.
	var chest: int = setup.nodes.keys().filter(func(id): return setup.nodes[id].type == "chest")[0]
	var c := run.duplicate(true)
	c.at = -1
	for id in setup.nodes:
		if chest in setup.nodes[id].kids:
			c.at = id
	c.done = true
	BounceRun.go(setup, c, chest)
	check(c.relics.size() == 2 and not c.offer.is_empty(), "the chest drops a relic and a boon pick")


func test_relic_runs_replay() -> void:
	for i in 3:
		var rng := Rng.new(i * 131 + 9)
		var setup := BounceRun.generate(40 + i)
		var run := BounceBot.greedy_start(setup, rng)
		BounceBot.greedy_play(setup, run, rng)
		var again := BounceRun.replay(setup, run)
		check_eq(again.relics, run.relics, "replayed relics")
		check_eq(BounceRun.score(again), BounceRun.score(run), "replayed score")


## The fight view reads a relic's numbers from the relic's def: a ball's own
## def has no collapse_range for Relic of Void, and reading it there stopped
## the frame's drawing, so both critters vanished during each collapse.
func test_view_reads_relic_numbers() -> void:
	var sim := MatchSim.new({"seed": 3, "p1": "pip", "p2": "laser", "relics": [["blackhole", "jackpot", "bubbles", "supernova"], []]})
	var view = preload("res://game/arena_view.gd").new()
	var b = sim.balls[0]
	for key in ["collapse_range", "prize_coin_reach", "bubble_secs", "nova_radius"]:
		check(not b.def.has(key), "pip's own def has no %s" % key)
		check(view._ability_num(b, key) > 0.0, "the view finds the relic's %s" % key)
	check_eq(view._ability_num(sim.balls[1], "beam_life"), float(sim.balls[1].def.beam_life), "own numbers still come from the def")
	view.free()
