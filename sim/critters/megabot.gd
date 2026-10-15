## Megabot, the Mech (Legendary Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 76,
	"name": "Megabot",
	"type": "Mech",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "planned",
	"color": "3d5a80",
	"vibe": "A giant-robot fan who built itself from spare parts and pure confidence.",
	"description": "Mech. Every third hit it fires a salvo of homing rockets and raises a shield.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 3rd hit: 4 rockets and a shield"},
		{"text": "Rockets deal 6"},
		{"text": "Rockets slow on hit"},
		{"text": "6 rockets"},
		{"text": "Below 30% HP: Mega Mode"},
	],
	"art": {"eyes": {"visor": true, "mouth": "none"}, "back": ["pods"], "front": ["vvisor", "chestlight"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.75},
}
