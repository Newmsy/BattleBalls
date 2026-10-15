## Minnow, the Fish (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 35,
	"name": "Minnow",
	"type": "Fish",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "live",
	"color": "00e5ff",
	"vibe": "A tiny anxious fish that finds a second gear when things look bad.",
	"description": "Fish. It's small and slippery, and at half HP it panics into a permanent burst of speed.",
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
		{"text": "Small; at half HP panics: +35% speed"},
		{"text": "Panic speed +40%", "grow_speed": 0.4},
		{"text": "Panicking also heals 8", "grow_heal": 8.0},
		{"text": "Panic speed +45%", "grow_speed": 0.45},
		{"text": "The panic splashes the foe away (8 damage)", "grow_pulse_damage": 8.0},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["fantail"], "scale": 0.85},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.4},
}
