## Flicker, the Candle (Uncommon Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 32,
	"name": "Flicker",
	"type": "Candle",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "planned",
	"color": "fff1c1",
	"vibe": "A cheeky candle that vanishes in a puff of smoke after every poke.",
	"description": "Candle. After every hit it fades out briefly, taking much less damage.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Fades out for 0.6s after each hit"},
		{"text": "Fades for 0.8s"},
		{"text": "Its hits also burn (2/s for 2s)"},
		{"text": "Fades for 1s"},
		{"text": "While faded it leaves a burning trail"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["candle"], "front": ["drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
