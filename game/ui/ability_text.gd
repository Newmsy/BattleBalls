## A critter's ability as words, for every screen that shows it: one line as it
## is at a tier (fight HUD, detail, pickers), what a tier adds (fuse), and the
## long description (i sheets). Read from the critter files (sim/critters/).
## Callers: const AbilityText := preload("res://game/ui/ability_text.gd").
##
## Data (sim/critters/<id>.gd, checked by CritterDb.validate): tiers[0].text
## is the T1 ability (<= 60 chars); tiers[1..4].text say what that tier adds
## ("Beam {^lamp_dps} → {lamp_dps}/sec", "+ Beam sweeps 45°"). A tier's "now"
## is the whole ability from that tier up in one line. Placeholders
## (CritterDb.fill) show the numbers it fights with at that tier and level
## (CritterDb.fight_def; level 1 and no gear unless a screen knows better), so
## every screen's numbers are the real ones. The T5 "special" is its name.

const CritterDb := preload("res://sim/critter_db.gd")


## The ability as it is at `tier`, with that tier's numbers, in one line.
## `def` fills it from a fighting ball's own def instead (gear, boons...).
static func now(id: String, tier: int, level := 1, def := {}) -> String:
	if not CritterDb.has(id):
		return ""
	var tiers: Array = CritterDb.get_critter(id).tiers
	var t := clampi(tier, 1, tiers.size())
	var line := str(tiers[0].get("now", tiers[0].text))
	for i in range(1, t):
		if tiers[i].has("now"):
			line = str(tiers[i].now)
	return CritterDb.fill(line, def if not def.is_empty() else CritterDb.fight_def(id, t, level))


## What reaching `tier` adds: "Beam 5 → 7/sec" or "+ Beam sweeps 45°".
## Tier 1 is the ability itself (now(id, 1)).
static func change(id: String, tier: int, level := 1) -> String:
	if not CritterDb.has(id):
		return ""
	if tier <= 1:
		return now(id, 1, level)
	var tiers: Array = CritterDb.get_critter(id).tiers
	var t := clampi(tier, 1, tiers.size())
	return CritterDb.fill(str(tiers[t - 1].text), CritterDb.fight_def(id, t, level), CritterDb.fight_def(id, t - 1, level))


## The longer description for the i sheets, without the leading "Type." (the
## type shows next to it on every screen), with T1 numbers.
static func full(id: String) -> String:
	if not CritterDb.has(id):
		return ""
	var d := CritterDb.fill(str(CritterDb.get_critter(id).description), CritterDb.fight_def(id, 1))
	var cut := d.find(". ")
	return d.substr(cut + 2) if cut >= 0 and cut < 24 else d


## What every tier adds on top of its own line, for ability ladders.
const EVERY_TIER := "Every tier also raises its HP, damage and ability power."


## The T5 signature's name ("Honey Pot"), or "" when it has none.
static func special(id: String) -> String:
	if not CritterDb.has(id):
		return ""
	var tiers: Array = CritterDb.get_critter(id).tiers
	return str(tiers[tiers.size() - 1].get("special", "")) if not tiers.is_empty() else ""
