## A random-choice Bounce Run player for tools and tests: picks a random path,
## fighter, aim, boon, event choice and shop buy at every step. Plays the same
## run the same way for the same rng seed.
extends RefCounted

const BounceRun := preload("res://sim/bounce_run.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Rng := preload("res://sim/rng.gd")


## A fresh run on `setup` with random draft and starting boons.
static func start(setup: Dictionary, rng) -> Dictionary:
	var picks: Array = []
	while picks.size() < BounceRun.PICKS:
		var c: int = rng.range_int(0, BounceRun.DRAFT - 1)
		if not c in picks:
			picks.append(c)
	var start_boons: Array = []
	while start_boons.size() < BounceRun.START_BOONS:
		var b: String = setup.start_offer[rng.range_int(0, setup.start_offer.size() - 1)]
		if not b in start_boons:
			start_boons.append(b)
	return BounceRun.new_run(setup, picks, start_boons)


## Plays one step. Returns the fight result ({winner, ticks, row}) when the
## step was a fight, else {}.
static func step(setup: Dictionary, run: Dictionary, rng) -> Dictionary:
	match BounceRun.phase(setup, run):
		"boon":
			BounceRun.take_boon(run, _any(run.offer, rng))
		"map":
			BounceRun.go(setup, run, _any(BounceRun.next_nodes(setup, run), rng))
		"fight":
			var row: int = BounceRun.node(setup, run.at).row
			var slot: int = _any(BounceRun.living(run), rng)
			var aim: int = -450 + rng.range_int(-400, 400)
			var result := MatchSim.new(BounceRun.fight_config(setup, run, slot, aim)).run_to_end()
			BounceRun.record(setup, run, slot, aim, result.winner, result.ticks, result.hp[1])
			return {"winner": result.winner, "ticks": result.ticks, "row": row}
		"shop":
			var items: Array = ["boon:0", "boon:1", "boon:2", "revive", "clean"].filter(func(i): return BounceRun.can_buy(setup, run, i))
			if items.is_empty() or rng.range_int(0, 2) == 0:
				BounceRun.leave(setup, run)
			else:
				var item: String = _any(items, rng)
				var arg = null
				if item == "revive":
					arg = _any(BounceRun.dead(run), rng)
				BounceRun.buy(setup, run, item, arg)
		"rest":
			var options: Array = ["revive", "polish", "clean"].filter(func(c): return BounceRun.can_rest(run, c))
			if options.is_empty():
				options = ["pass"]
			BounceRun.rest(setup, run, "revive" if "revive" in options else _any(options, rng))
		"event":
			var ev := BounceRun.event(setup, run)
			var ok: Array = ev.choices.filter(func(c): return BounceRun.can_choose(setup, run, c.id))
			var c: Dictionary = _any(ok, rng)
			var args := BounceRun.choice_args(setup, run, c)
			BounceRun.choose(setup, run, c.id, _any(args, rng) if not args.is_empty() else null)
	return {}


## Plays a whole run; returns {"fights": [results...]}.
static func play(setup: Dictionary, run: Dictionary, rng) -> Dictionary:
	var fights: Array = []
	var guard := 0
	while not run.over and guard < 400:
		var r := step(setup, run, rng)
		if not r.is_empty():
			fights.append(r)
		guard += 1
	return {"fights": fights}


static func _any(items: Array, rng):
	return items[rng.range_int(0, items.size() - 1)]
