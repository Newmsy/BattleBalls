## Munch, the Muncher (Epic Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 61,
	"name": "Munch",
	"type": "Muncher",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "planned",
	"color": "fb8500",
	"vibe": "A cheerful glutton who treats every fight like a buffet.",
	"description": "Muncher. Every hit takes a bite: Munch heals a little and grows bigger and stronger, up to 5 bites.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bites heal 3 and grow it, max 5"},
		{"text": "Bites heal 4"},
		{"text": "At 5 bites: 15% armour"},
		{"text": "Up to 6 bites"},
		{"text": "At full size it burps a shockwave"},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "bigmouth"}, "front": ["napkin"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.95},
}
