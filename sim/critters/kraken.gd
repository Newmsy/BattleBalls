## Kraken, the Kraken (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 81,
	"name": "Kraken",
	"type": "Kraken",
	"rarity": "legendary",
	"rarity_power": 0.977, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "8e3bbd",
	"vibe": "A playful deep-sea giant who just wants to hug everything at once.",
	"description": "Kraken. Four long tentacles sweep in a wide circle around it ({tentacle_damage} dmg a touch), and every 6s they slam down, grabbing the foe for {grab_secs}s and leaving ink puddles that slow foes {ink_slow%}%.",
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "always", "do": "tentacles"}, {"on": "every", "secs": 6.0, "do": "ink_slam"}],
	"params": {
		"tentacle_count": 4,
		"tentacle_orbit": 76.0, ## Reach beyond its edge.
		"tentacle_size": 18.0,
		"tentacle_damage": 1.5,
		"tentacle_spin": 1.2, ## Radians a second.
		"tentacle_cooldown": 1.0,
		"ink_radius": 70.0,
		"ink_life": 3.0,
		"ink_slow": 0.25,
		"ink_dps": 1.0,
		"ink_shove": 0, ## T3: slams knock foes near a tip away.
		"hug_every": 0, ## T5: every this many slams is a hug.
		"hug_secs": 1.0,
		"hug_range": 400.0,
		"hug_accel": 900.0,
		"grab_secs": 1.0, ## Each slam grabs the nearest foe and drags it into the sweep this long...
		"grab_range": 450.0, ## ...when it is this close.
	},
	"tiers": [
		{"text": "4 tentacles sweep for 1.5; slam every 6s grabs the foe", "now": "{tentacle_count} tentacles sweep for {tentacle_damage}; slam every 6s grabs the foe"},
		{"text": "Tentacles {^tentacle_damage} → {tentacle_damage}", "tentacle_damage": 2.5},
		{"text": "+ Slams knock foes back", "now": "{tentacle_count} tentacles sweep {tentacle_damage}; every 6s a grab + knockback slam", "ink_shove": 1},
		{"text": "Tentacle reach +39%", "tentacle_orbit": 106.0},
		{"text": "+ Every 3rd slam is a giant hug", "now": "{tentacle_count} tentacles sweep {tentacle_damage}; grab slam every 6s, 3rd hugs", "hug_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "beak"}, "back": ["tentacles"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.75},
}
