## Bramble, the Thorns (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 8,
	"name": "Bramble",
	"type": "Hedge",
	"rarity": "uncommon",
	"rarity_power": 1.106, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.89, 0.94, 1.00, 1.10, 1.21], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Disruptor",
	"status": "live",
	"color": "4f7a3a",
	"vibe": "Grumpy hedge that just wants to be left alone.",
	"description": "Bramble. When bumped, it sends {reflect_ratio%}% of the damage back at the attacker (up to {reflect_cap} a hit), and its sting burns {reflect_burn}/sec (a burning foe can't heal). Every {thorn_every}rd bump it takes shoots {thorn_count} thorns ({thorn_damage} dmg each) and leaves a thorn patch.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "hurt", "do": "reflect"}, {"on": "hurt", "do": "thorn_burst"}],
	"params": {
		"reflect_ratio": 0.18, ## Share of damage taken sent back.
		"reflect_low": 0.0, ## Share below half HP, when above 0.
		"reflect_burn": 0.5, ## Burn per second on the attacker for 2s, when above 0. Burning foes can't heal.
		"reflect_cap": 5.0, ## Most sent back from one hit.
		"reflect_from": "contact", ## all, contact, ability (not contact) or copying.
		"thorn_every": 3, ## Every this-many bumps taken, thorns fly...
		"thorn_count": 8,
		"thorn_damage": 3.0,
		"thorn_patch_dps": 2.0, ## ...and a thorn patch is left for 3s.
	},
	"tiers": [
		{"text": "Sends back 18% of bumps, burns; every 3rd: 8 thorns fly", "card": "Sends part of each bump back at the attacker with a burning sting, and sometimes fires thorns.", "now": "Sends back {reflect_ratio%}% of bumps, burns; every 3rd: {thorn_count} thorns fly"},
		{"text": "Sends back 18 → 22%", "reflect_ratio": 0.22},
		{"text": "Burn {^reflect_burn} → {reflect_burn}/sec", "reflect_burn": 1.0},
		{"text": "Sends back 22 → 26%", "reflect_ratio": 0.26},
		{"text": "+ Below 50% HP: sends back 50%", "card": "Sends bumps back with a burning sting, much more when it's low, and sometimes fires thorns.", "now": "Bumped: sends back {reflect_ratio%}% ({reflect_low%}% below 50% HP), burns", "reflect_low": 0.5},
	],
	"chaos": {"closing_walls": {"reflect_cap": 0.7}}, ## Short fights: big hitters can't outlast the sting.
	"art": {"eyes": {"sep": .3, "w": .17, "h": .19, "p": .09, "brow": .32, "mouth": "frown"}, "front": ["bramble"]},
	"sound": {"ouch": "ouch_nature", "pitch": 0.8},
}
