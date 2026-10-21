## Mossy, the Moss ball (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 27,
	"name": "Mossy",
	"type": "Moss ball",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "2d6a4f",
	"vibe": "A sleepy forest moss ball that heals up whenever it's left in peace.",
	"description": "Moss ball. When it hasn't been bumped for 3s, it slowly regrows 0.8 HP/s.",
	"stats": {"hp": 110.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "hurt", "do": "regrow"}, {"on": "always", "do": "regrow"}],
	"params": {
		"regrow_after": 3.0,
		"regrow_hps": 0.8,
		"regrow_spores": 0.0,
	},
	"tiers": [
		{"text": "Unbumped for 3s: regrow 0.8 HP/s", "now": "Unbumped for {regrow_after}s: regrow {regrow_hps} HP/s"},
		{"text": "Regrow 0.8 → 1 HP/s", "regrow_hps": 1.0},
		{"text": "Unbumped wait 3 → 2.5s", "regrow_after": 2.5},
		{"text": "Regrow 1 → 1.2 HP/s", "regrow_hps": 1.2},
		{"text": "+ Regrowing sheds stinging spores (3/s)", "now": "Unbumped for {regrow_after}s: regrow {regrow_hps} HP/s + spores {regrow_spores}/s", "regrow_spores": 3.0},
	],
	"chaos": {"closing_walls": {"hp": 1.1}, "bumpers": {"hp": 1.1}}, ## Shrinking walls and bumper knocks leave no quiet moment to regrow
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["fuzz", "mushroom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
