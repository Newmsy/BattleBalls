## Wrecker, the Wrecking ball (Epic Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 62,
	"name": "Wrecker",
	"type": "Wrecking ball",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "planned",
	"color": "495057",
	"vibe": "A demolition bot who thinks everything looks better knocked down.",
	"description": "Wrecking ball. A heavy wrecking ball swings around it on a chain, smashing foes into walls.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "A wrecking ball swings for 9"},
		{"text": "The ball hits for 11"},
		{"text": "The chain is a beam too"},
		{"text": "The ball spins faster"},
		{"text": "Every 8s a big wind-up lap"},
	],
	"art": {"eyes": {"visor": true, "mouth": "flat"}, "back": ["chainball"], "front": ["hazard", "hardhat"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.75},
}
