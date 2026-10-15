## Cogs, the Gear (Uncommon Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 33,
	"name": "Cogs",
	"type": "Gear",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "planned",
	"color": "b5838d",
	"vibe": "A wind-up toy gear that gets wound tighter every time it's knocked.",
	"description": "Gear. Every time it's hit it winds up faster, the opposite of Zip.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hit: winds up +6% speed, max +36%"},
		{"text": "+8% per hit taken"},
		{"text": "Fully wound: +2 contact damage"},
		{"text": "Winds up to +48%"},
		{"text": "Fully wound, its next hit crits (x2)"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "flat"}, "back": ["gears", "key"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.0},
}
