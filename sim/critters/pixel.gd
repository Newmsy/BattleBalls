## Pixel, the Sprite (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 71,
	"name": "Pixel",
	"type": "Sprite",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "live",
	"color": "7cff4f",
	"vibe": "A glitchy 8-bit sprite who blinks between frames.",
	"description": "Sprite. Every 5 seconds it teleports, leaving a pixel bomb where it was.",
	"stats": {"hp": 131.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.0},
	"ability": [{"on": "every", "secs": "glitch_every", "do": "glitch"}],
	"params": {
		"glitch_every": 5.0,
		"glitch_away": 250.0, ## Lands at least this far from where it was.
		"bomb_arm": 0.6,
		"bomb_radius": 80.0, ## Blast reach.
		"bomb_damage": 11.0,
		"bomb_max": 2, ## Oldest bomb goes when a new one would pass this.
		"bomb_line": 1, ## Bombs dropped per teleport, back along its path.
		"glitch_pulse": 0.0, ## T3: pulse damage where it lands.
		"glitch_pulse_radius": 80.0,
	},
	"tiers": [
		{"text": "Teleports every 5s, leaving a bomb (11 damage)"},
		{"text": "Bombs deal 14", "bomb_damage": 14.0},
		{"text": "Lands with a glitch pulse (4 damage)", "glitch_pulse": 4.0},
		{"text": "Teleports every 4s", "glitch_every": 4.0},
		{"text": "Leaves a line of 3 bombs behind it", "bomb_line": 3, "bomb_max": 6},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "square": true, "mouth": "smile"}, "body": "pixel"},
	"sound": {"ouch": "ouch_laser", "pitch": 1.4},
}
