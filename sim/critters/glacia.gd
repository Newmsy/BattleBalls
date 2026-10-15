## Glacia, the Ice queen (Legendary Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 90,
	"name": "Glacia",
	"type": "Ice queen",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "planned",
	"color": "b9a7ff",
	"vibe": "A regal ice queen, cool, polite and utterly in charge.",
	"description": "Ice queen. Every 7 seconds it raises a ring of ice pillars around the foe, then shatters them so the shards fly inward.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 7s rings the foe in 5 pillars"},
		{"text": "Shards deal 7"},
		{"text": "Shards slow 20%"},
		{"text": "6 pillars"},
		{"text": "Big rings of 8 fire two volleys"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smirk"}, "back": ["tallcrystals", "cape_collar"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.05},
}
