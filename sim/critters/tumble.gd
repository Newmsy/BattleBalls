## Tumble, the Tumbleweed (Uncommon Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 26,
	"name": "Tumble",
	"type": "Tumbleweed",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "planned",
	"color": "c8a165",
	"vibe": "A dusty tumbleweed that gathers itself up every time it rolls.",
	"description": "Tumbleweed. Every wall bounce makes it a little bigger and harder-hitting, until it gets hit.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "+5% size, +1 damage per bounce, max 6"},
		{"text": "Grows up to 8 times"},
		{"text": "Being hurt only knocks off half"},
		{"text": "+1.5 damage per bounce"},
		{"text": "At max size a hit on it bursts in dust"},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "smirk"}, "front": ["twigs"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.05},
}
