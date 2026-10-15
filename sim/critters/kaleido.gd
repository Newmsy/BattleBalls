## Kaleido, the Kaleidoscope (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 72,
	"name": "Kaleido",
	"type": "Kaleidoscope",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "live",
	"color": "ff006e",
	"vibe": "A dizzy kaleidoscope that can never settle on one look.",
	"description": "Kaleidoscope. Every 4 seconds it clicks to its next mode: spikes for harder hits, a shield, then a burst of speed.",
	"stats": {"hp": 120.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "start", "do": "kaleido"}, {"on": "every", "secs": "mode_secs", "do": "kaleido"}],
	"params": {
		"mode_count": 3.0,
		"mode_secs": 4.0,
		"mode_damage": 3.0,
		"mode_shield": 12.0,
		"mode_speed": 0.3,
		"mode_pulse_radius": 0.0,
		"mode_pulse_damage": 4.0,
	},
	"tiers": [
		{"text": "Every 4s: spikes (+3 damage), a 12 shield, or +30% speed"},
		{"text": "Spikes +4, shield 14", "mode_damage": 4.0, "mode_shield": 14.0},
		{"text": "Each click flashes a small pulse (4 damage)", "mode_pulse_radius": 90.0},
		{"text": "Clicks every 3.5s", "mode_secs": 3.5},
		{"text": "A fourth prism mode: all three at half", "mode_count": 4.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "swirl": true, "mouth": "smile"}, "front": ["shards"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.25},
}
