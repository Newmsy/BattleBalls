## Astra, the Constellation (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 100,
	"name": "Astra",
	"type": "Constellation",
	"rarity": "rare",
	"role": "Zoner",
	"status": "live",
	"color": "3346c9",
	"vibe": "Joins the dots across the whole sky, then lights them up.",
	"description": "Constellation. Every wall bounce pins a star; every 3rd joins the last three into a constellation that flashes, hitting foes inside ({astra_damage} dmg) and slowing them {astra_slow%}% for {astra_slow_secs}s.",
	"tier_power": [1.20, 1.20, 1.20, 1.20, 1.17], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.5},
	"ability": [{"on": "wall", "do": "star_pin"}, {"on": "always", "do": "star_tick"}],
	"params": {
		"astra_damage": 14.0,
		"astra_slow": 0.3,
		"astra_slow_secs": 1.5,
		"astra_linger": 0.0, ## T5: stays lit this long...
		"astra_edge_damage": 4.0, ## ...and its outline stings for this.
	},
	"tiers": [
		{"text": "3 wall stars flash a triangle: 14, slow 30%", "card": "Its wall bounces pin stars; every third joins them into a triangle that flashes and slows foes inside.", "now": "3 wall stars flash a triangle: {astra_damage}, slow {astra_slow%}%"},
		{"text": "Flash {^astra_damage} → {astra_damage}"},
		{"text": "Slow lasts {^astra_slow_secs} → {astra_slow_secs}s", "astra_slow_secs": 2.0},
		{"text": "Slow {^astra_slow%} → {astra_slow%}%", "astra_slow": 0.35},
		{"text": "+ Stays lit 2s; its outline stings", "special": "Starsign", "card": "Every third wall star joins a triangle that flashes, stays lit and stings foes crossing its lines.", "now": "Triangle flash {astra_damage}, slow; lit {astra_linger}s, lines sting {astra_edge_damage}", "astra_linger": 2.0},
	],
	"art": {"eyes": {"sep": .3, "w": .18, "h": .22, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["starpins"], "front": ["constellation"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 1.2},
}
