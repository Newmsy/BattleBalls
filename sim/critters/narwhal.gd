## Narwhal, the Narwhal (Legendary Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 86,
	"name": "Narwhal",
	"type": "Narwhal",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "planned",
	"color": "b8e0d2",
	"vibe": "A dreamy arctic unicorn of the sea who charges like a knight.",
	"description": "Narwhal. Every 5 seconds it charges at the foe, its horn leaving a glittering beam along the path, and the charge hit deals double.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Charges every 5s for x2, beam trail"},
		{"text": "Beam deals 10/s"},
		{"text": "The charge knocks the foe back hard"},
		{"text": "Charges every 4s"},
		{"text": "A missed charge curves round again"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["horn", "fluke"], "front": ["speckles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.05},
}
