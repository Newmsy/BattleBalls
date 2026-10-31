## Choo, the Toy train (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 104,
	"name": "Choo",
	"type": "Toy train",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "live",
	"color": "e8433f",
	"vibe": "Right on schedule, and the schedule says you.",
	"description": "Toy train. Every {train_every}s it lays a loop of track through the foe and a {train_cars}-car train runs it; a foe the train hits takes {train_damage} dmg and is carried along the rails for {carry_secs}s.",
	"tier_power": [0.89, 0.93, 0.96, 0.98, 1.00], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 120.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.0},
	"ability": [{"on": "every", "secs": "train_every", "do": "lay_track"}, {"on": "always", "do": "train_tick"}],
	"params": {
		"train_every": 7.0,
		"loop_radius": 170.0,
		"train_speed": 520.0,
		"train_laps": 1,
		"train_cars": 3,
		"train_damage": 9.0,
		"carry_secs": 0.8,
		"whistle_stun": 0.0, ## T5: foes near the loop are stunned as it sets off.
	},
	"tiers": [
		{"text": "Every 7s a train loops through the foe (9)", "card": "Every few seconds it lays a loop of track through the foe; a toy train runs it and carries off foes.", "now": "Every {train_every}s a train loops through the foe ({train_damage})"},
		{"text": "Train {^train_damage} → {train_damage}, 4 cars", "train_cars": 4},
		{"text": "Wider loop: +{+loop_radius}%", "loop_radius": 195.0},
		{"text": "Train every {^train_every} → {train_every}s", "train_every": 6.0},
		{"text": "+ Runs twice; whistle stuns 0.3s", "special": "Express", "card": "Every few seconds a toy train runs its loop of track twice; its whistle stuns foes near the loop.", "now": "Every {train_every}s a train loops twice ({train_damage}); whistle stun", "train_laps": 2, "whistle_stun": 0.3},
	],
	"art": {"badge_top": 1.6, "eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["chimney", "wheels"], "front": ["cowcatcher"]},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.0},
}
