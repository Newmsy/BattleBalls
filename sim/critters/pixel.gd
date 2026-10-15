## Pixel, the Sprite (Epic Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 71,
	"name": "Pixel",
	"type": "Sprite",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "planned",
	"color": "7cff4f",
	"vibe": "A glitchy 8-bit sprite who blinks between frames.",
	"description": "Sprite. Every 5 seconds it teleports, leaving a pixel bomb where it was.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Teleports every 5s, leaves a bomb"},
		{"text": "Bombs deal 14"},
		{"text": "Lands with a glitch pulse"},
		{"text": "Teleports every 4s"},
		{"text": "Leaves a line of 3 bombs"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "square": true, "mouth": "smile"}, "body": "pixel"},
	"sound": {"ouch": "ouch_laser", "pitch": 1.4},
}
