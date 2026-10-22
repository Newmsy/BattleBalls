## Jawbreaker, the Jawbreaker (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 45,
	"name": "Jawbreaker",
	"type": "Jawbreaker",
	"rarity": "rare",
	"rarity_power": 1.064, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "2ec4b6",
	"vibe": "A rock-hard candy collector who keeps its winnings spinning close.",
	"description": "Jawbreaker. Every hit adds a candy that circles it and bonks foes for 4, up to 3; a hit of 10 or more on it knocks one off.",
	"stats": {"hp": 131.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "always", "do": "candies"}, {"on": "hit", "do": "candy"}, {"on": "hurt", "do": "candy_loss"}],
	"params": {
		"candy_max": 3,
		"candy_orbit": 34.0, ## Distance beyond its edge.
		"candy_size": 12.0,
		"candy_damage": 4.0,
		"candy_spin": 3.0, ## Radians a second.
		"candy_cooldown": 0.5,
		"candy_start": 0,
		"candy_loss_hit": 10.0, ## A single hit this big knocks a candy off.
		"candy_blast_radius": 140.0, ## T5 sugar blast.
		"candy_blast_damage": 0.0,
	},
	"tiers": [
		{"text": "Hits add an orbiting candy (4), max 3", "now": "Hits add an orbiting candy ({candy_damage}), max {candy_max}"},
		{"text": "Candy 4 → 5", "candy_damage": 5.0},
		{"text": "+ Starts the fight with 1 candy", "now": "Hits add an orbiting candy ({candy_damage}), max {candy_max}; starts with {candy_start}", "candy_start": 1},
		{"text": "Max candies 3 → 4", "candy_max": 4},
		{"text": "Starts with 1 → 3 · full set blasts 16", "now": "Starts with {candy_start} candies ({candy_damage}), max {candy_max}; full: blast {candy_blast_damage}", "candy_blast_damage": 16.0, "candy_start": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smirk"}, "back": ["moons"], "front": ["candyrings"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.0},
}
