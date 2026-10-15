## Gearbox, the Gearbox (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 70,
	"name": "Gearbox",
	"type": "Gearbox",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "live",
	"color": "a7c957",
	"vibe": "A revved-up racing bot that lives for top gear.",
	"description": "Gearbox. Every 3 seconds it shifts up a gear, and in top gear its next hit is a slam that resets it to first.",
	"stats": {"hp": 110.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "every", "secs": "gear_every", "do": "shift"}, {"on": "hurt", "do": "downshift"}, {"on": "strike", "do": "gear_slam"}],
	"params": {
		"gear_every": 3.0, ## Seconds per gear.
		"gear_step": 0.15, ## Extra speed per gear.
		"gear_max": 3, ## Top gear: the next hit slams.
		"gear_slam_mult": 2.0, ## Top-gear hit.
		"gear_knock": 1.5, ## The slammed foe flies off at this x its speed for 0.4s.
		"gear_keep": 0, ## T3: being hit doesn't drop a gear.
		"trail_every": 0.08, ## T5 turbo trail.
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 6.0,
	},
	"tiers": [
		{"text": "Shifts up every 3s; top gear slams x2"},
		{"text": "+18% speed per gear", "gear_step": 0.18},
		{"text": "Being hit doesn't drop a gear", "gear_keep": 1},
		{"text": "Shifts every 2.5s", "gear_every": 2.5},
		{"text": "A fourth turbo gear with a burning trail", "gear_max": 4, "ability": [{"on": "always", "do": "gear_trail"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["gearstick"], "front": ["number", "goggles"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.05},
}
