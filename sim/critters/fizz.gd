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
	"description": "Soda. Every bounce off the arena walls shakes it up, and at 6 it bursts: a soda geyser blasts nearby foes away and it rockets off with a harder next hit.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "wall", "do": "fizz"}, {"on": "strike", "do": "fizz_hit"}],
	"params": {
		"fizz_at": 6.0,
		"fizz_speed": 0.5,
		"fizz_secs": 2.0,
		"fizz_damage": 6.0,
		"fizz_blast": 7.0, ## The burst: damage to foes near it, knocked away.
		"fizz_blast_radius": 170.0,
		"fizz_puddle": 0.0,
		"fizz_dash": 0.0,
		"fizz_splash": 0.0,
		"fizz_splash_radius": 100.0,
	},
	"tiers": [
		{"text": "Bursts at 6 shakes: geyser blast 7 (knocks foes away), +50% speed for 2s, +6 next hit"},
		{"text": "Bursts at 5 shakes", "fizz_at": 5.0},
		{"text": "Popping leaves a fizz puddle (25% slow)", "fizz_puddle": 0.25},
		{"text": "Bigger burst: blast 10 in a wider spray, +8 next hit", "fizz_damage": 8.0, "fizz_blast": 10.0, "fizz_blast_radius": 210.0},
		{"text": "Popping dashes at the foe and the hit splashes (6 damage)", "fizz_dash": 1.0, "fizz_splash": 6.0},
	],
	"chaos": {"closing_walls": {"fizz_at": 1.5, "fizz_blast": 0.8}}, ## A shrinking arena means walls every few frames
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["ringpull"], "front": ["fizz"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
