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
	"description": "Candle. After every hit its flame goes out and it fades, taking much less damage; then it relights with a burst of fire.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hit", "do": "phase"}, {"on": "guard", "do": "phased"}, {"on": "always", "do": "relight"}],
	"params": {
		"phase_secs": 1.0,
		"phase_guard": 0.3,
		"relight_damage": 5.0, ## The flame bursts back on when the fade ends.
		"relight_radius": 140.0,
		"scorch_dps": 2.0,
		"scorch_secs": 2.0,
		"trail_every": 0.1,
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 3.0,
	},
	"tiers": [
		{"text": "Goes out for 1s after each hit (takes 30% damage), then relights in a burst of fire (5)"},
		{"text": "Relight burst 7", "relight_damage": 7.0},
		{"text": "Its hits also burn (2/s for 2s)", "ability": [{"on": "hit", "do": "scorch"}]},
		{"text": "Bigger relight burst (radius 180, 9)", "relight_radius": 180.0, "relight_damage": 9.0},
		{"text": "While faded it leaves a burning trail", "ability": [{"on": "always", "do": "phase_fire"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["candle"], "front": ["drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
