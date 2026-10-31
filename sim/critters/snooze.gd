## Snooze, the Sleepy moon (Uncommon Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 94,
	"name": "Snooze",
	"type": "Sleepy moon",
	"rarity": "uncommon",
	"role": "Bruiser",
	"status": "live",
	"color": "ffe9a3",
	"vibe": "A drowsy little moon. Do not wake it. Really, don't.",
	"description": "Sleepy moon. Asleep it rolls {sleep_slow%}% slower and takes {sleep_armor%}% less damage. A foe's bump wakes it for {wake_secs}s: {wake_speed%}% faster and its hits deal +{wake_damage}, then it nods off again.",
	"tier_power": [1.00, 0.98, 0.95, 0.93, 0.92], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 134.0, "radius": 66.0, "speed": 400.0, "contact_damage": 16.5},
	"ability": [{"on": "always", "do": "snooze"}, {"on": "guard", "do": "snooze_guard"}, {"on": "bump", "do": "wake"}],
	"params": {
		"sleep_slow": 0.3,
		"sleep_armor": 0.2,
		"wake_speed": 0.5,
		"wake_damage": 4.0, ## Flat contact damage while awake.
		"wake_secs": 3.0,
		"wake_roar_radius": 0.0, ## T5: waking roars a knockback ring this big...
		"wake_roar_damage": 6.0, ## ...for this.
	},
	"tiers": [
		{"text": "Sleeps (-20% dmg taken); bumped: up 3s, +4 dmg", "card": "It sleeps, slow but hard to hurt. A bump wakes it up fast and hard-hitting for a few seconds.", "now": "Sleeps (-{sleep_armor%}% dmg taken); bumped: up {wake_secs}s, +{wake_damage} dmg"},
		{"text": "Awake {^wake_secs} → {wake_secs}s", "wake_secs": 3.5},
		{"text": "Sleep armor {^sleep_armor%} → {sleep_armor%}%", "sleep_armor": 0.25},
		{"text": "Awake {^wake_secs} → {wake_secs}s", "wake_secs": 4.0},
		{"text": "+ Wakes with a roar ({wake_roar_damage} + knockback), up {wake_secs}s", "special": "Rude Awakening", "card": "It sleeps, slow but hard to hurt. A bump wakes it with a knockback roar, fast and hard-hitting.", "now": "Sleeps (-{sleep_armor%}% taken); bumped: roar {wake_roar_damage}, up {wake_secs}s", "wake_secs": 4.5, "wake_roar_radius": 200.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "closed": true, "mouth": "o"}, "back": ["nightcap"], "front": ["craters"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 0.9},
}
