## Gumdrop, the Gumdrop (Common Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 22,
	"name": "Gumdrop",
	"type": "Gumdrop",
	"rarity": "common",
	"role": "Disruptor",
	"status": "live",
	"color": "9b5de5",
	"vibe": "A clingy candy who just wants to stick around.",
	"description": "Gumdrop. Every hit gums up the foe, slowing it, and every few seconds a gum string sticks the foe to Gumdrop and drags it along.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 21.0},
	"ability": [{"on": "hit", "do": "gum"}],
	"params": {
		"gum_slow": 0.25, ## Share of movement the foe loses.
		"gum_secs": 1.5,
		"gum_burn": 0.0, ## T3: burn per second, 2s.
		"gum_stacks": 1, ## T5: repeat hits stack this many times.
		"gum_cap": 0.45, ## Most a stacked slow can reach.
		"gum_string": 1.0, ## Seconds a gum string holds the foe to it...
		"gum_string_cooldown": 4.0, ## ...at most this often.
	},
	"tiers": [
		{"text": "Hits slow the foe 25%; every 4s a hit sticks it on a gum string for 1s"},
		{"text": "Slow 30%", "gum_slow": 0.3},
		{"text": "The goo also stings (burn 1/s for 2s)", "gum_burn": 1.0},
		{"text": "Slow lasts 2s", "gum_secs": 2.0},
		{"text": "Slows stack twice, up to 45%", "gum_stacks": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["sugar"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
