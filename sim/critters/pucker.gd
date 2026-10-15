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
	"description": "Sour grape. Every hit makes the foe sour, so it takes 15% more damage for 2 seconds.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 21.0},
	"ability": [{"on": "hit", "do": "sour"}],
	"params": {
		"sour_amount": 0.15, ## Extra damage share the foe takes.
		"sour_secs": 2.0,
		"sour_max": 0.0, ## T3: repeat hits stack up to this.
		"sour_puddle": 0.0, ## T5: puddle radius (2s).
		"sour_puddle_slow": 0.25,
	},
	"tiers": [
		{"text": "Hits make the foe sour: it takes 15% more damage for 2s"},
		{"text": "Sour +18%", "sour_amount": 0.18},
		{"text": "Repeat hits stack it up to +25%", "sour_max": 0.25},
		{"text": "Sour lasts 2.5s", "sour_secs": 2.5},
		{"text": "The splash leaves a sour puddle that slows 25% for 2s", "sour_puddle": 60.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "pout"}, "back": ["stemleaf"], "front": ["bloom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.25},
}
