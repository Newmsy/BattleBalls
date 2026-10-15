## Sundae, the Sundae (Legendary Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 77,
	"name": "Sundae",
	"type": "Sundae",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "planned",
	"color": "fde2e4",
	"vibe": "A towering ice cream sundae who wants everyone to have a scoop.",
	"description": "Sundae. Every hit stacks another scoop on top for harder hits, and every big hit it takes knocks a scoop off that splats into a sticky puddle.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits stack scoops, max 4; splats slow"},
		{"text": "+3 damage per scoop"},
		{"text": "Splats give brain freeze (3/s)"},
		{"text": "Up to 5 scoops"},
		{"text": "At 5 scoops hits shower sprinkles"},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "closed": true, "mouth": "smile"}, "back": ["scoops"], "front": ["cup"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.15},
}
