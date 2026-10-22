## Munch, the Muncher (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 61,
	"name": "Munch",
	"type": "Muncher",
	"rarity": "epic",
	"rarity_power": 1.133, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "fb8500",
	"vibe": "A cheerful glutton who treats every fight like a buffet.",
	"description": "Muncher. Every hit takes a bite: Munch heals 3, grows +5% and hits +1 harder, up to 5 bites.",
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
		{"text": "Bites heal 3, +5% size, +1 dmg; max 5", "now": "Bites heal {stack_heal}, +{stack_radius%}% size, +{stack_add} dmg; max {stack_max}"},
		{"text": "Bite heal 3 → 4", "stack_heal": 4.0},
		{"text": "+ At 5 bites: -15% dmg taken", "now": "Bites heal {stack_heal}, +{stack_add} dmg; full ({stack_max}): -{stack_full_armor%}% taken", "stack_full_armor": 0.15},
		{"text": "Max bites 5 → 6", "stack_max": 6.0},
		{"text": "+ Full: burps 10 + knockback, back to 2", "now": "Bites heal {stack_heal}, +{stack_add} dmg; full: -{stack_full_armor%}% taken, burp {burp_damage}", "burp_radius": 150.0, "ability": [{"on": "hit", "do": "stack_burp"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "bigmouth"}, "front": ["napkin"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.95},
}
