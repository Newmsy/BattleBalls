## Shade, the Shadow (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 99,
	"name": "Shade",
	"type": "Shadow",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "live",
	"color": "5b4b9e",
	"vibe": "It was here a second ago. It still is, sort of.",
	"description": "Shadow. Its shadow follows {shadow_delay}s behind on exactly the same path and hits foes it touches ({shadow_damage} dmg).",
	"tier_power": [1.06, 1.08, 1.10, 1.13, 1.17], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 410.0, "contact_damage": 15.0},
	"ability": [{"on": "always", "do": "shadow_tick"}],
	"params": {
		"shadow_delay": 1.0,
		"shadow_damage": 8.0,
		"shadow_two": 0, ## T5: a second shadow twice as far back...
		"shadow_swap": 0.0, ## ...and Shade swaps places with it this often.
	},
	"tiers": [
		{"text": "Shadow 1s behind hits foes it touches (8)", "card": "Its shadow replays its path a moment later and hits any foe it touches.", "now": "Shadow {shadow_delay}s behind hits foes it touches ({shadow_damage})"},
		{"text": "Shadow hit {^shadow_damage} → {shadow_damage}"},
		{"text": "Shadow sticks closer: {shadow_delay}s behind", "shadow_delay": 0.85},
		{"text": "Shadow hit {^shadow_damage} → {shadow_damage}"},
		{"text": "+ Second shadow; swaps places every 6s", "special": "Shadow Play", "card": "Two shadows replay its path and hit foes they touch; every few seconds it swaps places with the last one.", "now": "2 shadows hit foes ({shadow_damage}); swap places every {shadow_swap}s", "shadow_two": 1, "shadow_swap": 6.0},
	],
	"art": {"body": "shadow", "eyes": {"sep": .3, "w": .17, "h": .25, "p": .05, "glow": "b7a6ff", "mouth": "none"}, "back": ["shadowtwin"], "front": ["shadowcrown"]},
	"sound": {"ouch": "ouch_spooky", "pitch": 1.15},
}
