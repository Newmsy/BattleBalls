## Arena Ghosts (design/pvp.md section 6): the labelled bot defences that fill
## thin trophy bands and power offline practice, plus the three daily
## opponent cards. Everything is generated from fixed seeds, so every device
## (and later the server's ghost_bots table) sees the same bots.
##
## A lineup uses the Ghost Arena lineup shape v1 (game/online/ghost_lineup.gd
## on the backend branch): {v, slots: [{critter, tier, level, gear}], aim},
## where aim values are launch offsets off the centre line in tenths of a
## degree. Each slot also carries its own `aim` (pvp.md lineup v2), and the
## top-level `aim` lists the same shots so v1 readers still work.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Ladder := preload("res://game/pvp/ladder.gd")

const POOL_SEED := 0x6E05
const BAND_SIZE := 100 ## Trophies per band.
const BANDS := 50 ## Bands 0-99 up to 4900-4999.
const PER_BAND := 4
const AIM_SPREAD := 300 ## Bots aim up to 30 degrees either side of the centre line.
const CANDIDATES := 4 ## A card picks among this many nearest bots.

const NAME_FIRST := ["Sir", "Lady", "Captain", "Tiny", "Mega", "Pixel", "Neon", "Turbo", "Lord", "Doctor",
	"Sneaky", "Wobbly", "Glitchy", "Sparkle", "Cosmic", "Fuzzy", "Zippy", "Grumpy", "Lucky", "Disco"]
const NAME_SECOND := ["Wobbles", "Bouncer", "Prickles", "Nibbler", "Pinball", "Zapper", "Roller", "Bumper",
	"Gumdrop", "Marble", "Comet", "Pebble", "Jellybean", "Orbit", "Flicker", "Biscuit", "Noodle", "Rocket"]

static var _pool: Array[Dictionary] = []


## The full bot pool, lowest trophies first. Built once per run.
static func pool() -> Array[Dictionary]:
	if _pool.is_empty():
		_pool = _generate()
	return _pool


static func by_id(id: String) -> Dictionary:
	for bot in pool():
		if bot.id == id:
			return bot
	return {}


## Today's three opponent cards for a player: one each of easier, even and
## harder, nearest to their trophies plus the card's offset. Stable for a
## given (day, player, refresh), so reopening the screen shows the same cards.
static func offers(trophies: int, day: int, player_key: String, refresh: int = 0) -> Array[Dictionary]:
	var rng = Rng.new(hash("%d|%s|%d" % [day, player_key, refresh]))
	var taken := {}
	var cards: Array[Dictionary] = []
	for card in Ladder.CARD_ORDER:
		var target: int = trophies + Ladder.CARDS[card].offset
		var nearest := pool().filter(func(b: Dictionary) -> bool: return not taken.has(b.id))
		nearest.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var da := absi(a.trophies - target)
			var db := absi(b.trophies - target)
			return da < db or (da == db and a.id < b.id))
		var bot: Dictionary = nearest[rng.range_int(0, mini(CANDIDATES, nearest.size()) - 1)]
		taken[bot.id] = true
		cards.append({"card": card, "bot": bot})
	# At the ends of the ladder the bands overlap; keep easier <= even <= harder.
	var bots := cards.map(func(c: Dictionary) -> Dictionary: return c.bot)
	bots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.trophies < b.trophies)
	for i in cards.size():
		cards[i].bot = bots[i]
	return cards


## Launch angle for a lineup slot fired from `side`'s corner (0 or 1).
static func slot_angle(lineup: Dictionary, slot: int, side: int) -> int:
	var shots: Array = lineup.get("aim", [])
	var slot_aim = lineup.slots[slot].get("aim", null)
	var offset: int = int(slot_aim) if slot_aim != null else (int(shots[slot % shots.size()]) if not shots.is_empty() else 0)
	return MatchSim.AIM_AT_CENTRE[side] + offset


static func critters(lineup: Dictionary) -> Array:
	return lineup.slots.map(func(s: Dictionary) -> String: return s.critter)


static func _generate() -> Array[Dictionary]:
	var rng = Rng.new(POOL_SEED)
	var bots: Array[Dictionary] = []
	var used_names := {}
	for band in BANDS:
		for n in PER_BAND:
			var slots: Array = []
			var shots: Array = []
			for i in 3:
				var critter: String = BallDefs.PLAYABLE[rng.range_int(0, BallDefs.PLAYABLE.size() - 1)]
				var aim := rng.range_int(-AIM_SPREAD, AIM_SPREAD)
				slots.append({"critter": critter, "tier": 1, "level": 1, "gear": {}, "aim": aim})
				shots.append(aim)
			var name := _name(rng, used_names)
			bots.append({
				"id": "ghost-%03d" % bots.size(),
				"name": name,
				"is_bot": true,
				"trophies": band * BAND_SIZE + rng.range_int(0, BAND_SIZE - 1),
				"lineup": {"v": 1, "slots": slots, "aim": shots},
			})
	bots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.trophies < b.trophies or (a.trophies == b.trophies and a.id < b.id))
	return bots


static func _name(rng, used: Dictionary) -> String:
	for attempt in 50:
		var name := "%s %s" % [NAME_FIRST[rng.range_int(0, NAME_FIRST.size() - 1)], NAME_SECOND[rng.range_int(0, NAME_SECOND.size() - 1)]]
		if not used.has(name):
			used[name] = true
			return name
	var fallback := "Ghost %d" % used.size()
	used[fallback] = true
	return fallback
