## Clam, the Clam (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 42,
	"name": "Clam",
	"type": "Clam",
	"rarity": "rare",
	"rarity_power": 0.925, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "f7c6d9",
	"vibe": "A pearl-proud clam that snaps shut at the first sign of trouble.",
	"description": "Clam. Every 6s it snaps shut for 1.5s (-60% dmg taken), then pops open and fires a pearl at the foe for 8.",
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
		{"text": "Every 6s: shuts (-60% dmg taken), pearl 8", "now": "Every {fire_cooldown}s: shuts (-{shut_armor%}% dmg taken), pearl {shot_damage}"},
		{"text": "Pearl 8 → 10", "shot_damage": 10.0},
		{"text": "+ The pearl knocks the foe back", "now": "Every {fire_cooldown}s: shuts (-{shut_armor%}% dmg taken), pearl {shot_damage} + knockback", "shot_knock": 1},
		{"text": "Snap every 6 → 5s", "fire_cooldown": 5.0},
		{"text": "+ The pearl splits in 3 off walls", "now": "Every {fire_cooldown}s: shuts (-{shut_armor%}% dmg taken), splitting pearl {shot_damage}", "shot_split": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "none"}, "front": ["clamshell", "pearl"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.9},
}
