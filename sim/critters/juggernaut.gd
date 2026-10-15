## Boulder, the Juggernaut (Common Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 2,
	"name": "Boulder",
	"type": "Juggernaut",
	"rarity": "common",
	"role": "Bruiser",
	"status": "live",
	"color": "7d8799",
	"vibe": "Big, slow and completely unbothered.",
	"description": "Juggernaut. Huge and slow. Balls it hits take slam damage if they hit a wall soon after.",
	"stats": {"hp": 115.0, "radius": 82.0, "speed": 320.0, "contact_damage": 23.0},
	"ability": [{"on": "hit", "do": "mark_slam"}, {"on": "foe_wall", "do": "slam"}],
	"params": {
		"slam_damage": 9.0, ## Damage when a foe it just hit meets a wall.
		"slam_window": 0.3, ## Seconds after a hit that a wall bounce counts.
	},
	"tiers": [
		{"text": "Foes it hits take 9 slam damage off a wall within 0.3s"},
		{"text": "Slams for 10", "slam_damage": 10.0},
		{"text": "0.4s slam window", "slam_window": 0.4},
		{"text": "Slams for 12", "slam_damage": 12.0},
		{"text": "Shockwave on every hit"},
	],
	"art": {"eyes": {"sep": .24, "w": .11, "h": .12, "p": .08, "uni": true, "mouth": "flat"}, "front": ["rock_band"], "scale": 1.15},
	"sound": {},
}
