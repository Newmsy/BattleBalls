## Void, the Black Hole (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 13,
	"name": "Void",
	"type": "Black Hole",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "planned",
	"color": "0d0b17",
	"vibe": "Ancient, silent and a little terrifying.",
	"description": "Black Hole.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "every", "secs": 10.0, "do": "field"}, {"on": "every", "secs": 10.0, "do": "pulse"}],
	"params": {},
	"tiers": [
		{"text": "Collapses every 10s"},
		{"text": "Every 9s"},
		{"text": "Stronger pull"},
		{"text": "Every 8s"},
		{"text": "Leaves a mini black hole"},
	],
	"art": {"eyes": {"sep": .3, "dot": true, "mouth": "none", "ink": "ffffff", "mouth_ink": "e8e0ff"}, "body": "starfield", "back": ["swirl_arms"]},
	"sound": {},
}
