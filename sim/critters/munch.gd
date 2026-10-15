## Munch, the Muncher (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 61,
	"name": "Munch",
	"type": "Muncher",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "live",
	"color": "fb8500",
	"vibe": "A cheerful glutton who treats every fight like a buffet.",
	"description": "Muncher. Every hit takes a bite: Munch heals a little and grows bigger and stronger, up to 5 bites.",
	"stats": {"hp": 126.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "stack"}, {"on": "guard", "do": "stack_guard"}],
	"params": {
		"stack_max": 5.0,
		"stack_radius": 0.05,
		"stack_add": 1.0,
		"stack_heal": 3.0,
		"stack_armor": 0.0,
		"stack_full_armor": 0.0,
		"burp_radius": 0.0,
		"burp_damage": 10.0,
		"burp_keep": 2.0,
	},
	"tiers": [
		{"text": "Bites heal 3 and add +5% size and +1 damage, max 5"},
		{"text": "Bites heal 4", "stack_heal": 4.0},
		{"text": "At 5 bites: 15% armour", "stack_full_armor": 0.15},
		{"text": "Up to 6 bites", "stack_max": 6.0},
		{"text": "At full size it burps a shockwave (10 damage, knockback) and drops to 2 bites", "burp_radius": 150.0, "ability": [{"on": "hit", "do": "stack_burp"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "bigmouth"}, "front": ["napkin"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.95},
}
