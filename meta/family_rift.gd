## Rifts (design/dyes-rift-keys.md, project files): the Glitch tears small
## rifts into each family's home, and a Rift Key opens one. Pick a family,
## then fight three of its critters in a row on that family's arena: two
## rounds and a crowned Rift Boss (the family's star, an Epic or Legendary).
## Each win pays copies of that family's critters (the summon odds and the
## shared pity, wishlist counting double, Summon.roll_in) and Spark Dye
## drops; the boss adds a copy that is Rare or better. A loss ends the run
## and keeps what you won. No energy and no daily runs: the key is the cost.
## Opens with the Zone 1 boss, which also drops the first key.
##
## Same flow as the farming bosses (meta/gear_vault.gd), so the fight scene
## runs it like one: open() spends the key and draws the three foes, start()
## builds a round's fight from known setup only (it replays from the seed and
## the angles), finish() pays it.
extends RefCounted

const Zones := preload("res://meta/zones.gd")
const Campaign := preload("res://meta/campaign.gd")
const Lineup := preload("res://sim/lineup.gd")
const Power := preload("res://sim/power.gd")
const Families := preload("res://sim/families.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Roster := preload("res://game/ui/roster.gd")
const Summon := preload("res://game/ui/summon.gd")
const Dyes := preload("res://game/glow/dyes.gd")

const KEY := "rift"
## The rounds, in order: the foe's power as a share of your strongest
## critter's, and what a win pays.
const ROUNDS := [
	{"name": "Round 1", "power": 0.8, "copies": 2, "dyes": 1},
	{"name": "Round 2", "power": 0.9, "copies": 2, "dyes": 1},
	{"name": "Rift Boss", "power": 1.0, "copies": 2, "rare": 1, "dyes": 2, "boss": true},
]
## The fight scene reads a round's caption from here, like a boss level.
const DIFFICULTIES := ROUNDS
## Each family fights on one of its own arenas (sim/arenas.gd).
const ARENAS := {
	"nature": ["thorn", "hive"], "sea": ["reef", "kelp"], "tech": ["factory", "arcade"],
	"sweet": ["candy", "syrup"], "frost": ["frost", "storm"], "toybox": ["toybox", "pinball"],
	"spooky": ["graveyard", "manor"], "fire": ["magma", "inferno"], "cosmic": ["starfall", "nebula"],
}
const WIN_XP := 15
const LOSS_XP := 3


static func is_unlocked(profile) -> bool:
	return Campaign.is_cleared(profile, 0, Zones.zone(0).stages.size() - 1)


## True while a run is open (its key already spent).
static func in_run(profile) -> bool:
	return profile.rift.has("family")


## The family's critters that can fight and drop.
static func members(family: String) -> Array:
	return Families.MEMBERS.get(family, []).filter(func(id): return BallDefs.PLAYABLE.has(id) and Roster.ids().has(id))


## Spends a key and opens a Rift into `family`. Returns the run, or
## {error: "locked" | "run" (one is already open) | "family" | "key"}.
static func open(profile, family: String, now: int) -> Dictionary:
	if not is_unlocked(profile):
		return {"error": "locked"}
	if in_run(profile):
		return {"error": "run"}
	if members(family).size() < 3:
		return {"error": "family"}
	if profile.rift_keys() <= 0:
		return {"error": "key"}
	profile.add_rift_keys(-1)
	var seed_value := _seed(profile.runs, now, Families.ids().find(family))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var arenas: Array = ARENAS.get(family, ["square"])
	profile.rift = {"family": family, "round": 0, "seed": seed_value, "arena": arenas[rng.randi_range(0, arenas.size() - 1)],
		"foes": foes(family, rng), "copies": [], "dyes": []}
	profile.changed.emit()
	return profile.rift


## Three foes from the family: two from its Commons to Rares, then its star
## (an Epic or Legendary) as the Rift Boss.
static func foes(family: String, rng: RandomNumberGenerator) -> Array:
	var all := members(family)
	var low := all.filter(func(id): return Roster.RARITIES.find(Roster.get_critter(id).rarity) <= 2)
	var high := all.filter(func(id): return Roster.RARITIES.find(Roster.get_critter(id).rarity) >= 3)
	if low.size() < 2:
		low = all.duplicate()
	if high.is_empty():
		high = all.duplicate()
	var a: String = low[rng.randi_range(0, low.size() - 1)]
	var rest := low.filter(func(id): return id != a)
	var b: String = rest[rng.randi_range(0, rest.size() - 1)] if not rest.is_empty() else a
	return [a, b, high[rng.randi_range(0, high.size() - 1)]]


## Your strongest critter that can fight: what the foes are measured against,
## so picking a weaker fighter never makes a round easier.
static func top_power(profile) -> Dictionary:
	var best := {"id": "", "power": 1.0, "tier": 1}
	for id in Roster.ids():
		if Campaign.can_fight(profile, id):
			var pw: float = profile.fight_power(id)
			if best.id == "" or pw > best.power:
				best = {"id": id, "power": pw, "tier": int(profile.best(id).tier)}
	return best


## The foe's fight power multiplier and tier in `round`. The foe fights at the
## tier of your strongest critter; FOE_POWER pays back its stronger ability,
## as campaign foes do (meta/zones.gd).
static func foe_power(profile, round: int) -> Dictionary:
	var top := top_power(profile)
	var tier: int = clampi(top.tier, 1, Zones.FOE_POWER.size())
	return {"tier": tier, "power": top.power * ROUNDS[round].power * Zones.FOE_POWER[tier - 1],
		"rating": Power.rating(top.power * ROUNDS[round].power)}


## A round's fight config with the player's aim left as null, or {error:
## "run" (no run open or not this round) | "no_ball"}.
static func start(profile, round: int, fighter: String, _now: int) -> Dictionary:
	if not in_run(profile) or int(profile.rift.round) != round:
		return {"error": "run"}
	if not Campaign.can_fight(profile, fighter):
		return {"error": "no_ball"}
	var foe := foe_power(profile, round)
	var boss: bool = ROUNDS[round].get("boss", false)
	var cfg := {
		"seed": (int(profile.rift.seed) + round * 7919) & 0x7FFFFFFF,
		"p2": profile.rift.foes[round],
		"arena": profile.rift.arena,
		"angles": [null, null],
		"tiers": [1, foe.tier],
		"powers": [1.0, foe.power],
		"gear": [null, null],
		"sizes": [1.0, Zones.BOSS_SIZE if boss else 1.0],
	}
	return Lineup.apply(cfg, 0, profile.slot_of(fighter))


## Backing out before launch costs nothing: the round waits.
static func cancel(_profile, _now: int) -> void:
	pass


## Leaving between rounds: the run ends and you keep what you won.
static func leave(profile) -> void:
	profile.rift = {}
	profile.changed.emit()


## Pays a finished round (`fight` as for Campaign.finish). Returns {won,
## round, done (the run is over), cleared (all three beaten), copies: [ids],
## dyes: [{id, drops, need, unlocked}], xp, levels, critters, account_levels}.
static func finish(profile, round: int, fighter: String, fight: Dictionary, _now: int) -> Dictionary:
	var won: bool = fight.winner == 0
	var result := {"won": won, "round": round, "done": true, "cleared": false, "copies": [], "dyes": [],
		"xp": LOSS_XP, "levels": 0, "critters": [], "account_levels": 0, "family": str(profile.rift.get("family", ""))}
	if not in_run(profile) or int(profile.rift.round) != round:
		return result
	if not won:
		Campaign.give_xp(profile, result, fighter)
		leave(profile)
		return result
	var r: Dictionary = ROUNDS[round]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(profile.rift.seed) ^ (0x5bd1e995 + round * 131)
	var pool := members(result.family)
	if r.get("rare", 0) > 0:
		for i in r.rare:
			result.copies.append(Summon.roll_in(profile, rng, pool, true))
	for i in r.copies:
		result.copies.append(Summon.roll_in(profile, rng, pool))
	result.copies = result.copies.filter(func(id): return id != "")
	profile.add_copies(result.copies)
	for i in r.dyes:
		var got: Dictionary = profile.add_dye_drop(Dyes.roll(profile, rng))
		if not got.is_empty():
			result.dyes.append(got)
	result.xp = WIN_XP + round * 5
	Campaign.give_xp(profile, result, fighter)
	profile.rift.copies.append_array(result.copies)
	profile.rift.dyes.append_array(result.dyes.map(func(d): return d.id))
	profile.rift.round = round + 1
	result.done = round + 1 >= ROUNDS.size()
	result.cleared = result.done
	if result.done:
		profile.rift = {}
	profile.runs += 1
	profile.changed.emit()
	return result


static func _seed(runs: int, now: int, family: int) -> int:
	return (runs * 7307 + int(now / 60) * 13 + family * 977 + 11) & 0x7FFFFFFF
