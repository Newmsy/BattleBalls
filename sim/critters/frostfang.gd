## Frostfang, the Wolf (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 85,
	"name": "Frostfang",
	"type": "Wolf",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "live",
	"color": "6d6875",
	"vibe": "A lone winter wolf, quiet until the howl.",
	"description": "Wolf. Every hit adds frost to the foe, and the third freezes it solid for a moment while ice shards burst out of it.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 21.0},
	"ability": [{"on": "hit", "do": "frostbite"}, {"on": "strike", "do": "shatter"}],
	"params": {
		"bite_slow": 0.1, ## Slow per frost stack.
		"bite_max": 3, ## Stacks that freeze.
		"bite_secs": 3.0,
		"bite_freeze": 0.5,
		"shard_damage": 4.0, ## Ice shards burst from the frozen foe.
		"shard_radius": 140.0,
		"bite_sour": 0.0, ## T3: the frozen foe takes this much more damage.
		"bite_sour_secs": 2.0,
		"shatter_mult": 0.0, ## T5: hitting a frozen foe again.
	},
	"tiers": [
		{"text": "Hits frost the foe (10% slow each); the third freezes it 0.5s and bursts ice shards for 4"},
		{"text": "Shards deal 5", "shard_damage": 5.0},
		{"text": "The freeze leaves the foe brittle: +15% damage taken for 2s", "bite_sour": 0.15},
		{"text": "Shards deal 6 in a wider burst", "shard_damage": 6.0, "shard_radius": 180.0},
		{"text": "Hitting a frozen foe again deals double damage", "shatter_mult": 2.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "6fd3ff", "mouth": "fangs"}, "back": ["ears"], "front": ["ruff"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
