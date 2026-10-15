## Dupe, the Splitter (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 9,
	"name": "Dupe",
	"type": "Splitter",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "planned",
	"color": "ff6fae",
	"vibe": "Two personalities sharing one jelly body, never quite agreeing.",
	"description": "Splitter.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "split"}],
	"params": {},
	"tiers": [
		{"text": "Splits once at 50% HP"},
		{"text": "Children hit harder"},
		{"text": "Splits at 50% and 25%"},
		{"text": "Children hit harder still"},
		{"text": "Children also split"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mis": true, "mouth": "smile"}, "front": ["seam"]},
	"sound": {},
}
