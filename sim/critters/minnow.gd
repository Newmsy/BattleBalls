## Minnow, the Fish (Uncommon Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 35,
	"name": "Minnow",
	"type": "Fish",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "planned",
	"color": "00e5ff",
	"vibe": "A tiny anxious fish that finds a second gear when things look bad.",
	"description": "Fish. It's small and slippery, and at half HP it panics into a permanent burst of speed.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Small; at half HP panics: +35% speed"},
		{"text": "Panic speed +40%"},
		{"text": "Panicking also heals 8"},
		{"text": "Panic speed +45%"},
		{"text": "The panic splashes the foe away"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["fantail"], "scale": 0.85},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.4},
}
