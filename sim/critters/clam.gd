## Clam, the Clam (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 42,
	"name": "Clam",
	"type": "Clam",
	"rarity": "rare",
	"rarity_power": 0.925, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.88, 0.82, 0.96, 0.87, 0.94], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "f7c6d9",
	"vibe": "A pearl-proud clam that snaps shut at the first sign of trouble.",
	"description": "Clam. Every {fire_cooldown}s it snaps shut for {shut_secs}s (-{shut_armor%}% dmg taken, biting foes that hit it for {clamp_damage}), then pops open and fires {shot_count} pearls at the foe ({shot_damage} dmg each).",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "every", "secs": "fire_cooldown", "do": "shut"}, {"on": "guard", "do": "shut_guard"}, {"on": "always", "do": "shut_open"}, {"on": "hurt", "do": "clamp"}],
	"params": {
		"fire_cooldown": 6.0, ## Seconds between snaps.
		"shut_secs": 1.5,
		"shut_armor": 0.6, ## Share of damage blocked while shut.
		"shot_damage": 6.0, ## Each pearl.
		"shot_speed": 600.0,
		"shot_count": 3,
		"shot_aim": "foe",
		"shot_knock": 0, ## 1: the pearl knocks the foe back.
		"shot_split": 0, ## Splits into this many off a wall, when above 0.
		"shot_radius": 13.0,
		"shot_kind": "pearl",
		"clamp_damage": 6.0, ## A foe that bumps it while shut gets bitten.
	},
	"tiers": [
		{"text": "Every 6s shuts (-60% taken, bites 6), 3 pearls 6", "card": "Snaps shut to shrug off hits and bite attackers, then opens and fires pearls at the foe.", "now": "Every {fire_cooldown}s shuts (-{shut_armor%}% taken, bites {clamp_damage}), {shot_count} pearls {shot_damage}"},
		{"text": "Pearls {^shot_damage} → {shot_damage}", "shot_damage": 8.0},
		{"text": "+ The pearl knocks the foe back", "card": "Snaps shut to shrug off hits and bite attackers, then fires pearls that knock the foe back.", "now": "Every {fire_cooldown}s shuts, bites; {shot_count} pearls {shot_damage} + knockback", "shot_knock": 1},
		{"text": "Snap every 6 → 5s", "fire_cooldown": 5.0},
		{"text": "+ Pearls split in 3 off walls", "card": "Snaps shut to shrug off hits and bite attackers, then fires pearls that split off walls.", "now": "Every {fire_cooldown}s shuts, bites; {shot_count} splitting pearls {shot_damage}", "shot_split": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "none"}, "front": ["clamshell", "pearl"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.9},
}
