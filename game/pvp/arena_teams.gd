## Seeded Arena opponents. Every opponent that isn't a real player's saved
## squad (game/pvp/arena_players.gd) is built here to look like one
## (Newms 2026-11-02): a player-style name, an account level and a mixed
## squad of different critters, built to a target strength. Attack
## opponents sit near your trophies and are as strong as their trophies
## (strength_for); daily raids on your defence are sized to your defence
## (target). Everything comes from fixed seeds, so a squad (and the fight
## against it) replays from its config alone. `size` is 3 for the 3v3
## Series and 2 for the 2v2 League.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Lineup := preload("res://sim/lineup.gd")
const Families := preload("res://sim/families.gd")
const Gear := preload("res://sim/gear.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")

## Team strength against yours, per card.
const CARD_SCALE := {"easier": 0.85, "even": 1.0, "harder": 1.15}
## Teams grow this much stronger than you per 1,000 trophies, up to LADDER_MAX.
const LADDER_STEP := 0.08
const LADDER_MAX := 0.5
## Weakest team a card can show (a fresh T1 Common trio is about 1000).
const MIN_TARGET := 900
## Seeded opponents (offers): how many, how far around your trophies, and how
## their strength grows with trophies (strength_for).
const OFFER_COUNT := 10
const SPREAD_BELOW := 120.0
const SPREAD_ABOVE := 180.0
const TROPHIES_PER_TIER := 500
## Three T1 Uncommons at level 1: since one rarity step became a whole tier
## (2026-10-22) a fresh trio mixes rarities, and every family but Cosmic can
## field a team this weak (three T1 Commons were 3000).
const FRESH_TRIO := 3750
const MAX_STRENGTH := 25200 ## About a maxed T5 trio in gear (x1.4 with the rarity step).

## Player-style names (name_for): two halves run together in a few styles,
## or a short first name, sometimes with digits.
const NAME_A := ["frost", "moss", "pixel", "nova", "bouncy", "zap", "echo", "comet", "lucky", "turbo",
	"sneaky", "sunny", "mega", "tiny", "shadow", "neon", "bubble", "rocket", "ember", "glitch",
	"cosmo", "pinball", "sugar", "storm", "wobbly", "jelly", "spark", "orbit", "fizzy", "maple"]
const NAME_B := ["byte", "maya", "bea", "wizard", "king", "fox", "kid", "queen", "rider", "panda",
	"ace", "bun", "pop", "ninja", "otter", "moth", "drake", "boop", "star", "chip",
	"loop", "dash", "wave", "gnome", "pilot", "tiger", "yeti", "zebra", "bean", "duck"]
const FIRST := ["Zed", "Nova", "Kaz", "Tobi", "Remy", "Juno", "Ollie", "Pip", "Sasha", "Leo",
	"Ivy", "Max", "Noor", "Kai", "Yuki", "Rio", "Bex", "Finn", "Luca", "Ada"]
const NAME_TAGS := ["_Plays", "TV", "GG", "_YT", "xo"]


## Rating a team should have on `card`, for a player whose trio rates
## `mine` (Lineup.rating summed over the trio) at `trophies`.
static func target(mine: int, trophies: int, card: String) -> int:
	var ladder := 1.0 + minf(LADDER_MAX, LADDER_STEP * maxi(0, trophies) / 1000.0)
	return maxi(MIN_TARGET * 3, roundi(mine * ladder * CARD_SCALE[card]))


## offers() is pure, and building teams is the slowest part of
## opening the Arena, so both are kept for the session.
static var _offers_cache := {}


## Today's opponents, weakest first: OFFER_COUNT seeded player-style squads,
## each with its own trophies a little below or above yours and as strong as a
## player on those trophies (strength_for). {card: "seeded", bot}; a bot is
## a full lineup, so the fight needs nothing else to replay. Stable for
## (day, refresh, trophies to the nearest 50).
static func offers(trophies: int, day: int, refresh := 0, count := OFFER_COUNT, size := 3) -> Array[Dictionary]:
	var key := "%d|%d|%d|%d|%d" % [day, refresh, trophies, count, size]
	if not _offers_cache.has(key):
		_offers_cache[key] = _make_offers(trophies, day, refresh, count, size)
	var out: Array[Dictionary] = []
	for c in _offers_cache[key]:
		out.append(c.duplicate(true))
	return out


static func _make_offers(trophies: int, day: int, refresh: int, count: int, size := 3) -> Array[Dictionary]:
	var rng = Rng.new(hash("teams|%d|%d|%d|%d" % [day, refresh, trophies / 50, size]))
	var cards: Array[Dictionary] = []
	var names := {}
	for i in count:
		# Spread evenly from SPREAD_BELOW under you to SPREAD_ABOVE over you,
		# with a little jitter so the numbers don't look stepped.
		var t := float(i) / maxf(1.0, count - 1.0)
		var offset := lerpf(-SPREAD_BELOW, SPREAD_ABOVE, t) + rng.range_int(-20, 20)
		var theirs := maxi(0, trophies + roundi(offset))
		var team := make_player(strength_for(theirs) * size / 3, rng.range_int(1, 0x7FFFFFFF), theirs, size, names)
		team.id = "team-%d-%d-%d%s" % [day, refresh, i, "" if size == 3 else "-%d" % size]
		cards.append({"card": "seeded", "bot": team})
	return cards


## Summed trio Power Rating of a seeded team on `trophies`: a fresh T1 trio at
## 0, one tier stronger (x1.25) every TROPHIES_PER_TIER, up to a maxed trio.
static func strength_for(trophies: int) -> int:
	return mini(MAX_STRENGTH, roundi(FRESH_TRIO * pow(1.25, maxi(0, trophies) / float(TROPHIES_PER_TIER))))


## One player-style squad of `size` different critters from any family,
## levelled so its summed Power Rating lands as close to `goal` as it can.
## `trophies` sets their level; `taken` (name -> true) keeps names on one
## list apart.
static func make_player(goal: int, seed_value: int, trophies := 0, size := 3, taken := {}) -> Dictionary:
	var rng = Rng.new(seed_value)
	var per := goal / float(size)
	# Critters that can be built down to the goal; rarer ones only when the
	# goal is high enough for them even at 1 star.
	var fits: Array = _by_base().filter(func(id): return _base_rating(id) <= per * 1.05)
	if fits.size() < size:
		fits = _by_base().slice(0, size)
	var picks: Array = []
	while picks.size() < size:
		picks.append(fits.pop_at(rng.range_int(0, fits.size() - 1)))
	var slots: Array = []
	var shots: Array = []
	for id in picks:
		var s := _build(id, per)
		s.aim = rng.range_int(-ArenaGhosts.AIM_SPREAD, ArenaGhosts.AIM_SPREAD)
		shots.append(s.aim)
		slots.append(s)
	var name := name_for(rng)
	for n in 6:
		if not taken.has(name):
			break
		name = name_for(rng)
	taken[name] = true
	return {
		"id": "team",
		"name": name,
		"family": main_family(slots),
		"level": level_for(trophies, rng.range_int(-4, 4)),
		"trophies": trophies,
		"lineup": {"v": 1, "slots": slots, "aim": shots},
	}


## A player-style name from `rng` (sim/rng.gd), at most 14 letters.
static func name_for(rng) -> String:
	var a: String = NAME_A[rng.range_int(0, NAME_A.size() - 1)]
	var b: String = NAME_B[rng.range_int(0, NAME_B.size() - 1)]
	var first: String = FIRST[rng.range_int(0, FIRST.size() - 1)]
	var out := ""
	match rng.range_int(0, 6):
		0: out = a + b
		1: out = a + "_" + b
		2: out = a.capitalize() + b.capitalize()
		3: out = first
		4: out = first + NAME_TAGS[rng.range_int(0, NAME_TAGS.size() - 1)]
		5: out = a + b + str(rng.range_int(2, 99))
		_: out = first.to_lower() + "_" + b
	return out.replace(" ", "").left(14)


## A plausible account level for a player on `trophies`.
static func level_for(trophies: int, jitter := 0) -> int:
	return clampi(5 + maxi(0, trophies) / 70 + jitter, 3, 99)


## The family most of a squad comes from (the first critter's on a tie), for
## its colour and home painting.
static func main_family(slots: Array) -> String:
	var count := {}
	var best := ""
	for s in slots:
		var f := Families.of(str(s.critter))
		count[f] = int(count.get(f, 0)) + 1
		if best == "" or count[f] > count[best]:
			best = f
	return best


static var _base_cache := {}
static var _by_base_cache: Array = []


## A critter's rating at 1 star, level 1, no gear.
static func _base_rating(id: String) -> int:
	if not _base_cache.has(id):
		_base_cache[id] = Lineup.rating(Lineup.make(id))
	return _base_cache[id]


## Every playable critter, weakest at 1 star first.
static func _by_base() -> Array:
	if _by_base_cache.is_empty():
		_by_base_cache = BallDefs.PLAYABLE.duplicate()
		_by_base_cache.sort_custom(func(a, b): return _base_rating(a) < _base_rating(b) or (_base_rating(a) == _base_rating(b) and a < b))
	return _by_base_cache.duplicate()


## The team's summed Power Rating.
static func rating(team: Dictionary) -> int:
	var total := 0
	for s in team.lineup.slots:
		total += Lineup.rating(s)
	return total


## `critter` at the tier and level whose rating is nearest `per`, wearing the
## gear a player at that tier would (ArenaGhosts.bot_gear's pieces).
static func _build(critter: String, per: float) -> Dictionary:
	var best := {}
	var best_gap := INF
	for tier in range(1, Lineup.MAX_TIER + 1):
		var gear := _gear(tier)
		for level in range(1, Lineup.level_cap(tier) + 1):
			var s := Lineup.make(critter, tier, level, gear)
			var r := Lineup.rating(s)
			var gap := absf(r - per)
			if gap < best_gap:
				best_gap = gap
				best = s
			# Rating only grows with level, so the rest of this tier is further off.
			if r >= per:
				break
	return best


static func _gear(tier: int) -> Array:
	if tier < 2:
		return []
	var types := ["bubble_shell", "spike_core"]
	if tier >= Gear.CHARM_TIER:
		types.append("jet_charm")
	return types.map(func(t): return {"slot": Gear.PIECES[t].slot, "tier": tier - 1, "stats": Gear.stats_for(t, tier - 1)})
