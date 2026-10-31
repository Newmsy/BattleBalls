## Snowbo, the Snowman (Common Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 92,
	"name": "Snowbo",
	"type": "Snowman",
	"rarity": "common",
	"role": "Disruptor",
	"status": "live",
	"color": "fbfdff",
	"vibe": "A cheery snowman who shares his snow whether you want it or not.",
	"description": "Snowman. Every hit packs snow on the foe for {snow_secs}s, up to {snow_max} lumps: each makes it {snow_size%}% bigger and {snow_slow%}% slower, and Snowbo hits it {snow_hit%}% harder.",
	"tier_power": [1.12, 1.16, 1.22, 1.30, 1.40], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 128.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "hit", "do": "snowpack"}, {"on": "strike", "do": "snow_bowl"}],
	"params": {
		"snow_size": 0.08, ## Bigger per lump (a bigger target).
		"snow_slow": 0.08, ## Slower per lump.
		"snow_secs": 3.0,
		"snow_max": 3,
		"snow_hit": 0.1, ## Its hits deal this much more per lump on the foe.
		"snow_freeze": 0.0, ## T5: a full coat freezes it this long...
		"bowl_mult": 1.6, ## ...and Snowbo's next hit bowls it for this much.
	},
	"tiers": [
		{"text": "Hits pack snow: foe +8% size, -8% speed (x3)", "card": "Its hits pack snow on the foe, making it bigger and slower.", "now": "Hits pack snow: foe +{snow_size%}% size, -{snow_slow%}% speed (x{snow_max})"},
		{"text": "Snow lasts {^snow_secs} → {snow_secs}s", "snow_secs": 3.5},
		{"text": "Each lump {^snow_slow%} → {snow_slow%}% slower and bigger", "snow_slow": 0.1, "snow_size": 0.1},
		{"text": "Snow lasts {^snow_secs} → {snow_secs}s", "snow_secs": 4.0},
		{"text": "+ Full coat: frozen 0.6s, next hit bowls it", "special": "Snow Day", "card": "Its hits pack snow on the foe; a full coat freezes it into a snowball that Snowbo bowls away.", "now": "Snow +{snow_size%}% size, -{snow_slow%}% speed; x3: frozen, then bowled", "snow_freeze": 0.6},
	],
	"art": {"eyes": {"sep": .3, "w": .16, "h": .18, "p": .12, "iris": "1c1c26", "mouth": "none"}, "back": ["snowcap"], "front": ["carrot"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.1},
}
