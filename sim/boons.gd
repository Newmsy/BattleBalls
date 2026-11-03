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
##   Critter boons (one per critter, from the "boon" key of its file in
##   sim/critters/, see CRITTER_KEYS): only that critter (`for`) gets them.
##   add                    {param: amount} added to the critter's ability
##                          params (whole numbers stay whole)
##   mul                    {param: factor} multiplies them (several add up
##                          like stat percentages)
##   Stacked copies add their gains, but a cut (negative add, or a factor
##   under 1, like "trains 40% more often") counts once: piling up trigger
##   rate made Choo's trains crowd each other out.
##   ability                ability entries the critter gains, if it lacks them
##                          (most unlock its T5 trick early)
##   Text placeholders: {+key} the add amount, {+key%} it as a percentage,
##   {%key} the mul as a percentage change.
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

const CritterDb := preload("res://sim/critter_db.gd")

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

## Boons any critter can use, in a fixed order (offers and drafts index into this).
const BASE := ["thick_shell", "spiky_rim", "zoomies", "wall_snack", "overtime_bubble",
	"opening_bite", "bank_shot", "bumper_guard", "ember_rim",
	"frost_rim", "rebound_bolt", "pinball", "bounce_mine", "payback", "zap_collar",
	"second_wind", "fever"]
## A critter boon's keys in its critter file ("boon"). Its numbers are its
## Epic numbers: critter boons only ever come as Epic. "id" is optional
## (default "c_<critter>"); "proof" names what tests/test_critter_boons.gd
## measures to show it changes the fight.
const CRITTER_KEYS := ["id", "name", "text", "add", "mul", "ability", "proof"]

## Critter boons by id, built from the critter files.
static var CRITTER := _critter_boons()
## Every boon, in a fixed order: the general ones, then one per critter in
## Critterpedia order.
static var ALL: Array = BASE + CRITTER.keys()

## Boons any critter can use (no `for`): the starting picks come from these.
static var GENERAL: Array = BASE.duplicate()

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


static func _critter_boons() -> Dictionary:
	var out := {}
	for cid in CritterDb.live_ids():
		var c := CritterDb.get_critter(cid)
		if not c.has("boon"):
			continue
		var b: Dictionary = c.boon.duplicate(true)
		var id: String = b.get("id", "c_" + cid)
		b.erase("id")
		b["for"] = cid
		b["icon"] = "critter:" + cid
		out[id] = b
	return out


## The base def of a boon id without its rarity: general, Legendary or critter.
static func _base_def(base: String) -> Dictionary:
	return DEFS[base] if DEFS.has(base) else CRITTER.get(base, {})


## The id of `critter`'s own boon, or "" when it has none.
static func for_critter(critter: String) -> String:
	for id in CRITTER:
		if CRITTER[id]["for"] == critter:
			return id
	return ""


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
	assert(DEFS.has(base) or CRITTER.has(base), "Unknown boon id: %s" % id)
	var def: Dictionary = _base_def(base).duplicate(true)
	var rarity := id.get_slice(":", 1) if ":" in id else str(def.get("rarity", "common"))
	if CRITTER.has(base): # Critter boons are always Epic (Newms: Epic+ strength, they help one critter).
		rarity = "epic"
		def.erase("rarity")
	assert(rarity in RARITIES, "Unknown boon rarity: %s" % id)
	def.rarity = rarity
	if SCALE.get(rarity, 1.0) != 1.0 and not CRITTER.has(base):
		var k: float = SCALE[rarity]
		for key in ["hp", "damage", "speed"]:
			if def.has(key):
				def[key] = 1.0 + (def[key] - 1.0) * k
		for key in ["bounce_heal", "first_strike", "bank_bonus", "contact_armor"] + MECHANICS:
			if def.has(key):
				def[key] = def[key] * k
		if not "{" in def.text:
			def.text = describe(def)
	if "{" in def.text:
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
	return base if rarity in ["common", "legendary"] or CRITTER.has(base) else "%s:%s" % [base, rarity]


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
	var text := ", ".join(bits) + "."
	return text[0].to_upper() + text.substr(1)


## A boon's text with its numbers in place: {n} for a mechanic boon, and a
## critter boon's {+key}, {+key%} and {%key}.
static func _fill(def: Dictionary) -> String:
	if def.has("add") or def.has("mul"):
		var t: String = def.text
		for key in def.get("add", {}):
			var v = def.add[key]
			t = t.replace("{+%s%%}" % key, _num(float(v) * 100.0)).replace("{+%s}" % key, str(v) if v is int else _num(v))
			t = t.replace("{s:%s}" % key, "" if float(v) == 1.0 else "s") # "1 more beam", "2 more beams"
		for key in def.get("mul", {}):
			t = t.replace("{%%%s}" % key, _num(absf(def.mul[key] - 1.0) * 100.0))
		return t
	for key in MECHANICS:
		if def.has(key):
			var x: float = def[key]
			return def.text.replace("{n}", _num(x) if key == "b_zap" else _num(x * 100.0))
	return def.text


static func _num(x: float) -> String:
	if absf(x - roundf(x)) < 0.05 or x >= 10.0:
		return str(roundi(x))
	return ("%.2f" % x).trim_suffix("0") if absf(x * 10.0 - roundf(x * 10.0)) > 0.04 else "%.1f" % x


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
	var mul := {}
	var fast := {}
	var cut := {}
	for id in ids:
		var boon: Dictionary = id if id is Dictionary else get_def(id) # A Dictionary: an Ascension (ascended()).
		if boon.get("for", def.get("ability", "")) != def.get("ability", ""):
			continue
		for key in stat:
			stat[key] += boon.get(key, 1.0) - 1.0
		if boon.has("size"):
			out.radius *= boon.size
		for key in RUNTIME:
			out[key] += boon.get(key, 0.0)
		for key in boon.get("add", {}):
			var v = boon.add[key]
			if v < 0: # A faster cooldown or a shorter count: the best one counts, never stacks.
				cut[key] = mini(cut.get(key, 0), v) if v is int else minf(cut.get(key, 0.0), v)
			else:
				out[key] = out.get(key, 0) + v if out.get(key, 0) is int and v is int else float(out.get(key, 0.0)) + float(v)
		for key in boon.get("mul", {}):
			var f: float = boon.mul[key]
			if f < 1.0: # Likewise "more often": copies stack strength, not trigger rate.
				fast[key] = minf(fast.get(key, 1.0), f)
			else:
				mul[key] = mul.get(key, 1.0) + f - 1.0
		for e in boon.get("ability", []):
			if not out.get("effects", []).has(e):
				out.effects = out.get("effects", []) + [e]
	for key in cut: # Never down to 0 (an "every 0th bounce" would divide by zero).
		var was = out.get(key, 0)
		if was is int and cut[key] is int:
			out[key] = maxi(mini(was, 1), was + cut[key])
		else:
			out[key] = maxf(float(was) * 0.25, float(was) + float(cut[key]))
	for key in fast:
		mul[key] = mul.get(key, 1.0) * fast[key]
	for key in mul:
		if out.has(key):
			out[key] = out[key] * maxf(0.2, mul[key])
	out.hp *= maxf(0.1, stat.hp)
	out.speed *= maxf(0.1, stat.speed)
	for key in out:
		if String(key).ends_with("_damage"):
			out[key] *= maxf(0.1, stat.damage)
	for key in CAPS:
		out[key] = minf(out[key], CAPS[key])
	return out


## Ascension (Newms 2026-11-02): a T5 critter's own boon, kept for good at
## ASCEND_SHARE of its Bounce Run strength per level (A1-A5), in every fight
## its lineup slot plays. Gains scale with the level; a cut ("more often", a
## shorter count) scales too but never past the boon's own, like stacking.
const ASCEND_SHARE := 0.5
const ASCEND_MAX := 5

## The def of `critter`'s boon at Ascension `level` (0 or no boon: {}).
## apply_to_def takes it in place of an id.
static func ascended(critter: String, level: int) -> Dictionary:
	var id := for_critter(critter)
	level = clampi(level, 0, ASCEND_MAX)
	if id == "" or level == 0:
		return {}
	var k := ASCEND_SHARE * level
	var cut_k := minf(1.0, k)
	var def: Dictionary = _base_def(id).duplicate(true)
	def.rarity = "ascended"
	def.level = level
	var add := {}
	for key in def.get("add", {}):
		var v = def.add[key]
		var f := k if v >= 0 else cut_k
		if v is int:
			add[key] = signi(v) * maxi(1, roundi(absi(v) * f))
		else:
			add[key] = float(v) * f
	if def.has("add"):
		def.add = add
	var mul := {}
	for key in def.get("mul", {}):
		var m: float = def.mul[key]
		mul[key] = 1.0 + (m - 1.0) * (k if m >= 1.0 else cut_k)
	if def.has("mul"):
		def.mul = mul
	if "{" in def.text:
		def.text = _fill(def)
	return def


## One badge's worth of a stack: the def of `ids` (copies of one boon, any
## rarities) with their numbers added, its text rewritten to the totals, and
## `count` and `rarity` (the best copy's) filled in.
static func stacked(ids: Array) -> Dictionary:
	var best: String = ids[0]
	for id in ids:
		if RARITIES.find(rarity_of(id)) > RARITIES.find(rarity_of(best)):
			best = id
	var def: Dictionary = get_def(best).duplicate(true)
	def.count = ids.size()
	if ids.size() == 1 or GLITCHES.has(best):
		return def
	var base: Dictionary = _base_def(base_of(best))
	for key in ["hp", "damage", "speed"]:
		if def.has(key):
			def[key] = 1.0 + ids.reduce(func(t, id): return t + get_def(id)[key] - 1.0, 0.0)
	for key in ["bounce_heal", "first_strike", "bank_bonus", "contact_armor"] + MECHANICS:
		if def.has(key):
			def[key] = ids.reduce(func(t, id): return t + get_def(id)[key], 0.0)
	for key in def.get("add", {}):
		if def.add[key] >= 0: # Cuts (negative) count once, as in apply_to_def.
			def.add[key] = ids.reduce(func(t, id): return t + get_def(id).add[key], 0 if def.add[key] is int else 0.0)
	for key in def.get("mul", {}):
		if def.mul[key] >= 1.0: # "More often" counts once too.
			def.mul[key] = 1.0 + ids.reduce(func(t, id): return t + get_def(id).mul[key] - 1.0, 0.0)
	for key in CAPS:
		if def.has(key):
			def[key] = minf(def[key], CAPS[key])
	if "{" in base.text:
		def.text = _fill(def.merged({"text": base.text}, true))
	elif not def.has("for"):
		def.text = describe(def)
	return def
