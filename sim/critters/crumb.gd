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
	"description": "Cookie. At 66% and 33% HP a bite breaks off: -10% size, +{grow_speed%}% speed, {grow_bolts} crumbs fly at the foe ({bolt_damage} dmg each) and {crumb_pieces} cookie pieces drop that it can roll over to heal {crumb_heal}.",
	"stats": {"hp": 135.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "hp_below", "hp": 0.66, "do": "grow"}, {"on": "hp_below", "hp": 0.33, "do": "grow"}, {"on": "always", "do": "crumb_pick"}],
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
		"crumb_pieces": 2, ## Each bite drops this many cookie pieces (Newms 2026-10-22)...
		"crumb_heal": 5.0, ## ...and rolling over one eats it for this.
	},
	"tiers": [
		{"text": "Bites at 66/33% HP: +12% speed, crumbs to eat (+5)", "now": "Bites at 66/33% HP: +{grow_speed%}% speed, crumbs to eat (+{crumb_heal})"},
		{"text": "Speed per bite +12% → +15%", "grow_speed": 0.15},
		{"text": "+ Each bite heals 5", "now": "Bites at 66/33% HP: +{grow_speed%}% speed, heal {grow_heal}, crumbs to eat", "grow_heal": 5.0},
		{"text": "Speed per bite +15% → +18%", "grow_speed": 0.18},
		{"text": "+ 3rd bite at 15% HP · crumbs 4 → 8", "now": "Bites at 66/33/15% HP: +{grow_speed%}% speed, heal {grow_heal}, crumbs", "ability": [{"on": "hp_below", "hp": 0.15, "do": "grow"}], "grow_bolts": 8.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "front": ["chips", "bite"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.3},
}
