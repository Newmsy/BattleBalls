## Bounce Run players for tools and tests. The random one picks a random path,
## fighter, aim, boon, event choice and shop buy at every step; the greedy one
## (greedy_start/greedy_play) plays the obvious good moves. Both play the same
## run the same way for the same rng seed.
extends RefCounted

const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Power := preload("res://sim/power.gd")
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
	var relic: String = setup.relic_offer[rng.range_int(0, setup.relic_offer.size() - 1)]
	return BounceRun.new_run(setup, picks, start_boons, relic)


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


# --- Greedy play ---------------------------------------------------------------
# A "thinking" player for difficulty checks (boon_balance.gd --runs --greedy):
# drafts the rarest critters, takes the rarest boons, paths through chests,
# Charge Pads and shops, trades up, and spends Buttons. It still aims at
# random, so it's an easy bar a real player clears.

## Node types a greedy path heads for first.
const PATH_ORDER := ["chest", "rest", "shop", "mystery", "fight", "elite", "boss"]
## Event choices a greedy player takes when it can, best first.
const GOOD_CHOICES := ["hatch", "swap", "reach_in", "pocket_relic", "dash", "open_chest", "scoop_honey", "kick", "pay", "chip",
	"reforge", "temper", "wish_star", "look", "smash", "crank", "fight", "gumball", "spar", "offer_boon", "drink",
	"plug_in", "follow_light", "read", "swap_boon", "shake_globe"]


static func critter_rank(critter: String) -> int:
	return Power.RARITIES.find(str(BallDefs.DEFS[critter].get("rarity", "common")))


static func boon_rank(id: String) -> int:
	return -1 if Boons.is_glitch(id) else Boons.RARITIES.find(Boons.rarity_of(id))


static func greedy_start(setup: Dictionary, rng) -> Dictionary:
	var order: Array = range(BounceRun.DRAFT)
	order.sort_custom(func(a, b): return critter_rank(setup.cards[a].critter) > critter_rank(setup.cards[b].critter))
	var start_boons: Array = setup.start_offer.slice(0, BounceRun.START_BOONS)
	return BounceRun.new_run(setup, order.slice(0, BounceRun.PICKS), start_boons, setup.relic_offer[0])


static func greedy_step(setup: Dictionary, run: Dictionary, rng) -> Dictionary:
	match BounceRun.phase(setup, run):
		"boon":
			BounceRun.take_boon(run, _best(run.offer, boon_rank))
		"map":
			var next: Array = BounceRun.next_nodes(setup, run)
			next.sort_custom(func(a, b): return PATH_ORDER.find(BounceRun.node(setup, a).type) < PATH_ORDER.find(BounceRun.node(setup, b).type))
			BounceRun.go(setup, run, next[0])
		"fight":
			var row: int = BounceRun.node(setup, run.at).row
			var slot: int = _best(BounceRun.living(run), func(s): return critter_rank(run.critters[s]))
			var aim: int = -450 + rng.range_int(-400, 400)
			var result := MatchSim.new(BounceRun.fight_config(setup, run, slot, aim)).run_to_end()
			BounceRun.record(setup, run, slot, aim, result.winner, result.ticks, result.hp[1])
			return {"winner": result.winner, "ticks": result.ticks, "row": row}
		"shop":
			if BounceRun.can_buy(setup, run, "revive"):
				BounceRun.buy(setup, run, "revive", BounceRun.dead(run)[0])
				return {}
			if BounceRun.can_buy(setup, run, "clean"):
				BounceRun.buy(setup, run, "clean")
				return {}
			var best := ""
			for i in 3:
				var item := "boon:%d" % i
				if BounceRun.can_buy(setup, run, item) and (best == "" or BounceRun.price(setup, run, item) > BounceRun.price(setup, run, best)):
					best = item
			if best == "":
				BounceRun.leave(setup, run)
			else:
				BounceRun.buy(setup, run, best)
		"rest":
			for c in ["revive", "clean", "polish", "pass"]:
				if BounceRun.can_rest(run, c):
					var arg = null
					if c == "polish":
						arg = _best(BounceRun.polishable(run), boon_rank)
					BounceRun.rest(setup, run, c, arg)
					break
		"event":
			var ev := BounceRun.event(setup, run)
			var ids: Array = ev.choices.map(func(c): return c.id)
			var pick: Dictionary = {}
			for want in GOOD_CHOICES:
				if want in ids and BounceRun.can_choose(setup, run, want):
					pick = ev.choices[ids.find(want)]
					break
			if pick.is_empty():
				pick = ev.choices.filter(func(c): return BounceRun.can_choose(setup, run, c.id))[-1]
			var args := BounceRun.choice_args(setup, run, pick)
			var arg = null
			if not args.is_empty():
				match pick.get("arg", ""):
					"trade":
						var offer := BounceRun.trade_offer(setup, run)
						arg = _best(args, func(a): return critter_rank(offer[a[1]]) - critter_rank(run.critters[a[0]]))
					"living":
						# Robot: plug in the weakest; spar: train the strongest.
						arg = _best(args, func(s): return critter_rank(run.critters[s]) * (-1 if pick.id == "plug_in" else 1))
					"boon", "reroll":
						arg = _best(args, func(id): return -boon_rank(id))
					_:
						arg = _best(args, boon_rank) if pick.get("arg", "") == "polish" else args[0]
			BounceRun.choose(setup, run, pick.id, arg)
	return {}


static func greedy_play(setup: Dictionary, run: Dictionary, rng) -> Dictionary:
	var fights: Array = []
	var guard := 0
	while not run.over and guard < 400:
		var r := greedy_step(setup, run, rng)
		if not r.is_empty():
			fights.append(r)
		guard += 1
	return {"fights": fights}


static func _best(items: Array, rank: Callable):
	var best = items[0]
	for it in items:
		if rank.call(it) > rank.call(best):
			best = it
	return best
