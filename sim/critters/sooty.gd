## Sooty, the Coal (Common Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 19,
	"name": "Sooty",
	"type": "Coal",
	"rarity": "common",
	"role": "Zoner",
	"status": "planned",
	"color": "4a3b36",
	"vibe": "A grumpy little lump of coal that leaves hot spots wherever it sulks.",
	"description": "Coal. Every 4 seconds it drops a hot patch that burns foes standing in it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hot patch every 4s: 4 damage/s"},
		{"text": "Patches burn for 5/s"},
		{"text": "Leaving a patch keeps the foe burning"},
		{"text": "A patch every 3s"},
		{"text": "Hurt Sooty and every patch flares"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "frown"}, "back": ["smoke"], "front": ["embers"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
