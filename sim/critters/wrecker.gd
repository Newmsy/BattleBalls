## Wrecker, the Wrecking ball (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 62,
	"name": "Wrecker",
	"type": "Wrecking ball",
	"rarity": "epic",
	"tier_power": [0.94, 0.97, 1.00, 0.96, 0.92], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "495057",
	"vibe": "A demolition bot who thinks everything looks better knocked down.",
	"description": "Wrecking ball. A heavy wrecking ball swings round it on a chain ({wreck_damage} a hit), and a struck foe that hits a wall within 0.5s takes {wreck_slam_damage}.",
	"stats": {"hp": 120.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "always", "do": "wrecker"}],
	"params": {
		"wreck_orbit": 66.0, ## Chain length beyond its edge.
		"wreck_size": 24.0,
		"wreck_damage": 9.0,
		"wreck_spin": 2.0, ## Radians a second.
		"wreck_cooldown": 0.8,
		"wreck_slam_damage": 6.0, ## A struck foe that hits a wall within 0.5s.
		"wreck_chain_dps": 0.0, ## T3: the chain is a beam.
		"wreck_windup_every": 0.0, ## T5: a big wind-up lap this often.
		"wreck_windup_reach": 260.0, ## From its centre, during the wind-up lap.
	},
	"tiers": [
		{"text": "A wrecking ball swings round it for 9", "card": "A heavy wrecking ball swings round it on a chain. Foes it knocks into a wall take a slam.", "now": "A wrecking ball swings round it for {wreck_damage}"},
		{"text": "Ball {^wreck_damage} → {wreck_damage}", "wreck_damage": 11.0},
		{"text": "+ The chain is a beam ({wreck_chain_dps}/sec)", "card": "A wrecking ball swings round it on a chain of light that hurts. Foes knocked into a wall take a slam.", "now": "A wrecking ball swings for {wreck_damage}; chain beam {wreck_chain_dps}/sec", "wreck_chain_dps": 4.0},
		{"text": "Spin +30%", "wreck_spin": 2.6},
		{"text": "+ Every 8s a big wind-up lap", "card": "A wrecking ball swings round on a chain of light, with a big wide lap now and then. Wall slams hurt.", "now": "Ball swings for {wreck_damage}, chain {wreck_chain_dps}/sec; wide lap every {wreck_windup_every}s", "wreck_windup_every": 8.0},
	],
	"art": {"eyes": {"visor": true, "mouth": "flat"}, "back": ["chainball"], "front": ["hazard", "hardhat"]},
	"sound": {"ouch": "ouch_tech", "pitch": 0.75},
}
