## Ripple, the Water drop (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 47,
	"name": "Ripple",
	"type": "Water drop",
	"rarity": "rare",
	"role": "Zoner",
	"status": "live",
	"color": "4361ee",
	"vibe": "A bouncy water drop that makes waves everywhere it lands.",
	"description": "Water drop. Every wall bounce sends a damaging ripple along that wall.",
	"stats": {"hp": 120.0, "radius": 66.0, "speed": 400.0, "contact_damage": 19.5},
	"ability": [{"on": "wall", "do": "ripple"}, {"on": "always", "do": "slows"}],
	"params": {
		"ripple_reach": 200.0, ## Each way along the wall.
		"ripple_life": 1.0,
		"ripple_dps": 10.0,
		"ripple_slow": 0.0,
		"ripple_corner": 0, ## 1: ripples turn corners.
		"beam_max": 8,
	},
	"tiers": [
		{"text": "Wall bounces send a ripple along the wall"},
		{"text": "Ripples deal 12/s", "ripple_dps": 12.0},
		{"text": "The ripple slows 20%", "ripple_slow": 0.2},
		{"text": "Ripples run further", "ripple_reach": 300.0},
		{"text": "Ripples turn corners", "ripple_corner": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["droptop"], "front": ["shine"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
