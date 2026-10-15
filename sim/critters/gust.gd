## Gust, the Breeze (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 55,
	"name": "Gust",
	"type": "Breeze",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "live",
	"color": "c7f9cc",
	"vibe": "A puffed-cheek little breeze who just wants some personal space.",
	"description": "Breeze. Its wind always pushes foes gently away from it.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "always", "do": "wind"}],
	"params": {
		"wind_range": 220.0, ## Wind reach from Gust's centre; it fades to nothing at the edge.
		"wind_accel": 100.0, ## Push next to Gust (units/s^2); it bends paths, never slows.
		"wind_huff": 400.0, ## T3: push during a huff.
		"huff_secs": 0.3,
		"huff_damage": 0.0, ## T5: ice crystals in the huff.
		"huff_slow": 0.0, ## T5: chill for 1.5s.
	},
	"tiers": [
		{"text": "Its wind gently pushes foes away"},
		{"text": "Stronger wind (100 -> 120)", "wind_accel": 120.0},
		{"text": "Every 5s a strong huff (400 for 0.3s)", "ability": [{"on": "every", "secs": 5.0, "do": "huff"}]},
		{"text": "The wind reaches further (220 -> 260)", "wind_range": 260.0},
		{"text": "The huff carries ice crystals: 6 damage and a 15% chill", "huff_damage": 6.0, "huff_slow": 0.15},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "pout"}, "body": "cloud", "back": ["windcurls"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
