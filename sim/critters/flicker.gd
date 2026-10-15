## Flicker, the Candle (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 32,
	"name": "Flicker",
	"type": "Candle",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "live",
	"color": "fff1c1",
	"vibe": "A cheeky candle that vanishes in a puff of smoke after every poke.",
	"description": "Candle. After every hit it fades out briefly, taking much less damage.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.5},
	"ability": [{"on": "hit", "do": "phase"}, {"on": "guard", "do": "phased"}],
	"params": {
		"phase_secs": 0.6,
		"phase_guard": 0.3,
		"scorch_dps": 2.0,
		"scorch_secs": 2.0,
		"trail_every": 0.1,
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 3.0,
	},
	"tiers": [
		{"text": "Fades out for 0.6s after each hit, taking 30% damage"},
		{"text": "Fades for 0.8s", "phase_secs": 0.8},
		{"text": "Its hits also burn (2/s for 2s)", "ability": [{"on": "hit", "do": "scorch"}]},
		{"text": "Fades for 1s", "phase_secs": 1.0},
		{"text": "While faded it leaves a burning trail", "ability": [{"on": "always", "do": "phase_fire"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["candle"], "front": ["drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
