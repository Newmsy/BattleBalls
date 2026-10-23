## Fin, the Shark (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 25,
	"name": "Fin",
	"type": "Shark",
	"rarity": "uncommon",
	"rarity_power": 0.881, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "4f8fb8",
	"vibe": "A grinning shark pup who counts its bites out loud.",
	"description": "Shark. Every 4th hit is a big bite for x{chomp_mult} dmg.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "strike", "do": "chomp"}, {"on": "hit", "do": "chomp_heal"}],
	"params": {
		"chomp_every": 4.0,
		"chomp_mult": 2.5,
		"chomp_burn": 0.0,
		"chomp_heal": 0.0,
	},
	"tiers": [
		{"text": "Every 4th hit bites for x2.5", "now": "Every 4th hit bites for x{chomp_mult}"},
		{"text": "Big bite x{^chomp_mult} → {chomp_mult}", "chomp_mult": 3.0},
		{"text": "+ A big bite bleeds {chomp_burn}/sec for 3s", "now": "Every 4th hit bites for x{chomp_mult} + bleed {chomp_burn}/sec", "chomp_burn": 2.0},
		{"text": "Bites every 4th → 3rd hit", "now": "Every 3rd hit bites for x{chomp_mult} + bleed {chomp_burn}/sec", "chomp_every": 3.0},
		{"text": "+ A big bite heals 50% of its dmg", "now": "Every 3rd hit bites x{chomp_mult}, bleeds, heals {chomp_heal%}%", "chomp_heal": 0.5},
	],
	"chaos": {"closing_walls": {"chomp_mult": 0.75}, "glass_cannon": {"chomp_mult": 1.2}}, ## Closing Walls crowds foes into more bites; Glass Cannon fights end before many bites land
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "teeth"}, "back": ["dorsal"], "front": ["belly"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.95},
}
