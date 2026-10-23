## Old Oak, the Ancient tree (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 75,
	"name": "Old Oak",
	"type": "Ancient tree",
	"rarity": "legendary",
	"rarity_power": 1.102, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Bruiser",
	"status": "live",
	"color": "6f4518",
	"vibe": "A slow, kind forest elder who has seen a thousand fights.",
	"description": "Ancient tree. Every {swat_every}s its branches swat nearby foes away ({swat_damage} dmg). At 50% HP it takes root: {root_count} root pillars burst up around it and it regrows {root_regen} HP/sec while they stand ({root_life}s; higher tiers keep roots until a foe hits them).",
	"stats": {"hp": 122.0, "radius": 76.8, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "hp_below", "hp": 0.5, "do": "root"}, {"on": "always", "do": "root_tick"}, {"on": "every", "secs": "swat_every", "do": "swat"}],
	"params": {
		"root_count": 4,
		"root_radius": 35.0,
		"root_life": 6.0, ## Seconds the roots stand and it regrows.
		"root_stay": 0, ## Roots that stand until a foe bounces off them instead.
		"root_pin": 2.0, ## Seconds it holds still as it takes root.
		"root_regen": 3.0, ## HP a second while rooted.
		"root_shove": 0.0, ## Eruption radius, when above 0.
		"root_shove_damage": 8.0,
		"swat_every": 4.0, ## Its branches swat foes near it this often...
		"swat_radius": 170.0, ## ...this far from its centre...
		"swat_damage": 6.0, ## ...for this, knocking them away.
	},
	"tiers": [
		{"text": "Swats foes every 4s (6 dmg); roots at 50% HP: +3 HP/sec", "now": "Swats foes every {swat_every}s ({swat_damage} dmg); roots at 50% HP: +{root_regen} HP/sec"},
		{"text": "Regrow 3 → 4 HP/sec · 1 root stays till hit", "root_regen": 4.0, "root_stay": 1},
		{"text": "+ Roots erupt: {root_shove_damage} + knockback · 2 stay", "root_shove": 150.0, "root_stay": 2},
		{"text": "3 roots stay until a foe hits them", "root_stay": 3},
		{"text": "All 4 stay · takes root again at 20% HP", "now": "Swats ({swat_damage} dmg); roots at 50% and 20% HP: +{root_regen} HP/sec", "ability": [{"on": "hp_below", "hp": 0.2, "do": "root"}], "root_stay": 4},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["canopy"], "front": ["beard"]},
	"sound": {"ouch": "ouch_nature", "pitch": 0.7},
	"chaos": {"pillars": {"hp": 1.05}, "bumpers": {"hp": 1.04}}, ## Obstacles crowd out its root pillars.
}
