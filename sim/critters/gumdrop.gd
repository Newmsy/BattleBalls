## Gumdrop, the Gumdrop (Common Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 22,
	"name": "Gumdrop",
	"type": "Gumdrop",
	"rarity": "common",
	"role": "Disruptor",
	"status": "planned",
	"color": "9b5de5",
	"vibe": "A clingy candy who just wants to stick around.",
	"description": "Gumdrop. Every hit gums up the foe, slowing it for a moment.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits slow the foe 25% for 1.5s"},
		{"text": "Slow 30%"},
		{"text": "The goo also stings (burn 1/s)"},
		{"text": "Slow lasts 2s"},
		{"text": "Slows stack twice, up to 45%"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["sugar"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
