## Pounce, the Snow lynx (Epic Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 69,
	"name": "Pounce",
	"type": "Snow lynx",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "planned",
	"color": "b7b7a4",
	"vibe": "A patient snow-lynx kitten that waits for the perfect moment.",
	"description": "Snow lynx. When hurt, it marks the attacker, pounces a second later, and its hit on a marked foe deals double.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hurt: marks the attacker, pounces for x2"},
		{"text": "Pounce dash +100%"},
		{"text": "The pounce also slows 20%"},
		{"text": "Pounces every 3s"},
		{"text": "A crit on a marked foe re-marks it"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smirk"}, "back": ["ears"], "front": ["spots", "whiskers"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.15},
}
