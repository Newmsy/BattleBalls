## Drako, the Dragon (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 59,
	"name": "Drako",
	"type": "Dragon",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "live",
	"color": "2b9348",
	"vibe": "A baby dragon who is very serious about being fearsome.",
	"description": "Dragon. Every hit stokes its fire, and at 4 stokes it breathes a cone of fireballs and starts again.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "stack_breath"}, {"on": "guard", "do": "stack_guard"}],
	"params": {
		"stack_max": 4.0,
		"stack_radius": 0.0,
		"stack_add": 1.0,
		"stack_armor": 0.0,
		"stack_full_armor": 0.0,
		"fire_count": 5.0,
		"fire_cone": 40.0,
		"fire_range": 300.0,
		"fire_damage": 5.0,
		"fire_burn": 2.0,
		"fire_streak": 0.0,
	},
	"tiers": [
		{"text": "Each hit stokes +1 damage; at 4 its next hit breathes 5 fireballs (5 each) and a burn"},
		{"text": "Fireballs deal 6", "fire_damage": 6.0},
		{"text": "Each stoke gives 5% armour", "stack_armor": 0.05},
		{"text": "Throat full after 3 stokes", "stack_max": 3.0},
		{"text": "The breath leaves a burning streak (5/s)", "fire_streak": 5.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "smirk"}, "back": ["wings", "horns"], "front": ["belly"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
