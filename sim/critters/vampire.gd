## Count Nibbles, the Vampire (Common Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 1,
	"name": "Count Nibbles",
	"type": "Vampire",
	"rarity": "common",
	"role": "Bruiser",
	"status": "live",
	"color": "c2264a",
	"vibe": "A smug little aristocrat who thinks every fight is dinner.",
	"description": "Vampire. Heals for half the damage it deals when it hits.",
	"stats": {"hp": 100.0, "radius": 68.0, "speed": 400.0, "contact_damage": 16.0},
	"ability": [{"on": "hit", "do": "heal"}],
	"params": {"heal_ratio": 0.5},
	"tiers": [
		{"text": "Heal 50% of damage dealt"},
		{"text": "Heal 60%", "heal_ratio": 0.6},
		{"text": "Heal 70%", "heal_ratio": 0.7},
		{"text": "Heal 80%", "heal_ratio": 0.8},
		{"text": "Overheal becomes a shield"},
	],
	"art": {"badge_top": 1.3, "eyes": {"sep": .3, "w": .19, "h": .22, "p": .1, "lid": .45, "brow": .12, "mouth": "fangs"}, "back": ["cape_collar"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
