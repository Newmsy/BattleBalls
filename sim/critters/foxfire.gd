## Foxfire, the Fox spirit (Legendary Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 84,
	"name": "Foxfire",
	"type": "Fox spirit",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "planned",
	"color": "ffb4a2",
	"vibe": "A mischievous fox spirit who loves a good trick.",
	"description": "Fox spirit. Every 6 seconds it splits off two fox-fire illusions, and an illusion that's touched bursts into flame.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 6s splits off 2 fiery illusions"},
		{"text": "Illusions burst for 10"},
		{"text": "Illusions leave flame trails"},
		{"text": "3 illusions"},
		{"text": "A touched illusion swaps with Foxfire"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smirk"}, "back": ["ears", "foxtail"], "front": ["mask"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
