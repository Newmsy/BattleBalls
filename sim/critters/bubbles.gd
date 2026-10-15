## Bubbles, the Bubble (Common Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 21,
	"name": "Bubbles",
	"type": "Bubble",
	"rarity": "common",
	"role": "Disruptor",
	"status": "live",
	"color": "6fe3e8",
	"vibe": "A giggly bubble-blower that thinks every fight is bath time.",
	"description": "Bubble. Every 6 seconds it blows a bubble shield that pops on the first hit.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "every", "secs": "bubble_every", "do": "bubble"}, {"on": "guard", "do": "bubble_guard"}],
	"params": {
		"bubble_every": 6.0,
		"bubble_size": 10.0,
		"bubble_secs": 4.0,
		"bubble_min": 4.0,
		"bubble_knock": 0.0,
		"bubble_bolts": 0.0,
		"bolt_damage": 3.0,
	},
	"tiers": [
		{"text": "Every 6s a bubble shield soaks up to 10 of the next hit"},
		{"text": "Absorbs up to 12", "bubble_size": 12.0},
		{"text": "The pop pushes the attacker away", "bubble_knock": 1.0},
		{"text": "A bubble every 5s", "bubble_every": 5.0},
		{"text": "The pop sprays 4 little bubbles (3 damage each)", "bubble_bolts": 4.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "o"}, "body": "ghost", "tint": true, "front": ["sheen"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.35},
}
