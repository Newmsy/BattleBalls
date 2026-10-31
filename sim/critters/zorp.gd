## Zorp, the UFO (Common Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 93,
	"name": "Zorp",
	"type": "UFO",
	"rarity": "common",
	"role": "Disruptor",
	"status": "live",
	"color": "7dffb2",
	"vibe": "A tiny alien tourist who wants a closer look at everyone.",
	"description": "UFO. Every {abduct_every}s it beams the nearest foe up, holding it {lift_secs}s, then drops it with a thud ({drop_damage} dmg to foes near where it lands).",
	"tier_power": [0.92, 0.90, 0.87, 0.84, 0.80], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 118.0, "radius": 60.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "every", "secs": "abduct_every", "do": "abduct"}, {"on": "always", "do": "abduct_tick"}],
	"params": {
		"abduct_every": 6.0,
		"lift_secs": 0.5, ## Held up (a stun).
		"drop_radius": 90.0,
		"drop_damage": 5.0,
		"abduct_slam_damage": 0.0, ## T5: flung into the nearest wall for this.
	},
	"tiers": [
		{"text": "Every 6s beams foe up 0.5s, drops it for 5", "card": "Every few seconds it beams the foe up, holds it in the air, then drops it with a thud.", "now": "Every {abduct_every}s beams foe up {lift_secs}s, drops it for {drop_damage}"},
		{"text": "Drop {^drop_damage} → {drop_damage}", "lift_secs": 0.55},
		{"text": "Thud size +{+drop_radius}%", "drop_radius": 120.0},
		{"text": "Beam every {^abduct_every} → {abduct_every}s", "abduct_every": 5.5},
		{"text": "+ Drop flings it into a wall for {abduct_slam_damage}", "special": "Mothership", "card": "Every few seconds it beams the foe up, then drops it and slams it into the nearest wall.", "now": "Every {abduct_every}s beam up, drop {drop_damage}, slam into wall {abduct_slam_damage}", "abduct_slam_damage": 6.0},
	],
	"art": {"badge_top": 1.4, "eyes": {"sep": .32, "w": .22, "h": .3, "p": .14, "iris": "0d1230", "mouth": "o"}, "back": ["ufodome"], "front": ["saucer"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 1.4},
}
