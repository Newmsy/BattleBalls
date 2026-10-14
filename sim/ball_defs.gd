## Static definitions for every ball type. Pure data: the sim reads these,
## the renderer reads `color`, `display_name`, `rarity` and `badge_top`.
extends RefCounted

const DEFS := {
	"vampire": {
		"display_name": "Count Nibbles",
		"description": "Vampire. Heals for half the damage it deals when it hits.",
		"rarity": "common",
		"badge_top": 1.3,
		"hp": 100.0,
		"radius": 68.0,
		"speed": 400.0,
		"contact_damage": 16.0,
		"ability": "vampire",
		"heal_ratio": 0.5,
		"color": Color("c2264a"),
	},
	"laser": {
		"display_name": "Optic",
		"description": "Laser. Every wall bounce fires a beam back to its last bounce point.",
		"rarity": "rare",
		"badge_top": 1.6,
		"hp": 100.0,
		"radius": 58.0,
		"speed": 420.0,
		"contact_damage": 10.0,
		"ability": "laser",
		"beam_life": 3.0,
		"beam_damage": 4.5,
		"beam_hit_cooldown": 0.5,
		"beam_max": 6,
		"color": Color("27c8ff"),
	},
	# Onboarding foes (design/onboarding.md): weak on purpose, never offered in
	# pickers and skipped by the balance sim.
	"dummy": {
		"display_name": "Training Dummy",
		"description": "A practice target. It barely fights back.",
		"tutorial": true,
		"hp": 32.0,
		"radius": 76.0,
		"speed": 380.0,
		"contact_damage": 3.0,
		"ability": "",
		"color": Color("d9a066"),
	},
	"sparring": {
		"display_name": "Sparring Bot",
		"description": "A practice bot that hits back a little.",
		"tutorial": true,
		"hp": 45.0,
		"radius": 70.0,
		"speed": 420.0,
		"contact_damage": 5.0,
		"ability": "",
		"color": Color("9aa4ff"),
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
		"color": Color("8a94a8"),
	},
}

## Balls offered in the in-game picker.
const PLAYABLE := ["vampire", "laser"]


static func get_def(id: String) -> Dictionary:
	assert(DEFS.has(id), "Unknown ball id: %s" % id)
	return DEFS[id]
