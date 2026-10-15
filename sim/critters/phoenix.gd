## Ember, the Phoenix (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 14,
	"name": "Ember",
	"type": "Phoenix",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "planned",
	"color": "ff6a2a",
	"vibe": "Proud and fiery; refuses to stay down.",
	"description": "Phoenix.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "hp_below", "hp": 0.0, "do": "revive"}],
	"params": {},
	"tiers": [
		{"text": "Revives once at 30% HP"},
		{"text": "Revives at 40%"},
		{"text": "Revive burns nearby foes"},
		{"text": "Revives at 50%"},
		{"text": "Revives twice"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .2, "p": .1, "iris": "ffb300", "brow": .3, "mouth": "smirk"}, "back": ["flame_crest"]},
	"sound": {},
}
