## Frostfang, the Wolf (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 85,
	"name": "Frostfang",
	"type": "Wolf",
	"rarity": "legendary",
	"rarity_power": 1.024, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "6d6875",
	"vibe": "A lone winter wolf, quiet until the howl.",
	"description": "Wolf. Every hit adds frost to the foe, and the 2nd freezes it solid for 0.6s as ice shards burst out (4); Frostfang then hunts the frozen foe down and shatters it for x1.6.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hit", "do": "frostbite"}, {"on": "strike", "do": "shatter"}, {"on": "always", "do": "frost_hunt"}],
	"params": {
		"bite_slow": 0.1, ## Slow per frost stack.
		"bite_max": 2, ## Stacks that freeze.
		"bite_secs": 3.0,
		"bite_freeze": 0.6,
		"shard_damage": 4.0, ## Ice shards burst from the frozen foe.
		"shard_radius": 140.0,
		"bite_sour": 0.0, ## T3: the frozen foe takes this much more damage.
		"bite_sour_secs": 2.0,
		"shatter_mult": 1.6, ## Hitting a frozen foe again (and a second shard burst).
		"hunt_accel": 1400.0, ## Turns toward a foe it froze.
	},
	"tiers": [
		{"text": "Every 2nd hit freezes 0.6s, shards 4 · shatter x1.6", "now": "Every 2nd hit freezes {bite_freeze}s, shards {shard_damage} · shatter x{shatter_mult}"},
		{"text": "Shards 4 → 5", "shard_damage": 5.0},
		{"text": "+ Frozen foe: +15% dmg taken for 2s", "now": "Every 2nd hit freezes (+{bite_sour%}% taken), shards {shard_damage} · x{shatter_mult}", "bite_sour": 0.15},
		{"text": "Shards 5 → 6, size +29%", "shard_damage": 6.0, "shard_radius": 180.0},
		{"text": "Every hit freezes · shatter x1.6 → 2.2", "now": "Every hit freezes (+{bite_sour%}% taken), shards {shard_damage} · x{shatter_mult}", "bite_max": 1, "shatter_mult": 2.2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "6fd3ff", "mouth": "fangs"}, "back": ["ears"], "front": ["ruff"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
