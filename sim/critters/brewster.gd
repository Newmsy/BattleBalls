## Brewster, the Cauldron (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 68,
	"name": "Brewster",
	"type": "Cauldron",
	"rarity": "epic",
	"role": "Zoner",
	"status": "live",
	"color": "1b4332",
	"vibe": "A bubbly little cauldron who's always cooking up trouble.",
	"description": "Cauldron. Every 5s it lobs 3 potion blobs near the foe that splash into burning (4/s) or slowing (35%) puddles.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "every", "secs": "fire_cooldown", "do": "brew"}],
	"params": {
		"fire_cooldown": 5.0, ## Seconds between brews.
		"brew_count": 3,
		"brew_spread": 200.0, ## Blobs land within this of the foe.
		"brew_radius": 70.0,
		"brew_life": 3.0,
		"brew_dps": 4.0,
		"brew_slow": 0.35,
		"brew_flight": 0.8,
		"brew_big_every": 0, ## Every Nth brew is one huge puddle, when above 0.
		"brew_big_radius": 160.0,
	},
	"tiers": [
		{"text": "Every 5s lobs 3 blobs: burn 4/s or slow 35%", "now": "Every {fire_cooldown}s lobs {brew_count} blobs: burn {brew_dps}/s or slow {brew_slow%}%"},
		{"text": "Burn 4 → 5/s", "brew_dps": 5.0},
		{"text": "Blobs 3 → 4", "brew_count": 4},
		{"text": "Brew every 5 → 4s", "fire_cooldown": 4.0},
		{"text": "+ Every 3rd brew is one huge puddle", "now": "Every {fire_cooldown}s {brew_count} blobs: burn {brew_dps}/s or slow {brew_slow%}% · 3rd huge", "brew_big_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["witchhat"], "front": ["pot"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
