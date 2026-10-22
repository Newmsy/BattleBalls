## Minnow, the Fish (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 35,
	"name": "Minnow",
	"type": "Fish",
	"rarity": "uncommon",
	"rarity_power": 1.087, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "00e5ff",
	"vibe": "A tiny anxious fish that finds a second gear when things look bad.",
	"description": "Fish. It's small and slippery, and at 50% HP it panics into a lasting +35% speed.",
	"stats": {"hp": 125.0, "radius": 54.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "grow"}],
	"params": {
		"grow_radius": 0.0,
		"grow_speed": 0.35,
		"grow_add": 0.0,
		"grow_secs": 0.0,
		"grow_stack": 0.0,
		"grow_heal": 0.0,
		"grow_pulse_radius": 120.0,
		"grow_pulse_damage": 0.0,
		"grow_bolts": 0.0,
		"bolt_damage": 3.0,
	},
	"tiers": [
		{"text": "Small; at 50% HP panics: +35% speed", "now": "Small; at 50% HP panics: +{grow_speed%}% speed"},
		{"text": "Panic speed +35% → +40%", "grow_speed": 0.4},
		{"text": "+ Panicking heals 8", "now": "Small; at 50% HP panics: +{grow_speed%}% speed, heal {grow_heal}", "grow_heal": 8.0},
		{"text": "Panic speed +40% → +45%", "grow_speed": 0.45},
		{"text": "+ The panic splashes the foe away for 8", "now": "Small; at 50% HP panics: +{grow_speed%}% speed, heal {grow_heal}, splash {grow_pulse_damage}", "grow_pulse_damage": 8.0},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["fantail"], "scale": 0.85},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.4},
}
