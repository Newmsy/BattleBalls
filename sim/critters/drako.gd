## Drako, the Dragon (Epic Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 59,
	"name": "Drako",
	"type": "Dragon",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "planned",
	"color": "2b9348",
	"vibe": "A baby dragon who is very serious about being fearsome.",
	"description": "Dragon. Every hit stokes its fire, and at 4 stokes it breathes a cone of fireballs and starts again.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "4 hits stoke a cone of fireballs"},
		{"text": "Fireballs deal 6"},
		{"text": "Each stoke gives 5% armour"},
		{"text": "Breathes after 3 stokes"},
		{"text": "The breath leaves a burning streak"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "smirk"}, "back": ["wings", "horns"], "front": ["belly"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
