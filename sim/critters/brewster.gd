## Brewster, the Cauldron (Epic Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 68,
	"name": "Brewster",
	"type": "Cauldron",
	"rarity": "epic",
	"role": "Zoner",
	"status": "planned",
	"color": "1b4332",
	"vibe": "A bubbly little cauldron who's always cooking up trouble.",
	"description": "Cauldron. Every 5 seconds it lobs 3 potion blobs near the foe that splash into burning or slowing puddles.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 5s lobs 3 burning or slowing blobs"},
		{"text": "Burn puddles deal 5/s"},
		{"text": "4 blobs"},
		{"text": "Brews every 4s"},
		{"text": "Every third brew is one huge puddle"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["witchhat"], "front": ["pot"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
