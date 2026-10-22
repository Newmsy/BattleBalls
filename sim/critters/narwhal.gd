## Narwhal, the Narwhal (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 86,
	"name": "Narwhal",
	"type": "Narwhal",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "live",
	"color": "b8e0d2",
	"vibe": "A dreamy arctic unicorn of the sea who charges like a knight.",
	"description": "Narwhal. Every 4.5s it charges at the foe, its horn leaving a glittering beam along the path (8/s), and the charge hit deals x2.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 12.0},
	"ability": [{"on": "every", "secs": "lance_every", "do": "lance"}, {"on": "always", "do": "lance_tick"}, {"on": "strike", "do": "lance_hit"}],
	"params": {
		"lance_every": 4.5, ## Off Wisp's 5s phase beat, so the two never lock in step.
		"lance_speed_mult": 2.0, ## Charge speed, x its own.
		"lance_secs": 0.45,
		"lance_beam_life": 1.5,
		"lance_beam_dps": 8.0,
		"lance_hit_mult": 2.0, ## Its hit during a charge.
		"lance_knock": 0.0, ## T3: the charge hit flings the foe (x speed).
		"lance_retry": 0, ## T5: a charge that misses curves round once.
	},
	"tiers": [
		{"text": "Charges every 4.5s: beam 8/s, hit x2", "now": "Charges every {lance_every}s: beam {lance_beam_dps}/s, hit x{lance_hit_mult}"},
		{"text": "Beam 8 → 10/s", "lance_beam_dps": 10.0},
		{"text": "+ The charge hit knocks the foe back hard", "now": "Charges every {lance_every}s: beam {lance_beam_dps}/s, hit x{lance_hit_mult} + knockback", "lance_knock": 1.8},
		{"text": "Charge every 4.5 → 3.5s", "lance_every": 3.5},
		{"text": "+ A charge that misses curves round again", "now": "Charges every {lance_every}s (retries): beam {lance_beam_dps}/s, hit x{lance_hit_mult}", "lance_retry": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["horn", "fluke"], "front": ["speckles"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.05},
}
