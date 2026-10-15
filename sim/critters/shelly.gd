## Shelly, the Turtle (Uncommon Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 24,
	"name": "Shelly",
	"type": "Turtle",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "planned",
	"color": "52b788",
	"vibe": "A wise old sea turtle that knows exactly when to hide.",
	"description": "Turtle. Below 30% HP it pulls into its shell: much tougher, but slower.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Below 30% HP: 40% armour"},
		{"text": "45% armour"},
		{"text": "Tucking in also heals 8"},
		{"text": "50% armour"},
		{"text": "Tucking in slams its shell out first"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["shellhex"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
