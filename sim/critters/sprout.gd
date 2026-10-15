## Sprout, the Sprout (Rare Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 54,
	"name": "Sprout",
	"type": "Sprout",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "planned",
	"color": "8ac926",
	"vibe": "A sunny seedling that plants something everywhere it goes.",
	"description": "Sprout. Every wall bounce plants a seed that grows into a small pillar for 4 seconds.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bounces plant a 4s pillar"},
		{"text": "Pillars last 5s"},
		{"text": "Bouncing off a pillar deals 4"},
		{"text": "Pillars grow bigger"},
		{"text": "Wilting pillars scatter seeds"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["leaves"], "front": ["frost_freckles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.35},
}
