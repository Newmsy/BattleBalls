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
		"text": "Heal 0.4 HP every time you bounce off a wall.",
		"icon": "heart",
		"bounce_heal": 0.4,
	},
	"overtime_bubble": {
		"name": "Overtime Bubble",
		"text": "A 20 HP bubble shield pops on when overtime starts.",
		"icon": "bubble",
		"overtime_shield": 20.0,
	},
	"opening_bite": {
		"name": "Opening Bite",
		"text": "Your first hit of every fight deals +7 damage.",
		"icon": "fang",
		"first_strike": 7.0,
	},
	"bank_shot": {
		"name": "Bank Shot",
		"text": "After a wall bounce, your next hit deals +8%.",
		"icon": "bank",
		"bank_bonus": 0.08,
	},
	"bumper_guard": {
		"name": "Bumper Guard",
		"text": "Take 7% less damage from bumps.",
		"icon": "guard",
		"contact_armor": 0.07,
	},
	"sharper_fangs": {
		"name": "Sharper Fangs",
		"text": "Vampires heal 6% more of the damage they deal.",
		"icon": "fang",
		"for": "vampire",
		"heal_ratio": 0.06,
	},
	"prism": {
		"name": "Prism",
		"text": "Lasers keep 1 more beam up, and beams last 0.5s longer.",
		"icon": "beam",
		"for": "laser",
		"beam_max": 1,
		"beam_life": 0.5,
	},
}

## Every boon, in a fixed order (offers and drafts index into this).
const ALL := ["thick_shell", "spiky_rim", "zoomies", "wall_snack", "overtime_bubble",
	"opening_bite", "bank_shot", "bumper_guard", "sharper_fangs", "prism"]

## Runtime boon fields the sim reads straight off the def (0 = off).
const RUNTIME := ["bounce_heal", "overtime_shield", "first_strike", "bank_bonus", "contact_armor"]


static func get_def(id: String) -> Dictionary:
	assert(DEFS.has(id), "Unknown boon id: %s" % id)
	return DEFS[id]


## True when the boon does something for a ball with this ability.
static func applies_to(id: String, ability: String) -> bool:
	return get_def(id).get("for", ability) == ability


## A copy of a ball def with every boon in `ids` applied. Multipliers stack
## multiplicatively, everything else adds.
static func apply_to_def(def: Dictionary, ids: Array) -> Dictionary:
	var out := def.duplicate()
	for key in RUNTIME:
		out[key] = 0.0
	for id in ids:
		var boon := get_def(id)
		if not applies_to(id, str(def.get("ability", ""))):
			continue
		out.hp *= boon.get("hp", 1.0)
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
