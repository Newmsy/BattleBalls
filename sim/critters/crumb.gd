## Crumb, the Cookie (Common Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 18,
	"name": "Crumb",
	"type": "Cookie",
	"rarity": "common",
	"role": "Skirmisher",
	"status": "planned",
	"color": "a0522d",
	"vibe": "A plucky cookie who gets faster with every bite taken out of it.",
	"description": "Cookie. As it loses HP it shrinks and speeds up, at two-thirds and at one-third health.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Shrinks 10% and +12% speed per bite"},
		{"text": "+15% speed per bite"},
		{"text": "Each bite also heals 5"},
		{"text": "+18% speed per bite"},
		{"text": "A third bite at 15% HP sprays crumbs"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "front": ["chips", "bite"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
