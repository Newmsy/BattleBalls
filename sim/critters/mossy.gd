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
	"description": "Moss ball. Every hit plants moss on the foe that drains 0.4/s for 3s and feeds Mossy 0.4 HP/s; unbumped for 3s, it also regrows 0.8 HP/s.",
	"stats": {"hp": 110.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "hurt", "do": "regrow"}, {"on": "always", "do": "regrow"}, {"on": "hit", "do": "moss"}],
	"params": {
		"regrow_after": 3.0,
		"regrow_hps": 0.8,
		"regrow_spores": 0.0,
		"moss_dps": 0.4, ## Moss a hit plants on the foe...
		"moss_secs": 3.0,
		"moss_heal": 0.4, ## ...and what it feeds Mossy a second.
	},
	"tiers": [
		{"text": "Moss drains 0.4/s, feeds 0.4/s · unbumped 3s: regrow 0.8/s", "now": "Moss drains {moss_dps}/s, feeds {moss_heal}/s · unbumped {regrow_after}s: regrow {regrow_hps}/s"},
		{"text": "Moss 0.4 → 0.5/s, regrow 0.8 → 1/s", "moss_dps": 0.5, "moss_heal": 0.5, "regrow_hps": 1.0},
		{"text": "Moss lasts 3 → 4s, unbumped wait 3 → 2.5s", "moss_secs": 4.0, "regrow_after": 2.5},
		{"text": "Moss 0.5 → 0.6/s, regrow 1 → 1.2/s", "moss_dps": 0.6, "moss_heal": 0.6, "regrow_hps": 1.2},
		{"text": "+ Regrowing sheds stinging spores (3/s)", "now": "Moss {moss_dps}/s, feeds {moss_heal}/s · regrow {regrow_hps}/s + spores {regrow_spores}/s", "regrow_spores": 3.0},
	],
	"chaos": {"closing_walls": {"hp": 1.1}, "bumpers": {"hp": 1.1}}, ## Shrinking walls and bumper knocks leave no quiet moment to regrow
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["fuzz", "mushroom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
