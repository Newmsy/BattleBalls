## Bubbles, the Bubble (Common Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 21,
	"name": "Bubbles",
	"type": "Bubble",
	"rarity": "common",
	"role": "Disruptor",
	"status": "planned",
	"color": "6fe3e8",
	"vibe": "A giggly bubble-blower that thinks every fight is bath time.",
	"description": "Bubble. Every 6 seconds it blows a bubble shield that pops on the first hit.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bubble shield absorbs up to 10"},
		{"text": "Absorbs up to 12"},
		{"text": "The pop pushes the attacker away"},
		{"text": "A bubble every 5s"},
		{"text": "The pop sprays 4 little bubbles"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "o"}, "body": "ghost", "tint": true, "front": ["sheen"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.35},
}
