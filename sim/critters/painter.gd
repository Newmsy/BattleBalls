## Painter, the Painter (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 46,
	"name": "Painter",
	"type": "Painter",
	"rarity": "rare",
	"rarity_power": 1.072, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "ffe8a3",
	"vibe": "A messy artist who thinks the arena is its canvas.",
	"description": "Painter. It leaves a paint trail that lasts 3s, and foes on the paint take +10% dmg.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 21.0},
	"ability": [{"on": "always", "do": "paint"}, {"on": "every", "secs": "balloon_every", "do": "balloon"}],
	"params": {
		"paint_every": 0.1, ## Seconds between paint blobs.
		"paint_width": 40.0,
		"paint_life": 3.0,
		"paint_vuln": 0.1, ## Extra damage share for foes on paint.
		"paint_linger": 0.0, ## T3: seconds it stays after leaving.
		"paint_flash_damage": 6.0, ## T5 flash.
		"balloon_every": 6.0, ## Lobs a paint balloon where the foe is heading...
		"balloon_damage": 4.0,
		"balloon_radius": 110.0, ## ...its splash: +15% dmg taken, slow 20% for 3s.
	},
	"tiers": [
		{"text": "Paint trail 3s (+10% dmg taken); paint balloon every 6s", "now": "Paint trail {paint_life}s (+{paint_vuln%}% dmg taken); paint balloon every {balloon_every}s"},
		{"text": "Dmg taken +10% → +12%", "paint_vuln": 0.12},
		{"text": "+ A foe stays painted 1s after", "paint_linger": 1.0},
		{"text": "Paint lasts 3 → 4s", "paint_life": 4.0},
		{"text": "+ Every 6s the paint flashes: 6 to foes on it", "now": "Paint trail {paint_life}s: +{paint_vuln%}% taken, balloons, flash every 6s", "ability": [{"on": "every", "secs": 6.0, "do": "paint_flash"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "front": ["splats", "beret"]},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.2},
}
