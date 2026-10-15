## Puppeteer, the Puppeteer (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 73,
	"name": "Puppeteer",
	"type": "Puppeteer",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "live",
	"color": "6d2e46",
	"vibe": "A theatrical little puppet-master who wants you in its show.",
	"description": "Puppeteer. When it hits, it ties a string to the foe and drags it along its path for a moment.",
	"stats": {"hp": 134.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hit", "do": "string"}],
	"params": {
		"string_cooldown": 5.0, ## Seconds between strings.
		"string_length": 120.0, ## Most slack between the two balls.
		"string_secs": 0.7,
		"string_slam": 0.0, ## T3: damage when the dragged foe hits a wall.
		"string_stun": 0.3, ## T5: dizzy seconds when the string snaps.
		"string_shield": 10.0, ## T5: shield when it bows.
	},
	"tiers": [
		{"text": "Strings the foe for 0.7s on a hit (every 5s)"},
		{"text": "A string every 4s", "string_cooldown": 4.0},
		{"text": "A dragged foe that hits a wall takes +6", "string_slam": 6.0},
		{"text": "Strings last 1s", "string_secs": 1.0},
		{"text": "The snap leaves the foe dizzy and Puppeteer bows (+10 shield)", "ability": [{"on": "always", "do": "string_snap"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["controlbar", "tophat"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
