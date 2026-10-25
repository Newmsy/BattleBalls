## Comet, the Comet (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 49,
	"name": "Comet",
	"type": "Comet",
	"rarity": "rare",
	"rarity_power": 0.915, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.20, 1.10, 1.00, 0.86, 0.74], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "ff5ad1",
	"vibe": "A starry show-off that leaves a sparkly mess wherever it zooms.",
	"description": "Comet. It leaves a stardust trail that stings foes who cross it ({trail_dps}/sec); the trail lasts 1.5s.",
	"stats": {"hp": 111.0, "radius": 64.0, "speed": 420.0, "contact_damage": 15.0},
	"ability": [{"on": "always", "do": "stardust"}],
	"params": {
		"trail_every": 0.1, ## Seconds between stardust blobs.
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 2.5,
		"linger_dps": 2.0, ## T3: crossing the trail burns this much...
		"linger_slow": 0.0,
		"linger_secs": 2.0, ## ...for this long.
		"star_damage": 5.0, ## T5: the shooting star's hit.
	},
	"tiers": [
		{"text": "Stardust trail stings 2.5/sec, lasts 1.5s", "card": "Leaves a stardust trail that stings foes who cross it.", "now": "Stardust trail stings {trail_dps}/sec, lasts {trail_life}s"},
		{"text": "Trail {^trail_dps} → {trail_dps}/sec", "trail_dps": 3.5},
		{"text": "+ Crossing it burns {linger_dps}/sec for 2s", "card": "Leaves a stardust trail that stings and burns foes who cross it.", "now": "Stardust trail stings {trail_dps}/sec + burns, lasts {trail_life}s", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "Trail lasts 1.5 → 2s", "trail_life": 2.0},
		{"text": "+ Shooting star every 3s ({star_damage} dmg)", "card": "Leaves a burning stardust trail and flicks shooting stars at the foe.", "now": "Burning stardust trail {trail_dps}/sec, {trail_life}s · star every 3s", "ability": [{"on": "every", "secs": 3.0, "do": "star"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["comettail"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 1.15},
}
