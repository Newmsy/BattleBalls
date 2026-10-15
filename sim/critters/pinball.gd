## Pinball, the Pinball (Common Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 17,
	"name": "Pinball",
	"type": "Pinball",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "planned",
	"color": "f1f3f5",
	"vibe": "A show-off arcade ball that treats every wall like a bumper worth points.",
	"description": "Pinball. Every wall it touches since its last hit adds damage to its next hit.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "+1 hit damage per wall, max 5"},
		{"text": "+1.5 damage per wall"},
		{"text": "Cashing in 3+ walls knocks the foe back"},
		{"text": "+2 damage per wall"},
		{"text": "A hit after 5 walls is a TILT! crit (x2)"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "body": "chrome", "tint": true, "back": ["rears"], "front": ["bulbs"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.25},
}
