## Pucker, the Sour grape (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 39,
	"name": "Pucker",
	"type": "Sour grape",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "live",
	"color": "7b2cbf",
	"vibe": "A sour grape whose face says it all.",
	"description": "Sour grape. Every hit makes the foe sour (it takes more damage); at full sour the foe puckers up, frozen for a moment, and sour juice splashes out.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 21.0},
	"ability": [{"on": "hit", "do": "sour"}],
	"params": {
		"sour_amount": 0.15, ## Extra damage share the foe takes.
		"sour_secs": 3.5,
		"sour_max": 0.3, ## Repeat hits stack up to this; at full sour the foe puckers.
		"pucker_stun": 0.5,
		"pucker_damage": 5.0,
		"sour_puddle": 0.0, ## T5: puddle radius (2s).
		"sour_puddle_slow": 0.25,
	},
	"tiers": [
		{"text": "Hits stack sour (+15% damage taken for 3.5s, max 30%); full sour puckers the foe (stunned 0.5s, splash 5)"},
		{"text": "Sour +18%", "sour_amount": 0.18},
		{"text": "Pucker splash deals 8", "pucker_damage": 8.0},
		{"text": "Sour lasts 4.5s", "sour_secs": 4.5},
		{"text": "The splash deals 12 and leaves a sour puddle that slows 25% for 2s", "sour_puddle": 60.0, "pucker_damage": 12.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "pout"}, "back": ["stemleaf"], "front": ["bloom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.25},
}
