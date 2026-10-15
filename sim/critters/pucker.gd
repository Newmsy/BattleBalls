## Pucker, the Sour grape (Uncommon Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 39,
	"name": "Pucker",
	"type": "Sour grape",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "planned",
	"color": "7b2cbf",
	"vibe": "A sour grape whose face says it all.",
	"description": "Sour grape. Every hit makes the foe sour, so it takes 15% more damage for 2 seconds.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits make the foe take +15% for 2s"},
		{"text": "Sour: +18%"},
		{"text": "Repeat hits stack it up to +25%"},
		{"text": "Sour lasts 2.5s"},
		{"text": "The sour splash leaves a slow puddle"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "pout"}, "back": ["stemleaf"], "front": ["bloom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.25},
}
