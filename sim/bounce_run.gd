## Bounce Run: a daily roguelite run built from the UTC day number alone, so
## every device gets the same draft, foes and boon offers without a server.
##
## Draft 3 of DRAFT critters, then 3 of START_OFFER starting boons for the
## whole trio, then climb FLOORS fights. Before each fight you see the foe and
## send one of your living critters. A win earns another boon (pick 1 of 3); a
## loss knocks that critter out of the run, and you retry the floor with
## another. The run ends when the top floor falls or your trio is out.
##
## A floor's foe carries exactly as many boons as you can have there (three
## to start plus one per floor cleared), drawn from the same pool, and its
## power follows FOE_POWER: well under yours on the first floors, over it at
## the top. Everyone climbs the same tower, so the board stays fair. Your
## edge is picking boons that suit your trio, who you send, and your aim.
##
## Your trio grows as it climbs: it fights at tier_at(floor), one tier up
## every 2 floors (T5 on the last two). Every boon rolls a rarity
## (sim/boons.gd): Rare and Epic boons have bigger numbers, and a Legendary
## is a boon with an effect of its own.
##
## A run is plain data (see new_run) so it can be saved, resumed, posted to
## the leaderboard and re-checked later by replaying its log.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const MatchSim := preload("res://sim/match_sim.gd")

## Bump when a change alters how a run plays out (boons, generation, fight
## rules), so the server only compares runs played on the same rules.
const RULES_VERSION := 3
const EPOCH_UNIX := 1791936000 ## 2026-10-14 00:00 UTC: Bounce Run #1.
const DAY := 86400
const FLOORS := 10
const DRAFT := 6 ## Critter cards in the draft.
const PICKS := 3
const START_OFFER := 6 ## General boons offered at the start.
const START_BOONS := 3 ## Of those, how many the trio starts with.
const OFFER := 3
## Foe names per floor, for flavour. The top floor is the day's champion.
const FOE_TITLES := ["Rookie", "Rascal", "Scrapper", "Bruiser", "Hotshot", "Veteran", "Ace", "Elite", "Legend", "Champion"]
## Foe power per floor (sim/power.gd: 1.0 is your trio's). The first floors
## are a warm-up; most runs end around floor 7, and a full clear is rare
## (tools/boon_balance.gd --runs checks the curve).
const FOE_POWER := [0.55, 0.65, 0.75, 0.85, 0.95, 1.05, 1.15, 1.25, 1.35, 1.45]
const FLOORS_PER_TIER := 2


## The tier your trio fights at on floor index `floor_i` (0 = the first floor).
static func tier_at(floor_i: int) -> int:
	return mini(1 + floor_i / FLOORS_PER_TIER, 5)


## 1 on 2026-10-14 (UTC), counting up one per day.
static func day_number(unix_time: float) -> int:
	return maxi(1, floori((unix_time - EPOCH_UNIX) / DAY) + 1)


## The day's run setup: the critter draft, the starting boon offer and the
## foe on every floor.
static func generate(day: int) -> Dictionary:
	var rng := Rng.new(day * 2654435 + 977)
	var cards: Array = []
	var critters := _shuffled(BallDefs.PLAYABLE, rng)
	for i in DRAFT:
		# Every playable critter shows up before any repeats.
		cards.append({"critter": critters[i % critters.size()]})
	var start_offer: Array = _shuffled(Boons.GENERAL, rng).slice(0, START_OFFER)
	var floors: Array = []
	for f in FLOORS:
		var critter: String = BallDefs.PLAYABLE[rng.range_int(0, BallDefs.PLAYABLE.size() - 1)]
		var boons: Array = []
		for k in START_BOONS + f:
			boons.append(_pick_boon(rng, critter, boons))
		floors.append({"critter": critter, "boons": boons, "seed": rng.range_int(1, 999999), "title": FOE_TITLES[f]})
	return {"day": day, "cards": cards, "start_offer": start_offer, "floors": floors}


## A fresh run for `setup` with the drafted card indices and the starting
## boons picked from setup.start_offer.
static func new_run(setup: Dictionary, picks: Array, start: Array) -> Dictionary:
	assert(picks.size() == PICKS and start.size() == START_BOONS)
	assert(start.all(func(id): return id in setup.start_offer))
	return {"day": setup.day, "rules": RULES_VERSION, "picks": picks.duplicate(), "start": start.duplicate(),
		"boons": start.duplicate(), "floor": 0, "out": [false, false, false], "ticks": 0, "log": [], "offer": [], "over": false}


## The pick slot's card.
static func card(setup: Dictionary, run: Dictionary, slot: int) -> Dictionary:
	return setup.cards[run.picks[slot]]


## Boons a pick slot fights with: the run's boons, shared by the whole trio
## (ability boons only work on critters with that ability).
static func fighter_boons(_setup: Dictionary, run: Dictionary, _slot: int) -> Array:
	return run.boons


## MatchSim config for sending `slot` at the current floor with `aim`.
static func fight_config(setup: Dictionary, run: Dictionary, slot: int, aim) -> Dictionary:
	var foe: Dictionary = setup.floors[run.floor]
	return {"seed": foe.seed, "p1": card(setup, run, slot).critter, "p2": foe.critter,
		"angles": [aim, null], "boons": [fighter_boons(setup, run, slot), foe.boons], "powers": [1.0, FOE_POWER[run.floor]],
		"tiers": [tier_at(run.floor), 1]}


## Records a fight. A win climbs a floor and, unless the run is won, deals a
## boon offer to pick from; anything else knocks the fighter out.
static func record(setup: Dictionary, run: Dictionary, slot: int, aim: int, winner: int, ticks: int) -> void:
	assert(not run.over and run.offer.is_empty() and not run.out[slot])
	run.log.append({"floor": run.floor, "slot": slot, "aim": aim, "won": winner == 0, "ticks": ticks})
	run.ticks += ticks
	if winner == 0:
		run.floor += 1
		if run.floor >= FLOORS:
			run.over = true
		else:
			run.offer = offer(setup, run)
	else:
		run.out[slot] = true
		if not run.out.has(false):
			run.over = true


## Takes boon `id` from the current offer.
static func take_boon(run: Dictionary, id: String) -> void:
	assert(id in run.offer)
	run.boons.append(id)
	run.offer = []


## OFFER boons for the floor just cleared, seeded by day and floor. Skips
## boons the trio already runs (at any rarity) and ability boons none of the
## trio can use. Each card rolls a rarity; a Legendary roll swaps the card for
## a Legendary boon the trio doesn't have yet.
static func offer(setup: Dictionary, run: Dictionary) -> Array:
	var abilities: Array = []
	for slot in PICKS:
		abilities.append(BallDefs.get_def(card(setup, run, slot).critter).ability)
	var held: Array = run.boons.map(func(id): return Boons.base_of(id))
	var pool: Array = []
	for id in Boons.ALL:
		if id in held:
			continue
		if abilities.any(func(a): return Boons.applies_to(id, a)):
			pool.append(id)
	var rng := Rng.new(setup.day * 7919 + run.floor * 104729 + 31)
	var out: Array = []
	for id in _shuffled(pool, rng).slice(0, OFFER):
		out.append(_with_roll(rng, id, held + out.map(func(o): return Boons.base_of(o))))
	return out


static func living(run: Dictionary) -> Array:
	var out: Array = []
	for slot in PICKS:
		if not run.out[slot]:
			out.append(slot)
	return out


## Floors cleared, critters left, and total fight time: the leaderboard order.
static func score(run: Dictionary) -> Dictionary:
	return {"floors": run.floor, "lives": living(run).size(), "ticks": run.ticks}


## True when score `a` ranks above `b`.
static func better(a: Dictionary, b: Dictionary) -> bool:
	if a.floors != b.floors:
		return a.floors > b.floors
	if a.lives != b.lives:
		return a.lives > b.lives
	return a.ticks < b.ticks


## Replays a run's log from its picks and returns the rebuilt run, so a
## posted score can be checked against the sim. Boon picks come from `run`.
static func replay(setup: Dictionary, run: Dictionary) -> Dictionary:
	var check := new_run(setup, run.picks, run.start)
	var boon_i := START_BOONS
	for entry in run.log:
		var sim := MatchSim.new(fight_config(setup, check, entry.slot, entry.aim))
		var result := sim.run_to_end()
		record(setup, check, entry.slot, entry.aim, result.winner, result.ticks)
		if not check.offer.is_empty() and boon_i < run.boons.size():
			take_boon(check, run.boons[boon_i])
			boon_i += 1
	return check


static func _pick_boon(rng, critter: String, avoid: Array) -> String:
	var ability: String = BallDefs.get_def(critter).ability
	var held: Array = avoid.map(func(id): return Boons.base_of(id))
	var pool := Boons.ALL.filter(func(id): return Boons.applies_to(id, ability) and not id in held)
	if pool.is_empty():
		pool = Boons.ALL.filter(func(id): return Boons.applies_to(id, ability))
	return _with_roll(rng, pool[rng.range_int(0, pool.size() - 1)], held)


## `base` at a seeded rarity. A Legendary roll gives a Legendary boon not in
## `held` (base ids), or an Epic when all of them are taken.
static func _with_roll(rng, base: String, held: Array) -> String:
	var rarity := Boons.roll_rarity(rng)
	if rarity == "legendary":
		var free: Array = Boons.LEGENDARY.filter(func(id): return not id in held)
		if not free.is_empty():
			return free[rng.range_int(0, free.size() - 1)]
		rarity = "epic"
	return Boons.with_rarity(base, rarity)


static func _shuffled(items: Array, rng) -> Array:
	var out := items.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j: int = rng.range_int(0, i)
		var t = out[i]
		out[i] = out[j]
		out[j] = t
	return out
