## Clam, the Clam (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 42,
	"name": "Clam",
	"type": "Clam",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "live",
	"color": "f7c6d9",
	"vibe": "A pearl-proud clam that snaps shut at the first sign of trouble.",
	"description": "Clam. Every 6 seconds it snaps shut, taking much less damage for a moment, then pops open and fires a pearl at the foe.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "every", "secs": "fire_cooldown", "do": "shut"}, {"on": "guard", "do": "shut_guard"}, {"on": "always", "do": "shut_open"}],
	"params": {
		"fire_cooldown": 6.0, ## Seconds between snaps.
		"shut_secs": 1.5,
		"shut_armor": 0.6, ## Share of damage blocked while shut.
		"shot_damage": 8.0, ## The pearl.
		"shot_speed": 600.0,
		"shot_count": 1,
		"shot_aim": "foe",
		"shot_knock": 0, ## 1: the pearl knocks the foe back.
		"shot_split": 0, ## Splits into this many off a wall, when above 0.
		"shot_radius": 13.0,
		"shot_kind": "pearl",
	},
	"tiers": [
		{"text": "Every 6s: shuts for 60% armour, fires a pearl for 8"},
		{"text": "Pearl deals 10", "shot_damage": 10.0},
		{"text": "The pearl knocks the foe back", "shot_knock": 1},
		{"text": "Snaps every 5s", "fire_cooldown": 5.0},
		{"text": "The pearl splits in 3 off walls", "shot_split": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "none"}, "front": ["clamshell", "pearl"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
