## Jawbreaker, the Jawbreaker (Rare Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 45,
	"name": "Jawbreaker",
	"type": "Jawbreaker",
	"rarity": "rare",
	"role": "Bruiser",
	"status": "live",
	"color": "2ec4b6",
	"vibe": "A rock-hard candy collector who keeps its winnings spinning close.",
	"description": "Jawbreaker. Every hit adds a candy that circles it and bonks foes, up to 3.",
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
		{"text": "Hits add an orbiting candy, max 3"},
		{"text": "Candies bonk for 5", "candy_damage": 5.0},
		{"text": "Starts the fight with 1 candy", "candy_start": 1},
		{"text": "Up to 4 candies", "candy_max": 4},
		{"text": "Starts with 3 candies, and a full set cracks in a sugar blast for 16", "candy_blast_damage": 16.0, "candy_start": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smirk"}, "back": ["moons"], "front": ["candyrings"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
