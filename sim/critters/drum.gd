## Drum, the Drum (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 37,
	"name": "Drum",
	"type": "Drum",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "live",
	"color": "e63946",
	"vibe": "A party drum that answers every bump with a BOOM.",
	"description": "Drum. Every hit it lands sends out a shockwave ring that shoves foes back.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.25},
	"ability": [{"on": "hit", "do": "boom"}],
	"params": {
		"boom_radius": 120.0, ## Shockwave reach beyond Drum's centre; it knocks foes straight away.
		"boom_damage": 3.0,
		"boom_slam": 0.0, ## T3: extra damage when a knocked foe hits a wall within 0.5s.
		"boom_double_every": 0, ## T5: every Nth hit booms twice (0 = never).
	},
	"tiers": [
		{"text": "Every hit booms a shockwave for 3"},
		{"text": "Shockwave deals 4", "boom_damage": 4.0},
		{"text": "Knocked into a wall within 0.5s: +5", "boom_slam": 5.0},
		{"text": "Shockwave radius 120 -> 150", "boom_radius": 150.0},
		{"text": "Every third hit is a double boom", "boom_double_every": 3, "ability": [{"on": "always", "do": "boom_echo"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["sticks"], "front": ["drumhead", "rope"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.0},
}
