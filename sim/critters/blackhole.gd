## Void, the Black Hole (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 13,
	"name": "Void",
	"type": "Black Hole",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "live",
	"color": "0d0b17",
	"vibe": "Ancient, silent and a little terrifying.",
	"description": "Black Hole. Every 8s it collapses, dragging everything in, then explodes in a ring of light that scorches (a burning foe can't heal).",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "always", "do": "collapse"}, {"on": "guard", "do": "collapse_guard"}],
	"params": {
		"collapse_every": 8.0,
		"collapse_secs": 1.5,
		"collapse_range": 450.0,
		"collapse_accel": 950.0,
		"collapse_damage": 18.0,
		"collapse_radius": 260.0,
		"collapse_burn": 1.0, ## The blast burns this much a second for 3s (a burning foe can't heal).
		"collapse_ring": 0.0, ## Burning ring damage a second, 3s, when above 0.
		"collapse_guard": 1.0, ## Damage taken while collapsing.
	},
	"tiers": [
		{"text": "Collapses every 8s, blast 18"},
		{"text": "Blast 22", "collapse_damage": 22.0},
		{"text": "Takes 30% less damage while collapsing", "collapse_guard": 0.7},
		{"text": "Every 7s", "collapse_every": 7.0},
		{"text": "The blast leaves a burning ring", "collapse_ring": 5.0},
	],
	"art": {"eyes": {"sep": .3, "dot": true, "mouth": "none", "ink": "ffffff", "mouth_ink": "e8e0ff"}, "body": "starfield", "back": ["swirl_arms"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.6},
}
