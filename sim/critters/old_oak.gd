## Old Oak, the Ancient tree (Legendary Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 75,
	"name": "Old Oak",
	"type": "Ancient tree",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "planned",
	"color": "6f4518",
	"vibe": "A slow, kind forest elder who has seen a thousand fights.",
	"description": "Ancient tree. At half HP it takes root: four root pillars burst up around it and it regrows health while they stand.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Half HP: takes root, regrows 3 HP/s"},
		{"text": "Regrows 4 HP/s"},
		{"text": "Roots erupt with a shove"},
		{"text": "Root pillars last 8s"},
		{"text": "Takes root again at 20% HP"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["canopy"], "front": ["beard"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
