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
		"ripple_wave_radius": 0.0, ## T5: each bounce also breaks as a wave this big...
		"ripple_wave_damage": 8.0, ## ...dealing this.
		"ripple_reach": 200.0, ## Each way along the wall.
		"ripple_life": 1.0,
		"ripple_damage": 10.0, ## A second.
		"ripple_slow": 0.0,
		"ripple_corner": 0, ## 1: ripples turn corners.
		"beam_max": 8,
	},
	"tiers": [
		{"text": "Wall bounces send ripples both ways along the wall (10/s)"},
		{"text": "Ripples deal 12/s", "ripple_damage": 12.0},
		{"text": "The ripple slows 20%", "ripple_slow": 0.2},
		{"text": "Ripples run further", "ripple_reach": 300.0},
		{"text": "Tidal: ripples turn corners; each bounce also makes a wave (8)", "ripple_corner": 1, "ripple_wave_radius": 220.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["droptop"], "front": ["shine"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
