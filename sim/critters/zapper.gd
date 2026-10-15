## Zapper, the Coil bot (Rare Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 57,
	"name": "Zapper",
	"type": "Coil bot",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "planned",
	"color": "c47a2c",
	"vibe": "A buzzing coil bot that loves to share its electricity.",
	"description": "Coil bot. Every 5 seconds it zaps the foe with an arc that stuns it for a moment.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 5s zaps the foe: 6 damage, stun"},
		{"text": "Zap deals 8"},
		{"text": "The arc lingers as a beam"},
		{"text": "Zaps every 4s"},
		{"text": "Every third zap is a 3-arc storm"},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "flat"}, "back": ["rodball"], "front": ["coil"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.05},
}
