## Orbit, the Gravity (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 11,
	"name": "Orbit",
	"type": "Gravity",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "planned",
	"color": "5b4bd6",
	"vibe": "Serene little planet; everything comes to it eventually.",
	"description": "Gravity.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "always", "do": "field"}],
	"params": {},
	"tiers": [
		{"text": "Weak pull field"},
		{"text": "Stronger pull"},
		{"text": "Pull also slows"},
		{"text": "Bigger field"},
		{"text": "Pull pulse slams foes into walls"},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "closed": true, "mouth": "smile"}, "back": ["orbit_ring"], "front": ["orbit_ring"]},
	"sound": {},
}
