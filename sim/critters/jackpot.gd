## Jackpot, the Slot machine (Legendary Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 80,
	"name": "Jackpot",
	"type": "Slot machine",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "planned",
	"color": "e0115f",
	"vibe": "A flashy arcade slot machine who's sure the next spin is the big one.",
	"description": "Slot machine. Every 6 seconds it spins its reels and fires a seeded prize: a ring of mines, a cross of beams or a burst of coins.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 6s spins for one of 3 prizes"},
		{"text": "Prizes hit 20% harder"},
		{"text": "A fourth prize: a 20 shield"},
		{"text": "Spins every 5s"},
		{"text": "Every 4th spin pays out every prize"},
	],
	"art": {"eyes": {"none": true, "mouth": "grin"}, "back": ["lever"], "front": ["reels"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.1},
}
