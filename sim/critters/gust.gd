## Gust, the Breeze (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 55,
	"name": "Gust",
	"type": "Breeze",
	"rarity": "rare",
	"rarity_power": 1.104, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "c7f9cc",
	"vibe": "A puffed-cheek little breeze who just wants some personal space.",
	"description": "Breeze. Its wind pushes foes away, a big huff every 5s blasts them across the arena, and a foe blown into a wall takes 7.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "always", "do": "gale"}, {"on": "every", "secs": "huff_every", "do": "huff"}],
	"params": {
		"wind_range": 220.0, ## Wind reach from Gust's centre; it fades to nothing at the edge.
		"wind_accel": 100.0, ## Push next to Gust (units/s^2); it bends paths, never slows.
		"wind_huff": 1600.0, ## Push during a huff.
		"huff_every": 5.0,
		"gust_slam": 7.0, ## A foe blown into a wall takes this...
		"gust_slam_gap": 1.5, ## ...at most this often.
		"huff_secs": 0.4,
		"huff_damage": 0.0, ## T5: ice crystals in the huff.
		"huff_slow": 0.0, ## T5: chill for 1.5s.
	},
	"tiers": [
		{"text": "Wind pushes foes; huff every 5s; wall slams 7", "now": "Wind pushes foes; huff every {huff_every}s; wall slams {gust_slam}"},
		{"text": "Wind push +20%", "wind_accel": 120.0},
		{"text": "Wall slam 7 → 9", "gust_slam": 9.0},
		{"text": "Wind reach +18%, huff every 5 → 4s", "wind_range": 260.0, "huff_every": 4.0},
		{"text": "+ Icy huff: 6 dmg, slow 15%", "now": "Wind pushes foes; icy huff every {huff_every}s ({huff_damage}); wall slams {gust_slam}", "huff_damage": 6.0, "huff_slow": 0.15},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "pout"}, "body": "cloud", "back": ["windcurls"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
