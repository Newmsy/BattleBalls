## Pip, the Pea shooter (Common Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 20,
	"name": "Pip",
	"type": "Pea shooter",
	"rarity": "common",
	"role": "Zoner",
	"status": "live",
	"color": "9ef01a",
	"vibe": "An eager little pea pod that fires first and asks questions never.",
	"description": "Pea shooter. Every 3 seconds it spits a pea in the direction it's travelling.",
	"stats": {"hp": 128.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "every", "secs": "fire_cooldown", "do": "shoot"}],
	"params": {
		"fire_cooldown": 3.0, ## Seconds between peas.
		"shot_damage": 6.0,
		"shot_speed": 600.0,
		"shot_count": 1,
		"shot_aim": "heading",
		"shot_bounces": 0, ## Wall bounces before a pea vanishes.
		"shot_big_every": 0, ## Every Nth shot is shot_big_count peas, when above 0.
		"shot_big_count": 3,
		"shot_spread": 20.0,
		"shot_radius": 9.0,
		"shot_kind": "pea",
	},
	"tiers": [
		{"text": "Spits a pea every 3s for 6 damage"},
		{"text": "Peas deal 7", "shot_damage": 7.0},
		{"text": "Peas bounce off one wall", "shot_bounces": 1},
		{"text": "A pea every 2.5s", "fire_cooldown": 2.5},
		{"text": "Every third shot is a triple pea", "shot_big_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["tuft"], "front": ["snout"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.4},
}
