## Prickles, the Spiker (Common Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 3,
	"name": "Prickles",
	"type": "Spiker",
	"rarity": "common",
	"role": "Bruiser",
	"status": "planned",
	"color": "5cc95a",
	"vibe": "Overexcited cactus pup that gets pointier the more it fights.",
	"description": "Spiker.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [{"on": "hit", "do": "stack"}],
	"params": {},
	"tiers": [
		{"text": "+1 contact damage per hit landed, max 5"},
		{"text": "Max 6"},
		{"text": "Max 8"},
		{"text": "Max 10"},
		{"text": "Spikes fire off at full stacks"},
	],
	"art": {"eyes": {"sep": .32, "w": .24, "h": .28, "p": .12, "mouth": "grin"}, "back": ["spike_ring"]},
	"sound": {},
}
