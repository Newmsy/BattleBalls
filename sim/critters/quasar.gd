## Quasar, the Quasar (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 78,
	"name": "Quasar",
	"type": "Quasar",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "live",
	"color": "7400b8",
	"vibe": "A hypnotic cosmic lighthouse that never stops spinning.",
	"description": "Quasar. Two opposite beams slowly rotate out from it, and every 6 seconds they flare all the way to the walls.",
	"stats": {"hp": 120.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "always", "do": "quasar"}, {"on": "every", "secs": 6.0, "do": "quasar_flare"}],
	"params": {
		"quasar_length": 250.0,
		"quasar_spin": 1.047, ## Radians a second (60 degrees).
		"quasar_dps": 8.0,
		"quasar_flare_secs": 1.0,
		"quasar_flare_dps": 12.0,
		"quasar_reverse": 0, ## T3: the spin flips after every flare.
		"quasar_cross": 0, ## T5: a cross of four beams during the flare.
		"beam_color": "c77dff",
	},
	"tiers": [
		{"text": "Two spinning beams (8/s) flare to the walls every 6s"},
		{"text": "Beams deal 10/s", "quasar_dps": 10.0},
		{"text": "Beams reverse after each flare", "quasar_reverse": 1},
		{"text": "Longer beams", "quasar_length": 300.0},
		{"text": "Flares become a cross of 4 beams", "quasar_cross": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "none"}, "back": ["jets"], "front": ["core"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.8},
}
