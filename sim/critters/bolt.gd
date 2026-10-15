## Bolt, the Robot (Uncommon Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 36,
	"name": "Bolt",
	"type": "Robot",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "planned",
	"color": "3a3aff",
	"vibe": "An overeager little robot that zaps itself somewhere new after every punch.",
	"description": "Robot. After every second hit it teleports to a new spot.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Teleports after every 2nd hit"},
		{"text": "First hit after landing deals +2"},
		{"text": "The spot it leaves crackles"},
		{"text": "Teleports after every hit"},
		{"text": "Arrives with a zap beam"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "square": true, "mouth": "flat"}, "back": ["boltant"], "front": ["panel"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.25},
}
