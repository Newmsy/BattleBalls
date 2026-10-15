## Swarm, the Beehive (Epic Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 65,
	"name": "Swarm",
	"type": "Beehive",
	"rarity": "epic",
	"role": "Zoner",
	"status": "planned",
	"color": "bb8a2d",
	"vibe": "A busy beehive that is never, ever alone.",
	"description": "Beehive. Three bees circle it and sting foes they touch, and every 5 seconds one flies off at the foe while a new one hatches.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "3 bees sting; one launches every 5s"},
		{"text": "Bees deal 4"},
		{"text": "Launched bees poison"},
		{"text": "4 bees"},
		{"text": "Below 50% HP the whole swarm launches"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["bees"], "front": ["hive", "door"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.3},
}
