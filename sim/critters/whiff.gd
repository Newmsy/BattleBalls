## Whiff, the Skunk (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 44,
	"name": "Whiff",
	"type": "Skunk",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "live",
	"color": "9d8ec7",
	"vibe": "A sweet-natured skunk who has no idea why everyone backs away.",
	"description": "Skunk. A stink cloud always surrounds it, hurting foes that stay close (2/s).",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "always", "do": "stink"}],
	"params": {
		"stink_radius": 120.0, ## Cloud reach from Whiff's centre.
		"stink_dps": 2.0,
		"stink_slow": 0.0, ## T3: the stink slows.
		"stink_bloom_radius": 220.0, ## T5: cloud size while blooming.
		"stink_bloom_secs": 4.0,
	},
	"tiers": [
		{"text": "A stink cloud hurts close foes 2/s", "now": "A stink cloud hurts close foes {stink_dps}/s"},
		{"text": "Stink 2 → 3/s", "stink_dps": 3.0},
		{"text": "+ The stink slows 10%", "now": "A stink cloud hurts close foes {stink_dps}/s, slow {stink_slow%}%", "stink_slow": 0.1},
		{"text": "Cloud size +25%", "stink_radius": 150.0},
		{"text": "+ Below 40% HP the cloud blooms huge for 4s", "now": "Stink cloud {stink_dps}/s, slow {stink_slow%}%; blooms at 40% HP", "ability": [{"on": "hp_below", "hp": 0.4, "do": "bloom"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["bigtail"], "front": ["stripe"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.05},
}
