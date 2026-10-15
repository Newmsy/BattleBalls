## Disco, the Disco ball (Rare Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 58,
	"name": "Disco",
	"type": "Disco ball",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "planned",
	"color": "a06cd5",
	"vibe": "A glittering party animal that dazzles everyone around it.",
	"description": "Disco ball. Every 4 seconds it flashes six short light beams outward that dazzle and slow foes.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 4s flashes 6 dazzling rays"},
		{"text": "Rays deal 5"},
		{"text": "8 rays"},
		{"text": "Rays reach further"},
		{"text": "The rays bounce off walls once"},
	],
	"art": {"eyes": {"none": true, "mouth": "grin"}, "front": ["tiles", "shades"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.15},
}
