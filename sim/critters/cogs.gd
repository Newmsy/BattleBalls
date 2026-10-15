## Cogs, the Gear (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 33,
	"name": "Cogs",
	"type": "Gear",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "live",
	"color": "b5838d",
	"vibe": "A wind-up toy gear that gets wound tighter every time it's knocked.",
	"description": "Gear. Every time it's bumped it winds up faster, the opposite of Zip.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.5},
	"ability": [{"on": "hurt", "do": "wind"}, {"on": "strike", "do": "unwind"}],
	"params": {
		"wind_step": 0.06,
		"wind_cap": 0.36,
		"wind_secs": 4.0,
		"wind_add": 0.0,
		"wind_crit": 0.0,
	},
	"tiers": [
		{"text": "Bumped: winds up +6% speed, max +36%, for 4s"},
		{"text": "+8% per bump", "wind_step": 0.08},
		{"text": "Fully wound: +2 contact damage", "wind_add": 2.0},
		{"text": "Winds up to +48%", "wind_cap": 0.48},
		{"text": "Fully wound, its next hit crits (x2) and unwinds", "wind_crit": 2.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "flat"}, "back": ["gears", "key"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.0},
}
