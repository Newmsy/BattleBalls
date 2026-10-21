## Supernova, the Star (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 79,
	"name": "Supernova",
	"type": "Star",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "live",
	"color": "ffd6a5",
	"vibe": "A tiny star with a very big ending planned.",
	"description": "Star. For 12s it swells and brightens (+3% size and +0.5 dmg every 2s), then explodes for 18 in a huge blast and a burn, and starts over small.",
	"stats": {"hp": 120.0, "radius": 60.0, "speed": 400.0, "contact_damage": 12.0},
	"ability": [{"on": "every", "secs": 2.0, "do": "stack"}, {"on": "always", "do": "nova"}],
	"params": {
		"stack_max": 10.0,
		"stack_radius": 0.03,
		"stack_add": 0.5,
		"stack_heal": 0.0,
		"nova_every": 12.0,
		"nova_radius": 420.0,
		"nova_damage": 18.0,
		"nova_burn": 4.0,
		"nova_ring": 0.0,
	},
	"tiers": [
		{"text": "Swells 12s, then explodes for 18 + burn", "now": "Swells {nova_every}s, then explodes for {nova_damage} + burn"},
		{"text": "Blast 18 → 26", "nova_damage": 26.0},
		{"text": "+ The blast leaves a glowing ring (5/s)", "now": "Swells {nova_every}s, then explodes for {nova_damage} + burn + ring", "nova_ring": 5.0},
		{"text": "Nova every 12 → 10s, size +14%", "nova_every": 10.0, "nova_radius": 480.0},
		{"text": "+ Below 30% HP it goes nova early, once", "ability": [{"on": "hp_below", "hp": 0.3, "do": "nova_early"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["corona"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.85},
}
