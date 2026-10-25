## Count Nibbles, the Vampire (Common Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 1,
	"name": "Count Nibbles",
	"type": "Vampire",
	"rarity": "common",
	"tier_power": [1.06, 1.05, 1.04, 1.16, 1.28], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "c2264a",
	"vibe": "A smug little aristocrat who thinks every fight is dinner.",
	"description": "Vampire. Heals for 50% of the damage it deals when it hits.",
	"stats": {"hp": 100.0, "radius": 68.0, "speed": 400.0, "contact_damage": 16.0},
	"ability": [{"on": "hit", "do": "heal"}],
	"params": {"heal_ratio": 0.5, "overheal_cap": 25.0},
	"tiers": [
		{"text": "Heals 50% of dmg dealt", "card": "Heals for a big share of the damage it deals.", "now": "Heals {heal_ratio%}% of dmg dealt"},
		{"text": "Heal 50 → 60%", "heal_ratio": 0.6},
		{"text": "Heal 60 → 70%", "heal_ratio": 0.7},
		{"text": "Heal 70 → 80%", "heal_ratio": 0.8},
		{"text": "+ Overheal becomes a shield (max 25)", "card": "Heals for most of the damage it deals, and extra healing becomes a shield.", "now": "Heals {heal_ratio%}% of dmg dealt; overheal shields up to {overheal_cap}", "ability": [{"on": "hit", "do": "overheal"}]},
	],
	"art": {"badge_top": 1.3, "eyes": {"sep": .3, "w": .19, "h": .22, "p": .1, "lid": .45, "brow": .12, "mouth": "fangs"}, "back": ["cape_collar"]},
	"sound": {"ouch": "ouch_spooky", "pitch": 1.0},
}
