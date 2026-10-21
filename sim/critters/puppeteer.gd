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
	"description": "Puppeteer. When it hits, at most every 6s, it ties a string to the foe, drags it along for 0.7s, then hurls it into the nearest wall for a 8 slam.",
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
		{"text": "Every 6s a hit strings foe, hurls it: slam 8", "now": "Every {string_cooldown}s a hit strings foe, hurls it: slam {string_slam}"},
		{"text": "String every 6 → 4s", "string_cooldown": 4.0},
		{"text": "Slam 8 → 11 + stun 0.4s", "now": "Every {string_cooldown}s a hit strings foe, hurls: slam {string_slam} + stun", "string_slam": 11.0, "string_slam_stun": 0.4},
		{"text": "String 0.7 → 1s", "string_secs": 1.0},
		{"text": "+ Throws harder, then bows for a 10 shield", "now": "Every {string_cooldown}s a hit strings foe, hurls: slam {string_slam} + stun, bow", "string_fling": 1.1, "ability": [{"on": "always", "do": "string_snap"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["controlbar", "tophat"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
