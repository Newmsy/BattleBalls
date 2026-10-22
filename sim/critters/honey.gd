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
	"description": "Honey pot. Every wall bounce drips a honey puddle (up to 4); a foe that rolls in is stuck 0.6s, and Honey's next hit on a stuck foe crushes it for x1.5.",
	"stats": {"hp": 113.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.0},
	"ability": [{"on": "wall", "do": "honey"}, {"on": "always", "do": "honey_trap"}, {"on": "strike", "do": "honey_crush"}],
	"params": {
		"honey_sting_damage": 0.0, ## T5: a foe getting stuck takes this.
		"honey_dps": 0.0, ## T5: puddles sting this much a second.
		"honey_lob": 4.0, ## T5: seconds between honey lobbed under the foe.
		"honey_pull": 0.0, ## T5: puddles drag foes within twice their size in this hard.
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
		{"text": "Bounces drip honey: sticks foe 0.6s, next hit x1.5", "now": "Bounces drip honey: sticks foe {honey_stick}s, next hit x{honey_crush}"},
		{"text": "Puddles 4 → 5s, crush x1.5 → 1.75", "honey_life": 5.0, "honey_crush": 1.75},
		{"text": "+ Foes stay slowed 35% for 1s after", "now": "Bounces drip honey: sticks {honey_stick}s, then slow; next hit x{honey_crush}", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "Max puddles 4 → 6, size +27%", "honey_max": 6, "honey_radius": 70.0},
		{"text": "+ Lobs honey every 4s; pull, sting 6/s, crush x2.2", "now": "Drips + lobs honey (every {honey_lob}s): sticks {honey_stick}s, hit x{honey_crush}", "special": "Honey Pot", "honey_merge_radius": 90.0, "honey_crush": 2.2, "honey_pull": 900.0, "honey_sting_damage": 14.0, "honey_dps": 6.0, "ability": [{"on": "every", "secs": "honey_lob", "do": "honey_lob"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "front": ["jarlid", "drips"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 0.85},
}
