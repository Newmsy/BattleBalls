## Hook, the Grapple (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 56,
	"name": "Hook",
	"type": "Grapple",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "live",
	"color": "9a031e",
	"vibe": "A swashbuckling grapple that loves to reel in a catch.",
	"description": "Grapple. Every wall bounce it yanks the foe toward itself, and a yanked foe that meets Hook within 1s takes +5.",
	"stats": {"hp": 132.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "wall", "do": "yank"}, {"on": "hit", "do": "yank_bonus"}],
	"params": {
		"yank_impulse": 220.0, ## Velocity added toward Hook (a ball moves at 400).
		"yank_big_every": 0, ## T5: every this-many bounces is a big reel-in.
		"yank_big_slow": 0.3,
		"yank_bonus": 5.0, ## Extra damage when a yanked foe hits it within 1s.
	},
	"tiers": [
		{"text": "Bounces yank foe in · hit within 1s: +5", "now": "Bounces yank foe in · hit within 1s: +{yank_bonus}"},
		{"text": "Yank +18%", "yank_impulse": 260.0},
		{"text": "Yanked hit +5 → +8", "yank_bonus": 8.0},
		{"text": "Yank +15%", "yank_impulse": 300.0},
		{"text": "+ Every 2nd bounce: big reel-in, slow 30%", "now": "Bounces yank foe in (every 2nd: big, slows) · hit in 1s: +{yank_bonus}", "yank_big_every": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smirk"}, "back": ["hook"], "front": ["bandana"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.95},
}
