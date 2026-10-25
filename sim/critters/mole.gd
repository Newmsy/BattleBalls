## Mole, the Mole (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 52,
	"name": "Mole",
	"type": "Mole",
	"rarity": "rare",
	"tier_power": [0.97, 1.01, 1.05, 1.04, 0.92], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "b08968",
	"vibe": "A busy little digger who pops up exactly where you didn't want it.",
	"description": "Mole. Every 6s it burrows for 1s (-70% dmg taken), tunnels toward the foe, then bursts up beneath it for {dig_damage} with a knockback.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "every", "secs": "dig_every", "do": "dig"}, {"on": "guard", "do": "phased"}, {"on": "always", "do": "surface"}],
	"params": {
		"dig_every": 6.0,
		"phase_secs": 1.0, ## Seconds underground.
		"phase_guard": 0.3, ## Damage taken underground.
		"dig_radius": 120.0, ## The shove as it surfaces.
		"dig_damage": 9.0,
		"dig_hunt": 2200.0, ## Underground it turns toward the foe this hard.
		"dig_rush": 0.0, ## T3: extra speed for 1s after surfacing.
		"dig_clods": 0, ## T5: dirt clods lobbed at the foe.
		"clod_damage": 4.0,
	},
	"tiers": [
		{"text": "Digs every 6s (-70% taken), tunnels to foe, bursts up for 9", "now": "Digs every {dig_every}s (-70% taken), tunnels to foe, bursts up for {dig_damage}"},
		{"text": "Burst {^dig_damage} → {dig_damage}", "dig_damage": 11.0},
		{"text": "+ Surfacing: +20% speed for 1s", "now": "Digs every {dig_every}s (-70% taken), bursts up for {dig_damage}, rushes", "dig_rush": 0.2},
		{"text": "Dig every 6 → 5s", "dig_every": 5.0},
		{"text": "+ The burst throws 3 dirt clods ({clod_damage} dmg)", "now": "Digs every {dig_every}s (-70% taken), bursts {dig_damage} + {dig_clods} clods, rushes", "dig_clods": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .11, "h": .12, "p": .07, "mouth": "none"}, "back": ["paws"], "front": ["helmet", "molesnout"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.1},
}
