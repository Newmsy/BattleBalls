## Mammoth, the Mammoth (Epic Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 60,
	"name": "Mammoth",
	"type": "Mammoth",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "planned",
	"color": "7f5539",
	"vibe": "A woolly giant who believes every wall is a friend.",
	"description": "Mammoth. Its hits shove foes hard, and a foe that slams into a wall right after is frozen for a moment.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits shove hard; wall slams freeze"},
		{"text": "Slams deal +8"},
		{"text": "Slams leave an icy patch"},
		{"text": "Slam window 0.8s"},
		{"text": "Frozen foes shatter for double"},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "none"}, "back": ["fur"], "front": ["tusks", "trunk"], "scale": 1.12},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
