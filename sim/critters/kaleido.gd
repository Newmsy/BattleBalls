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
	"description": "Kaleidoscope. Every 4s it clicks to its next mode: spikes (+3 dmg), a 12 shield, then +30% speed.",
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
		{"text": "Every 4s: spikes +3, 12 shield, or +30% speed", "now": "Every {mode_secs}s: spikes +{mode_damage}, {mode_shield} shield, or +{mode_speed%}% speed"},
		{"text": "Spikes +3 → +4, shield 12 → 14", "mode_damage": 4.0, "mode_shield": 14.0},
		{"text": "+ Each click pulses for 4", "now": "Every {mode_secs}s pulse + spikes +{mode_damage}, {mode_shield} shield or +{mode_speed%}% speed", "mode_pulse_radius": 90.0},
		{"text": "Click every 4 → 3.5s", "mode_secs": 3.5},
		{"text": "+ A 4th mode: all three at half", "now": "Every {mode_secs}s pulse + spikes, shield, speed or all at half", "mode_count": 4.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "swirl": true, "mouth": "smile"}, "front": ["shards"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.25},
}
