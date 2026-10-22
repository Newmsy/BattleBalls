## Cogs, the Gear (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 33,
	"name": "Cogs",
	"type": "Gear",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "live",
	"color": "b5838d",
	"vibe": "A wind-up toy gear that gets wound tighter every time it's knocked.",
	"description": "Gear. Every bump winds it up faster (+9% speed, max +36%, holds 10s); fully wound, its next hit unwinds for x1.6.",
	"stats": {"hp": 119.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "hurt", "do": "wind"}, {"on": "strike", "do": "unwind"}],
	"params": {
		"wind_step": 0.09,
		"wind_cap": 0.36, ## Fully wound at 4 bumps.
		"wind_secs": 10.0,
		"wind_add": 0.0,
		"wind_crit": 1.6,
	},
	"tiers": [
		{"text": "Bumps wind +9% speed (max 36%) · full: next hit x1.6", "now": "Bumps wind +{wind_step%}% speed (max {wind_cap%}%) · full: next hit x{wind_crit}"},
		{"text": "Wind 9 → 12% per bump", "wind_step": 0.12},
		{"text": "+ Fully wound: +2 contact dmg", "now": "Bumps wind +{wind_step%}% speed (max {wind_cap%}%) · full: +{wind_add}, hit x{wind_crit}", "wind_add": 2.0},
		{"text": "Max wind 36 → 48%", "wind_cap": 0.48},
		{"text": "Wind 12 → 16%, unwind x1.6 → 2.6", "wind_crit": 2.6, "wind_step": 0.16},
	],
	"chaos": {"glass_cannon": {"wind_step": 0.7}}, ## Glass Cannon bumps hurt more, so each wind-up is worth more
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "flat"}, "back": ["gears", "key"]},
	"sound": {"ouch": "ouch_tech", "pitch": 1.0},
}
