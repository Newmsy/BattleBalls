## Hook, the Grapple (Rare Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 56,
	"name": "Hook",
	"type": "Grapple",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "planned",
	"color": "9a031e",
	"vibe": "A swashbuckling grapple that loves to reel in a catch.",
	"description": "Grapple. Every wall bounce it yanks the foe a little toward itself.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bounces yank the foe toward it"},
		{"text": "Stronger yank"},
		{"text": "A yanked foe that hits Hook takes +4"},
		{"text": "Even stronger yank"},
		{"text": "Every 4th bounce reels in and slows"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smirk"}, "back": ["hook"], "front": ["bandana"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.95},
}
