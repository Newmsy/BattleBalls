## Chill, the Frost (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 7,
	"name": "Chill",
	"type": "Frost",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "bfe9ff",
	"vibe": "Sleepy and unhurried; everything near it slows down to its pace.",
	"description": "Frost. Leaves an icy trail that slows foes who cross it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 11.0},
	"ability": [{"on": "always", "do": "trail"}],
	"params": {
		"trail_every": 0.1, ## Seconds between trail blobs.
		"trail_width": 30.0,
		"trail_life": 2.0,
		"trail_slow": 0.3, ## Share of a foe's movement lost on the ice.
		"trail_dps": 0.0,
		"breath_radius": 120.0, ## T5 frost breath.
		"breath_slow": 0.5,
		"breath_secs": 1.0,
	},
	"tiers": [
		{"text": "Icy trail slows foes 30%, lasts 2s"},
		{"text": "Trail lasts 2.5s", "trail_life": 2.5},
		{"text": "The ice also stings", "trail_dps": 1.0},
		{"text": "Slows 40%", "trail_slow": 0.4},
		{"text": "Every 5s it puffs frost breath that slows 50%", "ability": [{"on": "every", "secs": 5.0, "do": "breath"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .19, "h": .2, "p": .09, "lid": .55, "mouth": "o"}, "back": ["ice_crown"], "front": ["frost_freckles"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.25},
}
