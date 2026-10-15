## Echo, the Mirror (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 12,
	"name": "Echo",
	"type": "Mirror",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "live",
	"color": "cfd8e6",
	"vibe": "A copycat show-off that mimics whoever just hit it.",
	"description": "Mirror. When hurt, copies the foe's ability (at 25% damage) for 3s and reflects a little damage while copying.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "hurt", "do": "copy"}, {"on": "always", "do": "copy_tick"}, {"on": "hurt", "do": "reflect"}],
	"params": {
		"copy_secs": 3.0,
		"copy_cooldown": 6.0,
		"copy_shield": 0.0,
		"copy_scale": 0.25, ## Copied ability damage is 25% of the original.
		"reflect_ratio": 0.25,
		"reflect_low": 0.0,
		"reflect_burn": 0.0,
		"reflect_cap": 0.0,
		"reflect_from": "copying",
	},
	"tiers": [
		{"text": "Copies for 3s, every 6s at most"},
		{"text": "Copies for 4s", "copy_secs": 4.0},
		{"text": "Copying also gives a 10 shield", "copy_shield": 10.0},
		{"text": "Every 5s at most", "copy_cooldown": 5.0},
		{"text": "A copy lasts until the next one", "copy_secs": 600.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .25, "p": .1, "mouth": "smile"}, "body": "chrome"},
	"sound": {"ouch": "ouch_laser", "pitch": 1.1},
}
