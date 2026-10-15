## Orbit, the Gravity (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 11,
	"name": "Orbit",
	"type": "Gravity",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "live",
	"color": "5b4bd6",
	"vibe": "Serene little planet; everything comes to it eventually.",
	"description": "Gravity. Gently pulls foes toward itself, and its little moons bonk anything that comes close.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "always", "do": "pull"}, {"on": "always", "do": "moons"}],
	"params": {
		"pull_range": 300.0,
		"pull_accel": 250.0, ## Steering at full strength, units/s^2.
		"pull_close": 0, ## 1: stronger the closer they are.
		"moon_count": 1,
		"moon_orbit": 40.0, ## Distance beyond its edge.
		"moon_size": 14.0,
		"moon_damage": 5.0,
		"moon_spin": 3.0, ## Radians a second.
		"moon_cooldown": 0.5,
		"flare_radius": 200.0, ## T5 ring flare.
		"flare_slam": 8.0,
	},
	"tiers": [
		{"text": "1 moon"},
		{"text": "2 moons", "moon_count": 2},
		{"text": "The pull grows stronger up close", "pull_close": 1, "pull_accel": 450.0},
		{"text": "3 moons", "moon_count": 3},
		{"text": "Every 6s its ring flares, flinging foes into walls", "ability": [{"on": "every", "secs": 6.0, "do": "flare"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "closed": true, "mouth": "smile"}, "back": ["orbit_ring"], "front": ["orbit_ring"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.7},
}
