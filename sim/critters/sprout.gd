## Sprout, the Sprout (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 54,
	"name": "Sprout",
	"type": "Sprout",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "live",
	"color": "8ac926",
	"vibe": "A sunny seedling that plants something everywhere it goes.",
	"description": "Sprout. Every wall bounce plants a seed that grows into a small pillar for 4 seconds.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "wall", "do": "seed"}],
	"params": {
		"seed_radius": 30.0,
		"seed_life": 4.0,
		"seed_grow": 0.5, ## Seconds before a seed pillar is solid.
		"seed_max": 3,
		"seed_damage": 0.0, ## To foes that bounce off a pillar.
		"seed_shots": 0, ## Seeds a wilting pillar scatters at the foe.
		"seed_shot_damage": 4.0,
	},
	"tiers": [
		{"text": "Bounces plant a 4s pillar"},
		{"text": "Pillars last 5s", "seed_life": 5.0},
		{"text": "Bouncing off a pillar deals 4", "seed_damage": 4.0},
		{"text": "Pillars grow bigger", "seed_radius": 40.0},
		{"text": "Wilting pillars scatter 3 seeds", "seed_shots": 3, "ability": [{"on": "always", "do": "seed_wilt"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["leaves"], "front": ["frost_freckles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.35},
}
