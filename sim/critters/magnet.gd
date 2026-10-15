## Flux, the Magnet (Epic Disruptor), Season 1's debut critter. Spec:
## design/season1.md. One file is the whole critter: see "Adding a critter"
## in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 16,
	"name": "Flux",
	"type": "Magnet",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "live",
	"color": "ff3b5c",
	"vibe": "A buzzing little horseshoe that can't decide if it loves you or hates you.",
	"description": "Magnet. Every 3s its field flips: Pull drags the foe in and its first hit of each Pull snaps for 2.5x damage; a weaker Push shoves it away.",
	"stats": {"hp": 100.0, "radius": 62.0, "speed": 400.0, "contact_damage": 13.0},
	"ability": [{"on": "always", "do": "field"}, {"on": "strike", "do": "snap"}],
	"params": {
		"field_period": 3.0, ## Seconds per phase; Pull comes first.
		"field_range": 520.0, ## The field fades to nothing at this distance.
		"field_accel": 700.0, ## Steering at point blank, units/s^2, on both balls.
		"push_scale": 0.5, ## Push steers at this share of Pull's strength.
		"snap_mult": 2.5, ## Contact damage multiplier on the first hit of each Pull.
		"flip_pulse": 0.0, ## T5: damage of the pulse ring each flip fires.
		"flip_pulse_radius": 220.0,
	},
	"tiers": [
		{"text": "Field flips every 3s; first Pull hit snaps for 2.5x"},
		{"text": "Stronger field", "field_accel": 800.0},
		{"text": "Snaps for 3x", "snap_mult": 3.0},
		{"text": "Flips every 2.5s", "field_period": 2.5},
		{"text": "Every flip fires a pulse ring (6 damage, knocks back)", "flip_pulse": 6.0},
	],
	"art": {"badge_top": 1.55, "body": "magnet", "pole": "2f7bff", "back": ["magnet_prongs"],
		"eyes": {"sep": .3, "w": .19, "h": .23, "p": .1, "brow": .16, "mouth": "grin"}},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.0},
}
