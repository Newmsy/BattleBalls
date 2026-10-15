## Drizzle, the Rain cloud (Uncommon Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 29,
	"name": "Drizzle",
	"type": "Rain cloud",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "planned",
	"color": "7b8cde",
	"vibe": "A gloomy little raincloud that rains on everyone's parade.",
	"description": "Rain cloud. Every 5 seconds it rains on the foe's spot, hurting anything that stays there.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Rains on the foe every 5s: 4 damage/s"},
		{"text": "Rain deals 5/s"},
		{"text": "Sleety rain slows 20%"},
		{"text": "Rains every 4s"},
		{"text": "Every third shower is a thunderstorm"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "pout"}, "body": "cloud", "back": ["drops"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.1},
}
