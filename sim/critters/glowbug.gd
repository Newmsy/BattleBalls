## Glowbug, the Firefly (Uncommon Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 31,
	"name": "Glowbug",
	"type": "Firefly",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "planned",
	"color": "d4ff3a",
	"vibe": "A dreamy firefly that brings its own little lights to every fight.",
	"description": "Firefly. A tiny light-bug circles it and stings foes it touches.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "A light-bug circles and stings"},
		{"text": "Bug stings for 5"},
		{"text": "Two bugs"},
		{"text": "Bugs orbit wider"},
		{"text": "Every 6s the bugs flare"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["antenna2"], "front": ["glowbelly"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.4},
}
