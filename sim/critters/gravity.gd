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
	"description": "Gravity. Gently pulls foes toward itself, and its molten moons bonk for 5 and singe anything that comes close (1/s; a burning foe can't heal).",
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
		"moon_burn": 1.0, ## Moon hits burn this much a second for 2s (a burning foe can't heal).
		"moon_spin": 3.0, ## Radians a second.
		"moon_cooldown": 0.5,
		"flare_radius": 200.0, ## T5 ring flare.
		"flare_slam": 8.0,
	},
	"tiers": [
		{"text": "Pulls foes in; 1 molten moon bonks 5 + burn", "now": "Pulls foes in; {moon_count} molten moon bonks {moon_damage} + burn"},
		{"text": "Moons 1 → 2", "now": "Pulls foes in; {moon_count} molten moons bonk {moon_damage} + burn", "moon_count": 2},
		{"text": "Pull +80%, strongest up close", "pull_close": 1, "pull_accel": 450.0},
		{"text": "Moons 2 → 3", "moon_count": 3},
		{"text": "+ Every 6s a ring flare flings foes into walls", "now": "Pulls foes in; {moon_count} moons bonk {moon_damage} · flare every 6s", "ability": [{"on": "every", "secs": 6.0, "do": "flare"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "closed": true, "mouth": "smile"}, "back": ["orbit_ring"], "front": ["orbit_ring"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 0.7},
}
