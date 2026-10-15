## Fin, the Shark (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 25,
	"name": "Fin",
	"type": "Shark",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "4f8fb8",
	"vibe": "A grinning shark pup who counts its bites out loud.",
	"description": "Shark. Every fourth hit is a big bite for extra damage.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "strike", "do": "chomp"}, {"on": "hit", "do": "chomp_heal"}],
	"params": {
		"chomp_every": 4.0,
		"chomp_mult": 2.5,
		"chomp_burn": 0.0,
		"chomp_heal": 0.0,
	},
	"tiers": [
		{"text": "Every 4th hit bites for x2.5"},
		{"text": "Big bite: x3", "chomp_mult": 3.0},
		{"text": "A big bite leaves the foe bleeding (2/s for 3s)", "chomp_burn": 2.0},
		{"text": "Bites on every 3rd hit", "chomp_every": 3.0},
		{"text": "A big bite heals Fin for half its damage", "chomp_heal": 0.5},
	],
	"chaos": {"closing_walls": {"chomp_mult": 0.75}, "glass_cannon": {"chomp_mult": 1.2}}, ## Closing Walls crowds foes into more bites; Glass Cannon fights end before many bites land
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "teeth"}, "back": ["dorsal"], "front": ["belly"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.95},
}
