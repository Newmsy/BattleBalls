## Zing, the Wasp (Rare Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 50,
	"name": "Zing",
	"type": "Wasp",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "planned",
	"color": "f5c400",
	"vibe": "A buzzy little wasp that never misses a chance to sting.",
	"description": "Wasp. Every wall bounce it fires a homing stinger at the foe.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bounces fire a homing stinger for 5"},
		{"text": "Stingers deal 6"},
		{"text": "Stingers poison (2/s for 2s)"},
		{"text": "Stingers home harder"},
		{"text": "Every 4th bounce fires a swarm of 4"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "flat"}, "back": ["wings", "stinger"], "front": ["stripes"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.4},
}
