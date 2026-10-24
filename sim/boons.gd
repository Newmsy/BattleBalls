## Bounce Run boons: run-only perks. Pure data plus a helper that folds a list
## of boons into a ball def, so the sim reads them like any other stat and the
## same config still gives the same fight. Boons never touch permanent
## progression. Each one is checked by tools/boon_balance.gd: holding it at
## equal power must win 52-62% (a tilt, BALANCE.md rule 2), never more.
##
## Fields (all optional; several boons of the same kind add up):
##   hp, damage, speed      multipliers on base stats (damage scales contact
##                          damage and every *_damage stat)
##   bounce_heal            HP healed on every wall bounce
##   overtime_shield        shield HP granted when overtime starts
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
##                          wall-bounce sparks and mines, Second Wind, Fever
##
## Rarity: an offered boon rolls a rarity (roll_rarity). "id" is Common;
## "id:rare" and "id:epic" are the same boon with bigger numbers (SCALE).
## Legendary boons are their own ids (LEGENDARY), each with an effect no
## other boon has.
extends RefCounted

const DEFS := {
	"thick_shell": {
		"name": "Thick Shell",
		"text": "+7% max HP.",
		"icon": "shield",
		"hp": 1.07,
	},
	"spiky_rim": {
		"name": "Spiky Rim",
		"text": "+6% damage.",
		"icon": "spike",
		"damage": 1.06,
	},
	"zoomies": {
		"name": "Zoomies",
		"text": "Move 8% faster.",
		"icon": "bolt",
		"speed": 1.08,
	},
	"wall_snack": {
		"name": "Wall Snack",
		"text": "Heal 0.4 HP per wall bounce.",
		"icon": "heart",
		"bounce_heal": 0.4,
	},
	"overtime_bubble": {
		"name": "Overtime Bubble",
		"text": "20 HP shield in overtime.",
		"icon": "bubble",
		"overtime_shield": 20.0,
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
		"b_bolt": 0.08,
	},
	"pinball": {
		"name": "Pinball",
		"text": "Bump a foe into a wall: it takes {n}% of a bump more.",
		"icon": "pinball",
		"b_pinball": 0.2,
	},
	"bounce_mine": {
		"name": "Bounce Mine",
		"text": "Every 3rd wall bounce drops a mine: {n}% of a bump.",
		"icon": "mine",
		"b_mine": 0.3,
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
		"name": "Overtime Fever",
		"text": "In overtime, grow big and bump {n}% harder.",
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
		"text": "Revive once at 35% HP.",
		"icon": "feather",
		"rarity": "legendary",
		"boon_revive": 0.35,
	},
	"thorn_crown": {
		"name": "Thorn Crown",
		"text": "Reflect 35% of bump damage.",
		"icon": "thorns",
		"rarity": "legendary",
		"thorns": 0.35,
	},
	"vampire_kiss": {
		"name": "Vampire Kiss",
		"text": "Heal 20% of bump damage dealt.",
		"icon": "drop",
		"rarity": "legendary",
		"lifesteal": 0.2,
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
	"glitch_chilled": {"name": "Chilled", "text": "Move 5% slower.", "icon": "bolt", "speed": 0.95},
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
	"b_wind", "b_fever", "b_storm", "b_fling"]

## Runtime boon fields the sim reads straight off the def (0 = off), MECHANICS included.
const RUNTIME := ["bounce_heal", "overtime_shield", "first_strike", "bank_bonus", "contact_armor",
	"boon_revive", "thorns", "lifesteal", "overcharge",
	"b_burn", "b_chill", "b_bolt", "b_pinball", "b_mine", "b_payback", "b_zap", "b_wind", "b_fever", "b_storm", "b_fling"]

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
		for key in ["bounce_heal", "overtime_shield", "first_strike", "bank_bonus", "contact_armor", "heal_ratio", "beam_life"] + MECHANICS:
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
	if def.has("overtime_shield"):
		bits.append("%s HP shield in overtime" % _num(def.overtime_shield))
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


## A copy of a ball def with every boon in `ids` applied. Multipliers stack
## multiplicatively, everything else adds.
static func apply_to_def(def: Dictionary, ids: Array) -> Dictionary:
	var out := def.duplicate()
	for key in RUNTIME: # Gear (sim/gear.gd) may have set some already.
		out[key] = float(def.get(key, 0.0))
	for id in ids:
		var boon := get_def(id)
		if not applies_to(id, str(def.get("ability", ""))):
			continue
		out.hp *= boon.get("hp", 1.0)
		if boon.has("size"):
			out.radius *= boon.size
		out.speed *= boon.get("speed", 1.0)
		var damage: float = boon.get("damage", 1.0)
		for key in out:
			if String(key).ends_with("_damage"):
				out[key] *= damage
		for key in RUNTIME:
			out[key] += boon.get(key, 0.0)
		for key in ["heal_ratio", "beam_life"]:
			if out.has(key):
				out[key] += boon.get(key, 0.0)
		if out.has("beam_max"):
			out.beam_max += int(boon.get("beam_max", 0))
	out.contact_armor = minf(out.contact_armor, 0.5)
	return out
