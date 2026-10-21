## Swarm, the Beehive (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 65,
	"name": "Swarm",
	"type": "Beehive",
	"rarity": "epic",
	"role": "Zoner",
	"status": "live",
	"color": "bb8a2d",
	"vibe": "A busy beehive that is never, ever alone.",
	"description": "Beehive. 3 bees circle it and sting foes they touch (3), and every 8s one flies off at the foe while a new one hatches.",
	"stats": {"hp": 121.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "always", "do": "swarm"}, {"on": "every", "secs": "bee_every", "do": "bee_launch"}],
	"params": {
		"bee_count": 3,
		"bee_orbit": 30.0, ## Distance beyond its edge.
		"bee_size": 10.0,
		"bee_damage": 3.0,
		"bee_spin": 4.0, ## Radians a second.
		"bee_cooldown": 0.5,
		"bee_every": 8.0, ## One bee flies off at the foe this often.
		"bee_respawn": 2.0, ## Seconds for a launched bee to hatch again.
		"bee_speed": 560.0,
		"bee_turn": 5.0, ## Homing, radians a second.
		"bee_life": 3.0,
		"bee_launch_damage": 3.0,
		"bee_poison_dps": 0.0, ## T3: launched bees poison for 2s.
	},
	"tiers": [
		{"text": "3 bees sting 3; one launches every 8s", "now": "{bee_count} bees sting {bee_damage}; one launches every {bee_every}s"},
		{"text": "Bee sting 3 → 4", "bee_damage": 4.0},
		{"text": "+ Launched bees poison 2/s", "now": "{bee_count} bees sting {bee_damage}; a poison bee launches every {bee_every}s", "bee_poison_dps": 2.0},
		{"text": "Bees 3 → 4", "bee_count": 4},
		{"text": "+ Below 50% HP the whole swarm launches", "now": "{bee_count} bees sting {bee_damage}; launch every {bee_every}s, all at 50% HP", "ability": [{"on": "hp_below", "hp": 0.5, "do": "swarm_all"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": ["bees"], "front": ["hive", "door"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.3},
}
