## Rift, the Wormhole (Epic Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 102,
	"name": "Rift",
	"type": "Wormhole",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "live",
	"color": "38e0d0",
	"vibe": "Folds the arena in half when nobody is looking.",
	"description": "Wormhole. Its last 2 wall bounces open linked portals for {portal_secs}s. Any ball entering one comes out of the other, and Rift's first hit after warping lands x{warp_mult}.",
	"tier_power": [0.97, 1.02, 1.08, 1.15, 1.25], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "wall", "do": "rift_open"}, {"on": "always", "do": "rift_tick"}, {"on": "strike", "do": "rift_hit"}],
	"params": {
		"portal_radius": 44.0,
		"portal_count": 2,
		"portal_secs": 4.0,
		"warp_mult": 1.8,
		"warp_slow": 0.0, ## T5: a foe coming out is dizzy (slowed this much 1s).
	},
	"tiers": [
		{"text": "Wall bounces open portals 4s; warp hit x1.8", "card": "Its wall bounces open linked portals any ball can fall through; its first hit after a warp lands harder.", "now": "Wall bounces open portals {portal_secs}s; warp hit x{warp_mult}"},
		{"text": "Portals last {^portal_secs} → {portal_secs}s", "portal_secs": 5.0},
		{"text": "Portal size +{+portal_radius}%", "portal_radius": 52.0},
		{"text": "Warp hit x{^warp_mult} → x{warp_mult}", "warp_mult": 2.0},
		{"text": "+ Loop of 3 portals; foes come out dizzy", "special": "Event Horizon", "card": "Its wall bounces open a loop of three portals; foes come out dizzy and its next hit lands harder.", "now": "3 portals {portal_secs}s; foes out dizzy, warp hit x{warp_mult}", "portal_count": 3, "warp_slow": 0.3},
	],
	"art": {"body": "swirl", "eyes": {"sep": .34, "w": .19, "h": .23, "p": .1, "swirl": true, "mouth": "o"}, "back": ["portals"], "front": ["riftrim"]},
	"sound": {"ouch": "ouch_cosmic", "pitch": 0.85},
}
