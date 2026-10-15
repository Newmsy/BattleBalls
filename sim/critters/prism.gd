## Spectra, the Prism (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 15,
	"name": "Spectra",
	"type": "Prism",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "planned",
	"color": "9ad8ff",
	"vibe": "Dazzling and a bit vain about it.",
	"description": "Prism.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "hurt", "do": "beam"}],
	"params": {},
	"tiers": [
		{"text": "Splits projectiles into 2 beams"},
		{"text": "3 beams"},
		{"text": "Beams home in"},
		{"text": "4 beams"},
		{"text": "Reflects lasers back"},
	],
	"art": {"eyes": {"sep": .3, "w": .21, "h": .26, "p": .11, "sparkle": true, "mouth": "smile"}, "body": "prism"},
	"sound": {},
}
