## Pounce, the Snow lynx (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 69,
	"name": "Pounce",
	"type": "Snow lynx",
	"rarity": "epic",
	"tier_power": [0.94, 0.94, 0.95, 0.94, 0.93], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "b7b7a4",
	"vibe": "A patient snow-lynx kitten that waits for the perfect moment.",
	"description": "Snow lynx. When hurt, at most every 4s, it marks the attacker and pounces 1s later; its hit on a marked foe deals x{marked_mult}.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.5},
	"ability": [{"on": "hurt", "do": "mark"}, {"on": "always", "do": "pounce"}, {"on": "strike", "do": "marked"}],
	"params": {
		"mark_cooldown": 4.0, ## Seconds between marks.
		"mark_min": 5.0, ## A scratch smaller than this doesn't wake it.
		"mark_secs": 3.0,
		"pounce_delay": 1.0, ## Seconds from mark to pounce.
		"pounce_speed_mult": 1.8, ## Pounce speed, x its own.
		"pounce_secs": 0.6,
		"marked_mult": 2.0, ## Its hit on a marked foe.
		"pounce_slow": 0.0, ## T3: slows the struck foe this much for 1.5s.
		"pounce_remark": 0, ## T5: a marked hit marks the foe again, once.
	},
	"tiers": [
		{"text": "Hurt: marks attacker (every 4s), pounces; hit x2", "now": "Hurt: marks attacker (every {mark_cooldown}s), pounces; hit x{marked_mult}"},
		{"text": "Pounce speed x1.8 → 2", "pounce_speed_mult": 2.0},
		{"text": "+ The pounce slows 20%", "now": "Hurt: marks (every {mark_cooldown}s), pounces, slow {pounce_slow%}%; hit x{marked_mult}", "pounce_slow": 0.2},
		{"text": "Mark every 4 → 3s max", "mark_cooldown": 3.0},
		{"text": "+ A marked hit marks the foe again, once", "now": "Hurt: marks (every {mark_cooldown}s), 2 pounces, slow {pounce_slow%}%; x{marked_mult}", "pounce_remark": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smirk"}, "back": ["ears"], "front": ["spots", "whiskers"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.15},
}
