## Leviathan, the Sea serpent (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 74,
	"name": "Leviathan",
	"type": "Sea serpent",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "live",
	"color": "0f7173",
	"vibe": "A grand old sea serpent who rules the deep and knows it.",
	"description": "Sea serpent. Its glowing tail segments sting foes that touch them, and every 9 seconds it dives and bursts up under the foe in a huge wave.",
	"stats": {"hp": 105.0, "radius": 64.0, "speed": 400.0, "contact_damage": 12.0},
	"ability": [{"on": "always", "do": "tail"}, {"on": "always", "do": "dive_tick"}, {"on": "every", "secs": "dive_every", "do": "dive"}, {"on": "guard", "do": "dive_guard"}],
	"params": {
		"tail_count": 3,
		"tail_size": 22.0,
		"tail_damage": 3.0,
		"tail_cooldown": 0.6,
		"tail_slow": 0.0, ## T3: segments slow foes they touch.
		"dive_every": 9.0,
		"dive_secs": 1.2,
		"dive_lock": 0.5, ## The splash point stops following the foe this long before it erupts.
		"dive_guard": 0.4, ## Damage taken while diving.
		"wave_radius": 220.0,
		"wave_damage": 12.0,
		"pool_radius": 150.0, ## T5 whirlpool.
		"pool_life": 3.0,
		"pool_dps": 0.0,
		"pool_slow": 0.3,
	},
	"tiers": [
		{"text": "Tail stings; every 9s a huge wave"},
		{"text": "The wave deals 15", "wave_damage": 15.0},
		{"text": "4 segments that also slow", "tail_count": 4, "tail_slow": 0.2},
		{"text": "A wave every 8s", "dive_every": 8.0},
		{"text": "The eruption leaves a whirlpool", "pool_dps": 4.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "none"}, "back": ["segments", "frill"], "front": ["gills"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
