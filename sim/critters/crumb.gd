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
	"description": "Cookie. At 66% and 33% HP a bite breaks off: -10% size, +12% speed, and 4 crumbs fly at the foe (3 each).",
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
		{"text": "At 66%/33% HP sheds a bite: +12% speed, 4 crumbs", "now": "At 66%/33% HP sheds a bite: +{grow_speed%}% speed, {grow_bolts} crumbs"},
		{"text": "Speed per bite +12% → +15%", "grow_speed": 0.15},
		{"text": "+ Each bite heals 5", "now": "At 66%/33% HP sheds a bite: +{grow_speed%}% speed, heal {grow_heal}, {grow_bolts} crumbs", "grow_heal": 5.0},
		{"text": "Speed per bite +15% → +18%", "grow_speed": 0.18},
		{"text": "+ 3rd bite at 15% HP · crumbs 4 → 8", "now": "At 66/33/15% HP sheds a bite: +{grow_speed%}% speed, heal {grow_heal}, {grow_bolts} crumbs", "ability": [{"on": "hp_below", "hp": 0.15, "do": "grow"}], "grow_bolts": 8.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "front": ["chips", "bite"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.3},
}
