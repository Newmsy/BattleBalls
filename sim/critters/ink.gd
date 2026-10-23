## Ink, the Squid (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 38,
	"name": "Ink",
	"type": "Squid",
	"rarity": "uncommon",
	"rarity_power": 1.106, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.00, 0.95, 1.06, 1.11, 0.95], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Disruptor",
	"status": "live",
	"color": "3c1f5c",
	"vibe": "A shy squid that squirts ink when startled and hopes nobody noticed.",
	"description": "Squid. When hurt, at most every 3s, it squirts a stinging ink cloud that lasts 2.5s, slows foes inside 35% and stings them {ink_dps}/sec.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.25},
	"ability": [{"on": "hurt", "do": "ink"}],
	"params": {
		"ink_radius": 100.0,
		"ink_life": 2.5,
		"ink_slow": 0.35, ## Share of movement a foe loses in the ink.
		"ink_dps": 1.5, ## The ink stings.
		"ink_cooldown": 3.0, ## Seconds between squirts.
		"ink_dash": 0.0, ## T3: seconds of speed burst after a squirt.
	},
	"tiers": [
		{"text": "Hurt: stinging ink 1.5/sec, slow 35% (every 3s max)", "now": "Hurt: stinging ink {ink_dps}/sec, slow {ink_slow%}% (every {ink_cooldown}s max)"},
		{"text": "Ink lasts 2.5 → 3s", "ink_life": 3.0},
		{"text": "+ Squirting gives a 1s speed burst", "now": "Hurt: stinging ink {ink_dps}/sec, slow {ink_slow%}%, dash (every {ink_cooldown}s max)", "ink_dash": 1.0},
		{"text": "Squirt every 3 → 2.5s", "ink_cooldown": 2.5},
		{"text": "Squirt every 2.5 → 1.5s · ink stings {^ink_dps} → {ink_dps}/sec", "now": "Hurt: stinging ink {ink_dps}/sec, slow {ink_slow%}%, dash (every {ink_cooldown}s)", "ink_dps": 5.0, "ink_cooldown": 1.5},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "beak"}, "back": ["tentacles"]},
	"sound": {"ouch": "ouch_sea", "pitch": 1.15},
}
