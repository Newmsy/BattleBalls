## Wrecker, the Wrecking ball (Epic Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 62,
	"name": "Wrecker",
	"type": "Wrecking ball",
	"rarity": "epic",
	"role": "Bruiser",
	"status": "live",
	"color": "495057",
	"vibe": "A demolition bot who thinks everything looks better knocked down.",
	"description": "Wrecking ball. A heavy wrecking ball swings around it on a chain, smashing foes into walls.",
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
		{"text": "A wrecking ball swings for 9; wall slams add 6"},
		{"text": "The ball hits for 11", "wreck_damage": 11.0},
		{"text": "The chain hurts too (4/s)", "wreck_chain_dps": 4.0},
		{"text": "The ball spins faster", "wreck_spin": 2.6},
		{"text": "Every 8s a wide wind-up lap for double damage", "wreck_windup_every": 8.0},
	],
	"art": {"eyes": {"visor": true, "mouth": "flat"}, "back": ["chainball"], "front": ["hazard", "hardhat"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 0.75},
}
