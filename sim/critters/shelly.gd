## Shelly, the Turtle (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 24,
	"name": "Shelly",
	"type": "Turtle",
	"rarity": "uncommon",
	"rarity_power": 1.156, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.87, 0.90, 0.94, 0.94, 0.94], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "52b788",
	"vibe": "A wise old sea turtle that knows exactly when to hide.",
	"description": "Turtle. Below 30% HP it tucks into its shell and spins: -{grow_armor%}% dmg taken, +{grow_speed%}% speed, and its hits deal x{shell_hit} and fling the foe away.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hp_below", "hp": 0.3, "do": "grow"}, {"on": "guard", "do": "grow_guard"}, {"on": "strike", "do": "shell_kick"}],
	"params": {
		"grow_radius": 0.0,
		"grow_speed": 0.25, ## Tucked in, it spins like a kicked shell...
		"grow_add": 0.0,
		"grow_secs": 0.0,
		"grow_stack": 0.0,
		"grow_heal": 0.0,
		"grow_pulse_radius": 150.0,
		"grow_pulse_damage": 0.0,
		"grow_bolts": 0.0,
		"bolt_damage": 3.0,
		"grow_armor": 0.4,
		"shell_hit": 1.3, ## ...its hits deal this x and fling the foe.
	},
	"tiers": [
		{"text": "Below 30% HP shell spin: -40% dmg taken, +25% speed", "now": "Below 30% HP shell spin: -{grow_armor%}% dmg taken, +{grow_speed%}% speed"},
		{"text": "Shell -40% → -45% dmg taken", "grow_armor": 0.45},
		{"text": "+ Tucking in heals 8", "now": "Below 30% HP shell spin: -{grow_armor%}% taken, heal {grow_heal}", "grow_heal": 8.0},
		{"text": "Shell -45% → -50% dmg taken", "grow_armor": 0.5},
		{"text": "+ Tucking in slams out: {grow_pulse_damage} + knockback", "now": "Below 30% HP shell spin: slam {grow_pulse_damage}, heal {grow_heal}, -{grow_armor%}%", "grow_pulse_damage": 10.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["shellhex"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.85},
}
