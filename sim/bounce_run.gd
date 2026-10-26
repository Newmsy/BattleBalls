## Bounce Run: a daily roguelite run built from the UTC day number alone, so
## every device gets the same draft, map, foes, events and shop stock without
## a server.
##
## Draft 3 of DRAFT critters, then 3 of START_OFFER starting boons for the
## whole trio and 1 of RELIC_OFFER relics (sim/relics.gd), then climb a FLOORS-tall branching map (Slay the Spire style).
## Each floor you step to one of the nodes linked above you:
##   fight / elite  a foe you see before you commit. Send one of your living
##                  critters; a win earns a boon (pick 1 of 3) and Buttons, a
##                  loss knocks that critter out and you retry with another.
##                  The foe keeps the damage it took (run.foe_hp). Elites are
##                  bigger, stronger, pay better and always drop a relic.
##   mystery        usually an event with choices (EVENTS), sometimes a fight
##                  or a shop. What it holds is fixed for the day.
##   shop           spend Buttons (run-only currency) on boons and services.
##   rest           a Charge Pad: revive, polish a boon, or clean Glitches.
##   chest          a treasure chest: a relic, and a free pick of
##                  Rare-or-better boons.
##   boss           the Champion on the top floor.
## Relics are never a choice once the run is on: a drop is a random one the
## trio doesn't hold (run.dropped names the newest for the screen).
## Glitches are bad boons (sim/boons.gd) that only ever come from a choice.
## The run ends when the Champion falls or your trio is out.
##
## Both sides grow as you climb: your trio and the foes fight at
## tier_at(floor), one tier up every FLOORS_PER_TIER floors (T5 on the last
## four), and foe power follows FOE_POWER.
##
## A run is plain data (see new_run) so it can be saved, resumed, posted to
## the leaderboard and re-checked later: every step is in run.log, and
## replay() rebuilds the run from it.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const Arenas := preload("res://sim/arenas.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Boons := preload("res://sim/boons.gd")
const Relics := preload("res://sim/relics.gd")
const Families := preload("res://sim/families.gd")
const MatchSim := preload("res://sim/match_sim.gd")

## Bump when a change alters how a run plays out (boons, generation, fight
## rules), so the server only compares runs played on the same rules.
const RULES_VERSION := 12
const EPOCH_UNIX := 1791936000 ## 2026-10-14 00:00 UTC: Bounce Run #1.
const DAY := 86400
const FLOORS := 20
const COLS := 7 ## Map lanes (Slay the Spire uses 7).
const PATHS := 6 ## Walks up the map that make its links.
const DRAFT := 6 ## Critter cards in the draft.
const PICKS := 3
const START_OFFER := 6 ## General boons offered at the start.
const START_BOONS := 3 ## Of those, how many the trio starts with.
const RELIC_OFFER := 3 ## Relics offered at the start; the trio takes one.
const OFFER := 3
const FLOORS_PER_TIER := 4
## Foe names by floor pair, for flavour.
const FOE_TITLES := ["Rookie", "Rascal", "Scrapper", "Bruiser", "Hotshot", "Veteran", "Ace", "Brawler", "Legend", "Champion"]
## Foe power per floor (sim/power.gd: 1.0 is your trio's). The first floors
## are a warm-up and the top is a wall (tools/boon_balance.gd --runs checks
## the curve). Foes carry no boons, so power alone makes the climb, about
## 12% steeper each floor, 16% from floor 14, and the Champion is a wall: a
## greedy player (tools/boon_balance.gd --runs --greedy) clears about 30% of
## runs, a random one about 3%, and a random run's median ends on floor 13.
const FOE_POWER := [0.55, 0.67, 0.81, 0.95, 1.11, 1.28, 1.46, 1.66, 1.86, 2.08,
	2.31, 2.55, 2.81, 3.22, 3.71, 4.25, 4.86, 5.55, 6.31, 8.74]
const DOWNSIDE_POWER := 0.15 ## A Haunted Mirror look, a Star Map wish (and a few other risky picks) make a foe this much stronger.
const ELITE_POWER := 1.12 ## On top of the floor's power.
const ELITE_SIZE := 1.28
const BOSS_SIZE := 1.32
## A hatched Lost Egg critter fights beside whoever you send: small, a tier
## down and weaker, so it helps without carrying.
const HATCH_POWER := 0.7
const HATCH_SIZE := 0.72

## Fixed rows (index = floor - 1): the first is all fights, the middle all
## chests, the one before the Champion all Charge Pads.
const CHEST_ROW := 9
const REST_ROW := 18
## Roll weights for the other rows.
const NODE_WEIGHTS := {"fight": 40, "mystery": 25, "elite": 12, "shop": 10, "rest": 10}
## What a mystery node holds, out of 100.
const MYSTERY := {"event": 75, "fight": 15, "shop": 10}

## Buttons: earned in the run, spent in its shops, gone when it ends.
const PAY := {"fight": 15, "elite": 30}
const PRICES := {"common": 25, "rare": 45, "epic": 80, "legendary": 120, "revive": 50, "clean": 30, "restock": 10}
## How likely each rarity is to be one of the tide pool trader's critters.
const TRADER_ODDS := {"common": 4, "uncommon": 8, "rare": 22, "epic": 36, "legendary": 30}

## Every event a mystery node can hold, with its choices (shown in order).
## `arg` says what the player picks for that choice: a living critter, a
## knocked-out one, a boon, a Glitch, or a trader critter.
const EVENTS := {
	"lost_egg": {"name": "Lost Egg", "family": "nature", "text": "A mossy egg wobbles in the grass. Something inside is tapping back.",
		"choices": [
			{"id": "hatch", "name": "Hatch it", "text": "A hatchling joins every fight beside yours."},
			{"id": "sell", "name": "Sell it", "buttons": 40},
			{"id": "leave", "name": "Leave it"}]},
	"tide_pool_trader": {"name": "Tide Pool Trader", "family": "sea", "text": "A hermit crab collects critters. It likes yours.",
		"choices": [
			{"id": "swap", "name": "Swap a critter", "text": "Trade a critter for one of these.", "arg": "trade"},
			{"id": "swap_boon", "name": "Swap a boon", "text": "Your newest boon becomes a random one a rarity higher."},
			{"id": "leave", "name": "Leave"}]},
	"vending_machine": {"name": "Glitchy Vending Machine", "family": "glitch", "text": "It hums. The screen flickers: INSERT BUTTON.",
		"choices": [
			{"id": "pay", "name": "Pay", "text": "A random Rare boon.", "cost": 25},
			{"id": "kick", "name": "Kick it", "text": "Either an Epic boon or a Glitch (Sticky Floor)."},
			{"id": "leave", "name": "Walk away"}]},
	"candy_fountain": {"name": "Candy Fountain", "family": "sweet", "text": "Pink fizz bubbles up out of the floor.",
		"choices": [
			{"id": "drink", "name": "Drink", "text": "Revive a knocked-out critter. Nobody out? Take Wall Snack instead.", "arg": "out_or_none"},
			{"id": "bottle", "name": "Bottle it", "buttons": 30}]},
	"frozen_vault": {"name": "Frozen Vault", "family": "frost", "text": "A boon shines inside a block of ice.",
		"choices": [
			{"id": "chip", "name": "Chip it free", "text": "Give up one of your boons for a random Epic one.", "arg": "boon"},
			{"id": "leave", "name": "Leave it"}]},
	"training_dummy": {"name": "Training Dummy", "family": "toybox", "text": "It squeaks when you bump it.",
		"choices": [
			{"id": "spar", "name": "Spar", "text": "Pick a critter: its next fight is one tier higher.", "arg": "living"},
			{"id": "scrap", "name": "Take it apart", "buttons": 20}]},
	"haunted_mirror": {"name": "Haunted Mirror", "family": "spooky", "text": "Your reflection grins back. It shouldn't.",
		"choices": [
			{"id": "look", "name": "Look closer", "text": "Polish a boon one rarity up, but your next foe is 15% stronger.", "arg": "polish"},
			{"id": "smash", "name": "Smash it", "text": "Clean a Glitch.", "arg": "glitch"},
			{"id": "leave", "name": "Back away"}]},
	"lava_bridge": {"name": "Lava Bridge", "family": "fire", "text": "A shortcut over the magma. Something shiny waits on the far side.",
		"choices": [
			{"id": "dash", "name": "Dash across", "text": "Pick an Epic boon, and take a Glitch (Singed)."},
			{"id": "long", "name": "Go the long way"}]},
	"star_map": {"name": "Star Map", "family": "cosmic", "text": "The constellations look a lot like a route.",
		"choices": [
			{"id": "read", "name": "Read it", "text": "See what every mystery node holds."},
			{"id": "wish", "name": "Make a wish", "text": "Boon picks offer 4 instead of 3, but the Champion is 15% stronger."}]},
	"wandering_rival": {"name": "Wandering Rival", "family": "glitch", "text": "A masked critter blocks the path. \"One round?\"",
		"choices": [
			{"id": "fight", "name": "Fight", "text": "Losing knocks nobody out. Win: an Epic boon pick and 20 Buttons. Lose: -20 Buttons."},
			{"id": "wave", "name": "Wave politely"}]},
	"sunken_wreck": {"name": "Sunken Wreck", "family": "sea", "text": "A chest glints in a sunken ship. Something big is snoring beside it.",
		"choices": [
			{"id": "open_chest", "name": "Open the chest", "text": "A random relic, but your next foe is 15% stronger."},
			{"id": "grab_coins", "name": "Grab some coins", "buttons": 25}]},
	"ember_forge": {"name": "Ember Forge", "family": "fire", "text": "The anvil is still red hot.",
		"choices": [
			{"id": "temper", "name": "Temper a boon", "text": "Polish a boon one rarity up.", "cost": 40, "arg": "polish"},
			{"id": "reforge", "name": "Into the fire", "text": "A boon becomes Epic, and take a Glitch (Singed).", "arg": "polish"},
			{"id": "leave", "name": "Leave"}]},
	"snow_globe": {"name": "Snow Globe", "family": "frost", "text": "A tiny critter waves from inside the snow.",
		"choices": [
			{"id": "shake_globe", "name": "Shake it", "text": "Swap a boon for a random one of the same rarity.", "arg": "reroll"},
			{"id": "smash_globe", "name": "Smash it", "text": "Take a Glitch (Chilled).", "buttons": 40},
			{"id": "leave", "name": "Leave it"}]},
	"gumball_machine": {"name": "Gumball Machine", "family": "sweet", "text": "One coin, one gumball.",
		"choices": [
			{"id": "gumball", "name": "Buy a gumball", "text": "A random boon of a random rarity.", "cost": 10},
			{"id": "rattle", "name": "Rattle it", "text": "Take a Glitch (Sticky Floor).", "buttons": 20},
			{"id": "leave", "name": "Walk away"}]},
	"jack_in_the_box": {"name": "Jack-in-the-Box", "family": "toybox", "text": "The crank turns by itself. Click. Click.",
		"choices": [
			{"id": "crank", "name": "Turn the crank", "text": "Either a Rare-or-better boon pick or a 15% stronger next foe."},
			{"id": "leave", "name": "Leave it"}]},
	"ghost_lantern": {"name": "Ghost Lantern", "family": "spooky", "text": "A lantern drifts over the graves. It wants something warm.",
		"choices": [
			{"id": "offer_boon", "name": "Feed it a boon", "text": "Give up a boon to bring a knocked-out critter back.", "arg": "boon"},
			{"id": "follow_light", "name": "Follow it", "text": "See what every mystery node holds."},
			{"id": "leave", "name": "Back away"}]},
	"glitch_rift": {"name": "Glitch Rift", "family": "glitch", "text": "The floor splits into static. Something gold floats inside.",
		"choices": [
			{"id": "reach_in", "name": "Reach in", "text": "A Legendary boon, and two Glitches (Rusty and Sticky Floor)."},
			{"id": "pocket_relic", "name": "Pocket the relic", "text": "A random relic, and a Glitch (Rusty)."},
			{"id": "leave", "name": "Step back"}]},
	"beehive": {"name": "Beehive", "family": "nature", "text": "Golden honey drips from a buzzing hive.",
		"choices": [
			{"id": "scoop_honey", "name": "Scoop the honey", "text": "A random Epic boon, but the bees make your next foe 15% stronger."},
			{"id": "leave", "name": "Tiptoe past"}]},
	"fallen_star": {"name": "Fallen Star", "family": "cosmic", "text": "A star lands with a fizz. It's still warm.",
		"choices": [
			{"id": "wish_star", "name": "Wish on it", "text": "Polish a boon one rarity up.", "arg": "polish"},
			{"id": "keep_star", "name": "Keep it", "buttons": 45}]},
	"scrap_robot": {"name": "Scrap Robot", "family": "tech", "text": "A robot in a scrap heap. Its eye blinks on.",
		"choices": [
			{"id": "plug_in", "name": "Plug a critter in", "text": "It swaps for a random Tech critter, Rare or better.", "arg": "living"},
			{"id": "strip", "name": "Strip it for parts", "buttons": 25}]},
}
const EVENT_IDS := ["lost_egg", "tide_pool_trader", "vending_machine", "candy_fountain", "frozen_vault",
	"training_dummy", "haunted_mirror", "lava_bridge", "star_map", "wandering_rival", "sunken_wreck", "ember_forge",
	"snow_globe", "gumball_machine", "jack_in_the_box", "ghost_lantern", "glitch_rift", "beehive", "fallen_star", "scrap_robot"]
## The Scrap Robot's critters.
const ROBOT_FAMILY := "tech"
const ROBOT_RARITIES := ["rare", "epic", "legendary"]


## The tier your trio fights at on floor index `floor_i` (0 = the first floor).
static func tier_at(floor_i: int) -> int:
	return mini(1 + floor_i / FLOORS_PER_TIER, 5)


## 1 on 2026-10-14 (UTC), counting up one per day.
static func day_number(unix_time: float) -> int:
	return maxi(1, floori((unix_time - EPOCH_UNIX) / DAY) + 1)


## The day's run setup: the critter draft, the starting boon offer and the
## map with everything on it. A practice run passes its own `run_seed` (saved
## in the run as run.seed) for a fresh map; 0 is the day's shared one.
static func generate(day: int, run_seed := 0) -> Dictionary:
	var rng := Rng.new(_base(day, run_seed) * 2654435 + 977)
	var cards: Array = []
	var critters := _shuffled(BallDefs.PLAYABLE, rng)
	for i in DRAFT:
		# Every playable critter shows up before any repeats.
		cards.append({"critter": critters[i % critters.size()]})
	var start_offer: Array = _shuffled(Boons.GENERAL, rng).slice(0, START_OFFER)
	var nodes := _map(rng)
	var relic_offer: Array = _shuffled(Relics.IDS, rng).slice(0, RELIC_OFFER)
	return {"day": day, "seed": run_seed, "cards": cards, "start_offer": start_offer, "relic_offer": relic_offer, "nodes": nodes}


## The map: nodes keyed by id (row * COLS + col; the Champion is the only
## node on the top row), each {id, row, col, type, kids, ...}. Each floor is
## 4-6 nodes whose edges drift a lane at a time; links between two floors
## never cross and join near lanes, so paths split and merge like Slay the
## Spire's, about 1.8 ways on from each node.
static func _map(rng) -> Dictionary:
	var nodes := {}
	var lo: int = rng.range_int(0, 1)
	var hi: int = rng.range_int(COLS - 2, COLS - 1)
	var below: Array = []
	for row in FLOORS - 1:
		if row > 0:
			lo = clampi(lo + rng.range_int(-1, 1), 0, 2)
			hi = clampi(hi + rng.range_int(-1, 1), COLS - 3, COLS - 1)
		var inner: Array = _shuffled(range(lo + 1, hi), rng)
		var lanes: Array = [lo, hi] + inner.slice(0, mini(inner.size(), rng.range_int(2, 4)))
		lanes.sort()
		var here: Array = lanes.map(func(c): return row * COLS + c)
		for i in here.size():
			nodes[here[i]] = {"id": here[i], "row": row, "col": lanes[i], "kids": []}
		if not below.is_empty():
			_link(nodes, below, here, rng)
		below = here
	var boss_id: int = (FLOORS - 1) * COLS
	nodes[boss_id] = {"id": boss_id, "row": FLOORS - 1, "col": -1, "kids": [], "type": "boss"}
	var ids: Array = nodes.keys()
	ids.sort()
	for id in ids:
		var n: Dictionary = nodes[id]
		n.kids.sort()
		if n.row == FLOORS - 2:
			n.kids = [boss_id]
	var events := _shuffled(EVENT_IDS, rng)
	var next_event := 0
	for id in ids:
		var n: Dictionary = nodes[id]
		if n.row == FLOORS - 1:
			pass
		elif n.row == 0:
			n.type = "fight"
		elif n.row == CHEST_ROW:
			n.type = "chest"
		elif n.row == REST_ROW:
			n.type = "rest"
		else:
			n.type = _roll_type(rng, n, _parents(nodes, id).map(func(q): return nodes[q].type))
		n.seed = rng.range_int(1, 999999)
		if n.type == "mystery":
			n.holds = _roll(rng, MYSTERY)
			if n.holds == "event":
				n.event = events[next_event % events.size()]
				next_event += 1
				if next_event % events.size() == 0:
					events = _shuffled(EVENT_IDS, rng)
		if n.type in ["fight", "elite", "boss"] or n.get("holds", "") == "fight" or n.get("event", "") == "wandering_rival":
			n.foe = _foe(rng, n)
	return nodes


## Links floor `a` to the floor above, `b` (both sorted by lane), as a
## staircase: from the left ends to the right ends, each step moving the
## pointer on whichever side keeps the next link shortest. Links never cross,
## and every node gets a way in and a way on.
static func _link(nodes: Dictionary, a: Array, b: Array, rng) -> void:
	var i := 0
	var j := 0
	nodes[a[0]].kids.append(b[0])
	while i < a.size() - 1 or j < b.size() - 1:
		var steps: Array = [] # [di, dj, length]
		if i < a.size() - 1:
			steps.append([1, 0, absi(nodes[a[i + 1]].col - nodes[b[j]].col)])
		if j < b.size() - 1:
			steps.append([0, 1, absi(nodes[a[i]].col - nodes[b[j + 1]].col)])
		var best: Array = steps[0]
		for st in steps:
			if st[2] < best[2] or st[2] == best[2] and rng.range_int(0, 1) == 0:
				best = st
		i += best[0]
		j += best[1]
		if not b[j] in nodes[a[i]].kids:
			nodes[a[i]].kids.append(b[j])


static func _roll_type(rng, n: Dictionary, parent_types: Array) -> String:
	var weights := {}
	for t in NODE_WEIGHTS:
		if t == "elite" and n.row < 4 or t == "shop" and n.row < 3 or t == "rest" and (n.row < 5 or n.row == REST_ROW - 1):
			continue
		if t != "fight" and t != "mystery" and t in parent_types:
			continue # No shop after a shop, elite after an elite, ...
		if n.row == CHEST_ROW - 1 and t == "rest":
			continue
		weights[t] = NODE_WEIGHTS[t]
	return _roll(rng, weights)


static func _foe(rng, n: Dictionary) -> Dictionary:
	var row: int = n.row
	var kind: String = n.type if n.type in ["elite", "boss"] else "fight"
	var critter: String = BallDefs.PLAYABLE[rng.range_int(0, BallDefs.PLAYABLE.size() - 1)]
	# Foes never get boons: boons are yours. Floors get harder through power.
	var foe := {"critter": critter, "boons": [], "seed": rng.range_int(1, 999999), "power": FOE_POWER[row], "size": 1.0,
		"title": FOE_TITLES[mini(row / 2, FOE_TITLES.size() - 2)], "kind": kind}
	if kind == "elite":
		foe.power *= ELITE_POWER
		foe.size = ELITE_SIZE
		foe.title = "Elite " + foe.title
	elif kind == "boss":
		foe.size = BOSS_SIZE
		foe.title = "Champion"
	if n.get("event", "") == "wandering_rival":
		foe.title = "Masked Rival"
		foe.kind = "rival"
	return foe


## Node ids linked into `id` from the row below.
static func _parents(nodes: Dictionary, id: int) -> Array:
	var out: Array = []
	for q in nodes:
		if id in nodes[q].kids:
			out.append(q)
	return out


## A fresh run for `setup` with the drafted card indices, the starting boons
## picked from setup.start_offer and the relic from setup.relic_offer ("" for
## none).
static func new_run(setup: Dictionary, picks: Array, start: Array, relic := "") -> Dictionary:
	assert(picks.size() == PICKS and start.size() == START_BOONS)
	assert(start.all(func(id): return id in setup.start_offer))
	assert(relic == "" or relic in setup.get("relic_offer", []))
	return {"day": setup.day, "seed": setup.get("seed", 0), "rules": RULES_VERSION, "picks": picks.duplicate(), "start": start.duplicate(),
		"start_relic": relic, "relics": [] if relic == "" else [relic], "dropped": "",
		"critters": picks.map(func(i): return setup.cards[i].critter), "boons": start.duplicate(),
		"floor": 0, "at": -1, "done": true, "out": [false, false, false], "foe_hp": null, "ticks": 0, "fights": 0,
		"buttons": 0, "hatchling": "", "spar": -1, "foe_boost": 0.0, "wish": false, "revealed": false,
		"rival": false, "shop": {}, "log": [], "offer": [], "over": false}


## The pick slot's card (after any trades).
static func card(_setup: Dictionary, run: Dictionary, slot: int) -> Dictionary:
	return {"critter": run.critters[slot]}


static func node(setup: Dictionary, id: int) -> Dictionary:
	return setup.nodes.get(id, {})


## What the player is doing now: "boon" (a pick is waiting), "map" (pick the
## next node), "fight", "event", "shop", "rest", or "over".
static func phase(setup: Dictionary, run: Dictionary) -> String:
	if run.over:
		return "over"
	if not run.offer.is_empty():
		return "boon"
	if run.done or run.at < 0:
		return "map"
	var kind := kind_of(setup, run.at)
	if kind == "event" and run.rival:
		return "fight"
	return "fight" if kind in ["fight", "elite", "boss"] else kind


## A node's type, with a mystery node's contents filled in.
static func kind_of(setup: Dictionary, id: int) -> String:
	var n := node(setup, id)
	return n.get("holds", n.type) if n.type == "mystery" else n.type


## Node ids you can step to now.
static func next_nodes(setup: Dictionary, run: Dictionary) -> Array:
	if run.over or not run.done or not run.offer.is_empty():
		return []
	if run.at < 0:
		return setup.nodes.keys().filter(func(id): return setup.nodes[id].row == 0)
	var out: Array = node(setup, run.at).kids.duplicate()
	out.sort()
	return out


## Steps onto node `id`. A chest deals its boon pick straight away.
static func go(setup: Dictionary, run: Dictionary, id: int) -> void:
	assert(id in next_nodes(setup, run))
	run.log.append({"t": "go", "n": id})
	run.at = id
	run.done = false
	run.foe_hp = null
	var kind := kind_of(setup, id)
	if kind == "chest":
		drop_relic(setup, run)
		run.offer = offer(setup, run, "rare")
		_clear(setup, run)
	elif kind == "shop":
		run.shop = {"stock": _shop_stock(setup, run, 0), "sold": [], "restocked": false}


## The foe you face now, or {} off a fight.
static func foe(setup: Dictionary, run: Dictionary) -> Dictionary:
	if phase(setup, run) != "fight":
		return {}
	var f: Dictionary = node(setup, run.at).foe.duplicate()
	f.power *= 1.0 + float(run.foe_boost)
	if f.kind == "boss" and run.wish:
		f.power *= 1.0 + DOWNSIDE_POWER
	return f


## Boons a pick slot fights with: the run's boons, shared by the whole trio
## (ability boons only work on critters with that ability).
static func fighter_boons(_setup: Dictionary, run: Dictionary, _slot: int) -> Array:
	return run.boons


## MatchSim config for sending `slot` at the current node with `aim`. Every
## fight is on its own map, picked from the foe's seed and how many fights
## the run has had (so a retry is somewhere new and a replay finds the same).
## A hatched egg critter fights as p3 on your side (a 2v1).
static func fight_config(setup: Dictionary, run: Dictionary, slot: int, aim) -> Dictionary:
	var f := foe(setup, run)
	var row: int = node(setup, run.at).row
	var tier := tier_at(row)
	var cfg := {"seed": f.seed, "arena": Arenas.pick(f.seed * 16 + run.fights), "p1": card(setup, run, slot).critter, "p2": f.critter,
		"angles": [aim, null], "boons": [fighter_boons(setup, run, slot), f.boons], "relics": [run.get("relics", []), []], "powers": [1.0, f.power],
		"tiers": [mini(tier + (1 if run.spar == slot else 0), 5), tier], "sizes": [1.0, f.size], "hp": [null, run.get("foe_hp")], "tie_to": 0}
	if run.hatchling != "":
		cfg.p3 = run.hatchling
		cfg.p4 = null
		cfg.angles.append(null)
		cfg.boons.append([])
		cfg.relics.append([])
		cfg.powers.append(HATCH_POWER)
		cfg.tiers.append(maxi(1, tier - 1))
		cfg.sizes.append(HATCH_SIZE)
		cfg.hp.append(null)
	return cfg


## Records a fight. A win clears the node: Buttons and a boon pick (an Epic
## pick for beating the rival), or the run is won at the Champion. A loss
## knocks the fighter out and leaves the foe on `foe_hp` for your next send;
## losing to the rival only costs Buttons.
static func record(setup: Dictionary, run: Dictionary, slot: int, aim: int, winner: int, ticks: int, foe_hp := 0.0) -> void:
	assert(phase(setup, run) == "fight" and not run.out[slot])
	var f := foe(setup, run)
	run.log.append({"t": "fight", "slot": slot, "aim": aim, "won": winner == 0, "ticks": ticks})
	run.ticks += ticks
	run.fights += 1
	if run.spar == slot:
		run.spar = -1
	if f.kind == "rival":
		run.rival = false
		run.foe_boost = 0.0 # A Haunted Mirror boost spends itself on the rival too.
		if winner == 0:
			run.buttons += 20
			run.offer = offer(setup, run, "epic")
		else:
			run.buttons = maxi(0, run.buttons - 20)
		_clear(setup, run)
		return
	if winner == 0:
		run.foe_hp = null
		run.foe_boost = 0.0
		if f.kind == "boss":
			run.floor = FLOORS
			run.done = true
			run.over = true
			return
		run.buttons += PAY.get(f.kind, PAY.fight)
		if f.kind == "elite":
			drop_relic(setup, run)
		run.offer = offer(setup, run, "rare" if f.kind == "elite" else "common")
		_clear(setup, run)
	else:
		run.out[slot] = true
		# A double KO still leaves the foe standing, just barely.
		run.foe_hp = maxf(foe_hp, 0.01)
		if not run.out.has(false):
			run.over = true


## Marks the current node cleared: the floor counts and the map opens.
static func _clear(setup: Dictionary, run: Dictionary) -> void:
	run.done = true
	run.floor = maxi(run.floor, node(setup, run.at).row + 1)


## Takes boon `id` from the current offer.
static func take_boon(run: Dictionary, id: String) -> void:
	assert(id in run.offer)
	run.log.append({"t": "boon", "id": id})
	run.boons.append(id)
	run.offer = []


## Adds a random relic the trio doesn't hold, seeded by the day and the node
## (`salt` tells two drops on one node apart), and names it in run.dropped.
## Returns it, or "" when the trio holds every relic.
static func drop_relic(setup: Dictionary, run: Dictionary, salt := 0) -> String:
	var held: Array = run.get("relics", [])
	var pool: Array = Relics.IDS.filter(func(id): return not id in held)
	if pool.is_empty():
		return ""
	var rng := Rng.new(_base(setup.day, setup.get("seed", 0)) * 4441 + run.at * 9173 + salt * 37 + 11)
	var id: String = pool[rng.range_int(0, pool.size() - 1)]
	held.append(id)
	run.relics = held
	run.dropped = id
	return id


## Boons for the node just cleared, seeded by the day and the node. Skips
## boons the trio already runs (at any rarity) and ability boons none of the
## trio can use. Each card rolls a rarity, at least `floor_rarity`; a
## Legendary roll swaps the card for a Legendary boon the trio doesn't have.
static func offer(setup: Dictionary, run: Dictionary, floor_rarity := "common", salt := 0) -> Array:
	var pool := _boon_pool(setup, run)
	var held: Array = run.boons.map(func(id): return Boons.base_of(id))
	var rng := Rng.new(_base(setup.day, setup.get("seed", 0)) * 7919 + run.at * 104729 + salt * 613 + 31)
	var out: Array = []
	for id in _shuffled(pool, rng).slice(0, OFFER + (1 if run.wish else 0)):
		out.append(_with_roll(rng, id, held + out.map(func(o): return Boons.base_of(o)), floor_rarity))
	return out


static func _boon_pool(setup: Dictionary, run: Dictionary) -> Array:
	var abilities: Array = []
	for slot in PICKS:
		abilities.append(BallDefs.get_def(card(setup, run, slot).critter).ability)
	var held: Array = run.boons.map(func(id): return Boons.base_of(id))
	var pool: Array = []
	for id in Boons.ALL:
		if not id in held and abilities.any(func(a): return Boons.applies_to(id, a)):
			pool.append(id)
	return pool


# --- Shop -------------------------------------------------------------------

## Three boons on the shelf, one Common, one Rare, one Epic (a Legendary roll
## can upgrade any of them), plus the services.
static func _shop_stock(setup: Dictionary, run: Dictionary, restock: int) -> Array:
	var pool := _boon_pool(setup, run)
	var held: Array = run.boons.map(func(id): return Boons.base_of(id))
	var rng := Rng.new(_base(setup.day, setup.get("seed", 0)) * 5381 + run.at * 7727 + restock * 131 + 7)
	var out: Array = []
	var shelf := _shuffled(pool, rng).slice(0, 3)
	for i in shelf.size():
		out.append(_with_roll(rng, shelf[i], held + out.map(func(o): return Boons.base_of(o)), ["common", "rare", "epic"][i]))
	return out


## Price of a shop item: "boon:<i>", "revive", "clean" or "restock".
static func price(setup: Dictionary, run: Dictionary, item: String) -> int:
	if item.begins_with("boon:"):
		return PRICES[Boons.rarity_of(run.shop.stock[int(item.get_slice(":", 1))])]
	return PRICES[item]


## True when `item` can be bought now (stock left, Buttons, someone to revive...).
static func can_buy(setup: Dictionary, run: Dictionary, item: String) -> bool:
	if phase(setup, run) != "shop" or item in run.shop.sold:
		return false
	if item.begins_with("boon:") and int(item.get_slice(":", 1)) >= run.shop.stock.size():
		return false
	if run.buttons < price(setup, run, item):
		return false
	match item:
		"revive":
			return run.out.has(true)
		"clean":
			return not glitches(run).is_empty()
		"restock":
			return not run.shop.restocked
	return true


## Buys `item`; `arg` is the critter slot to revive or the Glitch to clean.
static func buy(setup: Dictionary, run: Dictionary, item: String, arg = null) -> void:
	assert(can_buy(setup, run, item))
	run.log.append({"t": "buy", "item": item, "arg": arg})
	run.buttons -= price(setup, run, item)
	match item:
		"revive":
			run.out[int(arg) if arg != null else run.out.find(true)] = false
		"clean":
			run.boons.erase(arg if arg != null else glitches(run)[0])
		"restock":
			run.shop.restocked = true
			run.shop.stock = _shop_stock(setup, run, 1)
			run.shop.sold = run.shop.sold.filter(func(s): return not s.begins_with("boon:"))
		_:
			run.boons.append(run.shop.stock[int(item.get_slice(":", 1))])
			run.shop.sold.append(item)


## Leaves the shop for the map.
static func leave(setup: Dictionary, run: Dictionary) -> void:
	assert(phase(setup, run) == "shop")
	run.log.append({"t": "leave"})
	run.shop = {}
	_clear(setup, run)


# --- Charge Pad ---------------------------------------------------------------

## Rest choices: "revive" (arg slot), "polish" (arg boon id), "clean", or
## "pass" when there's nothing to do.
static func can_rest(run: Dictionary, choice: String) -> bool:
	match choice:
		"pass":
			return true
		"revive":
			return run.out.has(true)
		"polish":
			return not polishable(run).is_empty()
		"clean":
			return not glitches(run).is_empty()
	return false


static func rest(setup: Dictionary, run: Dictionary, choice: String, arg = null) -> void:
	assert(phase(setup, run) == "rest" and can_rest(run, choice))
	run.log.append({"t": "rest", "choice": choice, "arg": arg})
	match choice:
		"revive":
			run.out[int(arg) if arg != null else run.out.find(true)] = false
		"polish":
			_polish(run, arg if arg != null else polishable(run)[0])
		"clean":
			for g in glitches(run):
				run.boons.erase(g)
	_clear(setup, run)


## Boons that can go one rarity up (Common and Rare ones).
static func polishable(run: Dictionary) -> Array:
	return run.boons.filter(func(id): return not Boons.is_glitch(id) and Boons.rarity_of(id) in ["common", "rare"])


static func glitches(run: Dictionary) -> Array:
	return run.boons.filter(func(id): return Boons.is_glitch(id))


static func _polish(run: Dictionary, id: String) -> String:
	var up := Boons.with_rarity(Boons.base_of(id), "rare" if Boons.rarity_of(id) == "common" else "epic")
	run.boons[run.boons.find(id)] = up
	return up


# --- Events -------------------------------------------------------------------

## The event at the current node, or {}.
static func event(setup: Dictionary, run: Dictionary) -> Dictionary:
	if phase(setup, run) != "event":
		return {}
	return EVENTS[node(setup, run.at).event]


## The two critters the tide pool trader offers here, weighted toward the rarer
## ones (TRADER_ODDS) and never one you already run.
static func trade_offer(setup: Dictionary, run: Dictionary) -> Array:
	var rng := Rng.new(int(node(setup, run.at).seed) * 31 + 5)
	var out: Array = []
	for k in 2:
		var weights := {}
		for c in BallDefs.PLAYABLE:
			if not c in run.critters and not c in out:
				weights[c] = TRADER_ODDS.get(str(BallDefs.DEFS[c].get("rarity", "common")), 4)
		out.append(_roll(rng, weights))
	return out


## Options for an event choice's `arg`: slots, boon ids or [slot, k] trades.
## Empty when the choice needs no pick.
static func choice_args(setup: Dictionary, run: Dictionary, choice: Dictionary) -> Array:
	match choice.get("arg", ""):
		"living":
			return living(run)
		"out_or_none":
			return dead(run)
		"boon":
			return run.boons.filter(func(id): return not Boons.is_glitch(id))
		"polish":
			return polishable(run)
		"glitch":
			return glitches(run)
		"reroll":
			return _swappable(run)
		"trade":
			var out: Array = []
			for s in living(run):
				for k in 2:
					out.append([s, k])
			return out
	return []


## True when the event's choice can be taken now.
static func can_choose(setup: Dictionary, run: Dictionary, choice_id: String) -> bool:
	var ev := event(setup, run)
	if ev.is_empty():
		return false
	var choice: Dictionary = {}
	for c in ev.choices:
		if c.id == choice_id:
			choice = c
	if choice.is_empty() or run.buttons < int(choice.get("cost", 0)):
		return false
	match choice_id:
		"hatch":
			return run.hatchling == ""
		"swap_boon":
			return not _swappable(run).is_empty()
		"drink":
			return true
		"offer_boon":
			return run.out.has(true) and not choice_args(setup, run, choice).is_empty()
		"plug_in":
			return not _robot_pool(run).is_empty()
		"open_chest", "pocket_relic":
			return run.get("relics", []).size() < Relics.IDS.size()
	return choice.get("arg", "") in ["", "out_or_none"] or not choice_args(setup, run, choice).is_empty()


## Takes an event choice; `arg` is one of choice_args() when it asks for one.
static func choose(setup: Dictionary, run: Dictionary, choice_id: String, arg = null) -> void:
	assert(can_choose(setup, run, choice_id))
	var ev := event(setup, run)
	var n := node(setup, run.at)
	run.log.append({"t": "event", "choice": choice_id, "arg": arg})
	var rng := Rng.new(int(n.seed) * 17 + 3)
	for c in ev.choices:
		if c.id == choice_id:
			run.buttons += int(c.get("buttons", 0)) - int(c.get("cost", 0))
	match choice_id:
		"hatch":
			var commons: Array = BallDefs.PLAYABLE.filter(func(c): return BallDefs.DEFS[c].get("rarity", "") == "common")
			run.hatchling = commons[rng.range_int(0, commons.size() - 1)]
		"swap":
			run.critters[int(arg[0])] = trade_offer(setup, run)[int(arg[1])]
		"swap_boon":
			var old: String = _swappable(run)[-1]
			var up: String = {"common": "rare", "rare": "epic", "epic": "legendary"}[Boons.rarity_of(old)]
			run.boons.erase(old)
			run.boons.append(_random_boon(setup, run, rng, up))
		"pay":
			run.boons.append(_random_boon(setup, run, rng, "rare"))
		"kick":
			if rng.range_int(0, 1) == 0:
				run.boons.append(_random_boon(setup, run, rng, "epic"))
			else:
				_glitch(run, "sticky_floor")
		"drink":
			if arg != null:
				run.out[int(arg)] = false
			elif not "wall_snack" in run.boons.map(func(id): return Boons.base_of(id)):
				run.boons.append("wall_snack")
			else:
				run.buttons += 15
		"chip":
			run.boons.erase(arg)
			run.boons.append(_random_boon(setup, run, rng, "epic"))
		"spar":
			run.spar = int(arg)
		"look":
			_polish(run, arg)
			run.foe_boost = DOWNSIDE_POWER
		"smash":
			run.boons.erase(arg)
		"dash":
			_glitch(run, "singed")
			run.offer = offer(setup, run, "epic", 1)
		"read":
			run.revealed = true
		"wish":
			run.wish = true
		"fight":
			run.rival = true
			return
		"open_chest":
			drop_relic(setup, run, 1)
			run.foe_boost = DOWNSIDE_POWER
		"temper":
			_polish(run, arg)
		"reforge":
			run.boons[run.boons.find(arg)] = Boons.with_rarity(Boons.base_of(arg), "epic")
			_glitch(run, "singed")
		"shake_globe":
			var rarity := Boons.rarity_of(arg)
			run.boons.erase(arg)
			run.boons.append(_random_boon(setup, run, rng, rarity))
		"smash_globe":
			_glitch(run, "chilled")
		"gumball":
			run.boons.append(_random_boon(setup, run, rng, Boons.roll_rarity(rng)))
		"rattle":
			_glitch(run, "sticky_floor")
		"crank":
			if rng.range_int(0, 1) == 0:
				run.offer = offer(setup, run, "rare", 1)
			else:
				run.foe_boost = DOWNSIDE_POWER
		"offer_boon":
			run.boons.erase(arg)
			run.out[run.out.find(true)] = false
		"follow_light":
			run.revealed = true
		"reach_in":
			run.boons.append(_random_boon(setup, run, rng, "legendary"))
			_glitch(run, "rusty")
			_glitch(run, "sticky_floor")
		"pocket_relic":
			drop_relic(setup, run, 1)
			_glitch(run, "rusty")
		"scoop_honey":
			run.boons.append(_random_boon(setup, run, rng, "epic"))
			run.foe_boost = DOWNSIDE_POWER
		"wish_star":
			_polish(run, arg)
		"plug_in":
			var pool := _robot_pool(run)
			run.critters[int(arg)] = pool[rng.range_int(0, pool.size() - 1)]
	_clear(setup, run)


## Tech critters, Rare or better, that the trio doesn't already run.
static func _robot_pool(run: Dictionary) -> Array:
	var out: Array = []
	for c in Families.MEMBERS[ROBOT_FAMILY]:
		if c in BallDefs.PLAYABLE and str(BallDefs.DEFS[c].get("rarity", "")) in ROBOT_RARITIES and not c in run.critters:
			out.append(c)
	return out


## Boons the trader can swap up (anything but Glitches and Legendaries).
static func _swappable(run: Dictionary) -> Array:
	return run.boons.filter(func(id): return not Boons.is_glitch(id) and Boons.rarity_of(id) != "legendary")


## A random boon the trio doesn't run, at `rarity` (a Legendary when asked
## and one is free, else Epic).
static func _random_boon(setup: Dictionary, run: Dictionary, rng, rarity: String) -> String:
	var held: Array = run.boons.map(func(id): return Boons.base_of(id))
	if rarity == "legendary":
		var free: Array = Boons.LEGENDARY.filter(func(id): return not id in held)
		if not free.is_empty():
			return free[rng.range_int(0, free.size() - 1)]
		rarity = "epic"
	var pool := _boon_pool(setup, run)
	if pool.is_empty():
		pool = Boons.GENERAL.duplicate()
	return Boons.with_rarity(pool[rng.range_int(0, pool.size() - 1)], rarity)


static func _glitch(run: Dictionary, base: String) -> void:
	var id := Boons.GLITCH_PREFIX + base
	if not id in run.boons:
		run.boons.append(id)


# --- Score and replay -----------------------------------------------------------

static func living(run: Dictionary) -> Array:
	var out: Array = []
	for slot in PICKS:
		if not run.out[slot]:
			out.append(slot)
	return out


static func dead(run: Dictionary) -> Array:
	var out: Array = []
	for slot in PICKS:
		if run.out[slot]:
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
## posted score can be checked against the sim: every fight is fought again.
static func replay(setup: Dictionary, run: Dictionary) -> Dictionary:
	var check := new_run(setup, run.picks, run.start, run.get("start_relic", ""))
	for entry in run.log:
		match entry.t:
			"go":
				go(setup, check, int(entry.n))
			"fight":
				var sim := MatchSim.new(fight_config(setup, check, int(entry.slot), int(entry.aim)))
				var result := sim.run_to_end()
				record(setup, check, int(entry.slot), int(entry.aim), result.winner, result.ticks, result.hp[1])
			"boon":
				take_boon(check, entry.id)
			"buy":
				buy(setup, check, entry.item, entry.arg)
			"leave":
				leave(setup, check)
			"rest":
				rest(setup, check, entry.choice, entry.arg)
			"event":
				choose(setup, check, entry.choice, entry.arg)
	return check


## What a run's draws are seeded from: the day, or a practice run's own seed
## (offset so it never lands on a real day's map).
static func _base(day: int, run_seed: int) -> int:
	return day if run_seed == 0 else 1000000 + run_seed


## `base` at a seeded rarity, at least `floor_rarity`. A Legendary roll gives
## a Legendary boon not in `held` (base ids), or an Epic when all are taken.
static func _with_roll(rng, base: String, held: Array, floor_rarity := "common") -> String:
	var rarity := Boons.roll_rarity(rng)
	if Boons.RARITIES.find(rarity) < Boons.RARITIES.find(floor_rarity):
		rarity = floor_rarity
	if rarity == "legendary":
		var free: Array = Boons.LEGENDARY.filter(func(id): return not id in held)
		if not free.is_empty():
			return free[rng.range_int(0, free.size() - 1)]
		rarity = "epic"
	return Boons.with_rarity(base, rarity)


## A key of `weights` ({key: weight}) picked by one seeded draw.
static func _roll(rng, weights: Dictionary) -> String:
	var keys: Array = weights.keys()
	keys.sort()
	var total := 0
	for k in keys:
		total += int(weights[k])
	var r: int = rng.range_int(0, total - 1)
	for k in keys:
		r -= int(weights[k])
		if r < 0:
			return k
	return keys[-1]


static func _shuffled(items: Array, rng) -> Array:
	var out := items.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j: int = rng.range_int(0, i)
		var t = out[i]
		out[i] = out[j]
		out[j] = t
	return out
