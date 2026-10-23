## Munch, the Muncher (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 61,
	"name": "Munch",
	"type": "Muncher",
	"rarity": "epic",
	"rarity_power": 1.153, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "fb8500",
	"vibe": "A cheerful glutton who treats every fight like a buffet.",
	"description": "Muncher. Every hit takes a bite: Munch heals {stack_heal}, grows +{stack_radius%}% and hits +{stack_add} harder, up to {stack_max} bites. The hit after it fills up swallows the foe for {swallow_secs}s and spits it into a wall ({swallow_slam} dmg), dropping {burp_keep} bites.",
	"stats": {"hp": 126.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "hit", "do": "stack"}, {"on": "hit", "do": "stack_swallow"}, {"on": "always", "do": "swallow_tick"}, {"on": "guard", "do": "stack_guard"}],
	"params": {
		"stack_max": 4.0,
		"stack_radius": 0.05,
		"stack_add": 1.0,
		"stack_heal": 4.0,
		"stack_armor": 0.0,
		"stack_full_armor": 0.0,
		"burp_radius": 0.0,
		"burp_damage": 10.0,
		"burp_keep": 2.0,
		"swallow_secs": 0.5, ## The hit after its bites fill swallows the foe this long...
		"swallow_slam": 10.0, ## ...then spits it out: the first wall it hits slams it for this.
	},
	"tiers": [
		{"text": "Bites heal 4, +1 dmg; full (4): swallow, spit", "now": "Bites heal {stack_heal}, +{stack_add} dmg; full ({stack_max}): swallow, spit"},
		{"text": "Bite heal 4 → 5, spit slam 10 → 13", "stack_heal": 5.0, "swallow_slam": 13.0},
		{"text": "+ Full of bites: -15% dmg taken", "now": "Bites heal {stack_heal}; full ({stack_max}): -{stack_full_armor%}% taken, swallow", "stack_full_armor": 0.15},
		{"text": "Max bites 4 → 5", "stack_max": 5.0},
		{"text": "+ Spit slam 13 → 18, burps {burp_damage} + knockback", "now": "Bites heal {stack_heal}; full: -{stack_full_armor%}% taken, swallow, burp {burp_damage}", "burp_radius": 150.0, "swallow_slam": 18.0},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "bigmouth"}, "front": ["napkin"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 0.95},
}
