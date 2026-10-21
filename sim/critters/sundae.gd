## Sundae, the Sundae (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 77,
	"name": "Sundae",
	"type": "Sundae",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "live",
	"color": "fde2e4",
	"vibe": "A towering ice cream sundae who wants everyone to have a scoop.",
	"description": "Sundae. Every hit stacks another scoop on top (+2 dmg, up to 4), and every hit of 20+ it takes knocks a scoop off into a sticky puddle that slows 40%.",
	"stats": {"hp": 136.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "stack"}, {"on": "hurt", "do": "stack_drop"}],
	"params": {
		"stack_max": 4.0,
		"stack_radius": 0.05,
		"stack_add": 2.0,
		"stack_heal": 0.0,
		"drop_at": 20.0,
		"splat_radius": 90.0,
		"splat_slow": 0.4,
		"splat_dps": 0.0,
		"spray_count": 0.0,
		"bolt_damage": 3.0,
	},
	"tiers": [
		{"text": "Hits stack scoops (+2 dmg), max 4; big hits drop one", "now": "Hits stack scoops (+{stack_add} dmg), max {stack_max}; big hits drop one"},
		{"text": "Per scoop +2 → +3", "stack_add": 3.0},
		{"text": "+ Splats give brain freeze (3/s)", "splat_dps": 3.0},
		{"text": "Max scoops 4 → 5", "stack_max": 5.0},
		{"text": "+ At 5 scoops hits shower 6 sprinkles", "now": "Hits stack scoops (+{stack_add} dmg), max {stack_max}; full: sprinkles", "spray_count": 6.0, "ability": [{"on": "hit", "do": "stack_spray"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "closed": true, "mouth": "smile"}, "back": ["scoops"], "front": ["cup"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.15},
}
