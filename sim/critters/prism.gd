## Spectra, the Prism (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 15,
	"name": "Spectra",
	"type": "Prism",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "live",
	"color": "9ad8ff",
	"vibe": "Dazzling and a bit vain about it.",
	"description": "Prism. Every wall bounce casts a rainbow beam at the foe, and ability damage it takes splits back as a beam.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 12.0},
	"ability": [{"on": "wall", "do": "beam_at"}, {"on": "hurt", "do": "reflect"}],
	"params": {
		"prism_damage": 1.3, ## Per hit, 4 hits a second.
		"prism_life": 0.8,
		"prism_fan": 1,
		"prism_full_every": 0, ## Every Nth bounce fans 7, when above 0.
		"beam_max": 9,
		"beam_rainbow": 1,
		"reflect_ratio": 0.15,
		"reflect_low": 0.0,
		"reflect_burn": 0.0,
		"reflect_cap": 0.0,
		"reflect_from": "ability",
	},
	"tiers": [
		{"text": "One rainbow beam per bounce"},
		{"text": "Stronger beams", "prism_damage": 1.8},
		{"text": "Beams fan into 3 colours", "prism_fan": 3},
		{"text": "Reflects 25%", "reflect_ratio": 0.25},
		{"text": "Every 4th bounce is the full spectrum: 7 beams", "prism_full_every": 4},
	],
	"art": {"eyes": {"sep": .3, "w": .21, "h": .26, "p": .11, "sparkle": true, "mouth": "smile"}, "body": "prism"},
	"sound": {"ouch": "ouch_laser", "pitch": 1.35},
}
