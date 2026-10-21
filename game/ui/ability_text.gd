## A critter's ability as words, for every screen that shows it: one line as it
## is at a tier (fight HUD, detail, pickers), what a tier adds (fuse), and the
## long description (i sheets). Read from the critter files (sim/critters/).
## Callers: const AbilityText := preload("res://game/ui/ability_text.gd").
##
## Data (sim/critters/<id>.gd, checked by CritterDb.validate): tiers[0].text
## is the T1 ability (<= 60 chars); tiers[1..4].text say what that tier adds
## ("Beam 6 → 8/s", "+ Beam sweeps 45°"). A tier's "now" is the whole ability
## from that tier up in one line; "{key}" in it shows the param at that tier
## and "{key%}" shows it as a percent (0.2 → 20). The T5 "special" is its name.

const CritterDb := preload("res://sim/critter_db.gd")


## The ability as it is at `tier`, with that tier's numbers, in one line.
static func now(id: String, tier: int) -> String:
	if not CritterDb.has(id):
		return ""
	var c := CritterDb.get_critter(id)
	var tiers: Array = c.tiers
	var t := clampi(tier, 1, tiers.size())
	var line := str(tiers[0].get("now", tiers[0].text))
	var params: Dictionary = c.params.duplicate()
	for i in t:
		for key in tiers[i]:
			if params.has(key):
				params[key] = tiers[i][key]
		if i > 0 and tiers[i].has("now"):
			line = str(tiers[i].now)
	return CritterDb.fill(line, params)


## What reaching `tier` adds: "Beam 6 → 8/s" or "+ Beam sweeps 45°".
## Tier 1 is the ability itself (now(id, 1)).
static func change(id: String, tier: int) -> String:
	if not CritterDb.has(id):
		return ""
	if tier <= 1:
		return now(id, 1)
	var tiers: Array = CritterDb.get_critter(id).tiers
	return str(tiers[clampi(tier, 1, tiers.size()) - 1].text)


## The longer description for the i sheets, without the leading "Type." (the
## type shows next to it on every screen).
static func full(id: String) -> String:
	if not CritterDb.has(id):
		return ""
	var d := str(CritterDb.get_critter(id).description)
	var cut := d.find(". ")
	return d.substr(cut + 2) if cut >= 0 and cut < 24 else d


## The T5 signature's name ("Honey Pot"), or "" when it has none.
static func special(id: String) -> String:
	if not CritterDb.has(id):
		return ""
	var tiers: Array = CritterDb.get_critter(id).tiers
	return str(tiers[tiers.size() - 1].get("special", "")) if not tiers.is_empty() else ""
