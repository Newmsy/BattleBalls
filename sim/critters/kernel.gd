## Kernel, the Popcorn (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 95,
	"name": "Kernel",
	"type": "Popcorn",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "ffcf5c",
	"vibe": "A kernel with a short fuse and a very loud pop.",
	"description": "Popcorn. Every {pop_every}rd wall bounce it pops {pop_count} hot kernels that ricochet round the arena for {pop_life}s, stinging the first foe each one hits ({pop_damage} dmg).",
	"tier_power": [0.92, 0.92, 0.92, 0.92, 0.92], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 120.0, "radius": 62.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "wall", "do": "kernel_pop"}],
	"params": {
		"pop_every": 3,
		"pop_count": 3,
		"pop_speed": 520.0,
		"pop_life": 3.0,
		"pop_damage": 6.0,
		"pop_puff_radius": 0.0, ## T5: each kernel puffs this big as it ends...
		"pop_puff_damage": 4.0, ## ...for this.
	},
	"tiers": [
		{"text": "Every 3rd bounce pops 3 ricochet kernels (6 dmg)", "card": "Every few wall bounces it pops hot kernels that ricochet round the arena.", "now": "Every {pop_every}rd bounce pops {pop_count} ricochet kernels ({pop_damage} dmg)"},
		{"text": "Kernels {^pop_count} → {pop_count}", "pop_count": 4},
		{"text": "Kernels fly {^pop_life} → {pop_life}s", "pop_life": 3.5},
		{"text": "Kernel dmg {^pop_damage} → {pop_damage}"},
		{"text": "+ 5 kernels that puff on their last bounce", "special": "Movie Night", "card": "Every few wall bounces it pops more hot kernels that ricochet round the arena and puff into popcorn.", "now": "Every {pop_every}rd bounce pops {pop_count} kernels ({pop_damage}), each puffs", "pop_count": 5, "pop_puff_radius": 70.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["popcorn"], "front": ["kernelband"]},
	"sound": {"ouch": "ouch_fire", "pitch": 1.25},
}
