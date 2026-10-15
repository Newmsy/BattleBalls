## Mole, the Mole (Rare Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 52,
	"name": "Mole",
	"type": "Mole",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "planned",
	"color": "b08968",
	"vibe": "A busy little digger who pops up exactly where you didn't want it.",
	"description": "Mole. Every 6 seconds it burrows for a second, taking much less damage, then bursts up with a shove.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Burrows every 6s, bursts up for 8"},
		{"text": "The burst deals 10"},
		{"text": "Surfaces 20% faster"},
		{"text": "Burrows every 5s"},
		{"text": "The burst throws dirt clods"},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "smile"}, "front": ["helmet", "starnose"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.1},
}
