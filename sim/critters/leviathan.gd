## Leviathan, the Sea serpent (Legendary Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 74,
	"name": "Leviathan",
	"type": "Sea serpent",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "planned",
	"color": "0f7173",
	"vibe": "A grand old sea serpent who rules the deep and knows it.",
	"description": "Sea serpent. Its glowing tail segments sting foes that touch them, and every 9 seconds it dives and bursts up under the foe in a huge wave.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Tail stings; every 9s a huge wave"},
		{"text": "The wave deals 20"},
		{"text": "4 segments that also slow"},
		{"text": "A wave every 8s"},
		{"text": "The eruption leaves a whirlpool"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "none"}, "back": ["segments", "frill"], "front": ["gills"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
