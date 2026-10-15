## Magmo, the Lava blob (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 41,
	"name": "Magmo",
	"type": "Lava blob",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "live",
	"color": "ff4500",
	"vibe": "A hot-headed lava blob who leaves a splash in every fight.",
	"description": "Lava blob. Every hit splashes a lava puddle that burns foes who stay in it.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "hit", "do": "lava"}],
	"params": {
		"lava_radius": 60.0,
		"lava_life": 2.5, ## Seconds a puddle lasts.
		"lava_dps": 5.0,
		"lava_max": 4, ## Oldest puddle goes when a new one would pass this.
		"linger_dps": 2.0, ## T3: a foe that was in the lava keeps burning this much...
		"linger_slow": 0.0,
		"linger_secs": 2.0, ## ...for this long.
		"home_guard": 0.8, ## T5: damage taken while standing in its own lava.
	},
	"tiers": [
		{"text": "Hits splash lava: 5 damage/s for 2.5s"},
		{"text": "Lava burns for 6/s", "lava_dps": 6.0},
		{"text": "Leaving the lava keeps the foe burning (2/s for 2s)", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "Lava lasts 3.5s", "lava_life": 3.5},
		{"text": "Standing in its lava: 20% armour", "ability": [{"on": "guard", "do": "home_guard"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "grin"}, "front": ["crust", "drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
