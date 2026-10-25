## Fuse, the Bomber (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 6,
	"name": "Fuse",
	"type": "Bomber",
	"rarity": "rare",
	"rarity_power": 0.922, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "2b3a67",
	"vibe": "Chaotic gremlin who laughs at its own explosions.",
	"description": "Bomb. Every wall bounce drops a mine (up to 3) that blows up for {mine_damage} when a foe touches it.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "wall", "do": "mine"}],
	"params": {
		"mine_arm": 0.5, ## Seconds before a mine is live.
		"mine_radius": 70.0, ## Blast reach beyond the mine.
		"mine_damage": 14.0,
		"mine_max": 3, ## Oldest mine goes when a new one would pass this.
		"mine_life": 15.0, ## Seconds before an untouched mine fizzles.
		"mine_chain": 0, ## 1: a blast sets off its other mines in reach.
	},
	"tiers": [
		{"text": "Bounces drop mines (14 dmg), max 3", "card": "Wall bounces drop mines that blow up when a foe touches them.", "now": "Bounces drop mines ({mine_damage} dmg), max {mine_max}"},
		{"text": "Max mines 3 → 4", "mine_max": 4},
		{"text": "Blast size +{+mine_radius}%", "mine_radius": 90.0},
		{"text": "Max mines 4 → 6", "mine_max": 6},
		{"text": "+ Mines chain-detonate", "card": "Wall bounces drop mines that set each other off in a chain.", "now": "Bounces drop chaining mines ({mine_damage} dmg), max {mine_max}", "mine_chain": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .23, "h": .26, "p": .07, "mis": true, "mouth": "teeth"}, "body": "bomb", "front": ["fuse"]},
	"sound": {"ouch": "ouch_fire", "pitch": 0.85},
}
