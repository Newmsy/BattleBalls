## Beacon, the Lighthouse (Epic Zoner). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 67,
	"name": "Beacon",
	"type": "Lighthouse",
	"rarity": "epic",
	"role": "Zoner",
	"status": "planned",
	"color": "06d6a0",
	"vibe": "A steady old lighthouse keeper who keeps an eye on everything.",
	"description": "Lighthouse. Every 4 seconds it shines a beam straight ahead to the far wall, and foes caught in the light take 20% more damage for 2 seconds.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 4s a beam: foes take +20%"},
		{"text": "Beam deals 8/s"},
		{"text": "The beam sweeps 45 degrees"},
		{"text": "A beam every 3.5s"},
		{"text": "Two beams, forward and back"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smile"}, "back": ["lamp"], "front": ["stripes"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.9},
}
