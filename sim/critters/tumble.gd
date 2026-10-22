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
	"description": "Tumbleweed. Every wall bounce makes it +5% bigger and +1 harder-hitting (up to 6), until something bumps it.",
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
		{"text": "Wall bounces: +5% size, +1 dmg, max 6", "now": "Wall bounces: +{twig_grow%}% size, +{twig_damage} dmg, max {twig_max}"},
		{"text": "Max stacks 6 → 8", "twig_max": 8.0},
		{"text": "+ A bump only knocks off half", "twig_keep": 0.5},
		{"text": "Per bounce +1 → +1.5 dmg", "twig_damage": 1.5},
		{"text": "+ At max, a bump on it bursts for 10", "now": "Wall bounces: +{twig_grow%}% size, +{twig_damage} dmg, max {twig_max}, then burst", "twig_burst": 10.0},
	],
	"chaos": {"hyper_speed": {"twig_damage": 0.75}}, ## Hyper Speed piles on twigs too fast
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "smirk"}, "front": ["twigs"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.05},
}
