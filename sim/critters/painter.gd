## Painter, the Painter (Rare Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 46,
	"name": "Painter",
	"type": "Painter",
	"rarity": "rare",
	"role": "Zoner",
	"status": "planned",
	"color": "ffe8a3",
	"vibe": "A messy artist who thinks the arena is its canvas.",
	"description": "Painter. Painter leaves a paint trail, and foes on the paint take 10% more damage.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Paint trail: foes take +10% damage"},
		{"text": "Paint: +12%"},
		{"text": "Splotches stick for 1s after"},
		{"text": "The trail lasts 4s"},
		{"text": "Every 6s the paint dries with a flash"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "front": ["splats", "beret"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
