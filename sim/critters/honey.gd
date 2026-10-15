## Honey, the Honey pot (Uncommon Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 30,
	"name": "Honey",
	"type": "Honey pot",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "planned",
	"color": "d97706",
	"vibe": "A sweet, slow-talking honey pot that leaves everyone a little sticky.",
	"description": "Honey pot. Every wall bounce drips a honey puddle that slows foes who roll through it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bounces drip honey: slow 35%, max 4"},
		{"text": "Puddles last 5s"},
		{"text": "Foes stay sticky for 1s after"},
		{"text": "Up to 6 puddles"},
		{"text": "Touching puddles merge into a big pool"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["jarlid", "drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
