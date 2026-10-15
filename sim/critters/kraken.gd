## Kraken, the Kraken (Legendary Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 81,
	"name": "Kraken",
	"type": "Kraken",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "planned",
	"color": "8e3bbd",
	"vibe": "A playful deep-sea giant who just wants to hug everything at once.",
	"description": "Kraken. Four long tentacles sweep in a wide circle around it, and every 6 seconds they slam down, leaving ink puddles that slow foes.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "4 tentacles sweep; slams every 6s"},
		{"text": "Tentacles deal 6"},
		{"text": "Slams also shove"},
		{"text": "Tentacles reach further"},
		{"text": "Every third slam is a giant hug"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "beak"}, "back": ["tentacles"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.75},
}
