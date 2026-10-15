## Mossy, the Moss ball (Uncommon Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 27,
	"name": "Mossy",
	"type": "Moss ball",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "planned",
	"color": "2d6a4f",
	"vibe": "A sleepy forest moss ball that heals up whenever it's left in peace.",
	"description": "Moss ball. When it hasn't been hurt for 3 seconds, it slowly regrows health.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Unhurt for 3s: regrow 2 HP/s"},
		{"text": "Regrow 2.5 HP/s"},
		{"text": "Starts regrowing after 2.5s"},
		{"text": "Regrow 3 HP/s"},
		{"text": "While regrowing it sheds stinging spores"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["fuzz", "mushroom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
