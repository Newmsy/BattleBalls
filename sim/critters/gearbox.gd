## Gearbox, the Gearbox (Epic Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 70,
	"name": "Gearbox",
	"type": "Gearbox",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "planned",
	"color": "a7c957",
	"vibe": "A revved-up racing bot that lives for top gear.",
	"description": "Gearbox. Every 3 seconds it shifts up a gear, and in top gear its next hit is a slam that resets it to first.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Shifts up every 3s, 3 gears"},
		{"text": "+18% speed per gear"},
		{"text": "Being hurt keeps its gears"},
		{"text": "Shifts every 2.5s"},
		{"text": "A fourth turbo gear leaves a fire trail"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["gearstick"], "front": ["number", "goggles"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.05},
}
