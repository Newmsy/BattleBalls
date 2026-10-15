## Fuse, the Bomber (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 6,
	"name": "Fuse",
	"type": "Bomber",
	"rarity": "rare",
	"role": "Zoner",
	"status": "planned",
	"color": "2b3a67",
	"vibe": "Chaotic gremlin who laughs at its own explosions.",
	"description": "Bomber.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "wall", "do": "mine"}],
	"params": {},
	"tiers": [
		{"text": "1 mine per bounce, max 3"},
		{"text": "Max 4 mines"},
		{"text": "Bigger blast"},
		{"text": "Max 6 mines"},
		{"text": "Mines chain-detonate"},
	],
	"art": {"eyes": {"sep": .3, "w": .23, "h": .26, "p": .07, "mis": true, "mouth": "teeth"}, "body": "bomb", "front": ["fuse"]},
	"sound": {},
}
