## Clam, the Clam (Rare Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 42,
	"name": "Clam",
	"type": "Clam",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "planned",
	"color": "f7c6d9",
	"vibe": "A pearl-proud clam that snaps shut at the first sign of trouble.",
	"description": "Clam. Every 6 seconds it snaps shut, taking much less damage for a moment, then pops open and fires a pearl at the foe.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 6s: shuts for 60% armour, fires a pearl"},
		{"text": "Pearl deals 10"},
		{"text": "The pearl knocks the foe back"},
		{"text": "Snaps every 5s"},
		{"text": "The pearl splits in 3 off walls"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "none"}, "front": ["clamshell", "pearl"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
