## Yeti, the Yeti (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 43,
	"name": "Yeti",
	"type": "Yeti",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "live",
	"color": "d6ccc2",
	"vibe": "A huggable mountain yeti with a very loud temper.",
	"description": "Yeti. It's big and furry, and at 50% HP it roars out an avalanche that deals 15, knocks back and slows everything nearby 40% for 2s.",
	"stats": {"hp": 140.0, "radius": 69.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "roar"}],
	"params": {
		"roar_radius": 260.0,
		"roar_damage": 15.0,
		"roar_slow": 0.4,
		"roar_secs": 2.0,
		"roar_drifts": 0.0,
	},
	"tiers": [
		{"text": "At 50% HP roars: 15, knockback, slow 40%", "now": "At 50% HP roars: {roar_damage}, knockback, slow {roar_slow%}%"},
		{"text": "Avalanche 15 → 18", "roar_damage": 18.0},
		{"text": "+ Roars again at 25% HP", "now": "At 50% and 25% HP roars: {roar_damage}, knockback, slow {roar_slow%}%", "ability": [{"on": "hp_below", "hp": 0.25, "do": "roar"}]},
		{"text": "Slow lasts 2 → 3s", "roar_secs": 3.0},
		{"text": "+ Leaves 3 snowdrifts (slow 30%)", "now": "At 50%/25% HP roars: {roar_damage}, knockback, slow, {roar_drifts} drifts", "roar_drifts": 3.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "teeth"}, "back": ["horns"], "front": ["fringe"], "scale": 1.1},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
