## Puff, the Pufferfish (Uncommon Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 23,
	"name": "Puff",
	"type": "Pufferfish",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "planned",
	"color": "ffd84a",
	"vibe": "A nervous pufferfish that balloons up when startled, then calms down.",
	"description": "Pufferfish. When hurt, it puffs up for 2 seconds: bigger, slower and spikier.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hurt: puffs up 30% for 2s, +2 damage"},
		{"text": "Puffed up: +3 damage"},
		{"text": "Puffing up shoves the attacker away"},
		{"text": "Puff lasts 2.5s"},
		{"text": "Deflating sprays 6 spines"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": -.14, "mouth": "pout"}, "back": ["sidefins"], "front": ["spots"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.15},
}
