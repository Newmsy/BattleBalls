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
	"magnet": {
		"display_name": "Flux",
		"description": "Magnet. Every 3s its field flips: Pull drags the foe in and its first hit of each Pull snaps for 2.5x damage; a weaker Push shoves it away.",
		"rarity": "epic",
		"badge_top": 1.55,
		"hp": 100.0,
		"radius": 62.0,
		"speed": 400.0,
		"contact_damage": 13.0,
		"ability": "magnet",
		"field_period": 3.0, ## Seconds per phase; Pull comes first.
		"field_range": 520.0, ## The field fades to nothing at this distance.
		"field_accel": 700.0, ## Steering at point blank, units/s^2, on both balls.
		"push_scale": 0.5, ## Push steers at this share of Pull's strength.
		"snap_mult": 2.5, ## Contact damage multiplier on the first hit of each Pull.
		"color": Color("ff3b5c"),
		"pole_color": Color("2f7bff"),
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
const PLAYABLE := ["vampire", "laser", "magnet"]


static func get_def(id: String) -> Dictionary:
	assert(DEFS.has(id), "Unknown ball id: %s" % id)
	return DEFS[id]
