## Dupe, the Splitter (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 9,
	"name": "Dupe",
	"type": "Splitter",
	"rarity": "epic",
	"rarity_power": 1.036, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "ff6fae",
	"vibe": "Two personalities sharing one jelly body, never quite agreeing.",
	"description": "Splitter. At 50% HP it tears into two smaller, faster minis that share what HP it has left.",
	"stats": {"hp": 145.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.5},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "split"}],
	"params": {
		"split_gens": 1, ## Splits per ball in all; above 1, minis split again below half their HP.
		"split_radius": 0.7, ## Mini size, x its own.
		"split_speed": 1.15, ## Mini speed, x its own.
		"split_damage": 0.0, ## Contact damage a mini adds.
	},
	"tiers": [
		{"text": "At 50% HP splits into two minis"},
		{"text": "+ Minis +2 dmg", "now": "At 50% HP splits into two minis (+{split_damage} dmg)", "split_damage": 2.0},
		{"text": "+ Minis split again at 50% of their HP", "now": "At 50% HP splits into minis that split again (+{split_damage} dmg)", "split_gens": 2},
		{"text": "Mini dmg +2 → +3", "split_damage": 3.0},
		{"text": "Mini speed x1.15 → 1.3", "split_speed": 1.3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smile"}, "front": ["seam"]},
	"sound": {},
}
