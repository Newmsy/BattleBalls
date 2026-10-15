## Boulder, the Juggernaut (Common Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 2,
	"name": "Boulder",
	"type": "Juggernaut",
	"rarity": "common",
	"role": "Bruiser",
	"status": "planned",
	"color": "7d8799",
	"vibe": "Big, slow and completely unbothered.",
	"description": "Juggernaut.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "always", "do": "armor"}],
	"params": {},
	"tiers": [
		{"text": "Takes 20% less damage"},
		{"text": "25% less"},
		{"text": "30% less, hits stun briefly"},
		{"text": "35% less"},
		{"text": "Shockwave on every hit"},
	],
	"art": {"eyes": {"sep": .24, "w": .11, "h": .12, "p": .08, "uni": true, "mouth": "flat"}, "front": ["rock_band"], "scale": 1.15},
	"sound": {},
}
