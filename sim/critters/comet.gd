## Comet, the Comet (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 49,
	"name": "Comet",
	"type": "Comet",
	"rarity": "rare",
	"rarity_power": 0.915, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "ff5ad1",
	"vibe": "A starry show-off that leaves a sparkly mess wherever it zooms.",
	"description": "Comet. It leaves a stardust trail that stings foes who cross it (2.5/s); the trail lasts 1.5s.",
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
		{"text": "Stardust trail stings 2.5/s, lasts 1.5s", "now": "Stardust trail stings {trail_dps}/s, lasts {trail_life}s"},
		{"text": "Trail 2.5 → 3.5/s", "trail_dps": 3.5},
		{"text": "+ Crossing it burns 2/s for 2s", "now": "Stardust trail stings {trail_dps}/s + burns, lasts {trail_life}s", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "Trail lasts 1.5 → 2s", "trail_life": 2.0},
		{"text": "+ Shooting star every 3s (5)", "now": "Burning stardust trail {trail_dps}/s, {trail_life}s · star every 3s", "ability": [{"on": "every", "secs": 3.0, "do": "star"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["comettail"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.15},
}
