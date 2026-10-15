## Blizz, the Snowflake (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 66,
	"name": "Blizz",
	"type": "Snowflake",
	"rarity": "epic",
	"role": "Zoner",
	"status": "live",
	"color": "90e0ef",
	"vibe": "A crisp, chatty snowflake that loves a good snowball fight.",
	"description": "Snowflake. Every 4 seconds it drops a snowflake mine, and each blast leaves a freezing patch that slows foes.",
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.5},
	"ability": [{"on": "every", "secs": 4.0, "do": "snow_mine"}, {"on": "always", "do": "chill"}],
	"params": {
		"mine_arm": 1.0,
		"mine_radius": 80.0,
		"mine_damage": 8.0,
		"mine_max": 3.0,
		"mine_life": 30.0,
		"mine_trigger": 16.0,
		"frost_radius": 100.0,
		"frost_secs": 3.0,
		"frost_slow": 0.2,
		"freeze_secs": 0.0,
	},
	"tiers": [
		{"text": "Every 4s a snowflake mine (8 damage) that leaves a 20% slow patch"},
		{"text": "Mines deal 10", "mine_damage": 10.0},
		{"text": "Mines go off when the foe gets close", "mine_trigger": 46.0},
		{"text": "Up to 4 mines", "mine_max": 4.0},
		{"text": "Standing in two frost patches freezes the foe for 0.4s", "freeze_secs": 0.4, "ability": [{"on": "always", "do": "frostbite"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["snowflake"], "front": ["cheeks"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.3},
}
