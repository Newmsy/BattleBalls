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
	"description": "Puppeteer. When it hits, it ties a string to the foe, drags it along, then hurls it into the nearest wall for a slam.",
	"stats": {"hp": 119.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.5},
	"ability": [{"on": "hit", "do": "string"}, {"on": "always", "do": "string_fling"}],
	"params": {
		"string_cooldown": 6.0, ## Seconds between strings.
		"string_length": 120.0, ## Most slack between the two balls.
		"string_secs": 0.7,
		"string_fling": 0.8, ## Then it hurls the foe away for this long...
		"string_slam": 8.0, ## ...and the first wall it hits slams it for this.
		"string_slam_stun": 0.0, ## T3: the slam stuns this long.
		"string_stun": 0.3, ## T5: dizzy seconds when the string snaps.
		"string_shield": 10.0, ## T5: shield when it bows.
	},
	"tiers": [
		{"text": "Strings the foe on a hit (every 6s), then hurls it into a wall: slam 8"},
		{"text": "A string every 4s", "string_cooldown": 4.0},
		{"text": "The slam deals 11 and stuns 0.4s", "string_slam": 11.0, "string_slam_stun": 0.4},
		{"text": "Strings last 1s", "string_secs": 1.0},
		{"text": "Throws harder (1.1s) and Puppeteer bows (+10 shield)", "string_fling": 1.1, "ability": [{"on": "always", "do": "string_snap"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["controlbar", "tophat"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
