## Pixel, the Sprite (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 71,
	"name": "Pixel",
	"type": "Sprite",
	"rarity": "epic",
	"rarity_power": 0.874, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.17, 1.18, 1.19, 1.12, 0.94], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "7cff4f",
	"vibe": "A glitchy 8-bit sprite who blinks between frames.",
	"description": "Sprite. Every {glitch_every}s it teleports, leaving a lag bomb ({bomb_damage} dmg) where it was; a foe it blasts glitches back to where it was {lag_secs}s ago.",
	"stats": {"hp": 131.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.0},
	"ability": [{"on": "every", "secs": "glitch_every", "do": "glitch"}, {"on": "always", "do": "lag_track"}, {"on": "blast", "do": "lag"}],
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
		"lag_secs": 0.4, ## A foe its bomb blasts glitches back to where it was this long ago.
	},
	"tiers": [
		{"text": "Teleports every 5s, leaves a lag bomb (11 dmg)", "now": "Teleports every {glitch_every}s, leaves a lag bomb ({bomb_damage} dmg)"},
		{"text": "Bomb {^bomb_damage} → {bomb_damage}", "bomb_damage": 14.0},
		{"text": "+ Lands with a glitch pulse ({glitch_pulse} dmg)", "now": "Teleports every {glitch_every}s: bomb {bomb_damage}, pulse {glitch_pulse}", "glitch_pulse": 4.0},
		{"text": "Teleport every 5 → 4s", "glitch_every": 4.0},
		{"text": "+ Leaves a line of 3 bombs", "now": "Teleports every {glitch_every}s: {bomb_line} bombs ({bomb_damage} dmg), pulse {glitch_pulse}", "bomb_line": 3, "bomb_max": 6},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "square": true, "mouth": "smile"}, "body": "pixel"},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.4},
}
