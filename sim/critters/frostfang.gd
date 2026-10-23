## Frostfang, the Wolf (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 85,
	"name": "Frostfang",
	"type": "Wolf",
	"rarity": "legendary",
	"rarity_power": 1.024, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.76, 0.88, 1.00, 1.00, 0.60], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "6d6875",
	"vibe": "A lone winter wolf, quiet until the howl.",
	"description": "Wolf. Every hit adds frost to the foe, and the {bite_max}nd freezes it solid for {bite_freeze}s as ice shards burst out ({shard_damage} dmg); Frostfang then hunts the frozen foe down and shatters it for x{shatter_mult}. Every {howl_every}s it howls up {wolf_count} ice wolves that hunt the foe ({wolf_damage} dmg each, slow 20%).",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "hit", "do": "frostbite"}, {"on": "strike", "do": "shatter"}, {"on": "always", "do": "frost_hunt"}, {"on": "every", "secs": "howl_every", "do": "howl"}],
	"params": {
		"bite_slow": 0.1, ## Slow per frost stack.
		"bite_max": 2, ## Stacks that freeze.
		"bite_secs": 3.0,
		"bite_freeze": 0.6,
		"shard_damage": 6.0, ## Ice shards burst from the frozen foe.
		"shard_radius": 140.0,
		"bite_sour": 0.0, ## T3: the frozen foe takes this much more damage.
		"bite_sour_secs": 2.0,
		"shatter_mult": 1.6, ## Hitting a frozen foe again (and a second shard burst).
		"hunt_accel": 1400.0, ## Turns toward a foe it froze.
		"howl_every": 10.0, ## Howls up ice-wolf spirits that hunt the foe...
		"wolf_count": 2,
		"wolf_damage": 3.0, ## ...each this much, slow 20%.
	},
	"tiers": [
		{"text": "2nd hit freezes, shards 6 · shatter x1.6 · howls every 10s", "now": "2nd hit freezes, shards {shard_damage} · shatter x{shatter_mult} · howls every {howl_every}s"},
		{"text": "Shards {^shard_damage} → {shard_damage}", "shard_damage": 7.0},
		{"text": "+ Frozen foe: +15% dmg taken for 2s", "now": "Every 2nd hit freezes (+{bite_sour%}% taken), shards {shard_damage} · x{shatter_mult}", "bite_sour": 0.15},
		{"text": "Shards {^shard_damage} → {shard_damage}, size +{+shard_radius}%", "shard_damage": 8.0, "shard_radius": 180.0},
		{"text": "Every hit freezes · shatter x{^shatter_mult} → {shatter_mult}", "now": "Every hit freezes (+{bite_sour%}% taken), shards {shard_damage} · x{shatter_mult}", "bite_max": 1, "shard_damage": 4.0, "shatter_mult": 1.3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "6fd3ff", "mouth": "fangs"}, "back": ["ears"], "front": ["ruff"]},
	"sound": {"ouch": "ouch_frost", "pitch": 0.8},
}
