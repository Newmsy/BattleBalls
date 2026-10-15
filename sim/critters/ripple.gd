## Ripple, the Water drop (Rare Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 47,
	"name": "Ripple",
	"type": "Water drop",
	"rarity": "rare",
	"role": "Zoner",
	"status": "planned",
	"color": "4361ee",
	"vibe": "A bouncy water drop that makes waves everywhere it lands.",
	"description": "Water drop. Every wall bounce sends a damaging ripple along that wall.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Wall bounces send a ripple along the wall"},
		{"text": "Ripples deal 12/s"},
		{"text": "The ripple slows 20%"},
		{"text": "Ripples run further"},
		{"text": "Ripples turn corners"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["droptop"], "front": ["shine"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
