## Magmo, the Lava blob (Rare Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 41,
	"name": "Magmo",
	"type": "Lava blob",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "planned",
	"color": "ff4500",
	"vibe": "A hot-headed lava blob who leaves a splash in every fight.",
	"description": "Lava blob. Every hit splashes a lava puddle that burns foes who stay in it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits splash lava: 5 damage/s for 2.5s"},
		{"text": "Lava burns for 6/s"},
		{"text": "Leaving the lava keeps the foe burning"},
		{"text": "Lava lasts 3.5s"},
		{"text": "Standing in its lava: 20% armour"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "grin"}, "front": ["crust", "drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
