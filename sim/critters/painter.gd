## Painter, the Painter (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 46,
	"name": "Painter",
	"type": "Painter",
	"rarity": "rare",
	"role": "Zoner",
	"status": "live",
	"color": "ffe8a3",
	"vibe": "A messy artist who thinks the arena is its canvas.",
	"description": "Painter. Painter leaves a paint trail, and foes on the paint take 10% more damage.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 21.0},
	"ability": [{"on": "always", "do": "paint"}],
	"params": {
		"paint_every": 0.1, ## Seconds between paint blobs.
		"paint_width": 40.0,
		"paint_life": 3.0,
		"paint_vuln": 0.1, ## Extra damage share for foes on paint.
		"paint_linger": 0.0, ## T3: seconds it stays after leaving.
		"paint_flash_damage": 6.0, ## T5 flash.
	},
	"tiers": [
		{"text": "Leaves a paint trail for 3s; foes on paint take 10% more damage"},
		{"text": "Paint +12%", "paint_vuln": 0.12},
		{"text": "A foe stays painted for 1s after leaving the paint", "paint_linger": 1.0},
		{"text": "Paint lasts 4s", "paint_life": 4.0},
		{"text": "Every 6s the paint dries with a flash: 6 damage to any foe on it", "ability": [{"on": "every", "secs": 6.0, "do": "paint_flash"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "front": ["splats", "beret"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
