## Old Oak, the Ancient tree (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 75,
	"name": "Old Oak",
	"type": "Ancient tree",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "live",
	"color": "6f4518",
	"vibe": "A slow, kind forest elder who has seen a thousand fights.",
	"description": "Ancient tree. At half HP it takes root: four root pillars burst up around it and it regrows health while they stand.",
	"stats": {"hp": 122.0, "radius": 76.8, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "root"}, {"on": "always", "do": "root_tick"}],
	"params": {
		"root_count": 4,
		"root_radius": 35.0,
		"root_life": 6.0, ## Seconds the roots stand and it regrows.
		"root_pin": 2.0, ## Seconds it holds still as it takes root.
		"root_regen": 3.0, ## HP a second while rooted.
		"root_shove": 0.0, ## Eruption radius, when above 0.
		"root_shove_damage": 8.0,
	},
	"tiers": [
		{"text": "At half HP takes root: holds 2s, regrows 3 HP/s for 6s"},
		{"text": "Regrows 4 HP/s", "root_regen": 4.0},
		{"text": "Taking root blasts nearby foes away (8 damage)", "root_shove": 150.0},
		{"text": "Roots last 8s, so it regrows for longer", "root_life": 8.0},
		{"text": "Takes root again at 20% HP", "ability": [{"on": "hp_below", "hp": 0.2, "do": "root"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["canopy"], "front": ["beard"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
	"chaos": {"pillars": {"hp": 1.05}, "bumpers": {"hp": 1.04}}, ## Obstacles crowd out its root pillars.
}
