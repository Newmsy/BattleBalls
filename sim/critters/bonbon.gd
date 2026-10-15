## Bonbon, the Wrapped candy (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 89,
	"name": "Bonbon",
	"type": "Wrapped candy",
	"rarity": "legendary",
	"role": "Disruptor",
	"status": "live",
	"color": "f15bb5",
	"vibe": "A sugary prankster who wraps everyone up like a present.",
	"description": "Wrapped candy. Every 6 seconds it gift-wraps the foe, holding it still for half a second, and the foe takes 20% more damage for 2 seconds after the ribbon pops.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.5},
	"ability": [{"on": "every", "secs": "wrap_every", "do": "wrap"}, {"on": "always", "do": "wrap_tick"}],
	"params": {
		"wrap_every": 6.0, ## Seconds between wraps.
		"wrap_hold": 0.5, ## Stun.
		"wrap_vuln": 0.2, ## Extra damage share after the pop...
		"wrap_vuln_secs": 2.0, ## ...for this long.
		"wrap_confetti": 0.0, ## T3: pop damage near the foe.
		"wrap_pull_every": 0, ## T5: every Nth wrap pulls the foe in.
		"wrap_pull": 1500.0,
	},
	"tiers": [
		{"text": "Every 6s it wraps the foe: held 0.5s, then +20% damage taken for 2s"},
		{"text": "+25% after the pop", "wrap_vuln": 0.25},
		{"text": "The pop scatters confetti candies for 6 damage", "wrap_confetti": 6.0},
		{"text": "Wraps every 5s", "wrap_every": 5.0},
		{"text": "Every third wrap is a surprise box: the pop pulls the foe toward Bonbon", "wrap_pull_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["wrapper", "bow"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
