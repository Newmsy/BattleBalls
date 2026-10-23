## Puff, the Pufferfish (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 23,
	"name": "Puff",
	"type": "Pufferfish",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "ffd84a",
	"vibe": "A nervous pufferfish that balloons up when startled, then calms down.",
	"description": "Pufferfish. When hurt, it puffs up for 2s: +30% size, -15% speed, +2 dmg, and its spines blast the attacker away for {grow_pulse_damage}.",
	"stats": {"hp": 119.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hurt", "do": "grow"}],
	"params": {
		"grow_radius": 0.3,
		"grow_speed": -0.15,
		"grow_add": 2.0,
		"grow_secs": 2.0,
		"grow_stack": 0.0,
		"grow_heal": 0.0,
		"grow_pulse_radius": 110.0,
		"grow_pulse_damage": 4.0,
		"grow_bolts": 0.0,
		"bolt_damage": 3.0,
		"grow_end_bolts": 0.0,
	},
	"tiers": [
		{"text": "Hurt: puffs up 2s (+2 dmg), spines blast 4", "now": "Hurt: puffs up {grow_secs}s (+{grow_add} dmg), spines blast {grow_pulse_damage}"},
		{"text": "Puffed dmg +2 → +3", "grow_add": 3.0},
		{"text": "Spine blast {^grow_pulse_damage} → {grow_pulse_damage}", "grow_pulse_damage": 6.0},
		{"text": "Puff 2 → 2.5s", "grow_secs": 2.5},
		{"text": "+ Deflating sprays 6 spines ({bolt_damage} each)", "now": "Hurt: puffs {grow_secs}s (+{grow_add} dmg), blast {grow_pulse_damage}, then {grow_end_bolts} spines", "ability": [{"on": "always", "do": "grow_end"}], "grow_end_bolts": 6.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": -.14, "mouth": "pout"}, "back": ["sidefins"], "front": ["spots"]},
	"sound": {"ouch": "ouch_sea", "pitch": 1.15},
}
