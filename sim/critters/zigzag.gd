## Zigzag, the Lightning (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 53,
	"name": "Zigzag",
	"type": "Lightning",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "live",
	"color": "faff70",
	"vibe": "A hyper bolt of lightning that leaves its path still crackling.",
	"description": "Lightning. After every hit, its path to the next wall becomes a crackling beam.",
	"stats": {"hp": 115.0, "radius": 66.0, "speed": 400.0, "contact_damage": 20.0},
	"ability": [{"on": "hit", "do": "zz_arm"}, {"on": "wall", "do": "zz_beam"}, {"on": "always", "do": "slows"}],
	"params": {
		"zz_life": 1.5,
		"zz_damage": 8.0, ## A second.
		"zz_slow": 0.0,
		"zz_segments": 1, ## 2: the beam zigzags one more bounce.
		"beam_max": 6,
	},
	"tiers": [
		{"text": "After a hit, its path crackles for 1.5s"},
		{"text": "Beam deals 10/s", "zz_damage": 10.0},
		{"text": "The beam slows 20%", "zz_slow": 0.2},
		{"text": "The beam lasts 2s", "zz_life": 2.0},
		{"text": "The beam zigzags one more bounce", "zz_segments": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["spikyhair"], "front": ["zigmark"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.35},
}
