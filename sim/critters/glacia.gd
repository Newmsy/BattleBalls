## Glacia, the Ice queen (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 90,
	"name": "Glacia",
	"type": "Ice queen",
	"rarity": "legendary",
	"rarity_power": 0.908, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.93, 0.89, 1.00, 1.02, 1.04], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Disruptor",
	"status": "live",
	"color": "b9a7ff",
	"vibe": "A regal ice queen, cool, polite and utterly in charge.",
	"description": "Ice queen. Every 5.5s it raises a ring of 5 ice pillars around the foe, then shatters them so the shards fly inward ({shard_damage} each).",
	"stats": {"hp": 103.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "every", "secs": 5.5, "do": "ice_ring"}, {"on": "always", "do": "ice_ring_tick"}, {"on": "always", "do": "slows"}],
	"params": {
		"ring_count": 5,
		"ring_radius": 150.0, ## Around the foe.
		"ring_pillar": 22.0,
		"ring_life": 1.5, ## Seconds before it shatters.
		"ring_big_every": 0, ## Every Nth ring is big, when above 0.
		"ring_big_count": 8,
		"ring_volley_gap": 0.4, ## A big ring's second volley.
		"shard_damage": 7.0,
		"shard_hits": 2, ## Most shards of one volley that hit the same foe.
		"shard_slow": 0.0,
	},
	"tiers": [
		{"text": "Every 5.5s rings the foe in 5 pillars; shards 7", "card": "Rings the foe in ice pillars, then shatters them so shards fly inward.", "now": "Every 5.5s rings the foe in {ring_count} pillars; shards {shard_damage}"},
		{"text": "Shards {^shard_damage} → {shard_damage}", "shard_damage": 8.0},
		{"text": "+ Shards slow 20%", "card": "Rings the foe in ice pillars, then shatters them so slowing shards fly inward.", "now": "Every 5.5s rings the foe in {ring_count} pillars; shards {shard_damage}, slow {shard_slow%}%", "shard_slow": 0.2},
		{"text": "Pillars 5 → 6", "ring_count": 6},
		{"text": "+ Every 2nd ring: 8 pillars, fires twice", "card": "Rings the foe in ice pillars and shatters them inward; every other ring is bigger and fires twice.", "now": "Every 5.5s {ring_count} pillars (2nd: {ring_big_count}, twice); shards {shard_damage}, slow", "ring_big_every": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smirk"}, "back": ["tallcrystals", "cape_collar"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.05},
	"chaos": {"rink": {"hp": 1.02}, "pillars": {"hp": 1.02}},
}
