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
	"description": "Yeti. It's big and furry, and below half HP it roars out an avalanche that hurts, shoves and slows everything nearby.",
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
		{"text": "At half HP it roars: 15 damage, knockback, 40% slow for 2s"},
		{"text": "Avalanche deals 18", "roar_damage": 18.0},
		{"text": "Roars again at 25% HP", "ability": [{"on": "hp_below", "hp": 0.25, "do": "roar"}]},
		{"text": "The slow lasts 3s", "roar_secs": 3.0},
		{"text": "The avalanche leaves 3 snowdrifts (30% slow)", "roar_drifts": 3.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "teeth"}, "back": ["horns"], "front": ["fringe"], "scale": 1.1},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
