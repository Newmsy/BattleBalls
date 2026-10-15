## Optic, the Laser (Rare Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 5,
	"name": "Optic",
	"type": "Laser",
	"rarity": "rare",
	"role": "Zoner",
	"status": "live",
	"color": "27c8ff",
	"vibe": "A calm, calculating little robot with one big eye.",
	"description": "Laser. Every wall bounce fires a beam back to its last bounce point.",
	"stats": {"hp": 100.0, "radius": 58.0, "speed": 420.0, "contact_damage": 10.0},
	"ability": [{"on": "wall", "do": "beam"}],
	"params": {"beam_life": 3.0, "beam_damage": 4.5, "beam_hit_cooldown": 0.5, "beam_max": 6},
	"tiers": [
		{"text": "Beams last 3s"},
		{"text": "Beams last 3.5s", "beam_life": 3.5},
		{"text": "Beams last 4s", "beam_life": 4.0},
		{"text": "Beams last 4.5s", "beam_life": 4.5},
		{"text": "Beams also link the 2 previous bounces"},
	],
	## Chaos Weekends: short fights cut off its beam build-up, so beams hit
	## harder under Big Head and Hyper Speed. Tuned with tools/balance.gd --modifiers.
	"chaos": {"big_head": {"beam_damage": 1.2}, "hyper_speed": {"beam_damage": 1.3}},
	"art": {"badge_top": 1.6, "eyes": {"one": true, "w": .4, "h": .4, "p": .16, "iris": "0a7bb0", "glow": "7fe6ff", "mouth": "none"}, "back": ["antennae"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.0},
}
