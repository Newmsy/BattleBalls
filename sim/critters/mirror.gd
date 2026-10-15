## Echo, the Mirror (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 12,
	"name": "Echo",
	"type": "Mirror",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "planned",
	"color": "cfd8e6",
	"vibe": "A copycat show-off that mimics whoever just hit it.",
	"description": "Mirror.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "hurt", "do": "copy"}],
	"params": {},
	"tiers": [
		{"text": "Copies the last ability that hit it"},
		{"text": "Copy lasts longer"},
		{"text": "Copies at full strength"},
		{"text": "Keeps 2 copies"},
		{"text": "Reflects the copy back"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .25, "p": .1, "mouth": "smile"}, "body": "chrome"},
	"sound": {},
}
