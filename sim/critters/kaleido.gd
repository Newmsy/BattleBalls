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
	"description": "Kaleidoscope. Every {mode_secs}s it clicks to its next mode, shattering {mode_shards} mirror shards outward ({mode_shard_damage} dmg each): spikes (+{mode_damage} dmg), a {mode_shield} shield, then +{mode_speed%}% speed.",
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
		"mode_shards": 6, ## Each click shatters this many mirror shards outward.
		"mode_shard_damage": 3.0,
	},
	"tiers": [
		{"text": "Every 4s 6 shards fly (3 dmg), then spikes, shield or speed", "card": "Clicks through modes, shattering mirror shards outward: spikes, then a shield, then speed.", "now": "Every {mode_secs}s {mode_shards} shards fly ({mode_shard_damage} dmg), then spikes, shield or speed"},
		{"text": "Spikes +{^mode_damage} → +{mode_damage}, shield {^mode_shield} → {mode_shield}", "mode_damage": 4.0, "mode_shield": 14.0},
		{"text": "+ Each click pulses for {mode_damage}", "card": "Clicks through modes with a pulse and mirror shards: spikes, then a shield, then speed.", "now": "Every {mode_secs}s pulse + spikes +{mode_damage}, {mode_shield} shield or +{mode_speed%}% speed", "mode_pulse_radius": 90.0},
		{"text": "Click every 4 → 3.5s", "mode_secs": 3.5},
		{"text": "+ A 4th mode: all three at half", "card": "Clicks through modes with a pulse and mirror shards: spikes, shield, speed, then all at once.", "now": "Every {mode_secs}s pulse + spikes, shield, speed or all at half", "mode_count": 4.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "swirl": true, "mouth": "none", "dy": -.12}, "back": ["kaleidocaps"], "front": ["kaleidotube"]},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.25},
}
