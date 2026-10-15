## Zing, the Wasp (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 50,
	"name": "Zing",
	"type": "Wasp",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "live",
	"color": "f5c400",
	"vibe": "A buzzy little wasp that never misses a chance to sting.",
	"description": "Wasp. Every wall bounce it fires a homing stinger at the foe.",
	"stats": {"hp": 112.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.5},
	"ability": [{"on": "wall", "do": "shoot"}],
	"params": {
		"fire_cooldown": 0.6, ## At most one stinger this often (corners and pillars bounce fast).
		"shot_damage": 1.8,
		"shot_speed": 600.0,
		"shot_count": 1,
		"shot_aim": "foe",
		"shot_homing": 2.5, ## Turn rate toward the foe, radians a second.
		"shot_burn": 0.0, ## Poison per second for 2s, when above 0.
		"shot_big_every": 0, ## Every Nth bounce is a swarm of shot_big_count, when above 0.
		"shot_big_count": 4,
		"shot_spread": 25.0,
		"shot_radius": 8.0,
		"shot_life": 2.5,
		"shot_kind": "stinger",
	},
	"tiers": [
		{"text": "Bounces fire a homing stinger for 1.8"},
		{"text": "Stingers deal 2.5", "shot_damage": 2.5},
		{"text": "Stingers poison (2/s for 2s)", "shot_burn": 2.0},
		{"text": "Stingers home harder", "shot_homing": 3.5},
		{"text": "Every 4th bounce fires a swarm of 4", "shot_big_every": 4},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "flat"}, "back": ["wings", "stinger"], "front": ["stripes"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.4},
}
