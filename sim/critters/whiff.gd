## Whiff, the Skunk (Rare Bruiser). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 44,
	"name": "Whiff",
	"type": "Skunk",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "planned",
	"color": "9d8ec7",
	"vibe": "A sweet-natured skunk who has no idea why everyone backs away.",
	"description": "Skunk. A stinky cloud always surrounds it, hurting foes that stay close.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "A stink cloud hurts close foes 3/s"},
		{"text": "Stink deals 4/s"},
		{"text": "The stink also slows 10%"},
		{"text": "The cloud grows"},
		{"text": "Below 40% HP the cloud blooms huge"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["bigtail"], "front": ["stripe"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.05},
}
