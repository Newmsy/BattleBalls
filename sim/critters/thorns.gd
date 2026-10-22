## Bramble, the Thorns (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 8,
	"name": "Bramble",
	"type": "Thorns",
	"rarity": "uncommon",
	"rarity_power": 1.106, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "4f7a3a",
	"vibe": "Grumpy hedge that just wants to be left alone.",
	"description": "Bramble. When bumped, it sends 18% of the damage back at the attacker (up to 5 a hit), and its sting burns 0.5/s (a burning foe can't heal).",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "hurt", "do": "reflect"}],
	"params": {
		"reflect_ratio": 0.18, ## Share of damage taken sent back.
		"reflect_low": 0.0, ## Share below half HP, when above 0.
		"reflect_burn": 0.5, ## Burn per second on the attacker for 2s, when above 0. Burning foes can't heal.
		"reflect_cap": 5.0, ## Most sent back from one hit.
		"reflect_from": "contact", ## all, contact, ability (not contact) or copying.
	},
	"tiers": [
		{"text": "Bumped: sends back 18% of dmg, sting burns 0.5/s", "now": "Bumped: sends back {reflect_ratio%}% of dmg, sting burns {reflect_burn}/s"},
		{"text": "Sends back 18 → 22%", "reflect_ratio": 0.22},
		{"text": "Burn 0.5 → 1/s", "reflect_burn": 1.0},
		{"text": "Sends back 22 → 26%", "reflect_ratio": 0.26},
		{"text": "+ Below 50% HP: sends back 50%", "now": "Bumped: sends back {reflect_ratio%}% ({reflect_low%}% below 50% HP), burns", "reflect_low": 0.5},
	],
	"chaos": {"closing_walls": {"reflect_cap": 0.7}}, ## Short fights: big hitters can't outlast the sting.
	"art": {"eyes": {"sep": .3, "w": .17, "h": .19, "p": .09, "brow": .32, "mouth": "frown"}, "back": ["thorn_ring"], "front": ["vines"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
