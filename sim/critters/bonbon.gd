## Bonbon, the Wrapped candy (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 89,
	"name": "Bonbon",
	"type": "Wrapped candy",
	"rarity": "legendary",
	"rarity_power": 1.104, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "f15bb5",
	"vibe": "A sugary prankster who wraps everyone up like a present.",
	"description": "Wrapped candy. Every 6s it gift-wraps the foe, holding it still 0.5s, and the foe takes +20% dmg for 2s after the ribbon pops. From T2 the ribbon stays on the floor as a snare that wraps the next foe to roll in.",
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
		"snare_max": 0, ## T2: the ribbon stays on the floor as this many snares.
	},
	"tiers": [
		{"text": "Wraps foe every 6s: stun 0.5s, then +20% dmg taken", "now": "Wraps foe every {wrap_every}s: stun {wrap_hold}s, then +{wrap_vuln%}% dmg taken"},
		{"text": "Dmg taken +20% → +25%; ribbon left as a snare", "now": "Wraps foe every {wrap_every}s: stun {wrap_hold}s, +{wrap_vuln%}% dmg taken, snare", "wrap_vuln": 0.25, "snare_max": 1},
		{"text": "+ The pop scatters confetti for 6", "now": "Wraps every {wrap_every}s: stun {wrap_hold}s, confetti {wrap_confetti}, +{wrap_vuln%}% taken, snare", "wrap_confetti": 6.0},
		{"text": "Wrap every 6 → 5s; snares 1 → 2", "wrap_every": 5.0, "snare_max": 2},
		{"text": "+ Every 3rd wrap pulls the foe to Bonbon", "wrap_pull_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "sparkle": true, "mouth": "grin"}, "back": ["wrapper", "bow"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.3},
}
