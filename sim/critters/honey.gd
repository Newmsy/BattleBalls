## Honey, the Honey pot (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 30,
	"name": "Honey",
	"type": "Honey pot",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "d97706",
	"vibe": "A sweet, slow-talking honey pot that leaves everyone a little sticky.",
	"description": "Honey pot. Every wall bounce drips a honey puddle; a foe that rolls in gets stuck fast, and Honey's next hit on a stuck foe crushes it for extra damage.",
	"stats": {"hp": 120.0, "radius": 64.0, "speed": 400.0, "contact_damage": 20.0},
	"ability": [{"on": "wall", "do": "honey"}, {"on": "always", "do": "honey_trap"}, {"on": "strike", "do": "honey_crush"}],
	"params": {
		"honey_radius": 55.0,
		"honey_life": 4.0,
		"honey_slow": 0.35, ## Share of movement a foe loses in honey.
		"honey_max": 4, ## Oldest puddle goes when a new one would pass this.
		"honey_stick": 0.6, ## A foe that rolls in is stuck (stunned) this long; the puddle is used up.
		"honey_crush": 1.5, ## Honey's hit on a foe stuck in its honey.
		"honey_merge_radius": 0.0, ## T5: touching puddles merge into a pool this big.
		"linger_dps": 0.0,
		"linger_slow": 0.35, ## T3: a foe that was in honey stays this slow...
		"linger_secs": 1.0, ## ...for this long.
	},
	"tiers": [
		{"text": "Bounces drip honey (max 4): a foe that rolls in is stuck 0.6s, and Honey's hit on it deals +50%"},
		{"text": "Puddles last 5s and crush hits deal +75%", "honey_life": 5.0, "honey_crush": 1.75},
		{"text": "Foes stay sticky for 1s after", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "Up to 6 bigger puddles", "honey_max": 6, "honey_radius": 70.0},
		{"text": "Touching puddles merge into a big pool (radius 90) that stings 6/s, and crush hits deal x2.2", "honey_merge_radius": 90.0, "honey_crush": 2.2, "linger_dps": 6.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["jarlid", "drips"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.85},
}
