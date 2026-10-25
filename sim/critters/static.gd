## Static, the Spark (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 28,
	"name": "Static",
	"type": "Spark",
	"rarity": "uncommon",
	"tier_power": [0.83, 0.83, 0.82, 0.80, 0.79], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Zoner",
	"status": "live",
	"color": "b388ff",
	"vibe": "A jittery ball of static that can't stop zapping things.",
	"description": "Spark. Every wall bounce zaps everything near it for {zap_damage} and slows it {zap_slow%}% for {zap_slow_secs}s. Each bounce also stores a charge (up to {charge_max}); its next hit arcs them all into the foe ({charge_damage} dmg each) and stuns it {charge_stun}s.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "wall", "do": "zap"}, {"on": "wall", "do": "static_charge"}, {"on": "hit", "do": "static_arc"}],
	"params": {
		"zap_radius": 150.0, ## Reach of a zap beyond Static's centre.
		"zap_damage": 5.0,
		"zap_slow": 0.2, ## Share of movement a zapped foe loses.
		"zap_slow_secs": 1.0,
		"zap_big_every": 0, ## T5: every Nth bounce is a big zap (0 = never).
		"zap_big_radius": 220.0,
		"zap_big_damage": 12.0,
		"charge_max": 2, ## Bounces store charges...
		"charge_damage": 3.0, ## ...its next hit arcs this much per charge...
		"charge_stun": 0.15, ## ...and stuns.
	},
	"tiers": [
		{"text": "Bounces zap: 5, slow 20%; stored charges +3 each on a hit", "card": "Wall bounces zap and slow foes nearby and store charge; its next hit arcs it all into the foe.", "now": "Bounces zap: {zap_damage}, slow {zap_slow%}%; stored charges +{charge_damage} each on a hit"},
		{"text": "Zap {^zap_damage} → {zap_damage}", "zap_damage": 6.0},
		{"text": "Slow 20 → 30%", "zap_slow": 0.3},
		{"text": "Zap size +{+zap_radius}%", "zap_radius": 190.0},
		{"text": "+ Every 2nd bounce: big zap for {zap_big_damage}", "card": "Wall bounces zap and slow foes nearby, some with a big zap, and store charge for its next hit.", "now": "Bounces zap nearby foes: {zap_damage}, slow {zap_slow%}% · 2nd: big {zap_big_damage}", "zap_big_every": 2, "zap_big_damage": 16.0},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "o"}, "back": ["zighair"], "front": ["sparks"]},
	"sound": {"ouch": "ouch_tech", "pitch": 1.35},
}
