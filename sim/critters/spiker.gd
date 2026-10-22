## Prickles, the Spiker (Common Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 3,
	"name": "Prickles",
	"type": "Spiker",
	"rarity": "common",
	"role": "Bruiser",
	"status": "live",
	"color": "5cc95a",
	"vibe": "Overexcited cactus pup that gets pointier the more it fights.",
	"description": "Spiker. Grows a spike on every hit it lands (up to 10); each spike adds +1.6 contact damage.",
	"stats": {"hp": 115.0, "radius": 62.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hit", "do": "grow_spike"}, {"on": "strike", "do": "spikes"}, {"on": "hit", "do": "spike_volley"}],
	"params": {
		"spike_damage": 1.6, ## Contact damage per spike.
		"spike_max": 10, ## Spikes stop growing here.
		"shot_damage": 3.0, ## T5: spikes fired at full stacks.
		"shot_speed": 500.0,
		"shot_count": 8,
		"spike_burst_at": 3, ## T5: hits fire spikes from this many spikes on (fights see ~5 hits).
		"shot_kind": "spike",
		"volley_every": 3, ## Every this-many spikes grown, a volley flies.
		"volley_count": 6,
		"volley_damage": 2.5,
	},
	"tiers": [
		{"text": "+1.6 dmg per hit, max 10 · every 3rd hit fires 6 spikes", "now": "+{spike_damage} dmg per hit, max {spike_max} · every 3rd hit fires {volley_count} spikes"},
		{"text": "Per spike +1.6 → +1.8", "spike_damage": 1.8},
		{"text": "Max spikes 10 → 12", "spike_max": 12},
		{"text": "Per spike +1.8 → +2", "spike_damage": 2.0},
		{"text": "+ From 3 spikes, hits fire 8 spikes (3)", "now": "+{spike_damage} dmg per hit landed, max {spike_max}; {spike_burst_at}+: spike ring", "ability": [{"on": "hit", "do": "spike_burst"}]},
	],
	"art": {"eyes": {"sep": .32, "w": .24, "h": .28, "p": .12, "mouth": "grin"}, "back": ["spike_ring"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.15},
}
