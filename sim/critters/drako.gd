## Drako, the Dragon (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 59,
	"name": "Drako",
	"type": "Dragon",
	"rarity": "epic",
	"rarity_power": 1.026, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.91, 0.93, 0.94, 0.91, 1.00], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "2b9348",
	"vibe": "A baby dragon who is very serious about being fearsome.",
	"description": "Dragon. Every hit stokes its fire (+{stack_add} dmg), and at {stack_max} stokes (or every {breath_every}s anyway) its next hit breathes a cone of {fire_count} fireballs ({fire_damage} dmg each, plus a burn) and starts again.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "stack_breath"}, {"on": "guard", "do": "stack_guard"}, {"on": "every", "secs": "breath_every", "do": "breath_timer"}],
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
		"breath_every": 9.0, ## It also breathes on its own this often (its stokes stay).
	},
	"tiers": [
		{"text": "Hits stoke +1 dmg; at 4 or every 9s: 5 fireballs (5 dmg)", "now": "Hits stoke +{stack_add} dmg; at {stack_max} or every {breath_every}s: {fire_count} fireballs ({fire_damage} dmg)"},
		{"text": "Fireballs {^fire_damage} → {fire_damage}", "fire_damage": 6.0},
		{"text": "+ Each stoke: -5% dmg taken", "now": "Stokes +{stack_add} dmg, -{stack_armor%}% taken; at {stack_max}: {fire_count} fireballs ({fire_damage} dmg)", "stack_armor": 0.05},
		{"text": "Stokes needed 4 → 3", "stack_max": 3.0},
		{"text": "+ The breath leaves a burning streak (5/sec)", "now": "Stokes +{stack_add} dmg, -{stack_armor%}% taken; at {stack_max}: {fire_count} fireballs + streak", "fire_streak": 5.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "smirk"}, "back": ["wings", "horns"], "front": ["belly"]},
	"sound": {"ouch": "ouch_fire", "pitch": 0.9},
}
