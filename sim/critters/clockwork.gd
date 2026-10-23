## Clockwork, the Clockwork (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 82,
	"name": "Clockwork",
	"type": "Clockwork",
	"rarity": "legendary",
	"rarity_power": 1.068, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.00, 1.05, 1.12, 1.19, 1.27], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "c9a227",
	"vibe": "A fussy brass timekeeper who refuses to be late, or to lose.",
	"description": "Clockwork. Every 5s it ticks out a ring ({tick_damage} dmg, slow {tick_slow%}% for {tick_slow_secs}s) that leaves a clock face for {face_secs}s, slowing foes on it and speeding Clockwork up. Every {stop_every}s it stops time on its foes for {stop_secs}s, and once below 30% HP it rewinds, winning back {rewind_share%}% of the HP it lost in the last {rewind_secs}s.",
	"stats": {"hp": 117.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "every", "secs": 5.0, "do": "tick_ring"}, {"on": "every", "secs": "stop_every", "do": "time_stop"}, {"on": "always", "do": "rewind_track"}, {"on": "always", "do": "slows"}, {"on": "hp_below", "hp": 0.3, "do": "rewind"}, {"on": "always", "do": "face_haste"}],
	"params": {
		"tick_radius": 160.0,
		"tick_damage": 3.0,
		"tick_slow": 0.3,
		"tick_slow_secs": 1.0,
		"face_secs": 2.0, ## Each ring leaves a clock face this long: it slows foes...
		"face_haste": 0.25, ## ...and Clockwork runs this much faster on it.
		"rewind_secs": 3.0,
		"rewind_share": 0.3, ## How much of the lost HP comes back.
		"rewind_place": 0, ## 1: the rewind also puts it back where it was.
		"rewind_stop": 0.0, ## Seconds foes freeze at the rewind (stun cap 0.6).
		"stop_every": 10.0, ## Stops time on its foes this often...
		"stop_secs": 0.4, ## ...for this long.
	},
	"tiers": [
		{"text": "Ring every 5s (3, slow), stops time every 10s, rewinds", "now": "Ring every 5s ({tick_damage}, slow), stops time every {stop_every}s, rewinds"},
		{"text": "Tick {^tick_damage} → {tick_damage}, clock faces 2 → 3s", "tick_damage": 4.0, "face_secs": 3.0},
		{"text": "+ Rewinding also turns back its spot", "rewind_place": 1},
		{"text": "Rewind 3 → 4s, clock faces 3 → 4s, haste +40%", "rewind_secs": 4.0, "face_secs": 4.0, "face_haste": 0.4},
		{"text": "Tick {^tick_damage} → {tick_damage} + rewind stops time 0.6s", "now": "Ring every 5s ({tick_damage} dmg), time stops, rewind {rewind_secs}s + time stop", "rewind_stop": 0.6, "tick_damage": 6.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["gearcrown"], "front": ["clockface", "monocle"]},
	"sound": {"ouch": "ouch_tech", "pitch": 0.95},
}
