## Zip, the Speedster (Common Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 4,
	"name": "Zip",
	"type": "Speedster",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "live",
	"color": "ffb020",
	"vibe": "A cocky sprinter who never stops moving.",
	"description": "Speedster. Speeds up on every wall bounce and hits harder the faster it goes. Getting bumped resets it.",
	"stats": {"hp": 105.0, "radius": 48.0, "speed": 400.0, "contact_damage": 12.5},
	"ability": [{"on": "wall", "do": "accelerate"}, {"on": "strike", "do": "momentum"}, {"on": "hurt", "do": "brake"}],
	"params": {
		"speed_gain": 0.12, ## Speed added per wall bounce, as a share of current speed.
		"max_speed_mult": 1.8, ## Top speed as a multiple of base.
		"trail_every": 0.08, ## T5 afterimage.
		"trail_width": 34.0,
		"trail_life": 0.8,
		"trail_dps": 8.0,
	},
	"tiers": [
		{"text": "+12% speed per wall bounce, up to 1.8x"},
		{"text": "Up to 2x", "max_speed_mult": 2.0},
		{"text": "+14% per bounce", "speed_gain": 0.14},
		{"text": "Up to 2.2x", "max_speed_mult": 2.2},
		{"text": "Above 1.3x speed it leaves a damaging afterimage (8/s)", "ability": [{"on": "always", "do": "afterimage"}]},
	],
	"chaos": {"rink": {"hp": 1.06}, "big_head": {"hp": 1.05}, "hyper_speed": {"speed_gain": 0.85}, "double_trouble": {"speed_gain": 0.67}}, ## Small and quick: Neon Rink and Big Head hit it more; fast twists overfeed it.
	"art": {"eyes": {"sep": .3, "w": .21, "h": .14, "p": .09, "brow": .22, "mouth": "smirk"}, "back": ["speed_streaks"], "front": ["headband"]},
	"sound": {},
}
