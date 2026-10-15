## Fizz, the Soda (Uncommon Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 34,
	"name": "Fizz",
	"type": "Soda",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "planned",
	"color": "ff4da6",
	"vibe": "A shaken-up soda that's always one bounce away from popping.",
	"description": "Soda. Every wall bounce builds pressure, and at 10 it pops for a burst of speed and a harder hit.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Pops at 10 pressure for speed and power"},
		{"text": "Pops at 8 pressure"},
		{"text": "Popping leaves a fizz puddle"},
		{"text": "The pop adds +8 damage"},
		{"text": "Popping dashes at the foe and splashes"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["ringpull"], "front": ["fizz"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
