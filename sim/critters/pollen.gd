## Pollen, the Dandelion (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 40,
	"name": "Pollen",
	"type": "Dandelion",
	"rarity": "uncommon",
	"tier_power": [1.05, 0.97, 0.90, 0.87, 1.00], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Disruptor",
	"status": "live",
	"color": "caffbf",
	"vibe": "A dreamy dandelion puff that sneezes seeds everywhere when bumped.",
	"description": "Dandelion. When bumped, at most every 1.5s, it puffs out 4 seeds that drift slowly and sting anything they touch for {shot_damage}.",
	"stats": {"hp": 120.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "hurt", "do": "shoot"}],
	"params": {
		"fire_cooldown": 1.5, ## Seconds between puffs.
		"shot_when_bumped": 1, ## Only contact hits shake seeds loose, so ability damage can't farm puffs.
		"shot_damage": 4.0,
		"shot_speed": 150.0,
		"shot_count": 4,
		"shot_aim": "ring",
		"shot_life": 3.0,
		"shot_radius": 9.0,
		"shot_kind": "seed",
		"shot_burst_damage": 0.0, ## Spent seeds burst for this, when above 0.
		"shot_burst_radius": 40.0,
	},
	"tiers": [
		{"text": "Bumped: puffs 4 seeds (4 dmg), every 1.5s max", "card": "When bumped, puffs out drifting seeds that sting anything they touch.", "now": "Bumped: puffs {shot_count} seeds ({shot_damage} dmg), every {fire_cooldown}s max"},
		{"text": "Seed {^shot_damage} → {shot_damage}", "shot_damage": 5.0},
		{"text": "Seeds 4 → 6", "shot_count": 6},
		{"text": "Puff every 1.5 → 1s max", "fire_cooldown": 1.0},
		{"text": "+ Spent seeds burst for {shot_burst_damage}", "card": "When bumped, puffs out drifting seeds that sting, then burst.", "now": "Bumped: puffs {shot_count} bursting seeds ({shot_damage} dmg), every {fire_cooldown}s", "shot_burst_damage": 3.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "o"}, "back": ["tufts"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.35},
}
