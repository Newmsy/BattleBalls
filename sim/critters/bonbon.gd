## Bonbon, the Wrapped candy (Legendary Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 89,
	"name": "Bonbon",
	"type": "Wrapped candy",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "planned",
	"color": "f15bb5",
	"vibe": "A sugary prankster who wraps everyone up like a present.",
	"description": "Wrapped candy. Every 6 seconds it gift-wraps the foe, holding it still for half a second, and the foe takes 20% more damage for 2 seconds after the ribbon pops.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 6s wraps the foe: +20% damage"},
		{"text": "Wrapped foes take +25%"},
		{"text": "The pop scatters candies"},
		{"text": "Wraps every 5s"},
		{"text": "Every third wrap pulls the foe in"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["wrapper", "bow"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
