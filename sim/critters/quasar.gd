## Quasar, the Quasar (Legendary Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 78,
	"name": "Quasar",
	"type": "Quasar",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "planned",
	"color": "7400b8",
	"vibe": "A hypnotic cosmic lighthouse that never stops spinning.",
	"description": "Quasar. Two opposite beams slowly rotate out from it, and every 6 seconds they flare all the way to the walls.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Two spinning beams flare every 6s"},
		{"text": "Beams deal 10/s"},
		{"text": "Beams reverse after each flare"},
		{"text": "Longer beams"},
		{"text": "The flare adds a spinning cross"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "none"}, "back": ["jets"], "front": ["core"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.8},
}
