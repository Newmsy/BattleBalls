## Disco, the Disco ball (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 58,
	"name": "Disco",
	"type": "Disco ball",
	"rarity": "rare",
	"rarity_power": 1.049, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "a06cd5",
	"vibe": "A glittering party animal that dazzles everyone around it.",
	"description": "Disco ball. Every 4s it flashes 6 short light beams outward that hit for 4 and slow foes 30% for 1s.",
	"stats": {"hp": 122.0, "radius": 66.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "every", "secs": 4.0, "do": "disco"}, {"on": "always", "do": "slows"}],
	"params": {
		"disco_rays": 6,
		"disco_length": 250.0,
		"disco_damage": 4.0,
		"disco_slow": 0.3,
		"disco_slow_secs": 1.0,
		"disco_bounce": 0, ## 1: rays bend off the first wall they meet.
		"disco_floor_dps": 3.0, ## Each flash lights a 3x3 dance floor for 2s: slow 25% and this much a second.
	},
	"tiers": [
		{"text": "Every 4s: 6 rays (4, slow 30%) + a lit dance floor", "now": "Every 4s: {disco_rays} rays ({disco_damage}, slow {disco_slow%}%) + a lit dance floor"},
		{"text": "Ray dmg 4 → 5", "disco_damage": 5.0},
		{"text": "Rays 6 → 8", "disco_rays": 8},
		{"text": "Ray reach +28%", "disco_length": 320.0},
		{"text": "+ Rays bounce off walls once", "now": "Every 4s: {disco_rays} bouncing rays ({disco_damage}) + a lit dance floor", "disco_bounce": 1},
	],
	"art": {"eyes": {"none": true, "mouth": "grin"}, "front": ["tiles", "shades"]},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.15},
}
