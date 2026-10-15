## Fin, the Shark (Uncommon Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 25,
	"name": "Fin",
	"type": "Shark",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "planned",
	"color": "4f8fb8",
	"vibe": "A grinning shark pup who counts its bites out loud.",
	"description": "Shark. Every fourth hit is a big bite for extra damage.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 4th hit bites for x2.5"},
		{"text": "Big bite: x3"},
		{"text": "A big bite leaves the foe bleeding"},
		{"text": "Bites on every 3rd hit"},
		{"text": "A big bite heals Fin for half"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "teeth"}, "back": ["dorsal"], "front": ["belly"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.95},
}
