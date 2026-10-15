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
	"description": "Cauldron. Every 5 seconds it lobs 3 potion blobs near the foe that splash into burning or slowing puddles.",
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
		{"text": "Every 5s lobs 3 burning (4/s) or slowing blobs"},
		{"text": "Burn puddles deal 5/s", "brew_dps": 5.0},
		{"text": "4 blobs", "brew_count": 4},
		{"text": "Brews every 4s", "fire_cooldown": 4.0},
		{"text": "Every third brew is one huge puddle", "brew_big_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "grin"}, "back": ["witchhat"], "front": ["pot"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
