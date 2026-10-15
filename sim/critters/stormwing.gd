## Stormwing, the Thunderbird (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 83,
	"name": "Stormwing",
	"type": "Thunderbird",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "live",
	"color": "4895ef",
	"vibe": "A proud storm bird who arrives with a thunderclap.",
	"description": "Thunderbird. Every wall bounce charges a spark, and its next hit unleashes them as chain lightning that leaps from the foe to its last bounce points and stuns.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.0},
	"ability": [{"on": "wall", "do": "spark"}, {"on": "hit", "do": "storm"}],
	"params": {
		"spark_max": 4, ## Sparks it can hold.
		"storm_dps": 5.0, ## Chain lightning damage a second (1s).
		"storm_stun": 0.3,
		"storm_burn": 0.0, ## T3: burn per second, 2s.
		"thunder_radius": 200.0, ## T5 thunderclap at full sparks.
		"thunder_damage": 0.0,
	},
	"tiers": [
		{"text": "Wall bounces charge up to 4 sparks; its next hit spends them as chain lightning (5 a second) and stuns 0.3s"},
		{"text": "Lightning 6.5 a second", "storm_dps": 6.5},
		{"text": "The lightning also burns (2 a second for 2s)", "storm_burn": 2.0},
		{"text": "Holds 5 sparks", "spark_max": 5},
		{"text": "A full charge also calls a thunderclap (12 damage nearby)", "thunder_damage": 12.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "ffb300", "mouth": "smirk"}, "back": ["wings", "boltcrest"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.0},
}
