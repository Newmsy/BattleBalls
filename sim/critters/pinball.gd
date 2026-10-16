## Pinball, the Pinball (Common Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 17,
	"name": "Pinball",
	"type": "Pinball",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "live",
	"color": "f1f3f5",
	"vibe": "A show-off arcade ball that treats every wall like a bumper worth points.",
	"description": "Pinball. Every wall it touches since its last hit adds damage to its next hit.",
	"stats": {"hp": 126.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "wall", "do": "light"}, {"on": "strike", "do": "cash_in"}],
	"params": {
		"bulb_damage": 1.0, ## Extra damage per wall since its last hit.
		"bulb_max": 5,
		"bulb_knock": 0, ## T3: cashing in this many or more knocks the foe back.
		"bulb_tilt": 0.0, ## T5: a full board deals this x on top.
	},
	"tiers": [
		{"text": "+1 damage per wall, up to 5"},
		{"text": "+1.5 per wall", "bulb_damage": 1.5},
		{"text": "Cashing in 3+ walls knocks the foe back", "bulb_knock": 3},
		{"text": "+2 per wall", "bulb_damage": 2.0},
		{"text": "A hit after 5 walls is a TILT! x2", "bulb_tilt": 2.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "body": "chrome", "tint": true, "back": ["rears"], "front": ["bulbs"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.25},
}
