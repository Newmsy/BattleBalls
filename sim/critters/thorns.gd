## Bramble, the Thorns (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 8,
	"name": "Bramble",
	"type": "Thorns",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "live",
	"color": "4f7a3a",
	"vibe": "Grumpy hedge that just wants to be left alone.",
	"description": "Bramble. When hurt, sends a quarter of the damage back at the attacker.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "hurt", "do": "reflect"}],
	"params": {
		"reflect_ratio": 0.3, ## Share of damage taken sent back.
		"reflect_low": 0.0, ## Share below half HP, when above 0.
		"reflect_burn": 0.0, ## Burn per second on the attacker for 2s, when above 0.
		"reflect_cap": 5.0, ## Most sent back from one hit.
		"reflect_from": "all", ## all, ability (not contact) or copying.
	},
	"tiers": [
		{"text": "Sends back 25% of damage taken"},
		{"text": "30%", "reflect_ratio": 0.3},
		{"text": "Thorns also burn", "reflect_burn": 1.0},
		{"text": "35%", "reflect_ratio": 0.35},
		{"text": "Below half HP the vine bursts: 50%", "reflect_low": 0.5},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "h": .19, "p": .09, "brow": .32, "mouth": "frown"}, "back": ["thorn_ring"], "front": ["vines"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
