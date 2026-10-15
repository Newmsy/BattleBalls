## Comet, the Comet (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 49,
	"name": "Comet",
	"type": "Comet",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "live",
	"color": "ff5ad1",
	"vibe": "A starry show-off that leaves a sparkly mess wherever it zooms.",
	"description": "Comet. It leaves a stardust trail that hurts foes who cross it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 420.0, "contact_damage": 12.5},
	"ability": [{"on": "always", "do": "stardust"}],
	"params": {
		"trail_every": 0.1, ## Seconds between stardust blobs.
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 5.0,
		"linger_dps": 2.0, ## T3: crossing the trail burns this much...
		"linger_slow": 0.0,
		"linger_secs": 2.0, ## ...for this long.
		"star_damage": 5.0, ## T5: the shooting star's hit.
	},
	"tiers": [
		{"text": "Stardust trail stings 5/s, lasts 1.5s"},
		{"text": "Trail deals 6/s", "trail_dps": 6.0},
		{"text": "Crossing the trail also burns (2/s for 2s)", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "The trail lasts 2s", "trail_life": 2.0},
		{"text": "Every 3s its tail flicks a shooting star at the foe (5 damage)", "ability": [{"on": "every", "secs": 3.0, "do": "star"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["comettail"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.15},
}
