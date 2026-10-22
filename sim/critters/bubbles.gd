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
	"description": "Bubble. Every 5s it blows a bubble shield that soaks up to 10 of the next hit, then pops, knocking the attacker back and spraying 3 little bubbles.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "every", "secs": "bubble_every", "do": "bubble"}, {"on": "guard", "do": "bubble_guard"}],
	"params": {
		"bubble_every": 5.0,
		"bubble_size": 10.0,
		"bubble_secs": 4.0,
		"bubble_min": 4.0,
		"bubble_knock": 1.0,
		"bubble_bolts": 3.0,
		"bolt_damage": 3.0,
		"bubble_splash": 0.0, ## T5: the pop bursts as a wave.
	},
	"tiers": [
		{"text": "Bubble every 5s soaks 10; pop knockback + 3 bubbles", "now": "Bubble every {bubble_every}s soaks {bubble_size}; pop knockback + {bubble_bolts} bubbles"},
		{"text": "Soaks 10 → 12", "bubble_size": 12.0},
		{"text": "Pop sprays 3 → 5 bubbles", "bubble_bolts": 5.0},
		{"text": "Bubble every 5 → 4s", "bubble_every": 4.0},
		{"text": "+ The pop bursts as a wave (8)", "now": "Bubble every {bubble_every}s soaks {bubble_size}; pop knockback, {bubble_bolts} bubbles + wave {bubble_splash}", "bubble_splash": 8.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "o"}, "body": "ghost", "tint": true, "front": ["sheen"]},
	"sound": {"ouch": "ouch_sea", "pitch": 1.35},
}
