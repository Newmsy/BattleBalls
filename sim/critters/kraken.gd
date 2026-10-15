## Kraken, the Kraken (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 81,
	"name": "Kraken",
	"type": "Kraken",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "live",
	"color": "8e3bbd",
	"vibe": "A playful deep-sea giant who just wants to hug everything at once.",
	"description": "Kraken. Four long tentacles sweep in a wide circle around it, and every 6 seconds they slam down, leaving ink puddles that slow foes.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "always", "do": "tentacles"}, {"on": "every", "secs": 6.0, "do": "ink_slam"}],
	"params": {
		"tentacle_count": 4,
		"tentacle_orbit": 76.0, ## Reach beyond its edge.
		"tentacle_size": 18.0,
		"tentacle_damage": 1.5,
		"tentacle_spin": 1.2, ## Radians a second.
		"tentacle_cooldown": 1.0,
		"ink_radius": 70.0,
		"ink_life": 3.0,
		"ink_slow": 0.25,
		"ink_dps": 1.0,
		"ink_shove": 0, ## T3: slams knock foes near a tip away.
		"hug_every": 0, ## T5: every this many slams is a hug.
		"hug_secs": 1.0,
		"hug_range": 400.0,
		"hug_accel": 900.0,
	},
	"tiers": [
		{"text": "4 tentacles sweep; slams every 6s"},
		{"text": "Tentacles deal 3.5", "tentacle_damage": 3.5},
		{"text": "Slams also shove", "ink_shove": 1},
		{"text": "Tentacles reach further", "tentacle_orbit": 106.0},
		{"text": "Every third slam is a giant hug", "hug_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "beak"}, "back": ["tentacles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.75},
}
