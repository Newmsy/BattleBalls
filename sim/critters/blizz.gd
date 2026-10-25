## Blizz, the Snowflake (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 66,
	"name": "Blizz",
	"type": "Snowflake",
	"rarity": "epic",
	"rarity_power": 0.968, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "90e0ef",
	"vibe": "A crisp, chatty snowflake that loves a good snowball fight.",
	"description": "Snowflake. Every 4s it drops a snowflake mine (up to 3) that blasts for {mine_damage} and leaves a frost patch that slows foes 20% for 3s.",
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.5},
	"ability": [{"on": "every", "secs": 4.0, "do": "snow_mine"}],
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
		{"text": "Mine every 4s: 8 dmg + slow 20% patch", "card": "Drops snowflake mines that blast foes and leave slowing frost.", "now": "Mine every 4s: {mine_damage} dmg + slow {frost_slow%}% patch"},
		{"text": "Mines {^mine_damage} → {mine_damage}", "mine_damage": 10.0},
		{"text": "+ Mines go off when the foe gets close", "card": "Drops snowflake mines that blow up as foes come near and leave slowing frost.", "now": "Proximity mine every 4s: {mine_damage} dmg + slow {frost_slow%}% patch", "mine_trigger": 46.0},
		{"text": "Max mines 3 → 4", "mine_max": 4.0},
		{"text": "+ 2 frost patches at once freeze foe 0.4s", "card": "Drops snowflake mines that blow up as foes come near. Foes caught in two frost patches freeze.", "now": "Proximity mine every 4s: {mine_damage} dmg, patches slow + freeze", "freeze_secs": 0.4, "ability": [{"on": "always", "do": "snow_freeze"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["snowflake"], "front": ["cheeks"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.3},
}
