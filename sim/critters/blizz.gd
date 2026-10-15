## Blizz, the Snowflake (Epic Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 66,
	"name": "Blizz",
	"type": "Snowflake",
	"rarity": "epic",
	"role": "Zoner",
	"status": "planned",
	"color": "90e0ef",
	"vibe": "A crisp, chatty snowflake that loves a good snowball fight.",
	"description": "Snowflake. Every 4 seconds it drops a snowflake mine, and each blast leaves a freezing patch that slows foes.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Snowflake mines every 4s for 10"},
		{"text": "Mines deal 12"},
		{"text": "Mines go off when the foe gets close"},
		{"text": "Up to 4 mines"},
		{"text": "Two frost patches freeze the foe"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["snowflake"], "front": ["cheeks"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.3},
}
