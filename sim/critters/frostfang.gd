## Frostfang, the Wolf (Legendary Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 85,
	"name": "Frostfang",
	"type": "Wolf",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "planned",
	"color": "6d6875",
	"vibe": "A lone winter wolf, quiet until the howl.",
	"description": "Wolf. Every hit adds frost to the foe, and the third freezes it solid for a moment while ice shards burst out of it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Third frosty hit freezes the foe"},
		{"text": "Shards deal 5"},
		{"text": "Freezing howls: +20% speed"},
		{"text": "8 shards"},
		{"text": "Hit a frozen foe fast for double"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "6fd3ff", "mouth": "fangs"}, "back": ["ears"], "front": ["ruff"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
