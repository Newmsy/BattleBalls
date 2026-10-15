## Mortar, the Toy cannon (Rare Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 48,
	"name": "Mortar",
	"type": "Toy cannon",
	"rarity": "rare",
	"role": "Zoner",
	"status": "planned",
	"color": "5c6b3a",
	"vibe": "A toy-box cannon that's very proud of its maths.",
	"description": "Toy cannon. Every 4 seconds it lobs a shell at where the foe will be in a second.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Lobs a shell every 4s for 12"},
		{"text": "Shells deal 14"},
		{"text": "The crater burns for 2s"},
		{"text": "A shell every 3.5s"},
		{"text": "Every third shot is a barrage"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "flat"}, "back": ["barrel"], "front": ["cap"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.85},
}
