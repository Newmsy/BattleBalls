## Ink, the Squid (Uncommon Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 38,
	"name": "Ink",
	"type": "Squid",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "planned",
	"color": "3c1f5c",
	"vibe": "A shy squid that squirts ink when startled and hopes nobody noticed.",
	"description": "Squid. When hurt, it squirts an ink cloud that slows foes caught inside.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hurt: squirts ink that slows 35%"},
		{"text": "Ink lasts 3s"},
		{"text": "Squirting gives Ink +25% speed"},
		{"text": "Squirts every 2.5s"},
		{"text": "The ink also stings foes inside"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "beak"}, "back": ["tentacles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.15},
}
