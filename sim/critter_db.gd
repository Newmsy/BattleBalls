## Every critter, read from its own file in sim/critters/<id>.gd. This is the
## one place the sim, menus, art, sound, summons and tests learn what critters
## exist: adding a file adds the critter everywhere. "Adding a critter" in
## README.md documents the keys; validate() enforces them.
extends RefCounted

const Abilities := preload("res://sim/abilities.gd")
const Modifiers := preload("res://sim/modifiers.gd")
const Arenas := preload("res://sim/arenas.gd")
const Power := preload("res://sim/power.gd")
const DMath := preload("res://sim/dmath.gd")

const DIR := "res://sim/critters/"
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const ROLES := ["Bruiser", "Zoner", "Skirmisher", "Disruptor", "Baseline"]
## live: fights in the sim and is offered to players. planned: shown in the
## collection (art, ladder) but its ability isn't built yet. baseline: Plain.
const STATUSES := ["live", "planned", "baseline"]
const REQUIRED := ["no", "name", "type", "rarity", "role", "status", "color", "vibe", "description", "stats", "ability", "params", "tiers", "art", "sound"]
const STATS := ["hp", "radius", "speed", "contact_damage"]
const TIERS := 5
## Tier keys that are words for players, not params (game/ui/ability_text.gd):
## "text" (T1: the ability, T2-T5: what the tier adds), "now" (the whole ability
## from that tier up, with "{param}"/"{param%}" filled in) and "special" (T5 name).
const TEXT_KEYS := ["text", "now", "special"]
const TEXT_MAX := 60 ## T1 text and every tier's "now" line, once filled in.
const CHANGE_MAX := 50 ## T2-T5 text.
const ABILITY_TIER_STEP := 0.25 ## Ability damage, burn, heal and shield per tier above T1 (T5 = x2).
const RADIUS_TIER_STEP := 0.06 ## Ability reach per tier above T1 (T5 = +24%).
## Damage multipliers of special hits; their bonus over x1 grows like damage.
const HIT_MULTS := ["ambush_mult", "chomp_mult", "gear_slam_mult", "honey_crush", "lance_hit_mult", "marked_mult", "ping_hit_mult", "shatter_mult", "snap_mult", "wind_crit"]

static var _critters := {}
static var _ids: Array = []


## Every critter id (Plain included), in Critterpedia number order.
static func ids() -> Array:
	_load()
	return _ids


## Critters that fight in the sim and are offered to players, by number.
static func live_ids() -> Array:
	return ids().filter(func(id): return _critters[id].status == "live")


## Everything the sim can fight with: live critters plus the Plain baseline.
static func sim_ids() -> Array:
	return ids().filter(func(id): return _critters[id].status != "planned")


static func has(id: String) -> bool:
	_load()
	return _critters.has(id)


## The critter's file contents, plus "id".
static func get_critter(id: String) -> Dictionary:
	_load()
	assert(_critters.has(id), "Unknown critter: %s" % id)
	return _critters.get(id, {})


## The flat definition the fight sim reads: stats, then ability params with the
## tier upgrades up to `tier` applied, plus the bits the renderer needs.
## `bonus_tiers` adds ability potency and reach as if the critter were that
## many tiers higher, without its tier upgrades: rarity's tier per step
## (Power.rarity_tiers), which MatchSim adds to every fight.
static func sim_def(id: String, tier := 1, bonus_tiers := 0.0) -> Dictionary:
	var c := get_critter(id)
	var def := {
		"id": id,
		"ability": id,
		"effects": c.ability,
		"display_name": c.name,
		"description": c.description,
		"rarity": c.rarity,
		"color": Color(c.color),
		"badge_top": c.art.get("badge_top", 1.15),
		"ouch": c.sound.get("ouch", ""),
		"voice_pitch": c.sound.get("pitch", 1.0),
		"chaos": c.get("chaos", {}),
		## Fight power per rarity step on top of Power (MatchSim, real fights
		## only): evens out kits that gain more or less than most from rarity's
		## ability potency (tools/rarity_critters.gd).
		"rarity_power": float(c.get("rarity_power", 1.0)),
		## Fight power at this tier on top of that (MatchSim, real fights
		## only): evens a kit out against its own rarity at each tier, for
		## kits whose tier upgrades land bigger or smaller than most
		## (tools/round_robin.gd --same).
		"tier_power": float(c.get("tier_power", [1.0, 1.0, 1.0, 1.0, 1.0])[clampi(tier, 1, TIERS) - 1]),
		"tier": clampi(tier, 1, TIERS), ## So the renderer can draw a stronger ability bigger.
	}
	def.merge(c.stats, true)
	def.merge(c.params, true)
	var effects: Array = c.ability.duplicate()
	for t in clampi(tier, 1, TIERS):
		for key in c.tiers[t]:
			if key == "ability":
				effects.append_array(c.tiers[t].ability) # A tier can add new behaviour.
			elif not key in TEXT_KEYS:
				def[key] = c.tiers[t][key]
	def.effects = effects
	# Every tier above T1 also makes the ability hit harder, on top of its own
	# upgrades, so a T5 ability clearly outclasses a T1 one (Newms: ~95% at
	# equal stats). Contact damage and HP stay with Power.scale_def.
	var steps := float(clampi(tier, 1, TIERS) - 1) + bonus_tiers
	var potency := 1.0 + ABILITY_TIER_STEP * steps
	if potency != 1.0:
		for key in def.keys():
			var k := String(key)
			if k == "contact_damage" or not (def[key] is float or def[key] is int):
				continue
			if k.ends_with("_damage") or k.ends_with("_dps") or k.ends_with("_burn") or k.ends_with("_shield") or k.ends_with("_hps"):
				def[key] = def[key] * potency
			elif k in HIT_MULTS and def[key] > 1.0: # Only the bonus part grows.
				def[key] = 1.0 + (def[key] - 1.0) * potency
			elif k.ends_with("_radius") and def[key] > 1.0: # Bigger, so a T5 also looks stronger.
				def[key] = def[key] * (1.0 + RADIUS_TIER_STEP * steps)
	return def


## Problems with one critter file, as readable strings; empty when it's fine.
static func validate(id: String, c: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key in REQUIRED:
		if not c.has(key):
			errors.append("%s: missing \"%s\"" % [id, key])
	if not errors.is_empty():
		return errors
	if not id.is_valid_identifier() or id != id.to_lower():
		errors.append("%s: file name must be a lowercase snake_case id" % id)
	if c.has("tier_power") and (not c.tier_power is Array or c.tier_power.size() != TIERS or c.tier_power.any(func(x): return not (x is float or x is int) or x <= 0.0)):
		errors.append("%s: tier_power must be %d positive numbers, one per tier" % [id, TIERS])
	if not c.rarity in RARITIES:
		errors.append("%s: rarity \"%s\" is not one of %s" % [id, c.rarity, RARITIES])
	if not c.role in ROLES:
		errors.append("%s: role \"%s\" is not one of %s" % [id, c.role, ROLES])
	if not c.status in STATUSES:
		errors.append("%s: status \"%s\" is not one of %s" % [id, c.status, STATUSES])
	if not Color.html_is_valid(c.color):
		errors.append("%s: color \"%s\" is not a hex colour" % [id, c.color])
	for s in STATS:
		if not (c.stats.get(s) is float or c.stats.get(s) is int) or float(c.stats.get(s)) <= 0.0:
			errors.append("%s: stats.%s must be a positive number" % [id, s])
	if c.tiers.size() != TIERS:
		errors.append("%s: needs exactly %d tiers (T1 to T5)" % [id, TIERS])
	for t in c.tiers.size():
		if str(c.tiers[t].get("text", "")) == "":
			errors.append("%s: tier %d has no text" % [id, t + 1])
		for key in c.tiers[t]:
			if not key in TEXT_KEYS and key != "ability" and not c.params.has(key):
				errors.append("%s: tier %d changes \"%s\", which isn't in params" % [id, t + 1, key])
	if c.status != "baseline" and c.tiers.size() == TIERS:
		errors.append_array(_validate_text(id, c))
	for mod in c.get("chaos", {}):
		if not (Modifiers.DEFS.has(mod) or Arenas.DEFS.has(mod)):
			errors.append("%s: chaos names unknown modifier or arena \"%s\"" % [id, mod])
			continue
		for key in c.chaos[mod]:
			if not (c.stats.has(key) or c.params.has(key)):
				errors.append("%s: chaos.%s changes \"%s\", which isn't in stats or params" % [id, mod, key])
	if c.status == "live":
		var all: Array = c.ability.duplicate()
		for t in c.tiers:
			all.append_array(t.get("ability", []))
		errors.append_array(Abilities.validate(id, all, c.params))
	return errors


## Ability text rules (README "Adding a critter"): T1 and every "now" line fit
## TEXT_MAX once filled in, and every placeholder names a param; T2-T5 fit
## CHANGE_MAX; arrows are "→"; rates are "/sec", not "/s"; a T1 "now" fills in
## to exactly the T1 text, so the T1 numbers match the params. Lengths are
## checked with the file's own numbers (screens show the sim's, see fill()).
static func _validate_text(id: String, c: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var params: Dictionary = c.params.duplicate()
	var prev: Dictionary = params.duplicate()
	var line := str(c.tiers[0].get("now", c.tiers[0].text))
	var re := RegEx.create_from_string("\\{[\\^+]?([a-z_0-9]+)%?\\}")
	var rate := RegEx.create_from_string("[0-9}]( HP)?/s\\b")
	var texts := {"description": str(c.description)}
	for t in TIERS:
		var tier: Dictionary = c.tiers[t]
		prev = params.duplicate()
		for key in tier:
			if params.has(key):
				params[key] = tier[key]
		var text := str(tier.get("text", ""))
		texts["tier %d text" % (t + 1)] = text
		if "->" in text:
			errors.append("%s: tier %d text uses \"->\"; use \"→\"" % [id, t + 1])
		if t > 0 and fill(text, params, prev).length() > CHANGE_MAX:
			errors.append("%s: tier %d text is over %d characters" % [id, t + 1, CHANGE_MAX])
		if tier.has("now"):
			line = str(tier.now)
			texts["tier %d now" % (t + 1)] = line
		var now := fill(line, params)
		if now.length() > TEXT_MAX:
			errors.append("%s: tier %d ability line is over %d characters: %s" % [id, t + 1, TEXT_MAX, now])
		if t == 0 and tier.has("now") and now != fill(text, params):
			errors.append("%s: T1 \"now\" fills in to \"%s\", not the T1 text" % [id, now])
	for where in texts:
		for m in re.search_all(texts[where]):
			if not c.params.has(m.get_string(1)):
				errors.append("%s: %s names \"%s\", which isn't in params" % [id, where, m.get_string(1)])
		if rate.search(texts[where]) != null:
			errors.append("%s: %s writes a rate as \"/s\"; write \"/sec\" (players read /s as per stack)" % [id, where])
	return errors


## A critter as it fights at `tier` and `level` with no gear or talents: what
## MatchSim builds for a Lineup slot (sim_def with rarity's ability tiers,
## scaled by Power, its rarity_power and tier_power). Ability text is filled from this, so
## the numbers on screen are the ones that fight.
static func fight_def(id: String, tier: int, level := 1) -> Dictionary:
	var c := get_critter(id)
	var steps := maxi(0, RARITIES.find(str(c.rarity)))
	var power := Power.multiplier(str(c.rarity), tier, level) * DMath.ipow(float(c.get("rarity_power", 1.0)), steps)
	power *= float(c.get("tier_power", [1.0, 1.0, 1.0, 1.0, 1.0])[clampi(tier, 1, TIERS) - 1])
	return Power.scale_def(sim_def(id, tier, Power.rarity_tiers(str(c.rarity))), power)


## `line` with its placeholders filled in from `params`: "{key}" is the param,
## "{key%}" the param as a percent (0.2 → 20), "{^key}" / "{^key%}" the same
## from `prev` (the tier before, for "old → new") and "{+key}" how much it
## grew since `prev`, in percent (70 → 90 is 29). Numbers show as players read
## them (shown()). Unknown keys stay as written.
static func fill(line: String, params: Dictionary, prev := {}) -> String:
	var out := ""
	var i := 0
	while i < line.length():
		var open := line.find("{", i)
		var close := line.find("}", open) if open >= 0 else -1
		if close < 0:
			break
		var key := line.substr(open + 1, close - open - 1)
		var pct := key.ends_with("%")
		key = key.trim_suffix("%")
		var src := params
		var grow := false
		if key.begins_with("^"):
			key = key.substr(1)
			src = prev
		elif key.begins_with("+"):
			key = key.substr(1)
			grow = true
		out += line.substr(i, open - i)
		if grow and params.has(key) and float(prev.get(key, 0.0)) != 0.0:
			out += str(roundi((float(params[key]) / float(prev[key]) - 1.0) * 100.0))
		elif not grow and src.has(key) and (src[key] is float or src[key] is int):
			out += shown(float(src[key]) * (100.0 if pct else 1.0))
		else:
			out += line.substr(open, close - open + 1)
		i = close + 1
	return out + line.substr(i)


## A number as ability text shows it: whole from 10 up, else to one decimal
## (6.0 → "6", 5.625 → "5.6", 37.5 → "38").
static func shown(v: float) -> String:
	return num(roundf(v) if absf(v) >= 10.0 else roundf(v * 10.0) / 10.0)


## 6.0 → "6", 6.5 → "6.5", 0.25 → "0.25".
static func num(v: float) -> String:
	if absf(v - roundf(v)) < 0.000001:
		return str(int(roundf(v)))
	return String.num(v, 2)


static func _load() -> void:
	if not _ids.is_empty():
		return
	for file in DirAccess.get_files_at(DIR):
		# Exported builds list scripts as .gd.remap (and the compiled .gdc).
		file = file.trim_suffix(".remap")
		if not file.ends_with(".gd") or file.begins_with("_"):
			continue
		var id := file.get_basename()
		var c: Dictionary = load(DIR + file).CRITTER.duplicate(true)
		c.id = id
		_critters[id] = c
	_ids = _critters.keys()
	_ids.sort_custom(func(a, b): return _critters[a].no < _critters[b].no)
