## Drum, the Drum (Uncommon Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 37,
	"name": "Drum",
	"type": "Drum",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "planned",
	"color": "e63946",
	"vibe": "A party drum that answers every bump with a BOOM.",
	"description": "Drum. Every hit it lands sends out a shockwave ring that shoves foes back.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every hit booms a shockwave for 3"},
		{"text": "Shockwave deals 4"},
		{"text": "Wall slams within 0.5s deal +5"},
		{"text": "Shockwave radius grows"},
		{"text": "Every third hit is a double boom"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["sticks"], "front": ["drumhead", "rope"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.0},
}
