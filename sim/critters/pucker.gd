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
	"description": "Sour grape. Every hit makes the foe sour (+15% dmg taken for 3.5s, up to 30%); at full sour the foe puckers up, stunned 0.5s, and sour juice splashes out for 5.",
	"stats": {"hp": 108.0, "radius": 64.0, "speed": 400.0, "contact_damage": 20.0},
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
		{"text": "Hits sour foe +15% dmg taken (max 30%) · full: stun 0.5s", "now": "Hits sour foe +{sour_amount%}% dmg taken (max {sour_max%}%) · full: stun {pucker_stun}s"},
		{"text": "Sour +15% → +18%", "sour_amount": 0.18},
		{"text": "Splash 5 → 8", "now": "Hits sour foe +{sour_amount%}% (max {sour_max%}%) · full: stun, splash {pucker_damage}", "pucker_damage": 8.0},
		{"text": "Sour lasts 3.5 → 4.5s", "sour_secs": 4.5},
		{"text": "Splash 8 → 12 + puddle (slow 25%)", "now": "Hits sour foe +{sour_amount%}% (max {sour_max%}%) · full: stun, splash {pucker_damage}, puddle", "sour_puddle": 60.0, "pucker_damage": 12.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "pout"}, "back": ["stemleaf"], "front": ["bloom"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.25},
}
