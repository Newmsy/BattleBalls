## Clockwork, the Clockwork (Legendary Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 82,
	"name": "Clockwork",
	"type": "Clockwork",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "planned",
	"color": "c9a227",
	"vibe": "A fussy brass timekeeper who refuses to be late, or to lose.",
	"description": "Clockwork. Every 5 seconds it ticks out a ring that slows foes, and once below 30% HP it rewinds to its health from 3 seconds ago.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Ticks a slowing ring; rewinds at 30% HP"},
		{"text": "Ticks deal 4"},
		{"text": "Rewinding also turns back its spot"},
		{"text": "Rewinds 4s"},
		{"text": "At the rewind, time stops for the foe"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["gearcrown"], "front": ["clockface", "monocle"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.95},
}
