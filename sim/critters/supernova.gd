## Supernova, the Star (Legendary Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 79,
	"name": "Supernova",
	"type": "Star",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "planned",
	"color": "ffd6a5",
	"vibe": "A tiny star with a very big ending planned.",
	"description": "Star. It swells and brightens for 20 seconds, then explodes in a huge blast and starts over small.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 20s explodes for 30"},
		{"text": "The blast deals 35"},
		{"text": "The blast leaves a glowing ring"},
		{"text": "Explodes every 17s"},
		{"text": "Below 30% HP it goes nova early"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["corona"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.85},
}
