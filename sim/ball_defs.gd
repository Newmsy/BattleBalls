## Static definitions for every ball type. Pure data: the sim reads these,
## the renderer reads `color` and `display_name`.
extends RefCounted

const DEFS := {
	"vampire": {
		"display_name": "Vampire",
		"description": "Heals for half the damage it deals on hit.",
		"hp": 100.0,
		"radius": 68.0,
		"speed": 400.0,
		"contact_damage": 16.0,
		"ability": "vampire",
		"heal_ratio": 0.5,
		"color": Color(0.85, 0.15, 0.25),
	},
	"laser": {
		"display_name": "Laser",
		"description": "Every wall bounce fires a beam back to its last bounce point.",
		"hp": 100.0,
		"radius": 58.0,
		"speed": 420.0,
		"contact_damage": 4.0,
		"ability": "laser",
		"beam_life": 3.0,
		"beam_damage": 7.0,
		"beam_hit_cooldown": 0.5,
		"beam_max": 6,
		"color": Color(0.2, 0.85, 1.0),
	},
	# Ability-free baseline used by tests and as a balance reference.
	"plain": {
		"display_name": "Plain",
		"description": "No ability. A baseline ball.",
		"hp": 100.0,
		"radius": 64.0,
		"speed": 400.0,
		"contact_damage": 10.0,
		"ability": "",
		"color": Color(0.75, 0.75, 0.8),
	},
}

## Balls offered in the in-game picker.
const PLAYABLE := ["vampire", "laser"]


static func get_def(id: String) -> Dictionary:
	assert(DEFS.has(id), "Unknown ball id: %s" % id)
	return DEFS[id]
