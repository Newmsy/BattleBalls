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
	"description": "Spiker. Grows a spike on every hit it lands; each spike adds contact damage.",
	"stats": {"hp": 115.0, "radius": 62.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "hit", "do": "grow_spike"}, {"on": "strike", "do": "spikes"}],
	"params": {
		"spike_damage": 1.6, ## Contact damage per spike.
		"spike_max": 10, ## Spikes stop growing here.
	},
	"tiers": [
		{"text": "+1.6 contact damage per hit landed, max 10"},
		{"text": "+1.8 per spike", "spike_damage": 1.8},
		{"text": "Max 12", "spike_max": 12},
		{"text": "+2 per spike", "spike_damage": 2.0},
		{"text": "Spikes fire off at full stacks"},
	],
	"art": {"eyes": {"sep": .32, "w": .24, "h": .28, "p": .12, "mouth": "grin"}, "back": ["spike_ring"]},
	"sound": {},
}
