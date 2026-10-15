## Wisp, the Ghost (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 10,
	"name": "Wisp",
	"type": "Ghost",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "planned",
	"color": "e3d6ff",
	"vibe": "Shy and spooky, giggles when you miss it.",
	"description": "Ghost.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "every", "secs": 6.0, "do": "phase"}],
	"params": {},
	"tiers": [
		{"text": "Phases out 1s every 6s"},
		{"text": "Every 5s"},
		{"text": "Phases for 1.5s"},
		{"text": "Every 4s"},
		{"text": "Counters the hits it dodges"},
	],
	"art": {"eyes": {"sep": .3, "w": .15, "h": .24, "hollow": true, "mouth": "o"}, "body": "ghost", "back": ["wisp_tail"]},
	"sound": {},
}
