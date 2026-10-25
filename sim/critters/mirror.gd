## Echo, the Mirror (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 12,
	"name": "Echo",
	"type": "Mirror",
	"rarity": "epic",
	"rarity_power": 0.955, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.03, 1.02, 1.00, 0.96, 0.93], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Disruptor",
	"status": "live",
	"color": "cfd8e6",
	"vibe": "A copycat show-off that mimics whoever just hit it.",
	"description": "Mirror. When hurt, at most every 6s, it copies the foe's ability for 2.5s with a {copy_shield} shield: full strength while the shield holds, 25% after. It bounces 20% of contact damage back while copying.",
	"stats": {"hp": 136.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "hurt", "do": "copy"}, {"on": "always", "do": "copy_tick"}, {"on": "hurt", "do": "reflect"}],
	"params": {
		"copy_secs": 2.5,
		"copy_cooldown": 6.0,
		"copy_shield": 6.0, ## While this shield holds the copy is at full strength.
		"copy_scale": 0.25, ## Copied ability damage, pull and multipliers at 25% strength.
		"reflect_ratio": 0.2,
		"reflect_low": 0.0,
		"reflect_burn": 0.0,
		"reflect_cap": 0.0,
		"reflect_from": "copying",
	},
	"tiers": [
		{"text": "Hurt: copies foe's ability 2.5s, full while 6 shield", "card": "When hurt, it copies the foe's ability for a short time, behind a shield.", "now": "Hurt: copies foe's ability {copy_secs}s, full while {copy_shield} shield"},
		{"text": "Copy 2.5 → 3.5s", "copy_secs": 3.5},
		{"text": "Copy shield {^copy_shield} → {copy_shield}", "copy_shield": 12.0},
		{"text": "Copy every 6 → 5s max", "copy_cooldown": 5.0},
		{"text": "+ A copy lasts until the next one", "card": "When hurt, it copies the foe's ability and keeps it until the next copy, behind a shield.", "now": "Hurt: keeps a copy of foe's ability + {copy_shield} shield, every {copy_cooldown}s", "copy_secs": 600.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .25, "p": .1, "mouth": "smile"}, "body": "chrome"},
	"sound": {"ouch": "ouch_tech", "pitch": 1.1},
}
