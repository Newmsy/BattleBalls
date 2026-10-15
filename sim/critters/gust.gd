## Gust, the Breeze (Rare Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 55,
	"name": "Gust",
	"type": "Breeze",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "planned",
	"color": "c7f9cc",
	"vibe": "A puffed-cheek little breeze who just wants some personal space.",
	"description": "Breeze. Its wind always pushes foes gently away from it.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Its wind gently pushes foes away"},
		{"text": "Stronger wind"},
		{"text": "Every 5s a strong huff"},
		{"text": "The wind reaches further"},
		{"text": "The huff carries ice crystals"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "pout"}, "body": "cloud", "back": ["windcurls"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
