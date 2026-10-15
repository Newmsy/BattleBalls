## Fizz, the Soda (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 34,
	"name": "Fizz",
	"type": "Soda",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "live",
	"color": "ff4da6",
	"vibe": "A shaken-up soda that's always one bounce away from popping.",
	"description": "Soda. Every wall bounce builds pressure, and at 10 it pops for a burst of speed and a harder hit.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "wall", "do": "fizz"}, {"on": "strike", "do": "fizz_hit"}],
	"params": {
		"fizz_at": 10.0,
		"fizz_speed": 0.4,
		"fizz_secs": 2.0,
		"fizz_damage": 6.0,
		"fizz_puddle": 0.0,
		"fizz_dash": 0.0,
		"fizz_splash": 0.0,
		"fizz_splash_radius": 100.0,
	},
	"tiers": [
		{"text": "Pops at 10 pressure: +40% speed for 2s, +6 on its next hit"},
		{"text": "Pops at 8 pressure", "fizz_at": 8.0},
		{"text": "Popping leaves a fizz puddle (25% slow)", "fizz_puddle": 0.25},
		{"text": "The pop adds +8 damage", "fizz_damage": 8.0},
		{"text": "Popping dashes at the foe and the hit splashes (6 damage)", "fizz_dash": 1.0, "fizz_splash": 6.0},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["ringpull"], "front": ["fizz"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
