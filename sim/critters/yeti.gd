## Yeti, the Yeti (Rare Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 43,
	"name": "Yeti",
	"type": "Yeti",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "planned",
	"color": "d6ccc2",
	"vibe": "A huggable mountain yeti with a very loud temper.",
	"description": "Yeti. It's big and furry, and below half HP it roars out an avalanche that hurts, shoves and slows everything nearby.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Half HP: an avalanche roar for 15"},
		{"text": "Avalanche deals 18"},
		{"text": "Roars again at 25% HP"},
		{"text": "The slow lasts 3s"},
		{"text": "The avalanche leaves snowdrifts"},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "teeth"}, "back": ["horns"], "front": ["fringe"], "scale": 1.1},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
