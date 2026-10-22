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
	"description": "Mammoth. Its hits knock foes back hard, and a foe that slams into a wall within 0.8s takes 7 and freezes 0.5s.",
	"stats": {"hp": 125.0, "radius": 80.0, "speed": 400.0, "contact_damage": 16.75},
	"ability": [{"on": "hit", "do": "shove"}, {"on": "strike", "do": "shatter"}],
	"params": {
		"slam_damage": 7.0, ## A shoved foe that hits a wall in time.
		"slam_window": 0.8,
		"slam_freeze": 0.5,
		"slam_patch": 0.0, ## T3: icy patch on the wall (3s).
		"slam_patch_slow": 0.3,
		"shatter_mult": 0.0, ## T5: hitting a frozen foe.
	},
	"tiers": [
		{"text": "Hits knock foes back; wall slam in 0.8s: 7 + freeze", "now": "Hits knock foes back; wall slam in {slam_window}s: {slam_damage} + freeze"},
		{"text": "Slam 7 → 9", "slam_damage": 9.0},
		{"text": "+ The slam leaves ice: slow 30% for 3s", "now": "Knockback hits; wall slam in {slam_window}s: {slam_damage}, freeze, ice", "slam_patch": 70.0},
		{"text": "Slam window 0.8 → 1.1s", "slam_window": 1.1},
		{"text": "+ A frozen foe shatters on its next hit: x2", "now": "Knockback hits; wall slam in {slam_window}s: {slam_damage}, freeze, shatter x{shatter_mult}", "shatter_mult": 2.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "none"}, "back": ["fur"], "front": ["tusks", "trunk"], "scale": 1.12},
	"sound": {"ouch": "ouch_frost", "pitch": 0.7},
}
