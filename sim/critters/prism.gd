## Spectra, the Prism (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 15,
	"name": "Spectra",
	"type": "Prism",
	"rarity": "legendary",
	"rarity_power": 0.87, ## Per rarity step; also trimmed after the 2026-10-22 round robin (tools/round_robin.gd): it topped its rarity.
	"role": "Zoner",
	"status": "live",
	"color": "9ad8ff",
	"vibe": "Dazzling and a bit vain about it.",
	"description": "Prism. Every wall bounce casts a rainbow beam at the foe ({prism_damage} dmg), and {reflect_ratio%}% of the ability dmg it takes splits back as a beam.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "wall", "do": "beam_at"}, {"on": "hurt", "do": "reflect"}],
	"params": {
		"prism_damage": 1.0, ## Per hit, 4 hits a second.
		"prism_life": 0.8,
		"prism_fan": 1,
		"prism_full_every": 0, ## Every Nth cast fans 7, when above 0.
		"prism_gap": 1.1, ## Seconds between casts at least.
		"beam_max": 9,
		"beam_rainbow": 1,
		"reflect_ratio": 0.1,
		"reflect_low": 0.0,
		"reflect_burn": 0.0,
		"reflect_cap": 0.0,
		"reflect_from": "ability",
	},
	"tiers": [
		{"text": "Bounces cast a rainbow beam; reflects 10% ability dmg", "now": "Bounces cast a rainbow beam; reflects {reflect_ratio%}% ability dmg"},
		{"text": "Beam hit {^prism_damage} → {prism_damage}", "prism_damage": 1.8},
		{"text": "Beams 1 → 3", "now": "Bounces cast {prism_fan} rainbow beams; reflects {reflect_ratio%}% ability dmg", "prism_fan": 3},
		{"text": "Reflect 10 → 25%", "reflect_ratio": 0.25},
		{"text": "+ Every 3rd cast: full spectrum, 7 beams", "now": "Bounces cast {prism_fan} beams (3rd: 7); reflects {reflect_ratio%}% ability dmg", "prism_full_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .21, "h": .26, "p": .11, "sparkle": true, "mouth": "smile"}, "body": "prism"},
	"sound": {"ouch": "ouch_cosmic", "pitch": 1.35},
}
