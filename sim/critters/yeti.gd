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
	"rarity_power": 0.935, ## Per rarity step; also trimmed after the 2026-10-22 round robin (tools/round_robin.gd): it topped its rarity.
	"color": "d6ccc2",
	"vibe": "A huggable mountain yeti with a very loud temper.",
	"description": "Yeti. It's big and furry, and at 50% HP it roars out an avalanche that deals {roar_damage}, knocks back and slows everything nearby {roar_slow%}% for {roar_secs}s.",
	"stats": {"hp": 140.0, "radius": 69.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "roar"}],
	"params": {
		"roar_radius": 260.0,
		"roar_damage": 12.0,
		"roar_slow": 0.4,
		"roar_secs": 2.0,
		"roar_drifts": 0.0,
		"snowball_secs": 0.0, ## T5: a roar rolls it up in a snowball this long (x1.25 size, x1.5 hits).
	},
	"tiers": [
		{"text": "At 50% HP roars: 12, knockback, slow 40%", "now": "At 50% HP roars: {roar_damage}, knockback, slow {roar_slow%}%"},
		{"text": "Avalanche {^roar_damage} → {roar_damage}", "roar_damage": 16.0},
		{"text": "+ Roars again at 25% HP", "now": "At 50% and 25% HP roars: {roar_damage}, knockback, slow {roar_slow%}%", "ability": [{"on": "hp_below", "hp": 0.25, "do": "roar"}]},
		{"text": "Slow lasts 2 → 3s", "roar_secs": 3.0},
		{"text": "+ Roars roll a snowball (x1.5 hits 3s), 3 drifts", "now": "At 50%/25% HP roars {roar_damage}, drifts, snowball x1.5 hits", "roar_drifts": 3.0, "snowball_secs": 3.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "teeth"}, "back": ["horns"], "front": ["fringe"], "scale": 1.1},
	"sound": {"ouch": "ouch_frost", "pitch": 0.7},
}
