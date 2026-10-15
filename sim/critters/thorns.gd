## Bramble, the Thorns (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 8,
	"name": "Bramble",
	"type": "Thorns",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "planned",
	"color": "4f7a3a",
	"vibe": "Grumpy hedge that just wants to be left alone.",
	"description": "Thorns.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "hurt", "do": "reflect"}],
	"params": {},
	"tiers": [
		{"text": "Reflect 20% of damage taken"},
		{"text": "Reflect 25%"},
		{"text": "30%, plus a thorn burst"},
		{"text": "Reflect 35%"},
		{"text": "Thorn burst on every hit taken"},
	],
	"art": {"eyes": {"sep": .3, "w": .17, "h": .19, "p": .09, "brow": .32, "mouth": "frown"}, "back": ["thorn_ring"], "front": ["vines"]},
	"sound": {},
}
