## Clockwork, the Clockwork (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 82,
	"name": "Clockwork",
	"type": "Clockwork",
	"rarity": "legendary",
	"rarity_power": 1.068, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "c9a227",
	"vibe": "A fussy brass timekeeper who refuses to be late, or to lose.",
	"description": "Clockwork. Every 5s it ticks out a ring (3, slow 30% for 1s) that leaves a clock face for 2s, slowing foes on it and speeding Clockwork up; once below 30% HP it rewinds, winning back 30% of the HP it lost in the last 3s.",
	"stats": {"hp": 117.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "every", "secs": 5.0, "do": "tick_ring"}, {"on": "always", "do": "rewind_track"}, {"on": "always", "do": "slows"}, {"on": "hp_below", "hp": 0.3, "do": "rewind"}, {"on": "always", "do": "face_haste"}],
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
	},
	"tiers": [
		{"text": "Ticks a ring every 5s: 3, slow 30%; at 30% HP rewinds 3s", "now": "Ticks a ring every 5s: {tick_damage}, slow {tick_slow%}%; at 30% HP rewinds {rewind_secs}s"},
		{"text": "Tick 3 → 4, clock faces 2 → 3s", "tick_damage": 4.0, "face_secs": 3.0},
		{"text": "+ Rewinding also turns back its spot", "rewind_place": 1},
		{"text": "Rewind 3 → 4s, clock faces 3 → 4s, haste +40%", "rewind_secs": 4.0, "face_secs": 4.0, "face_haste": 0.4},
		{"text": "Tick 4 → 6 + rewind stops time 0.6s", "now": "Ring every 5s: {tick_damage}, slow {tick_slow%}%; at 30% HP rewind {rewind_secs}s, time stop", "rewind_stop": 0.6, "tick_damage": 6.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smirk"}, "back": ["gearcrown"], "front": ["clockface", "monocle"]},
	"sound": {"ouch": "ouch_tech", "pitch": 0.95},
}
