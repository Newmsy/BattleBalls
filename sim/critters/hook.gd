## Hook, the Grapple (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 56,
	"name": "Hook",
	"type": "Grapple",
	"rarity": "rare",
	"rarity_power": 1.067, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "9a031e",
	"vibe": "A swashbuckling grapple that loves to reel in a catch.",
	"description": "Grapple. Every {harpoon_every}s it harpoons the foe so they rush at each other, every wall bounce yanks the foe toward it, and a reeled-in foe that meets Hook right after takes +{yank_bonus}.",
	"stats": {"hp": 132.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "wall", "do": "yank"}, {"on": "hit", "do": "yank_bonus"}, {"on": "every", "secs": "harpoon_every", "do": "harpoon"}],
	"params": {
		"yank_impulse": 220.0, ## Velocity added toward Hook (a ball moves at 400).
		"yank_big_every": 0, ## T5: every this-many bounces is a big reel-in.
		"yank_big_slow": 0.3,
		"yank_bonus": 7.0, ## Extra damage when a yanked or reeled foe hits it within 1s.
		"harpoon_every": 4.0, ## Fires a grapple and reels the foe in...
		"harpoon_range": 600.0, ## ...when it is this close.
	},
	"tiers": [
		{"text": "Every 4s harpoons foe in; bounces yank; reeled hit +7", "now": "Every {harpoon_every}s harpoons foe in; bounces yank; reeled hit +{yank_bonus}"},
		{"text": "Yank +18%", "yank_impulse": 260.0},
		{"text": "Reeled hit +7 → +10", "yank_bonus": 10.0},
		{"text": "Yank +15%", "yank_impulse": 300.0},
		{"text": "+ Every 2nd bounce: big reel-in, slow 30%", "now": "Harpoon every {harpoon_every}s; bounces yank (2nd: big) · reeled +{yank_bonus}", "yank_big_every": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "wink": true, "mouth": "smirk"}, "back": ["hook"], "front": ["bandana"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.95},
}
