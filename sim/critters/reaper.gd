## Reaper, the Grim reaper (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 103,
	"name": "Reaper",
	"type": "Grim reaper",
	"rarity": "legendary",
	"role": "Bruiser",
	"status": "live",
	"color": "2b2f45",
	"vibe": "Polite, patient, and always on time.",
	"description": "Grim reaper. Every {doom_every}s it dooms the nearest foe: after a {doom_secs}s countdown its scythe sweeps for {reap_damage} dmg. Bumping Reaper before the end breaks the curse.",
	"tier_power": [0.85, 0.88, 0.91, 0.93, 0.95], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 122.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "every", "secs": "doom_every", "do": "doom"}, {"on": "bump", "do": "doom_break"}, {"on": "always", "do": "doom_tick"}],
	"params": {
		"doom_every": 8.0,
		"doom_secs": 3.0, ## The countdown; a bump on Reaper meanwhile breaks it.
		"reap_damage": 20.0,
		"soul_heal": 0.0, ## T5: a broken curse heals Reaper this much...
		"harvest_radius": 0.0, ## ...and the sweep also circles Reaper this wide...
		"harvest_damage": 10.0, ## ...for this.
	},
	"tiers": [
		{"text": "Every 8s dooms foe: 3s, then scythe 20", "card": "Every few seconds it dooms the foe to a scythe sweep after a countdown; bumping Reaper breaks the curse.", "now": "Every {doom_every}s dooms foe: {doom_secs}s, then scythe {reap_damage}"},
		{"text": "Scythe {^reap_damage} → {reap_damage}"},
		{"text": "Doom every {^doom_every} → {doom_every}s", "doom_every": 7.0},
		{"text": "Scythe {^reap_damage} → {reap_damage}"},
		{"text": "+ Sweep circles Reaper; broken curse heals", "special": "Final Harvest", "card": "It dooms the foe to a scythe sweep that also circles Reaper; a broken curse leaves a soul that heals it.", "now": "Every {doom_every}s doom: scythe {reap_damage} + ring {harvest_damage}; break heals {soul_heal}", "doom_every": 6.5, "harvest_radius": 190.0, "soul_heal": 12.0},
	],
	"art": {"badge_top": 1.55, "eyes": {"sep": .28, "w": .15, "h": .2, "p": .07, "glow": "5cf0f0", "iris": "5cf0f0", "mouth": "none"}, "back": ["scythe", "reaperhood"], "front": ["reaperface"]},
	"sound": {"ouch": "ouch_spooky", "pitch": 0.7},
}
