## Ivy, the Vine spirit (Legendary Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 87,
	"name": "Ivy",
	"type": "Vine spirit",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "planned",
	"color": "0b8a5f",
	"vibe": "A graceful vine spirit who decides where everyone stands.",
	"description": "Vine spirit. Every 6 seconds it raises a vine pillar beside the foe and lashes the foe to it for a second, then the vine snaps in a burst.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Every 6s lashes the foe to a vine 1s"},
		{"text": "The burst deals 12"},
		{"text": "The snap leaves a thorn patch"},
		{"text": "Lashes every 5s"},
		{"text": "Two pillars at once"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["flowercrown"], "front": ["vinewrap"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.1},
}
