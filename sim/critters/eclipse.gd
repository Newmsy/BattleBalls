## Eclipse, the Eclipse (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 88,
	"name": "Eclipse",
	"type": "Eclipse",
	"rarity": "legendary",
	"rarity_power": 0.911, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "f4a259",
	"vibe": "A calm celestial who is two moods in one body.",
	"description": "Eclipse. Every 5s it flips between Sun, where a blazing corona burns foes near it (4/s), and Moon, where it heals 1.5 HP/s; each flip flashes a ring that knocks foes back.",
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
		{"text": "Flips every 5s: Sun burns 4/s, Moon heals 1.5/s", "now": "Flips every {eclipse_secs}s: Sun burns {sun_dps}/s, Moon heals {moon_hps}/s"},
		{"text": "Sun 4 → 7/s, heal 1.5 → 4/s", "sun_dps": 7.0, "moon_hps": 4.0},
		{"text": "+ Moon gives a 10 shield", "now": "Flips every {eclipse_secs}s: Sun burns {sun_dps}/s, Moon heals {moon_hps}/s + {moon_shield} shield", "moon_shield": 10.0},
		{"text": "Flip every 5 → 4s", "eclipse_secs": 4.0},
		{"text": "+ Both at once 1.5s after flips · flash 12", "now": "Flips every {eclipse_secs}s: burn {sun_dps}/s, heal {moon_hps}/s, both {total_secs}s after", "special": "Total Eclipse", "total_secs": 1.5},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smile"}, "body": "eclipse"},
	"sound": {"ouch": "ouch_cosmic", "pitch": 0.9},
}
