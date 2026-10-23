## Sundae, the Sundae (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 77,
	"name": "Sundae",
	"type": "Sundae",
	"rarity": "legendary",
	"rarity_power": 1.14, ## Per rarity step; also trimmed after the 2026-10-22 round robin (tools/round_robin.gd): it topped its rarity.
	"tier_power": [1.06, 1.25, 0.95, 1.00, 1.05], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "fde2e4",
	"vibe": "A towering ice cream sundae who wants everyone to have a scoop.",
	"description": "Sundae. Every hit stacks another scoop on top (+{stack_add} dmg each, up to {stack_max}), and every hit of {drop_at}+ it takes knocks a scoop off into a sticky puddle that slows {splat_slow%}%. From T2 puddles stay until a foe rolls in; from T4 hits with full scoops throw the extra scoop at the foe.",
	"stats": {"hp": 136.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "stack_throw"}, {"on": "hit", "do": "stack"}, {"on": "hurt", "do": "stack_drop"}, {"on": "always", "do": "splat_tick"}],
	"params": {
		"stack_max": 3.0,
		"stack_radius": 0.05,
		"stack_add": 2.0,
		"stack_heal": 0.0,
		"drop_at": 20.0,
		"splat_radius": 90.0,
		"splat_slow": 0.4,
		"splat_dps": 0.0,
		"splat_stay": 0, ## T2: puddles stay until a foe rolls in, then last 3s.
		"scoop_throw": 0, ## T4: a hit with full scoops throws the extra one at the foe.
		"spray_count": 0.0,
		"bolt_damage": 3.0,
		"split_count": 0, ## T5 banana split: a full stack topples, throwing this many scoops...
		"split_damage": 6.0, ## ...each this much where it lands.
	},
	"tiers": [
		{"text": "Hits stack scoops (+2 dmg), max 3; big hits drop one", "now": "Hits stack scoops (+{stack_add} dmg), max {stack_max}; big hits drop one"},
		{"text": "Per scoop +2 → +3; puddles stay till stepped in", "stack_add": 3.0, "splat_stay": 1},
		{"text": "+ Splats give brain freeze ({splat_dps}/sec)", "splat_dps": 3.0},
		{"text": "Max scoops 3 → 5; + extra scoops are thrown", "now": "Hits stack scoops (+{stack_add} dmg), max {stack_max}; extras thrown", "stack_max": 5.0, "scoop_throw": 1},
		{"text": "+ Sprinkles; a full stack splits: 3 scoops thrown", "now": "Hits stack scoops (+{stack_add} dmg), max {stack_max}; sprinkles, banana split", "spray_count": 6.0, "split_count": 3, "ability": [{"on": "hit", "do": "stack_spray"}, {"on": "hit", "do": "banana_split"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "closed": true, "mouth": "smile"}, "back": ["scoops"], "front": ["cup"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.15},
}
