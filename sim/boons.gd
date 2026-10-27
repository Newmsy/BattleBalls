## Bounce Run boons: run-only perks. Pure data plus a helper that folds a list
## of boons into a ball def, so the sim reads them like any other stat and the
## same config still gives the same fight. Boons never touch permanent
## progression. Each one is checked by tools/boon_balance.gd: holding it at
## equal power must win 52-62% (a tilt, BALANCE.md rule 2), never more.
##
## Stacking: a run may hold the same boon more than once, at any rarities.
## Copies add their numbers (two +6% HP boons are +12%; 9% and 14% burns are a
## 23% burn). Legendary boons are one of a kind. See stacked().
##
## Fields (all optional; several boons of the same kind add up):
##   hp, damage, speed      multipliers on base stats (damage scales contact
##                          damage and every *_damage stat); their percentages
##                          add, so +6% and +6% are +12%
##   bounce_heal            HP healed on every wall bounce
##   first_strike           extra damage on your first contact hit of a fight
##   bank_bonus             your next contact hit after a wall bounce deals
##                          this much more (0.3 = +30%)
##   contact_armor          share of incoming contact damage ignored
##   heal_ratio, beam_max, beam_life   added to that ability's stat; only
##                          critters with the ability (`for`) get them
##   Legendary only:
##   boon_revive            once per fight, get back up at this share of max HP
##   thorns                 share of contact damage taken hit back at the bumper
##   lifesteal              heal this share of the contact damage you deal
##   overcharge             every Nth contact hit of a fight deals double
##   b_storm, b_fling, size  Storm Heart and Titan Belt (see MatchSim)
##   b_*                    the other fight-shaping boons (MECHANICS): bump
##                          burn, chill, pinball slams, payback, zap stuns,
##                          wall-bounce sparks and mines, Second Wind, Fever,
##                          Bubble (a shield of b_bubble x max HP at the start)
##
## Rarity: an offered boon rolls a rarity (roll_rarity). "id" is Common;
## "id:rare" and "id:epic" are the same boon with bigger numbers (SCALE).
## Legendary boons are their own ids (LEGENDARY), each with an effect no
## other boon has.
extends RefCounted

const DEFS := {
	"thick_shell": {
		"name": "Thick Shell",
		"text": "+6% max HP.",
		"icon": "shield",
		"hp": 1.06,
	},
	"spiky_rim": {
		"name": "Spiky Rim",
		"text": "+6% damage.",
		"icon": "spike",
		"damage": 1.06,
	},
	"zoomies": {
		"name": "Zoomies",
		"text": "Move 10% faster.",
		"icon": "bolt",
		"speed": 1.1,
	},
	"wall_snack": {
		"name": "Wall Snack",
		"text": "Heal 0.4 HP per wall bounce.",
		"icon": "heart",
		"bounce_heal": 0.4,
	},
	# Was Overtime Bubble: most fights end before overtime, so it shields from the start.
	"overtime_bubble": {
		"name": "Bubble",
		"text": "Start every fight with a shield worth {n}% of your max HP.",
		"icon": "bubble",
		"b_bubble": 0.06,
	},
	"opening_bite": {
		"name": "Opening Bite",
		"text": "First hit: +7 damage.",
		"icon": "fang",
		"first_strike": 7.0,
	},
	"bank_shot": {
		"name": "Bank Shot",
		"text": "+8% damage after a wall bounce.",
		"icon": "bank",
		"bank_bonus": 0.08,
	},
	"bumper_guard": {
		"name": "Bumper Guard",
		"text": "Take 7% less damage from bumps.",
		"icon": "guard",
		"contact_armor": 0.07,
	},
	"ember_rim": {
		"name": "Ember Rim",
		"text": "Bumps set the foe on fire: +{n}% of a bump over 2s.",
		"icon": "flame",
		"b_burn": 0.09,
	},
	"frost_rim": {
		"name": "Frost Rim",
		"text": "Bumps chill the foe: {n}% slower for 1.5s.",
		"icon": "snow",
		"b_chill": 0.2,
	},
	"rebound_bolt": {
		"name": "Rebound Bolt",
		"text": "Wall bounces fire a homing spark: {n}% of a bump.",
		"icon": "rebound",
		"b_bolt": 0.06,
	},
	"pinball": {
		"name": "Pinball",
		"text": "Bump a foe into a wall: it takes {n}% of a bump more.",
		"icon": "pinball",
		"b_pinball": 0.14,
	},
	"bounce_mine": {
		"name": "Bounce Mine",
		"text": "Every 3rd wall bounce drops a mine: {n}% of a bump.",
		"icon": "mine",
		"b_mine": 0.27,
	},
	"payback": {
		"name": "Payback",
		"text": "Get rammed, and your next bump hits {n}% harder.",
		"icon": "fist",
		"b_payback": 0.3,
	},
	"zap_collar": {
		"name": "Zap Collar",
		"text": "Every 4th bump stuns the foe for {n}s.",
		"icon": "collar",
		"b_zap": 0.2,
	},
	"second_wind": {
		"name": "Second Wind",
		"text": "Once, below 40% HP: dash off with a {n}% HP shield.",
		"icon": "wind",
		"b_wind": 0.06,
	},
	"fever": {
		"name": "Fever",
		"text": "After your 3rd bump in a fight, grow big and bump {n}% harder.",
		"icon": "thermo",
		"b_fever": 0.16,
	},
	"sharper_fangs": {
		"name": "Sharper Fangs",
		"text": "+6% lifesteal.",
		"icon": "fang",
		"for": "vampire",
		"heal_ratio": 0.06,
	},
	"prism": {
		"name": "Prism",
		"text": "+1 beam, beams +0.5s.",
		"icon": "beam",
		"for": "laser",
		"beam_max": 1,
		"beam_life": 0.5,
	},
	"phoenix_feather": {
		"name": "Phoenix Feather",
		"text": "Revive once at 28% HP.",
		"icon": "feather",
		"rarity": "legendary",
		"boon_revive": 0.28,
	},
	"thorn_crown": {
		"name": "Thorn Crown",
		"text": "Reflect 28% of bump damage.",
		"icon": "thorns",
		"rarity": "legendary",
		"thorns": 0.28,
	},
	"vampire_kiss": {
		"name": "Vampire Kiss",
		"text": "Heal 24% of bump damage dealt.",
		"icon": "drop",
		"rarity": "legendary",
		"lifesteal": 0.24,
	},
	"overcharge": {
		"name": "Overcharge",
		"text": "Every 3rd bump you land hits for double damage.",
		"icon": "zap",
		"rarity": "legendary",
		"overcharge": 3,
	},
	"storm_heart": {
		"name": "Storm Heart",
		"text": "Every 5s, lightning strikes your foe.",
		"icon": "storm",
		"rarity": "legendary",
		"b_storm": 0.2,
	},
	"titan_belt": {
		"name": "Titan Belt",
		"text": "Grow 25% bigger. Your bumps fling foes into walls.",
		"icon": "titan",
		"rarity": "legendary",
		"size": 1.25,
		"b_fling": 1.0,
		"b_pinball": 0.5,
	},
}

## Glitches: bad boons a Bounce Run event can hand you (only ever by
## choice). Their ids carry GLITCH_PREFIX; they never show up in offers, and
## a shop or Charge Pad cleans them.
const GLITCH_PREFIX := "glitch_"
const GLITCHES := {
	"glitch_sticky_floor": {"name": "Sticky Floor", "text": "Move 6% slower.", "icon": "bolt", "speed": 0.94},
	"glitch_singed": {"name": "Singed", "text": "-5% max HP.", "icon": "shield", "hp": 0.95},
	"glitch_chilled": {"name": "Chilled", "text": "Move 7% slower.", "icon": "bolt", "speed": 0.93},
	"glitch_rusty": {"name": "Rusty", "text": "-5% damage.", "icon": "spike", "damage": 0.95},
}

const RARITIES := ["common", "rare", "epic", "legendary"]
## Roll weights for an offered boon, in RARITIES order (out of 100).
const ODDS := [58, 27, 11, 4]
## How much bigger a Rare or Epic boon's numbers are than its Common.
const SCALE := {"common": 1.0, "rare": 1.6, "epic": 2.3}
const LEGENDARY := ["phoenix_feather", "thorn_crown", "vampire_kiss", "overcharge", "storm_heart", "titan_belt"]

## Every boon, in a fixed order (offers and drafts index into this).
const ALL := ["thick_shell", "spiky_rim", "zoomies", "wall_snack", "overtime_bubble",
	"opening_bite", "bank_shot", "bumper_guard", "sharper_fangs", "prism", "ember_rim",
	"frost_rim", "rebound_bolt", "pinball", "bounce_mine", "payback", "zap_collar",
	"second_wind", "fever"]

## Boons any critter can use (no `for`): the starting picks come from these.
static var GENERAL: Array = ALL.filter(func(id): return not DEFS[id].has("for"))

## Fight-shaping boon fields (b_*), read by MatchSim. Damage ones are shares
## of the holder's bump damage, so they keep up with tier and power.
const MECHANICS := ["b_burn", "b_chill", "b_bolt", "b_pinball", "b_mine", "b_payback", "b_zap",
	"b_wind", "b_fever", "b_storm", "b_fling", "b_bubble"]
## Stacked copies stop adding at these (a slow or stun past them stops the fight being one).
const CAPS := {"b_chill": 0.5, "contact_armor": 0.5}

## Runtime boon fields the sim reads straight off the def (0 = off), MECHANICS included.
const RUNTIME := ["bounce_heal", "first_strike", "bank_bonus", "contact_armor",
	"boon_revive", "thorns", "lifesteal", "overcharge",
	"b_burn", "b_chill", "b_bolt", "b_pinball", "b_mine", "b_payback", "b_zap", "b_wind", "b_fever", "b_storm", "b_fling", "b_bubble"]

static var _cache := {}


## The boon's def, with `rarity` filled in. "id:rare" / "id:epic" scale the
## Common's numbers by SCALE and rewrite its text to match.
static func get_def(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	if GLITCHES.has(id):
		var g: Dictionary = GLITCHES[id].duplicate()
		g.rarity = "glitch"
		_cache[id] = g
		return g
	var base := base_of(id)
	assert(DEFS.has(base), "Unknown boon id: %s" % id)
	var def: Dictionary = DEFS[base].duplicate()
	var rarity := id.get_slice(":", 1) if ":" in id else str(def.get("rarity", "common"))
	assert(rarity in RARITIES, "Unknown boon rarity: %s" % id)
	def.rarity = rarity
	if SCALE.get(rarity, 1.0) != 1.0:
		var k: float = SCALE[rarity]
		for key in ["hp", "damage", "speed"]:
			if def.has(key):
				def[key] = 1.0 + (def[key] - 1.0) * k
		for key in ["bounce_heal", "first_strike", "bank_bonus", "contact_armor", "heal_ratio", "beam_life"] + MECHANICS:
			if def.has(key):
				def[key] = def[key] * k
		if not "{n}" in def.text:
			def.text = describe(def)
	if "{n}" in def.text:
		def.text = _fill(def)
	_cache[id] = def
	return def


static func is_glitch(id: String) -> bool:
	return id.begins_with(GLITCH_PREFIX)


## "thick_shell" for "thick_shell:epic".
static func base_of(id: String) -> String:
	return id.get_slice(":", 0)


static func rarity_of(id: String) -> String:
	return get_def(id).rarity


## The id of `base` at `rarity` (Common has no suffix; Legendary boons are
## their own ids).
static func with_rarity(base: String, rarity: String) -> String:
	return base if rarity in ["common", "legendary"] else "%s:%s" % [base, rarity]


## A seeded rarity roll (one rng draw) using ODDS.
static func roll_rarity(rng) -> String:
	var r: int = rng.range_int(0, 99)
	for i in RARITIES.size():
		r -= ODDS[i]
		if r < 0:
			return RARITIES[i]
	return "common"


## Card text from a boon's numbers (Rare and Epic boons).
static func describe(def: Dictionary) -> String:
	var bits: Array = []
	if def.has("hp"):
		bits.append("+%s%% max HP" % _num((def.hp - 1.0) * 100.0))
	if def.has("damage"):
		bits.append("+%s%% damage" % _num((def.damage - 1.0) * 100.0))
	if def.has("speed"):
		bits.append("+%s%% speed" % _num((def.speed - 1.0) * 100.0))
	if def.has("bounce_heal"):
		bits.append("heal %s HP per wall bounce" % _num(def.bounce_heal))
	if def.has("first_strike"):
		bits.append("first hit +%s" % _num(def.first_strike))
	if def.has("bank_bonus"):
		bits.append("+%s%% damage after a wall bounce" % _num(def.bank_bonus * 100.0))
	if def.has("contact_armor"):
		bits.append("-%s%% bump damage" % _num(def.contact_armor * 100.0))
	if def.has("heal_ratio"):
		bits.append("+%s%% lifesteal" % _num(def.heal_ratio * 100.0))
	if def.has("beam_max"):
		bits.append("+%d beam, beams +%ss" % [def.beam_max, _num(def.beam_life)])
	var text := ", ".join(bits) + "."
	return text[0].to_upper() + text.substr(1)


## A mechanic boon's text with its number in place of {n}.
static func _fill(def: Dictionary) -> String:
	for key in MECHANICS:
		if def.has(key):
			var x: float = def[key]
			return def.text.replace("{n}", _num(x) if key == "b_zap" else _num(x * 100.0))
	return def.text


static func _num(x: float) -> String:
	return str(roundi(x)) if absf(x - roundf(x)) < 0.05 or x >= 10.0 else "%.1f" % x


## True when the boon does something for a ball with this ability.
static func applies_to(id: String, ability: String) -> bool:
	return get_def(id).get("for", ability) == ability


## A copy of a ball def with every boon in `ids` applied. Stat percentages
## add (+6% and +6% HP is +12%), as does everything else, up to CAPS.
static func apply_to_def(def: Dictionary, ids: Array) -> Dictionary:
	var out := def.duplicate()
	for key in RUNTIME: # Gear (sim/gear.gd) may have set some already.
		out[key] = float(def.get(key, 0.0))
	var stat := {"hp": 1.0, "speed": 1.0, "damage": 1.0}
	for id in ids:
		var boon := get_def(id)
		if not applies_to(id, str(def.get("ability", ""))):
			continue
		for key in stat:
			stat[key] += boon.get(key, 1.0) - 1.0
		if boon.has("size"):
			out.radius *= boon.size
		for key in RUNTIME:
			out[key] += boon.get(key, 0.0)
		for key in ["heal_ratio", "beam_life"]:
			if out.has(key):
				out[key] += boon.get(key, 0.0)
		if out.has("beam_max"):
			out.beam_max += int(boon.get("beam_max", 0))
	out.hp *= maxf(0.1, stat.hp)
	out.speed *= maxf(0.1, stat.speed)
	for key in out:
		if String(key).ends_with("_damage"):
			out[key] *= maxf(0.1, stat.damage)
	for key in CAPS:
		out[key] = minf(out[key], CAPS[key])
	return out


## One badge's worth of a stack: the def of `ids` (copies of one boon, any
## rarities) with their numbers added, its text rewritten to the totals, and
## `count` and `rarity` (the best copy's) filled in.
static func stacked(ids: Array) -> Dictionary:
	var best: String = ids[0]
	for id in ids:
		if RARITIES.find(rarity_of(id)) > RARITIES.find(rarity_of(best)):
			best = id
	var def: Dictionary = get_def(best).duplicate()
	def.count = ids.size()
	if ids.size() == 1 or GLITCHES.has(best):
		return def
	var base: Dictionary = DEFS[base_of(best)]
	for key in ["hp", "damage", "speed"]:
		if def.has(key):
			def[key] = 1.0 + ids.reduce(func(t, id): return t + get_def(id)[key] - 1.0, 0.0)
	for key in ["bounce_heal", "first_strike", "bank_bonus", "contact_armor", "heal_ratio", "beam_life", "beam_max"] + MECHANICS:
		if def.has(key):
			def[key] = ids.reduce(func(t, id): return t + get_def(id)[key], 0.0)
	for key in CAPS:
		if def.has(key):
			def[key] = minf(def[key], CAPS[key])
	if def.has("beam_max"):
		def.beam_max = int(def.beam_max)
	def.text = _fill(def.merged({"text": base.text}, true)) if "{n}" in base.text else describe(def)
	return def
