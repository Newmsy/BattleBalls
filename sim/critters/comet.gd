## Comet, the Comet (Rare Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 49,
	"name": "Comet",
	"type": "Comet",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "planned",
	"color": "ff5ad1",
	"vibe": "A starry show-off that leaves a sparkly mess wherever it zooms.",
	"description": "Comet. It leaves a stardust trail that hurts foes who cross it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Stardust trail burns 5/s for 1.5s"},
		{"text": "Trail deals 6/s"},
		{"text": "Crossing the trail also burns"},
		{"text": "The trail lasts 2s"},
		{"text": "Every 3s its tail flicks a homing star"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["comettail"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.15},
}
