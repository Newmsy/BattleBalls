## Megabot, the Mech (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 76,
	"name": "Megabot",
	"type": "Mech",
	"rarity": "legendary",
	"rarity_power": 0.976, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "3d5a80",
	"vibe": "A giant-robot fan who built itself from spare parts and pure confidence.",
	"description": "Mech. Every 3rd hit it fires a salvo of 4 homing rockets ({shot_damage} each) and raises a {salvo_shield} shield.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "salvo"}, {"on": "always", "do": "salvo_tick"}],
	"params": {
		"salvo_hits": 3, ## Contact hits per salvo.
		"salvo_shield": 15.0,
		"salvo_shield_secs": 3.0,
		"salvo_delay": 0.6, ## It brakes and locks on this long before the rockets fly.
		"shot_damage": 5.0, ## Per rocket.
		"shot_speed": 450.0,
		"shot_count": 4,
		"shot_aim": "foe",
		"shot_homing": 3.0,
		"shot_spread": 30.0,
		"shot_slow": 0.0, ## Rockets slow the foe this much for 1s.
		"shot_life": 2.5,
		"shot_radius": 9.0,
		"shot_kind": "rocket",
		"mega_secs": 6.0,
	},
	"tiers": [
		{"text": "Every 3rd hit: 4 rockets (5 dmg) + 15 shield", "now": "Every 3rd hit: {shot_count} rockets ({shot_damage} dmg) + {salvo_shield} shield"},
		{"text": "Rocket dmg {^shot_damage} → {shot_damage}", "shot_damage": 6.0},
		{"text": "+ Rockets slow 15%", "now": "Every 3rd hit: {shot_count} slowing rockets ({shot_damage} dmg) + {salvo_shield} shield", "shot_slow": 0.15},
		{"text": "Rockets 4 → 6", "shot_count": 6},
		{"text": "+ Below 30% HP: hits count x2 for 6s", "now": "Every 3rd hit: {shot_count} rockets ({shot_damage} dmg) + shield · Mega at 30%", "special": "Mega Mode", "ability": [{"on": "hp_below", "hp": 0.3, "do": "mega"}]},
	],
	"art": {"eyes": {"visor": true, "mouth": "none"}, "back": ["pods"], "front": ["vvisor", "chestlight"]},
	"sound": {"ouch": "ouch_tech", "pitch": 0.75},
}
