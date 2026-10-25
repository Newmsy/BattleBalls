## Bolt, the Robot (Uncommon Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 36,
	"name": "Bolt",
	"type": "Robot",
	"rarity": "uncommon",
	"rarity_power": 1.181, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [1.00, 1.07, 1.13, 1.25, 1.36], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Skirmisher",
	"status": "live",
	"color": "3a3aff",
	"vibe": "An overeager little robot that zaps itself somewhere new after every punch.",
	"description": "Robot. After every 2nd hit it teleports right behind the foe, lined up for a backstab: its next hit deals +3.",
	"stats": {"hp": 113.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.5},
	"ability": [{"on": "hit", "do": "blink"}, {"on": "strike", "do": "blink_bonus"}],
	"params": {
		"blink_every": 2, ## Teleports after every this-many contact hits.
		"blink_away": 60.0, ## Gap it leaves behind the foe.
		"blink_behind": 1, ## Lands behind the foe, facing it.
		"blink_bonus": 3.0, ## Extra damage on its first hit after landing.
		"blink_crackle": 0.0, ## T3: pulse damage where it left.
		"blink_crackle_radius": 70.0,
		"blink_zap": 0.0, ## T5: beam damage a second from its old spot to its new one.
	},
	"tiers": [
		{"text": "Every 2nd hit teleports behind foe; next hit +3", "card": "Every other hit, it teleports behind the foe for a stronger backstab.", "now": "Every 2nd hit teleports behind foe; next hit +{blink_bonus}"},
		{"text": "Backstab +3 → +5", "blink_bonus": 5.0},
		{"text": "+ The spot it leaves crackles for 5", "card": "Every other hit, it teleports behind the foe for a backstab, leaving a crackling spark.", "now": "Every 2nd hit teleports behind foe, crackles; next hit +{blink_bonus}", "blink_crackle": 5.0},
		{"text": "Teleports every 2nd hit → every hit", "card": "Every hit, it teleports behind the foe for a backstab, leaving a crackling spark.", "now": "Every hit teleports behind foe, crackles; next hit +{blink_bonus}", "blink_every": 1},
		{"text": "+ Zap beam along the jump (10/sec)", "card": "Every hit, it zaps a beam as it teleports behind the foe for a backstab.", "now": "Each hit: zap-teleports behind foe; next hit +{blink_bonus}", "blink_zap": 10.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "square": true, "mouth": "flat"}, "back": ["boltant"], "front": ["panel"]},
	"sound": {"ouch": "ouch_tech", "pitch": 1.25},
}
