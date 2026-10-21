## Shelly, the Turtle (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 24,
	"name": "Shelly",
	"type": "Turtle",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "52b788",
	"vibe": "A wise old sea turtle that knows exactly when to hide.",
	"description": "Turtle. Below 30% HP it pulls into its shell: -40% dmg taken, but -20% speed.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hp_below", "hp": 0.3, "do": "grow"}, {"on": "guard", "do": "grow_guard"}],
	"params": {
		"grow_radius": 0.0,
		"grow_speed": -0.2,
		"grow_add": 0.0,
		"grow_secs": 0.0,
		"grow_stack": 0.0,
		"grow_heal": 0.0,
		"grow_pulse_radius": 150.0,
		"grow_pulse_damage": 0.0,
		"grow_bolts": 0.0,
		"bolt_damage": 3.0,
		"grow_armor": 0.4,
	},
	"tiers": [
		{"text": "Below 30% HP: -40% dmg taken, -20% speed", "now": "Below 30% HP: -{grow_armor%}% dmg taken, {grow_speed%}% speed"},
		{"text": "Shell -40% → -45% dmg taken", "grow_armor": 0.45},
		{"text": "+ Tucking in heals 8", "now": "Below 30% HP: -{grow_armor%}% dmg taken, {grow_speed%}% speed, heal {grow_heal}", "grow_heal": 8.0},
		{"text": "Shell -45% → -50% dmg taken", "grow_armor": 0.5},
		{"text": "+ Tucking in slams out: 10 + knockback", "now": "Below 30% HP: slam {grow_pulse_damage}, heal {grow_heal}, -{grow_armor%}% dmg taken", "grow_pulse_damage": 10.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["shellhex"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
