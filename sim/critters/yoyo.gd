## Yo-Yo, the Yo-Yo (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 64,
	"name": "Yo-Yo",
	"type": "Yo-Yo",
	"rarity": "epic",
	"role": "Zoner",
	"status": "live",
	"color": "00b4d8",
	"vibe": "A show-off toy that never passes up a trick.",
	"description": "Yo-Yo. Every third wall bounce it pins its string to the wall and swings around that anchor for a second, its taut string hurting foes it sweeps.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "wall", "do": "yoyo_bounce"}, {"on": "always", "do": "yoyo"}],
	"params": {
		"yoyo_every": 3, ## Swings on every this-many-th wall bounce.
		"yoyo_string": 180.0,
		"yoyo_secs": 1.0,
		"yoyo_dps": 16.0,
		"yoyo_fling": 0.0, ## T3: speed x when it lets go at the foe.
		"yoyo_strings": 1,
		"beam_color": "7ff3ff",
	},
	"tiers": [
		{"text": "Every 3rd bounce swings on its string"},
		{"text": "String deals 20/s", "yoyo_dps": 20.0},
		{"text": "Walk the Dog: flings at the foe", "yoyo_fling": 1.6},
		{"text": "Swings every 2nd bounce", "yoyo_every": 2},
		{"text": "Around the World: two strings", "yoyo_strings": 2, "yoyo_secs": 1.4},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smirk"}, "front": ["yoyo"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.2},
}
