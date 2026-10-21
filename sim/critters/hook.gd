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
	"description": "Grapple. Every wall bounce it yanks the foe a little toward itself.",
	"stats": {"hp": 132.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "wall", "do": "yank"}, {"on": "hit", "do": "yank_bonus"}],
	"params": {
		"yank_impulse": 220.0, ## Velocity added toward Hook (a ball moves at 400).
		"yank_big_every": 0, ## T5: every this-many bounces is a big reel-in.
		"yank_big_slow": 0.3,
		"yank_bonus": 5.0, ## Extra damage when a yanked foe hits it within 1s.
	},
	"tiers": [
		{"text": "Each wall bounce yanks the foe closer; hitting it within 1s deals +5"},
		{"text": "Yanks the foe further in", "yank_impulse": 260.0},
		{"text": "Yanked foes take +8", "yank_bonus": 8.0},
		{"text": "Yanks the foe even further in", "yank_impulse": 300.0},
		{"text": "Every 2nd bounce yanks twice as far and slows the foe 30% for 1s", "yank_big_every": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smirk"}, "back": ["hook"], "front": ["bandana"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.95},
}
