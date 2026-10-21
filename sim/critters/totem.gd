## Totem, the Totem (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 63,
	"name": "Totem",
	"type": "Totem",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "live",
	"color": "2a9d8f",
	"vibe": "A stack of carved faces that all have opinions.",
	"description": "Totem. Every collision adds a carved face on top, each with its own buff, up to three: harder hits, tougher body, faster roll. Big hits knock one off.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "bump", "do": "face"}, {"on": "guard", "do": "face_guard"}, {"on": "hurt", "do": "stack_drop"}],
	"params": {
		"stack_max": 3.0,
		"face_damage": 2.0,
		"face_speed": 0.15,
		"face_armor": 0.15,
		"drop_at": 18.0,
		"splat_radius": 0.0,
		"splat_slow": 0.0,
		"splat_dps": 0.0,
		"shout_radius": 160.0,
		"shout_damage": 8.0,
	},
	"tiers": [
		{"text": "Bumps stack up to 3 faces: +2 damage, 15% armour, +15% speed"},
		{"text": "First face: +3 damage", "face_damage": 3.0},
		{"text": "Starts with one face", "ability": [{"on": "start", "do": "face"}]},
		{"text": "Armour face: 20%", "face_armor": 0.2},
		{"text": "A 4th, golden face: with 4, it shouts every 5s (8 damage)", "stack_max": 4.0, "ability": [{"on": "every", "secs": 5.0, "do": "face_shout"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "flat"}, "back": ["totemstack"], "scale": .9},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
