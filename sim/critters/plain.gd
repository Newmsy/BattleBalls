## Plain: no ability. A baseline ball for tests and the balance sim, never
## offered to players.
extends RefCounted

const CRITTER := {
	"no": 0,
	"name": "Plain",
	"type": "Plain",
	"rarity": "common",
	"role": "Baseline",
	"status": "baseline",
	"color": "8a94a8",
	"vibe": "No ability. A baseline ball.",
	"description": "No ability. A baseline ball.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [{"text": "No ability"}, {"text": "No ability"}, {"text": "No ability"}, {"text": "No ability"}, {"text": "No ability"}],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}},
	"sound": {},
}
