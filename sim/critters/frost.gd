## Chill, the Frost (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 7,
	"name": "Chill",
	"type": "Frost",
	"rarity": "rare",
	"role": "Zoner",
	"status": "planned",
	"color": "bfe9ff",
	"vibe": "Sleepy and unhurried; everything near it slows down to its pace.",
	"description": "Frost.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "always", "do": "trail"}],
	"params": {},
	"tiers": [
		{"text": "Icy trail slows foes 20%"},
		{"text": "Slows 25%"},
		{"text": "Trail lasts longer"},
		{"text": "Slows 30%"},
		{"text": "Frozen foes shatter for bonus damage"},
	],
	"art": {"eyes": {"sep": .3, "w": .19, "h": .2, "p": .09, "lid": .55, "mouth": "o"}, "back": ["ice_crown"], "front": ["frost_freckles"]},
	"sound": {},
}
