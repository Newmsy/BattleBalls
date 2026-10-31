## Boing, the Spring bot (Common Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 91,
	"name": "Boing",
	"type": "Spring bot",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "live",
	"color": "c9d3ea",
	"vibe": "A wind-up spring bot that never, ever stops bouncing.",
	"description": "Spring bot. Every wall bounce leaves a spring pad for {spring_life}s (up to {spring_max}). Boing rolling over one is launched {spring_boost%}% faster for {spring_secs}s and its hits while launched deal x{spring_hit_mult}; a foe rolling over one is bounced straight back.",
	"tier_power": [0.90, 0.93, 0.96, 0.98, 1.00], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 130.0, "radius": 62.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "wall", "do": "spring"}, {"on": "always", "do": "spring_tick"}, {"on": "strike", "do": "spring_hit"}],
	"params": {
		"spring_radius": 46.0,
		"spring_life": 3.0,
		"spring_max": 2,
		"spring_boost": 0.4, ## Extra speed while launched...
		"spring_secs": 1.0, ## ...for this long.
		"spring_hit_mult": 1.3, ## A hit while launched.
		"spring_stun": 0.0, ## T5: a launched hit stuns this long.
	},
	"tiers": [
		{"text": "Bounces leave springs (3s): launch it, bounce foes back", "card": "Its wall bounces leave spring pads that launch it faster and bounce foes straight back.", "now": "Bounces leave springs ({spring_life}s): launch it, bounce foes back"},
		{"text": "Springs last {^spring_life} → {spring_life}s", "spring_life": 3.5},
		{"text": "Launch {^spring_boost%} → {spring_boost%}% faster", "spring_boost": 0.5},
		{"text": "Launched hits x{^spring_hit_mult} → x{spring_hit_mult}", "spring_hit_mult": 1.45, "spring_life": 4.0},
		{"text": "+ 3 springs; launched hits stun 0.3s", "special": "Trampoline Park", "card": "Its wall bounces leave more springs that launch it into stunning hits and bounce foes back.", "now": "3 springs ({spring_life}s): launched hits stun; foes bounce back", "spring_max": 3, "spring_stun": 0.3},
	],
	"art": {"body": "chrome", "eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["springcoil"], "front": []},
	"sound": {"ouch": "ouch_tech", "pitch": 1.3},
}
