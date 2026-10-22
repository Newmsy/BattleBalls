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
	"description": "Soda. Every wall bounce shakes it up, and at 6 shakes it bursts: a geyser blasts nearby foes away for 7, and it rockets off (+50% speed for 2s) with +6 on its next hit.",
	"stats": {"hp": 119.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.0},
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
		{"text": "At 6 bounces bursts: blast 7, then +6 next hit", "now": "At {fizz_at} bounces bursts: blast {fizz_blast}, then +{fizz_damage} next hit"},
		{"text": "Bursts at 6 → 5 bounces", "fizz_at": 5.0},
		{"text": "+ The burst leaves a puddle (slow 25%)", "now": "At {fizz_at} bounces bursts: blast {fizz_blast}, puddle, +{fizz_damage} next hit", "fizz_puddle": 0.25},
		{"text": "Blast 7 → 10 (+24% size), next hit +6 → +8", "fizz_damage": 8.0, "fizz_blast": 10.0, "fizz_blast_radius": 210.0},
		{"text": "+ Burst dashes at foe; the hit splashes 6", "now": "At {fizz_at} bounces: blast {fizz_blast}, puddle, dash hit +{fizz_damage}, splash {fizz_splash}", "fizz_dash": 1.0, "fizz_splash": 6.0},
	],
	"chaos": {"closing_walls": {"fizz_at": 1.5, "fizz_blast": 0.8}}, ## A shrinking arena means walls every few frames
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["ringpull"], "front": ["fizz"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.3},
}
