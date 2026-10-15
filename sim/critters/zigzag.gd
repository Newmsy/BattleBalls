## Zigzag, the Lightning (Rare Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 53,
	"name": "Zigzag",
	"type": "Lightning",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "planned",
	"color": "faff70",
	"vibe": "A hyper bolt of lightning that leaves its path still crackling.",
	"description": "Lightning. After every hit, its path to the next wall becomes a crackling beam.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "After a hit, its path crackles for 1.5s"},
		{"text": "Beam deals 10/s"},
		{"text": "The beam slows 20%"},
		{"text": "The beam lasts 2s"},
		{"text": "The beam zigzags one more bounce"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["spikyhair"], "front": ["zigmark"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.35},
}
