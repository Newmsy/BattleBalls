## Narwhal, the Narwhal (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 86,
	"name": "Narwhal",
	"type": "Narwhal",
	"rarity": "legendary",
	"tier_power": [0.97, 1.01, 1.05, 0.84, 0.67], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "b8e0d2",
	"vibe": "A dreamy arctic unicorn of the sea who charges like a knight.",
	"description": "Narwhal. Every {lance_every}s it charges at the foe, its horn leaving a glittering beam along the path ({lance_beam_dps}/sec); the charge hit deals x{lance_hit_mult} and skewers the foe: the first wall it meets pins it ({skewer_damage} dmg, stun {skewer_stun}s).",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 12.0},
	"ability": [{"on": "every", "secs": "lance_every", "do": "lance"}, {"on": "always", "do": "lance_tick"}, {"on": "strike", "do": "lance_hit"}],
	"params": {
		"lance_every": 4.5, ## Off Wisp's 5s phase beat, so the two never lock in step.
		"lance_speed_mult": 2.0, ## Charge speed, x its own.
		"lance_secs": 0.45,
		"lance_beam_life": 1.5,
		"lance_beam_dps": 8.0,
		"lance_hit_mult": 2.0, ## Its hit during a charge.
		"lance_knock": 1.3, ## The charge hit flings the foe (x speed)...
		"skewer_damage": 8.0, ## ...and the first wall it meets in 0.6s pins it: this much...
		"skewer_stun": 0.5, ## ...held this long.
		"lance_retry": 0, ## T5: a charge that misses curves round once.
	},
	"tiers": [
		{"text": "Charges every 4.5s: beam 8/sec, x2 hit pins foe to a wall", "now": "Charges every {lance_every}s: beam {lance_beam_dps}/sec, x{lance_hit_mult} hit pins foe to a wall"},
		{"text": "Beam {^lance_beam_dps} → {lance_beam_dps}/sec", "lance_beam_dps": 10.0},
		{"text": "Charge knockback x1.3 → x1.8", "lance_knock": 1.8},
		{"text": "Charge every 4.5 → 3.5s", "lance_every": 3.5},
		{"text": "+ A charge that misses curves round again", "now": "Charges every {lance_every}s (retries): beam {lance_beam_dps}/sec, x{lance_hit_mult}, pins", "lance_retry": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["horn", "fluke"], "front": ["speckles"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.05},
}
