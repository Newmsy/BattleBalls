## Blaze, the Wildfire (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 101,
	"name": "Blaze",
	"type": "Wildfire",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "live",
	"color": "c8203c",
	"vibe": "A wildfire with a grin. Whatever it touches spreads it further.",
	"description": "Wildfire. Its hits set the foe ablaze for {blaze_secs}s (burning). A blazing foe drags a fire trail; Blaze rolling through the fire is {trail_speed%}% faster and heals {trail_heal} HP/sec.",
	"tier_power": [0.79, 0.77, 0.75, 0.73, 0.70], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 114.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "hit", "do": "ignite"}, {"on": "always", "do": "blaze_tick"}],
	"params": {
		"blaze_dps": 2.0,
		"blaze_secs": 3.0,
		"trail_radius": 34.0,
		"trail_life": 2.5,
		"trail_dps": 2.0, ## The trail burns Blaze's foes too.
		"trail_speed": 0.25,
		"trail_heal": 2.0,
		"firestorm_damage": 0.0, ## T5: the trail erupts for this when the blaze ends.
	},
	"tiers": [
		{"text": "Hits set foe ablaze 3s; its trail speeds Blaze", "card": "Its hits set the foe ablaze; the burning foe drags fire that speeds and heals Blaze.", "now": "Hits set foe ablaze {blaze_secs}s; its trail speeds Blaze"},
		{"text": "Ablaze {^blaze_secs} → {blaze_secs}s", "blaze_secs": 3.5},
		{"text": "Trail burns {^trail_dps} → {trail_dps}/sec"},
		{"text": "Ablaze {^blaze_secs} → {blaze_secs}s", "blaze_secs": 4.0},
		{"text": "+ Blaze ends: whole trail erupts", "special": "Firestorm", "card": "Its hits set the foe ablaze and it drags fire; when the blaze ends the whole trail erupts.", "now": "Ablaze {blaze_secs}s; trail erupts at the end ({firestorm_damage})", "firestorm_damage": 10.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .22, "p": .1, "brow": .14, "mouth": "grin"}, "back": ["blazecrest"], "front": ["blazeembers"]},
	"sound": {"ouch": "ouch_fire", "pitch": 1.05},
}
