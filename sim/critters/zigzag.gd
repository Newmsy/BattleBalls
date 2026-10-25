## Zigzag, the Lightning (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 53,
	"name": "Zigzag",
	"type": "Lightning",
	"rarity": "rare",
	"rarity_power": 1.049, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.81, 0.83, 0.86, 0.86, 0.86], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "faff70",
	"vibe": "A hyper bolt of lightning that leaves its path still crackling.",
	"description": "Lightning. After every hit a lightning bolt zigzags at the foe {zz_bolt_delay}s later, and its path to the next wall becomes a crackling beam ({zz_damage}/sec for {zz_life}s).",
	"stats": {"hp": 115.0, "radius": 66.0, "speed": 400.0, "contact_damage": 20.0},
	"ability": [{"on": "hit", "do": "zz_arm"}, {"on": "wall", "do": "zz_beam"}, {"on": "always", "do": "slows"}, {"on": "hit", "do": "zz_bolt_arm"}, {"on": "always", "do": "zz_bolt"}],
	"params": {
		"zz_life": 1.5,
		"zz_damage": 8.0, ## A second.
		"zz_slow": 0.0,
		"zz_segments": 1, ## 2: the beam zigzags one more bounce.
		"beam_max": 6,
		"zz_bolt_delay": 0.5, ## After a hit, a bolt zigzags at the foe this much later.
	},
	"tiers": [
		{"text": "After a hit: a bolt at the foe + its path crackle 8/sec", "card": "After each hit, a lightning bolt zigzags at the foe and its path crackles.", "now": "After a hit: a bolt at the foe + its path crackle {zz_damage}/sec"},
		{"text": "Beam {^zz_damage} → {zz_damage}/sec", "zz_damage": 10.0},
		{"text": "+ The beam slows 20%", "card": "After each hit, a lightning bolt zigzags at the foe and its path crackles and slows.", "now": "After a hit: a bolt at the foe + its path crackle, slow {zz_slow%}%", "zz_slow": 0.2},
		{"text": "Beam lasts 1.5 → 2s", "zz_life": 2.0},
		{"text": "Zigzags 2 more bounces, {^zz_damage} → {zz_damage}/sec, slow 30%", "card": "After each hit, lightning zigzags at the foe and off the walls, its path crackling and slowing.", "now": "After a hit: a bolt at the foe + 3 zigzags {zz_damage}/sec, slow {zz_slow%}%", "zz_segments": 3, "zz_damage": 18.0, "zz_slow": 0.3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["spikyhair"], "front": ["zigmark"]},
	"sound": {"ouch": "ouch_tech", "pitch": 1.35},
}
