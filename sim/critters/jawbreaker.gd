## Jawbreaker, the Jawbreaker (Rare Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 45,
	"name": "Jawbreaker",
	"type": "Jawbreaker",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "planned",
	"color": "2ec4b6",
	"vibe": "A rock-hard candy collector who keeps its winnings spinning close.",
	"description": "Jawbreaker. Every hit adds a candy that circles it and bonks foes, up to 3.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits add an orbiting candy, max 3"},
		{"text": "Candies bonk for 5"},
		{"text": "Starts the fight with 1 candy"},
		{"text": "Up to 4 candies"},
		{"text": "A full set cracks in a sugar blast"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smirk"}, "back": ["moons"], "front": ["candyrings"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
