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
	"stats": {"hp": 135.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "wall", "do": "yank"}, {"on": "hit", "do": "yank_bonus"}],
	"params": {
		"yank_impulse": 220.0, ## Velocity added toward Hook (a ball moves at 400).
		"yank_big_every": 0, ## T5: every this-many bounces is a big reel-in.
		"yank_big_slow": 0.3,
		"yank_bonus": 5.0, ## Extra damage when a yanked foe hits it within 1s.
	},
	"tiers": [
		{"text": "Every wall bounce yanks the foe in (220); a yanked foe that meets Hook within 1s takes +5"},
		{"text": "Yanks harder (260)", "yank_impulse": 260.0},
		{"text": "Yanked foes take +8", "yank_bonus": 8.0},
		{"text": "Yanks harder (300)", "yank_impulse": 300.0},
		{"text": "Every 2nd bounce is a big reel-in that slows", "yank_big_every": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smirk"}, "back": ["hook"], "front": ["bandana"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.95},
}
