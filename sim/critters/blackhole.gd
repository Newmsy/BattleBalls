## Void, the Black Hole (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 13,
	"name": "Void",
	"type": "Black Hole",
	"rarity": "legendary",
	"rarity_power": 0.953, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "0d0b17",
	"vibe": "Ancient, silent and a little terrifying.",
	"description": "Black Hole. Every 8s it collapses, dragging everything in, then explodes in a ring of light for {collapse_damage} that burns (a burning foe can't heal).",
	"stats": {"hp": 117.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.0},
	"ability": [{"on": "always", "do": "collapse"}, {"on": "guard", "do": "collapse_guard"}],
	"params": {
		"collapse_every": 8.0,
		"collapse_secs": 1.5,
		"collapse_range": 450.0,
		"collapse_accel": 950.0,
		"collapse_damage": 18.0,
		"collapse_radius": 260.0,
		"collapse_burn": 1.0, ## The blast burns this much a second for 3s (a burning foe can't heal).
		"collapse_ring": 0.0, ## Burning ring damage a second, 3s, when above 0.
		"collapse_guard": 1.0, ## Damage taken while collapsing.
	},
	"tiers": [
		{"text": "Collapses every 8s, pulls foes in, blast 18", "card": "Collapses, dragging foes in, then explodes in a ring of burning light.", "now": "Collapses every {collapse_every}s, pulls foes in, blast {collapse_damage}"},
		{"text": "Blast {^collapse_damage} → {collapse_damage}", "collapse_damage": 22.0},
		{"text": "+ -30% dmg taken while collapsing", "card": "Collapses, dragging foes in and shrugging off hits, then explodes in burning light.", "now": "Collapses every {collapse_every}s (-30% dmg taken), blast {collapse_damage}", "collapse_guard": 0.7},
		{"text": "Collapse every 8 → 7s", "collapse_every": 7.0},
		{"text": "+ Blast leaves a burning ring (5/sec)", "card": "Collapses, dragging foes in and shrugging off hits, then explodes into a ring of fire.", "now": "Collapses every {collapse_every}s (-30% taken), blast {collapse_damage} + fire ring", "collapse_ring": 5.0},
	],
	"art": {"eyes": {"sep": .3, "dot": true, "mouth": "none", "ink": "ffffff", "mouth_ink": "e8e0ff"}, "body": "starfield", "back": ["swirl_arms"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 0.6},
}
