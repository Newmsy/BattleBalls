## Mole, the Mole (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 52,
	"name": "Mole",
	"type": "Mole",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "live",
	"color": "b08968",
	"vibe": "A busy little digger who pops up exactly where you didn't want it.",
	"description": "Mole. Every 6 seconds it burrows for a second, taking much less damage, then bursts up with a shove.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "every", "secs": "dig_every", "do": "dig"}, {"on": "guard", "do": "phased"}, {"on": "always", "do": "surface"}],
	"params": {
		"dig_every": 6.0,
		"phase_secs": 1.0, ## Seconds underground.
		"phase_guard": 0.3, ## Damage taken underground.
		"dig_radius": 100.0, ## The shove as it surfaces.
		"dig_damage": 8.0,
		"dig_rush": 0.0, ## T3: extra speed for 1s after surfacing.
		"dig_clods": 0, ## T5: dirt clods lobbed at the foe.
		"clod_damage": 4.0,
	},
	"tiers": [
		{"text": "Every 6s burrows (70% less damage), bursts up for 8"},
		{"text": "Bursts up for 10", "dig_damage": 10.0},
		{"text": "Bursts up with a 20% speed rush for 1s", "dig_rush": 0.2},
		{"text": "Digs every 5s", "dig_every": 5.0},
		{"text": "The burst throws 3 dirt clods where the foe is going (4 each)", "dig_clods": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "smile"}, "front": ["helmet", "starnose"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.1},
}
