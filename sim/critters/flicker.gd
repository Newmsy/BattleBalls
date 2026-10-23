## Flicker, the Candle (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 32,
	"name": "Flicker",
	"type": "Candle",
	"rarity": "uncommon",
	"role": "Skirmisher",
	"status": "live",
	"rarity_power": 0.93, ## Per rarity step; also trimmed after the 2026-10-22 round robin (tools/round_robin.gd): it topped its rarity.
	"tier_power": [1.17, 1.24, 1.00, 0.98, 0.96], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"color": "fff1c1",
	"vibe": "A cheeky candle that vanishes in a puff of smoke after every poke.",
	"description": "Candle. After every hit its flame goes out for {phase_secs}s and it fades (-70% dmg taken); then it relights in a burst of fire ({relight_damage} dmg).",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hit", "do": "phase"}, {"on": "guard", "do": "phased"}, {"on": "always", "do": "relight"}],
	"params": {
		"phase_secs": 1.0,
		"phase_guard": 0.3,
		"relight_damage": 4.0, ## The flame bursts back on when the fade ends.
		"relight_nova_every": 0, ## T5 wick bomb: every this-many relights is a fire nova...
		"relight_nova_damage": 14.0,
		"relight_nova_radius": 260.0,
		"relight_radius": 140.0,
		"scorch_dps": 2.0,
		"scorch_secs": 2.0,
		"trail_every": 0.1,
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_dps": 3.0,
	},
	"tiers": [
		{"text": "After each hit fades 1s (-70% dmg taken), relights for 4", "now": "After each hit fades {phase_secs}s (-70% dmg taken), relights for {relight_damage}"},
		{"text": "Relight {^relight_damage} → {relight_damage}", "relight_damage": 6.0},
		{"text": "+ Its hits burn {scorch_dps}/sec for 2s", "now": "Burning hits; then fades {phase_secs}s (-70% taken), relights {relight_damage}", "ability": [{"on": "hit", "do": "scorch"}]},
		{"text": "Relight {^relight_damage} → {relight_damage}, size +{+relight_radius}%", "relight_radius": 180.0, "relight_damage": 8.0},
		{"text": "+ Fire trail; every 3rd relight: nova ({relight_nova_damage} dmg)", "now": "Burning hits; fades (fire trail), relights {relight_damage}; 3rd: nova", "relight_nova_every": 3, "ability": [{"on": "always", "do": "phase_fire"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["candle"], "front": ["drips"]},
	"sound": {"ouch": "ouch_spooky", "pitch": 1.2},
}
