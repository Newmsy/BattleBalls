## Disco, the Disco ball (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 58,
	"name": "Disco",
	"type": "Disco ball",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "live",
	"color": "a06cd5",
	"vibe": "A glittering party animal that dazzles everyone around it.",
	"description": "Disco ball. Every 4 seconds it flashes six short light beams outward that dazzle and slow foes.",
	"stats": {"hp": 122.0, "radius": 66.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "every", "secs": 4.0, "do": "disco"}, {"on": "always", "do": "slows"}],
	"params": {
		"disco_rays": 6,
		"disco_length": 250.0,
		"disco_damage": 4.0,
		"disco_slow": 0.3,
		"disco_slow_secs": 1.0,
		"disco_bounce": 0, ## 1: rays bend off the first wall they meet.
	},
	"tiers": [
		{"text": "Every 4s flashes 6 dazzling rays"},
		{"text": "Rays deal 5", "disco_damage": 5.0},
		{"text": "8 rays", "disco_rays": 8},
		{"text": "Rays reach further", "disco_length": 320.0},
		{"text": "The rays bounce off walls once", "disco_bounce": 1},
	],
	"art": {"eyes": {"none": true, "mouth": "grin"}, "front": ["tiles", "shades"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.15},
}
