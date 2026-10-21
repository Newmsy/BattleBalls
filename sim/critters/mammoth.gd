## Mammoth, the Mammoth (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 60,
	"name": "Mammoth",
	"type": "Mammoth",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "live",
	"color": "7f5539",
	"vibe": "A woolly giant who believes every wall is a friend.",
	"description": "Mammoth. Its hits shove foes hard, and a foe that slams into a wall right after is frozen for a moment.",
	"stats": {"hp": 125.0, "radius": 80.0, "speed": 400.0, "contact_damage": 16.75},
	"ability": [{"on": "hit", "do": "shove"}, {"on": "strike", "do": "shatter"}],
	"params": {
		"slam_damage": 6.0, ## A shoved foe that hits a wall in time.
		"slam_window": 0.6,
		"slam_freeze": 0.5,
		"slam_patch": 0.0, ## T3: icy patch on the wall (3s).
		"slam_patch_slow": 0.3,
		"shatter_mult": 0.0, ## T5: hitting a frozen foe.
	},
	"tiers": [
		{"text": "Hits shove foes; a wall within 0.6s deals 6 and freezes 0.5s"},
		{"text": "Slams deal 8", "slam_damage": 8.0},
		{"text": "Slams leave an icy patch that slows 30% for 3s", "slam_patch": 70.0},
		{"text": "Slam window 0.8s", "slam_window": 0.8},
		{"text": "Its next hit on a foe it froze shatters for double damage", "shatter_mult": 2.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "none"}, "back": ["fur"], "front": ["tusks", "trunk"], "scale": 1.12},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.7},
}
