## Shelly, the Turtle (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 24,
	"name": "Shelly",
	"type": "Turtle",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "52b788",
	"vibe": "A wise old sea turtle that knows exactly when to hide.",
	"description": "Turtle. Below 30% HP it pulls into its shell: much tougher, but slower.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hp_below", "hp": 0.3, "do": "grow"}, {"on": "guard", "do": "grow_guard"}],
	"params": {
		"grow_radius": 0.0,
		"grow_speed": -0.2,
		"grow_add": 0.0,
		"grow_secs": 0.0,
		"grow_stack": 0.0,
		"grow_heal": 0.0,
		"grow_pulse_radius": 150.0,
		"grow_pulse_damage": 0.0,
		"grow_bolts": 0.0,
		"bolt_damage": 3.0,
		"grow_armor": 0.4,
	},
	"tiers": [
		{"text": "Below 30% HP: shoves foes off, then 40% armour, -20% speed"},
		{"text": "45% armour", "grow_armor": 0.45},
		{"text": "Tucking in also heals 8", "grow_heal": 8.0},
		{"text": "50% armour", "grow_armor": 0.5},
		{"text": "The shove also deals 10", "grow_pulse_damage": 10.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["shellhex"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
