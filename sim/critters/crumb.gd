## Crumb, the Cookie (Common Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 18,
	"name": "Crumb",
	"type": "Cookie",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "live",
	"color": "a0522d",
	"vibe": "A plucky cookie who gets faster with every bite taken out of it.",
	"description": "Cookie. As it loses HP it shrinks and speeds up, at two-thirds and at one-third health.",
	"stats": {"hp": 135.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "hp_below", "hp": 0.66, "do": "grow"}, {"on": "hp_below", "hp": 0.33, "do": "grow"}],
	"params": {
		"grow_radius": -0.1,
		"grow_speed": 0.12,
		"grow_add": 0.0,
		"grow_secs": 0.0,
		"grow_stack": 1.0,
		"grow_heal": 0.0,
		"grow_pulse_radius": 0.0,
		"grow_pulse_damage": 0.0,
		"grow_bolts": 4.0,
		"bolt_damage": 3.0,
	},
	"tiers": [
		{"text": "At 66% and 33% HP a bite breaks off: -10% size, +12% speed, 4 crumbs fly at the foe"},
		{"text": "+15% speed per bite", "grow_speed": 0.15},
		{"text": "Each bite also heals 5", "grow_heal": 5.0},
		{"text": "+18% speed per bite", "grow_speed": 0.18},
		{"text": "A third bite at 15% HP, and every bite sprays 8 crumbs", "ability": [{"on": "hp_below", "hp": 0.15, "do": "grow"}], "grow_bolts": 8.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "front": ["chips", "bite"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
