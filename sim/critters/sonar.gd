## Sonar, the Bat (Rare Skirmisher). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 51,
	"name": "Sonar",
	"type": "Bat",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "planned",
	"color": "3c096c",
	"vibe": "A nocturnal bat that always knows exactly where you are.",
	"description": "Bat. Every wall bounce it pings, swerving toward the foe and sending out a ring that slows.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Bounces ping: swerves in, slows 20%"},
		{"text": "Swerve dash +50%"},
		{"text": "The ping also deals 4"},
		{"text": "The ping reaches further"},
		{"text": "A dash hit right after a ping crits"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "fangs"}, "back": ["batwings", "ears"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
