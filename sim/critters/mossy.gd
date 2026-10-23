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
	"description": "Moss ball. Every hit plants moss on the foe that drains {moss_dps}/sec for {moss_secs}s and heals Mossy {moss_heal} HP/sec; unbumped for {regrow_after}s, it also regrows {regrow_hps} HP/sec.",
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
		{"text": "Moss 0.4/sec, heals 0.4 HP/sec · idle 3s: +0.8 HP/sec", "now": "Moss {moss_dps}/sec, heals {moss_heal} HP/sec · idle {regrow_after}s: +{regrow_hps} HP/sec"},
		{"text": "Moss {^moss_dps} → {moss_dps}/sec, regrow {^regrow_hps} → {regrow_hps}/sec", "moss_dps": 0.5, "moss_heal": 0.5, "regrow_hps": 1.0},
		{"text": "Moss lasts 3 → 4s, idle wait 3 → 2.5s", "moss_secs": 4.0, "regrow_after": 2.5},
		{"text": "Moss {^moss_dps} → {moss_dps}/sec, regrow {^regrow_hps} → {regrow_hps}/sec", "moss_dps": 0.6, "moss_heal": 0.6, "regrow_hps": 1.2},
		{"text": "+ Regrowing sheds stinging spores (3/sec)", "now": "Moss {moss_dps}/sec, heals {moss_heal} HP/sec · +{regrow_hps} HP/sec, spores", "regrow_spores": 3.0},
	],
	"chaos": {"closing_walls": {"hp": 1.1}, "bumpers": {"hp": 1.1}}, ## Shrinking walls and bumper knocks leave no quiet moment to regrow
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["fuzz", "mushroom"]},
	"sound": {"ouch": "ouch_nature", "pitch": 0.9},
}
