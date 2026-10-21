## Ink, the Squid (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 38,
	"name": "Ink",
	"type": "Squid",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "live",
	"color": "3c1f5c",
	"vibe": "A shy squid that squirts ink when startled and hopes nobody noticed.",
	"description": "Squid. When hurt, it squirts an ink cloud that slows foes caught inside.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.25},
	"ability": [{"on": "hurt", "do": "ink"}],
	"params": {
		"ink_radius": 90.0,
		"ink_life": 2.5,
		"ink_slow": 0.35, ## Share of movement a foe loses in the ink.
		"ink_dps": 0.0, ## T5: the ink stings.
		"ink_cooldown": 3.0, ## Seconds between squirts.
		"ink_dash": 0.0, ## T3: seconds of speed burst after a squirt.
	},
	"tiers": [
		{"text": "When hurt, squirts ink that slows foes 35% (every 3s at most)"},
		{"text": "Ink clouds last 3s", "ink_life": 3.0},
		{"text": "Squirting gives Ink a speed burst for 1s", "ink_dash": 1.0},
		{"text": "Squirts every 2.5s", "ink_cooldown": 2.5},
		{"text": "Squirts every 1.5s and the ink stings foes inside (5/s)", "ink_dps": 5.0, "ink_cooldown": 1.5},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "beak"}, "back": ["tentacles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.15},
}
