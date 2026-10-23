## Stormwing, the Thunderbird (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 83,
	"name": "Stormwing",
	"type": "Thunderbird",
	"rarity": "legendary",
	"rarity_power": 0.942, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.06, 1.03, 1.00, 1.11, 1.25], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "4895ef",
	"vibe": "A proud storm bird who arrives with a thunderclap.",
	"description": "Thunderbird. Every wall bounce charges a spark (up to 4), and its next hit unleashes them as chain lightning ({storm_dps}/sec) that leaps from the foe to its last bounce points and stuns 0.3s.",
	"stats": {"hp": 121.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.5},
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
		{"text": "Bounces store sparks (max 4); next hit chains 5/sec", "now": "Bounces store sparks (max {spark_max}); next hit chains {storm_dps}/sec"},
		{"text": "Lightning {^storm_dps} → {storm_dps}/sec", "storm_dps": 6.5},
		{"text": "+ The lightning burns {storm_burn}/sec for 2s", "now": "Bounces store sparks (max {spark_max}); next hit chains {storm_dps}/sec + burn", "storm_burn": 2.0},
		{"text": "Max sparks 4 → 5", "spark_max": 5},
		{"text": "+ A full charge calls a thunderclap ({thunder_damage} dmg)", "now": "Stores up to {spark_max} sparks; next hit chains {storm_dps}/sec + burn, clap", "thunder_damage": 12.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "ffb300", "mouth": "smirk"}, "back": ["wings", "boltcrest"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 1.0},
}
