## Glacia, the Ice queen (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 90,
	"name": "Glacia",
	"type": "Ice queen",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "live",
	"color": "b9a7ff",
	"vibe": "A regal ice queen, cool, polite and utterly in charge.",
	"description": "Ice queen. Every 7 seconds it raises a ring of ice pillars around the foe, then shatters them so the shards fly inward.",
	"stats": {"hp": 126.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "every", "secs": 7.0, "do": "ice_ring"}, {"on": "always", "do": "ice_ring_tick"}, {"on": "always", "do": "slows"}],
	"params": {
		"ring_count": 5,
		"ring_radius": 150.0, ## Around the foe.
		"ring_pillar": 22.0,
		"ring_life": 1.5, ## Seconds before it shatters.
		"ring_big_every": 0, ## Every Nth ring is big, when above 0.
		"ring_big_count": 8,
		"ring_volley_gap": 0.4, ## A big ring's second volley.
		"shard_damage": 6.0,
		"shard_hits": 3, ## Most shards of one volley that hit the same foe.
		"shard_slow": 0.0,
	},
	"tiers": [
		{"text": "Every 7s rings the foe in 5 pillars"},
		{"text": "Shards deal 7", "shard_damage": 7.0},
		{"text": "Shards slow 20%", "shard_slow": 0.2},
		{"text": "6 pillars", "ring_count": 6},
		{"text": "Every other ring has 8 pillars and fires twice", "ring_big_every": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smirk"}, "back": ["tallcrystals", "cape_collar"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.05},
	"chaos": {"rink": {"hp": 1.02}, "pillars": {"hp": 1.02}},
}
