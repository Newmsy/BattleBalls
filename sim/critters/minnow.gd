## Minnow, the Fish (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 35,
	"name": "Minnow",
	"type": "Fish",
	"rarity": "uncommon",
	"rarity_power": 1.087, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.97, 1.02, 1.07, 1.12, 1.00], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "00e5ff",
	"vibe": "A tiny anxious fish that finds a second gear when things look bad.",
	"description": "Fish. It's small and slippery, and at 50% HP it panics into a lasting +{grow_speed%}% speed while {school_count} little fish swim round it for {school_secs}s, nipping foes ({school_damage} dmg) and each soaking half of one hit.",
	"stats": {"hp": 125.0, "radius": 54.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "grow"}, {"on": "always", "do": "school"}, {"on": "guard", "do": "school_guard"}],
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
		"school_count": 2, ## The panic calls this many little fish...
		"school_secs": 6.0, ## ...for this long: they nip foes and each soaks half a hit.
		"school_damage": 3.0,
		"school_size": 14.0,
	},
	"tiers": [
		{"text": "Small; at 50% HP panics: +35% speed, 2 fish join", "now": "Small; at 50% HP panics: +{grow_speed%}% speed, {school_count} fish join"},
		{"text": "Panic speed +35% → +40%", "grow_speed": 0.4},
		{"text": "+ Panicking heals 8", "now": "At 50% HP panics: +{grow_speed%}% speed, heal {grow_heal}, {school_count} fish", "grow_heal": 8.0},
		{"text": "Panic speed +40% → +45%", "grow_speed": 0.45},
		{"text": "+ Panic splashes foe away ({grow_pulse_damage} dmg) · fish 2 → 3", "now": "At 50% HP panics: +{grow_speed%}% speed, heal, splash, {school_count} fish", "grow_pulse_damage": 8.0, "school_count": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["fantail"], "front": ["scales"], "scale": 0.85},
	"sound": {"ouch": "ouch_sea", "pitch": 1.4},
}
