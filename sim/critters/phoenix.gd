## Ember, the Phoenix (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 14,
	"name": "Ember",
	"type": "Phoenix",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "live",
	"color": "ff6a2a",
	"vibe": "Proud and fiery; refuses to stay down.",
	"description": "Phoenix. Its hits scorch (a burning foe can't heal), and the first time it falls it bursts back to life at 20% HP in a blast of flame.",
	"stats": {"hp": 112.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "fall", "do": "revive"}, {"on": "hit", "do": "scorch"}],
	"params": {
		"revive_hp": 0.2,
		"revive_radius": 200.0,
		"revive_damage": 4.0,
		"revive_burn": 1.0, ## Per second, 3s.
		"revive_shield": 0.0,
		"revive_bolts": 0,
		"scorch_dps": 0.5,
		"scorch_secs": 1.5,
		"trail_every": 0.1, ## T3 flame trail.
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 4.0,
	},
	"tiers": [
		{"text": "Revives once at 20% HP"},
		{"text": "Revives at 25%", "revive_hp": 0.25},
		{"text": "After reviving it leaves a flame trail", "ability": [{"on": "always", "do": "fire_trail"}]},
		{"text": "Revives at 30%", "revive_hp": 0.3},
		{"text": "The rebirth is a firestorm: 8 fire bolts and a 20 shield", "revive_bolts": 8, "revive_shield": 20.0},
	],
	"chaos": {"double_trouble": {"hp": 1.05}}, ## Bigger beams pick off a fresh revive.
	"art": {"eyes": {"sep": .3, "w": .2, "h": .2, "p": .1, "iris": "ffb300", "brow": .3, "mouth": "smirk"}, "back": ["flame_crest"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.25},
}
