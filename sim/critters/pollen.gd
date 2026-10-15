## Pollen, the Dandelion (Uncommon Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 40,
	"name": "Pollen",
	"type": "Dandelion",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "planned",
	"color": "caffbf",
	"vibe": "A dreamy dandelion puff that sneezes seeds everywhere when bumped.",
	"description": "Dandelion. When hurt, it puffs out seeds that drift slowly and sting anything they touch.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hurt: puffs 4 stinging seeds"},
		{"text": "Seeds deal 5"},
		{"text": "6 seeds"},
		{"text": "Puffs every 1s"},
		{"text": "Spent seeds burst"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "o"}, "back": ["tufts"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.35},
}
