## Kaleido, the Kaleidoscope (Epic Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 72,
	"name": "Kaleido",
	"type": "Kaleidoscope",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "planned",
	"color": "ff006e",
	"vibe": "A dizzy kaleidoscope that can never settle on one look.",
	"description": "Kaleidoscope. Every 4 seconds it clicks to its next mode: spikes for harder hits, a shield, then a burst of speed.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 4s: spikes, shield or speed"},
		{"text": "Spikes +4, shield 14"},
		{"text": "Each click flashes a small pulse"},
		{"text": "Clicks every 3.5s"},
		{"text": "A fourth prism mode: all three at half"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "swirl": true, "mouth": "smile"}, "front": ["shards"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.25},
}
