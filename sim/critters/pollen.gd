## Pollen, the Dandelion (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 40,
	"name": "Pollen",
	"type": "Dandelion",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "live",
	"color": "caffbf",
	"vibe": "A dreamy dandelion puff that sneezes seeds everywhere when bumped.",
	"description": "Dandelion. When bumped, it puffs out seeds that drift slowly and sting anything they touch.",
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
		{"text": "When bumped, puffs 4 drifting seeds that sting for 4"},
		{"text": "Seeds deal 5", "shot_damage": 5.0},
		{"text": "6 seeds", "shot_count": 6},
		{"text": "Puffs every 1s", "fire_cooldown": 1.0},
		{"text": "Seeds that drift out burst (3 damage)", "shot_burst_damage": 3.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "o"}, "back": ["tufts"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.35},
}
