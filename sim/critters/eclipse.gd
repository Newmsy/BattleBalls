## Eclipse, the Eclipse (Legendary Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 88,
	"name": "Eclipse",
	"type": "Eclipse",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "planned",
	"color": "f4a259",
	"vibe": "A calm celestial who is two moods in one body.",
	"description": "Eclipse. Every 5 seconds it flips between Sun, where a blazing corona burns foes near it, and Moon, where it heals, and each flip flashes a ring that pushes foes away.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Flips Sun and Moon every 5s"},
		{"text": "Corona 7/s, heals 4/s"},
		{"text": "Moon also gives a 10 shield"},
		{"text": "Flips every 4s"},
		{"text": "Total Eclipse: both at once"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smile"}, "body": "eclipse"},
	"sound": {"ouch": "ouch_laser", "pitch": 0.9},
}
