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
	"description": "Gear. Every bump winds it up faster (+12% speed, max +36%, holds 10s); fully wound, its next hit unwinds for x{wind_crit} and flings gear teeth.",
	"stats": {"hp": 119.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "hurt", "do": "wind"}, {"on": "strike", "do": "unwind"}],
	"params": {
		"wind_step": 0.12,
		"wind_cap": 0.36, ## Fully wound at 3 bumps (fights see ~5 hits).
		"wind_secs": 10.0,
		"wind_add": 0.0,
		"wind_crit": 2.0,
		"teeth_count": 3, ## The unwind flings gear teeth that ricochet once.
		"teeth_damage": 5.0,
	},
	"tiers": [
		{"text": "Bumps wind +12% speed (max 36%) · full: x2 hit + 3 gears", "now": "Bumps wind +{wind_step%}% speed (max {wind_cap%}%) · full: x{wind_crit} hit + {teeth_count} gears"},
		{"text": "Gear teeth 3 → 4", "teeth_count": 4},
		{"text": "+ Fully wound: +2 contact dmg", "now": "Bumps wind +{wind_step%}% speed (max {wind_cap%}%) · full: +{wind_add}, hit x{wind_crit}", "wind_add": 2.0},
		{"text": "Wind 12 → 16% per bump (max 48%)", "wind_step": 0.16, "wind_cap": 0.48},
		{"text": "Unwind x{^wind_crit} → {wind_crit}", "wind_crit": 3.0},
	],
	"chaos": {"glass_cannon": {"wind_step": 0.7}}, ## Glass Cannon bumps hurt more, so each wind-up is worth more
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "flat"}, "back": ["gears", "key"]},
	"sound": {"ouch": "ouch_tech", "pitch": 1.0},
}
