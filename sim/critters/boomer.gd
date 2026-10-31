## Boomer, the Boomerang (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 97,
	"name": "Boomer",
	"type": "Boomerang",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "e8a35b",
	"vibe": "A painted wooden toy with one trick, and it always comes back.",
	"description": "Boomerang. Every {throw_every}s it throws a boomerang at the nearest foe that curves out and flies home, hitting each foe once going out and once coming back ({boom_damage} dmg).",
	"tier_power": [1.02, 1.00, 0.97, 0.94, 0.92], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 120.0, "radius": 62.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "every", "secs": "throw_every", "do": "boomerang"}, {"on": "always", "do": "boomer_tick"}],
	"params": {
		"throw_every": 4.0,
		"boom_speed": 650.0,
		"boom_pull": 650.0, ## Pull home: about a 2s round trip.
		"boom_damage": 6.0,
		"boom_radius": 22.0,
		"boom_count": 1,
		"boom_catch_secs": 0.0, ## T5: a caught boomerang gives 30% speed this long.
	},
	"tiers": [
		{"text": "Every 4s a boomerang hits going out and back (6)", "card": "Every few seconds it throws a boomerang that hits on the way out and again on the way home.", "now": "Every {throw_every}s a boomerang hits going out and back ({boom_damage})"},
		{"text": "Boomerang size +{+boom_radius}%", "boom_radius": 26.0},
		{"text": "Boomerang {^boom_damage} → {boom_damage}, flies faster", "boom_speed": 720.0, "boom_pull": 720.0},
		{"text": "Throw every {^throw_every} → {throw_every}s", "throw_every": 3.5},
		{"text": "+ Two boomerangs; a catch = speed burst", "special": "Double Back", "card": "Every few seconds it throws two boomerangs that hit going out and back; catching one speeds it up.", "now": "Every {throw_every}s 2 boomerangs hit out and back ({boom_damage}); catch: speed", "boom_count": 2, "boom_catch_secs": 1.5},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .06, "mouth": "grin"}, "back": ["boomerang"], "front": ["toystripes"]},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.1},
}
