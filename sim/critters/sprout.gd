## Sprout, the Sprout (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 54,
	"name": "Sprout",
	"type": "Sprout",
	"rarity": "rare",
	"rarity_power": 1.134, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "8ac926",
	"vibe": "A sunny seedling that plants something everywhere it goes.",
	"description": "Sprout. Every wall bounce plants a seed that grows into a small pillar for 4s (up to 3); higher tiers keep pillars until a foe hits them.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "wall", "do": "seed"}],
	"params": {
		"seed_radius": 30.0,
		"seed_life": 4.0,
		"seed_grow": 0.5, ## Seconds before a seed pillar is solid.
		"seed_max": 3,
		"seed_damage": 0.0, ## To foes that bounce off a pillar.
		"seed_stay": 0, ## Pillars that stand until a foe bounces off them instead.
		"seed_shots": 0, ## Seeds a wilting pillar scatters at the foe.
		"seed_shot_damage": 4.0,
	},
	"tiers": [
		{"text": "Bounces plant a pillar for 4s, max 3", "now": "Bounces plant a pillar for {seed_life}s, max {seed_max}"},
		{"text": "Pillars last 4 → 5s · 1 stays till hit", "seed_life": 5.0, "seed_stay": 1},
		{"text": "+ Bouncing off a pillar deals {seed_damage}", "now": "Bounces plant a pillar ({seed_damage} on bump) for {seed_life}s, max {seed_max}", "seed_damage": 4.0},
		{"text": "Pillar size +{+seed_radius}% · 2 stay till hit", "seed_radius": 40.0, "seed_stay": 2},
		{"text": "All 3 stay till hit · fall into 3 seeds ({seed_damage} dmg)", "now": "Bounces plant pillars ({seed_damage} on bump) till hit; fall to seeds", "seed_shots": 3, "seed_stay": 3, "ability": [{"on": "always", "do": "seed_wilt"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["leaves"], "front": ["frost_freckles"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.35},
}
