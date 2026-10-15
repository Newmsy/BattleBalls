## Tumble, the Tumbleweed (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 26,
	"name": "Tumble",
	"type": "Tumbleweed",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "c8a165",
	"vibe": "A dusty tumbleweed that gathers itself up every time it rolls.",
	"description": "Tumbleweed. Every wall bounce makes it a little bigger and harder-hitting, until something bumps it.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "wall", "do": "twig"}, {"on": "hurt", "do": "twig_drop"}],
	"params": {
		"twig_grow": 0.05,
		"twig_damage": 1.0,
		"twig_max": 6.0,
		"twig_keep": 0.0,
		"twig_burst": 0.0,
		"twig_burst_radius": 140.0,
	},
	"tiers": [
		{"text": "+5% size, +1 damage per bounce, max 6"},
		{"text": "Grows up to 8 times", "twig_max": 8.0},
		{"text": "A bump only knocks off half", "twig_keep": 0.5},
		{"text": "+1.5 damage per bounce", "twig_damage": 1.5},
		{"text": "At max size, the next bump on it bursts in dust (10 damage)", "twig_burst": 10.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "smirk"}, "front": ["twigs"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.05},
}
