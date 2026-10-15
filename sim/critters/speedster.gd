## Zip, the Speedster (Common Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 4,
	"name": "Zip",
	"type": "Speedster",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "planned",
	"color": "ffb020",
	"vibe": "A cocky sprinter who never stops moving.",
	"description": "Speedster.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "wall", "do": "speed"}],
	"params": {},
	"tiers": [
		{"text": "+4% speed per wall bounce, max 5"},
		{"text": "Max 6"},
		{"text": "+5% per bounce"},
		{"text": "Max 8"},
		{"text": "Leaves a damaging afterimage"},
	],
	"art": {"eyes": {"sep": .3, "w": .21, "h": .14, "p": .09, "brow": .22, "mouth": "smirk"}, "back": ["speed_streaks"], "front": ["headband"]},
	"sound": {},
}
