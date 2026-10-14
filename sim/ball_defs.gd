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
		"contact_damage": 4.0,
		"ability": "laser",
		"beam_life": 3.0,
		"beam_damage": 7.0,
		"beam_hit_cooldown": 0.5,
		"beam_max": 6,
		"color": Color("27c8ff"),
	},
	"juggernaut": {
		"display_name": "Boulder",
		"description": "Juggernaut. Huge and slow. Balls it hits take slam damage if they hit a wall soon after.",
		"rarity": "common",
		"badge_top": 1.2,
		"hp": 140.0,
		"radius": 82.0,
		"speed": 320.0,
		"contact_damage": 19.0,
		"ability": "juggernaut",
		"slam_damage": 11.0,
		"slam_window": 0.3,
		"color": Color("7d8799"),
	},
	"spiker": {
		"display_name": "Prickles",
		"description": "Spiker. Grows a spike on every hit it lands; each spike adds contact damage.",
		"rarity": "common",
		"badge_top": 1.2,
		"hp": 115.0,
		"radius": 62.0,
		"speed": 400.0,
		"contact_damage": 18.0,
		"ability": "spiker",
		"spike_damage": 1.6,
		"spike_max": 10,
		"color": Color("5cc95a"),
	},
	"speedster": {
		"display_name": "Zip",
		"description": "Speedster. Speeds up on every wall bounce and hits harder the faster it goes. Getting hit resets it.",
		"rarity": "common",
		"badge_top": 1.2,
		"hp": 105.0,
		"radius": 48.0,
		"speed": 400.0,
		"contact_damage": 12.5,
		"ability": "speedster",
		"speed_gain": 0.12,
		"max_speed_mult": 1.8,
		"color": Color("ffb020"),
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
const PLAYABLE := ["vampire", "laser", "juggernaut", "spiker", "speedster"]


static func get_def(id: String) -> Dictionary:
	assert(DEFS.has(id), "Unknown ball id: %s" % id)
	return DEFS[id]
