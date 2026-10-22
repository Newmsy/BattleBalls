## Ripple, the Water drop (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 47,
	"name": "Ripple",
	"type": "Water drop",
	"rarity": "rare",
	"rarity_power": 1.052, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "4361ee",
	"vibe": "A bouncy water drop that makes waves everywhere it lands.",
	"description": "Water drop. Every wall bounce sends a damaging ripple along that wall (10/s).",
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
		{"text": "Bounces send a ripple along the wall: 10/s", "now": "Bounces send a ripple along the wall: {ripple_damage}/s"},
		{"text": "Ripple 10 → 12/s", "ripple_damage": 12.0},
		{"text": "+ Ripples slow 20%", "now": "Bounces send a slowing ripple along the wall: {ripple_damage}/s", "ripple_slow": 0.2},
		{"text": "Ripple reach +50%", "ripple_reach": 300.0},
		{"text": "+ Ripples turn corners · bounces make a wave (8)", "now": "Bounces: corner-turning ripple {ripple_damage}/s + wave {ripple_wave_damage}", "special": "Tidal", "ripple_corner": 1, "ripple_wave_radius": 220.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["droptop"], "front": ["shine"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
