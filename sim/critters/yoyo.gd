## Yo-Yo, the Yo-Yo (Epic Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 64,
	"name": "Yo-Yo",
	"type": "Yo-Yo",
	"rarity": "epic",
	"role": "Zoner",
	"status": "planned",
	"color": "00b4d8",
	"vibe": "A show-off toy that never passes up a trick.",
	"description": "Yo-Yo. Every third wall bounce it pins its string to the wall and swings around that anchor for a second, its taut string hurting foes it sweeps.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 3rd bounce swings on its string"},
		{"text": "String deals 12/s"},
		{"text": "Walk the Dog: flings at the foe"},
		{"text": "Swings every 2nd bounce"},
		{"text": "Around the World: two strings"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smirk"}, "front": ["yoyo"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.2},
}
