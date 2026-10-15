## Dupe, the Splitter (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 9,
	"name": "Dupe",
	"type": "Splitter",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "live",
	"color": "ff6fae",
	"vibe": "Two personalities sharing one jelly body, never quite agreeing.",
	"description": "Splitter. At half HP it tears into two smaller, faster minis that share what HP it has left.",
	"stats": {"hp": 145.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.5},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "split"}],
	"params": {
		"split_gens": 1, ## Splits per ball in all; above 1, minis split again below half their HP.
		"split_radius": 0.7, ## Mini size, x its own.
		"split_speed": 1.15, ## Mini speed, x its own.
		"split_damage": 0.0, ## Contact damage a mini adds.
	},
	"tiers": [
		{"text": "Splits into two minis at 50% HP"},
		{"text": "Minis hit harder (+2)", "split_damage": 2.0},
		{"text": "Minis split once more at half their HP", "split_gens": 2},
		{"text": "Minis hit harder still (+3)", "split_damage": 3.0},
		{"text": "Minis are faster", "split_speed": 1.3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smile"}, "front": ["seam"]},
	"sound": {},
}
