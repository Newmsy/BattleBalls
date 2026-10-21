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
	"description": "Yo-Yo. Every 3rd wall bounce it pins its string to the wall and swings round that anchor for 1s, its taut string hurting foes it sweeps (16/s), then flings itself at the foe.",
	"stats": {"hp": 127.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "wall", "do": "yoyo_bounce"}, {"on": "always", "do": "yoyo"}],
	"params": {
		"yoyo_every": 3, ## Swings on every this-many-th wall bounce.
		"yoyo_string": 180.0,
		"yoyo_secs": 1.0,
		"yoyo_dps": 16.0,
		"yoyo_fling": 1.5, ## Speed x when it lets go at the foe.
		"yoyo_strings": 1,
		"beam_color": "7ff3ff",
	},
	"tiers": [
		{"text": "Every 3rd bounce swings on its string (16/s), then flings", "now": "Every 3rd bounce swings on its string ({yoyo_dps}/s), then flings"},
		{"text": "String 16 → 20/s", "yoyo_dps": 20.0},
		{"text": "Fling speed x1.5 → 1.9", "yoyo_fling": 1.9},
		{"text": "Swings every 3rd → 2nd bounce", "now": "Every 2nd bounce swings on its string ({yoyo_dps}/s), then flings", "yoyo_every": 2},
		{"text": "Every bounce, 2 strings, 20 → 26/s", "now": "Every bounce swings on 2 strings ({yoyo_dps}/s), then flings", "special": "Around the World", "yoyo_every": 1, "yoyo_strings": 2, "yoyo_secs": 1.4, "yoyo_dps": 26.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smirk"}, "front": ["yoyo"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.2},
}
