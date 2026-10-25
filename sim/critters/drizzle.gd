## Drizzle, the Rain cloud (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 29,
	"name": "Drizzle",
	"type": "Rain cloud",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "7b8cde",
	"vibe": "A gloomy little raincloud that rains on everyone's parade.",
	"description": "Rain cloud. Every 5s it rains on the foe's spot ({rain_dps}/sec for 3s), hurting anything that stays there.",
	"stats": {"hp": 122.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "every", "secs": "rain_every", "do": "rain"}],
	"params": {
		"rain_every": 5.0, ## Seconds between showers.
		"rain_radius": 90.0,
		"rain_warn": 0.5, ## Seconds the dark circle shows before rain falls.
		"rain_life": 3.0,
		"rain_dps": 4.0,
		"rain_slow": 0.0, ## T3: sleet slows.
		"rain_storm_every": 0, ## T5: every Nth shower is a thunderstorm (0 = never).
		"rain_storm_radius": 60.0,
		"rain_storm_damage": 10.0,
	},
	"tiers": [
		{"text": "Rains on the foe every 5s: 4/sec", "card": "Rains on the foe's spot, hurting anything that stays under the cloud.", "now": "Rains on the foe every {rain_every}s: {rain_dps}/sec"},
		{"text": "Rain {^rain_dps} → {rain_dps}/sec", "rain_dps": 5.0},
		{"text": "+ Sleet: slow 20%", "card": "Rains sleet on the foe's spot, hurting and slowing anything under the cloud.", "now": "Rains on the foe every {rain_every}s: {rain_dps}/sec, slow {rain_slow%}%", "rain_slow": 0.2},
		{"text": "Rain every 5 → 4s", "rain_every": 4.0},
		{"text": "+ Every 3rd shower: thunder strike {rain_storm_damage}", "card": "Rains sleet on the foe's spot, hurting and slowing, with the odd thunder strike.", "now": "Rain every {rain_every}s: {rain_dps}/sec, slow {rain_slow%}% · every 3rd thunder", "rain_storm_every": 3, "ability": [{"on": "always", "do": "thunder"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "pout"}, "body": "cloud", "back": ["drops"]},
	"sound": {"ouch": "ouch_frost", "pitch": 1.1},
}
