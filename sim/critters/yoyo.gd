## Yo-Yo, the Yo-Yo (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 64,
	"name": "Yo-Yo",
	"type": "Yo-Yo",
	"rarity": "epic",
	"rarity_power": 1.057, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "00b4d8",
	"vibe": "A show-off toy that never passes up a trick.",
	"description": "Yo-Yo. Every 3rd wall bounce it pins its string to the wall and swings round that anchor for 1s, its taut string hurting foes it sweeps (16/s), then flings itself at the foe. From T2 every 3rd swing walks the dog: a longer swing that winds up faster and faster, then a harder fling whose hit lands +14.",
	"stats": {"hp": 127.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "wall", "do": "yoyo_bounce"}, {"on": "always", "do": "yoyo"}, {"on": "hit", "do": "walk_hit"}],
	"params": {
		"yoyo_every": 3, ## Swings on every this-many-th wall bounce.
		"yoyo_string": 180.0,
		"yoyo_secs": 1.0,
		"yoyo_dps": 16.0,
		"yoyo_fling": 1.5, ## Speed x when it lets go at the foe.
		"yoyo_strings": 1,
		"walk_every": 0, ## T2: every this-many-th swing walks the dog: a longer swing...
		"walk_secs": 1.0, ## ...this much longer...
		"walk_speed": 0.6, ## ...winding up to this much faster, then a harder fling...
		"walk_damage": 14.0, ## ...whose first hit lands this much more.
		"beam_color": "7ff3ff",
	},
	"tiers": [
		{"text": "Every 3rd bounce swings on its string (16/s), then flings", "now": "Every 3rd bounce swings on its string ({yoyo_dps}/s), then flings"},
		{"text": "String 16 → 20/s; every 3rd swing walks the dog", "now": "Every 3rd bounce swings ({yoyo_dps}/s), flings; walks the dog", "yoyo_dps": 20.0, "walk_every": 3},
		{"text": "Fling speed x1.5 → 1.9; walk hit 14 → 20", "yoyo_fling": 1.9, "walk_damage": 20.0},
		{"text": "Swings every 3rd → 2nd bounce", "now": "Every 2nd bounce swings ({yoyo_dps}/s), flings; walks the dog", "yoyo_every": 2},
		{"text": "Every bounce, 2 strings, 26/s; walk every 2nd", "now": "Every bounce swings on 2 strings ({yoyo_dps}/s); walks the dog", "walk_every": 2, "special": "Around the World", "yoyo_every": 1, "yoyo_strings": 2, "yoyo_secs": 1.4, "yoyo_dps": 26.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smirk"}, "front": ["yoyo"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.2},
}
