## Static, the Spark (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 28,
	"name": "Static",
	"type": "Spark",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "b388ff",
	"vibe": "A jittery ball of static that can't stop zapping things.",
	"description": "Spark. Every wall bounce zaps everything near it for 5 and slows it 20% for 1s.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "wall", "do": "zap"}],
	"params": {
		"zap_radius": 150.0, ## Reach of a zap beyond Static's centre.
		"zap_damage": 5.0,
		"zap_slow": 0.2, ## Share of movement a zapped foe loses.
		"zap_slow_secs": 1.0,
		"zap_big_every": 0, ## T5: every Nth bounce is a big zap (0 = never).
		"zap_big_radius": 220.0,
		"zap_big_damage": 12.0,
	},
	"tiers": [
		{"text": "Wall bounces zap nearby foes: 5, slow 20%", "now": "Wall bounces zap nearby foes: {zap_damage}, slow {zap_slow%}%"},
		{"text": "Zap 5 → 6", "zap_damage": 6.0},
		{"text": "Slow 20 → 30%", "zap_slow": 0.3},
		{"text": "Zap size +27%", "zap_radius": 190.0},
		{"text": "+ Every 2nd bounce: big zap for 16", "now": "Bounces zap nearby foes: {zap_damage}, slow {zap_slow%}% · 2nd: big {zap_big_damage}", "zap_big_every": 2, "zap_big_damage": 16.0},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["zighair"]},
	"sound": {"ouch": "ouch_tech", "pitch": 1.35},
}
