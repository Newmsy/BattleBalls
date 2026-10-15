## Static, the Spark (Uncommon Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 28,
	"name": "Static",
	"type": "Spark",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "planned",
	"color": "b388ff",
	"vibe": "A jittery ball of static that can't stop zapping things.",
	"description": "Spark. Every wall bounce zaps everything near it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Wall bounces zap nearby for 5"},
		{"text": "Zap deals 6"},
		{"text": "The zap slows 20% for 1s"},
		{"text": "Zap radius grows"},
		{"text": "Every 4th bounce is a big zap"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["zighair"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.35},
}
