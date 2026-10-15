## Stormwing, the Thunderbird (Legendary Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 83,
	"name": "Stormwing",
	"type": "Thunderbird",
	"rarity": "legendary",
	"role": "Skirmisher",
	"status": "planned",
	"color": "4895ef",
	"vibe": "A proud storm bird who arrives with a thunderclap.",
	"description": "Thunderbird. Every wall bounce charges a spark, and its next hit unleashes them as chain lightning that leaps from the foe to its last bounce points and stuns.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bounces charge sparks, max 4"},
		{"text": "Lightning deals 10/s"},
		{"text": "Lightning also burns"},
		{"text": "Up to 5 sparks"},
		{"text": "Max sparks calls a thunderclap"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "iris": "ffb300", "mouth": "smirk"}, "back": ["wings", "boltcrest"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.0},
}
