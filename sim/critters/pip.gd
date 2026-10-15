## Pip, the Pea shooter (Common Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 20,
	"name": "Pip",
	"type": "Pea shooter",
	"rarity": "common",
	"role": "Zoner",
	"status": "planned",
	"color": "9ef01a",
	"vibe": "An eager little pea pod that fires first and asks questions never.",
	"description": "Pea shooter. Every 3 seconds it spits a pea in the direction it's travelling.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Spits a pea every 3s for 6 damage"},
		{"text": "Peas deal 7"},
		{"text": "Peas bounce off one wall"},
		{"text": "A pea every 2.5s"},
		{"text": "Every third shot is a triple pea"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["tuft"], "front": ["snout"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.4},
}
