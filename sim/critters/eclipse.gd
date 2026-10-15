## Eclipse, the Eclipse (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 88,
	"name": "Eclipse",
	"type": "Eclipse",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "live",
	"color": "f4a259",
	"vibe": "A calm celestial who is two moods in one body.",
	"description": "Eclipse. Every 5 seconds it flips between Sun, where a blazing corona burns foes near it, and Moon, where it heals, and each flip flashes a ring that pushes foes away.",
	"stats": {"hp": 121.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "every", "secs": "eclipse_secs", "do": "eclipse"}, {"on": "always", "do": "corona"}],
	"params": {
		"eclipse_secs": 5.0,
		"flip_radius": 160.0,
		"sun_radius": 66.0,
		"sun_dps": 4.0,
		"moon_hps": 1.5,
		"moon_shield": 0.0,
		"total_secs": 0.0,
		"total_damage": 12.0,
	},
	"tiers": [
		{"text": "Flips every 5s: Sun burns foes near it (6/s), Moon heals 3/s; each flip pushes foes away"},
		{"text": "Corona 7/s, heals 4/s", "sun_dps": 7.0, "moon_hps": 4.0},
		{"text": "Moon also gives a 10 shield", "moon_shield": 10.0},
		{"text": "Flips every 4s", "eclipse_secs": 4.0},
		{"text": "Total Eclipse: both at once for 1.5s after each flip, and the flash burns for 12", "total_secs": 1.5},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smile"}, "body": "eclipse"},
	"sound": {"ouch": "ouch_laser", "pitch": 0.9},
}
