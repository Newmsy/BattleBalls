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
	"description": "Juggernaut. Huge and slow. A foe it hits takes 9 if it hits a wall within 0.3s.",
	"stats": {"hp": 115.0, "radius": 82.0, "speed": 320.0, "contact_damage": 23.0},
	"ability": [{"on": "hit", "do": "mark_slam"}, {"on": "foe_wall", "do": "slam"}],
	"params": {
		"slam_damage": 9.0, ## Damage when a foe it just hit meets a wall.
		"slam_window": 0.3, ## Seconds after a hit that a wall bounce counts.
		"boom_radius": 150.0, ## T5 shockwave.
		"boom_damage": 5.0,
		"boom_slam": 0.0,
		"boom_double_every": 0,
	},
	"tiers": [
		{"text": "Hit foes take 9 off a wall within 0.3s", "now": "Hit foes take {slam_damage} off a wall within {slam_window}s"},
		{"text": "Slam 9 → 10", "slam_damage": 10.0},
		{"text": "Slam window 0.3 → 0.4s", "slam_window": 0.4},
		{"text": "Slam 10 → 12", "slam_damage": 12.0},
		{"text": "+ Hits send a shockwave: 5 + knockback", "now": "Hits: shockwave {boom_damage}; foe takes {slam_damage} off a wall in {slam_window}s", "ability": [{"on": "hit", "do": "boom"}]},
	],
	## Chaos Weekends: fast, cramped twists favour its big hits; Double Trouble
	## feeds Vampire's heal off them. Tuned with tools/balance.gd --modifiers.
	"chaos": {"big_head": {"contact_damage": 0.97}, "hyper_speed": {"contact_damage": 0.97}, "double_trouble": {"contact_damage": 1.1}},
	"art": {"eyes": {"sep": .24, "w": .11, "h": .12, "p": .08, "uni": true, "mouth": "flat"}, "front": ["rock_band"], "scale": 1.15},
	"sound": {},
}
