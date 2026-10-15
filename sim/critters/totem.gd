## Totem, the Totem (Epic Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 63,
	"name": "Totem",
	"type": "Totem",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "planned",
	"color": "2a9d8f",
	"vibe": "A stack of carved faces that all have opinions.",
	"description": "Totem. Every collision adds a carved face on top, each with its own buff, up to three: harder hits, tougher body, faster roll.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bumps stack up to 3 carved faces"},
		{"text": "First face: +3 damage"},
		{"text": "Starts with one face"},
		{"text": "Armour face: 20%"},
		{"text": "A fourth, golden face shouts"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "flat"}, "back": ["totemstack"], "scale": .9},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
