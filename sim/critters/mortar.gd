## Mortar, the Toy cannon (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 48,
	"name": "Mortar",
	"type": "Toy cannon",
	"rarity": "rare",
	"role": "Zoner",
	"status": "live",
	"color": "5c6b3a",
	"vibe": "A toy-box cannon that's very proud of its maths.",
	"description": "Toy cannon. Every 4 seconds it lobs a shell at where the foe is about to be.",
	"stats": {"hp": 128.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "every", "secs": "fire_cooldown", "do": "lob"}],
	"params": {
		"fire_cooldown": 4.0, ## Seconds between shells.
		"lob_damage": 1.5,
		"lob_radius": 90.0,
		"lob_lead": 0.7, ## Aims where the foe will be this many seconds on, banking off walls.
		"lob_flight": 0.7,
		"lob_crater_dps": 0.0, ## Burning crater (radius 70, 2s), when above 0.
		"lob_barrage_every": 0, ## Every Nth shot is a 3-shell barrage, when above 0.
	},
	"tiers": [
		{"text": "Every 4s lobs a shell where the foe is going (1.5 damage)"},
		{"text": "Shells deal 2.5", "lob_damage": 2.5},
		{"text": "Shells leave a crater that burns 4/s for 2s", "lob_crater_dps": 4.0},
		{"text": "A shell every 3.5s", "fire_cooldown": 3.5},
		{"text": "Every third lob is 3 shells around the spot", "lob_barrage_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "flat"}, "back": ["barrel"], "front": ["cap"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.85},
}
