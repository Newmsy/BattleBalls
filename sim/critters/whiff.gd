## Whiff, the Skunk (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 44,
	"name": "Whiff",
	"type": "Skunk",
	"rarity": "rare",
	"tier_power": [1.09, 1.08, 1.06, 1.13, 1.21], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "9d8ec7",
	"vibe": "A sweet-natured skunk who has no idea why everyone backs away.",
	"description": "Skunk. A stink cloud always surrounds it, hurting foes that stay close ({stink_dps}/sec).",
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
		{"text": "A stink cloud hurts close foes 2/sec", "card": "A stink cloud surrounds it, hurting foes that stay close.", "now": "A stink cloud hurts close foes {stink_dps}/sec"},
		{"text": "Stink {^stink_dps} → {stink_dps}/sec", "stink_dps": 3.0},
		{"text": "+ The stink slows 10%", "card": "A stink cloud surrounds it, hurting and slowing foes that stay close.", "now": "A stink cloud hurts close foes {stink_dps}/sec, slow {stink_slow%}%", "stink_slow": 0.1},
		{"text": "Cloud size +{+stink_radius}%", "stink_radius": 150.0},
		{"text": "+ Below 40% HP the cloud blooms huge for 4s", "card": "A slowing stink cloud hurts foes close by, and blooms huge when it's low.", "now": "Stink cloud {stink_dps}/sec, slow {stink_slow%}%; blooms at 40% HP", "ability": [{"on": "hp_below", "hp": 0.4, "do": "bloom"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["bigtail"], "front": ["stripe"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.05},
}
