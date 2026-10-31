## Gourdo, the Jack-o'-lantern (Uncommon Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 96,
	"name": "Gourdo",
	"type": "Jack-o'-lantern",
	"rarity": "uncommon",
	"role": "Disruptor",
	"status": "live",
	"color": "ff8a2a",
	"vibe": "A grinning pumpkin who lives for one perfect BOO.",
	"description": "Jack-o'-lantern. Every 5s it flashes a scary face: the nearest foe turns tail, flying straight away, and takes {scare_vuln%}% more damage for {scare_secs}s.",
	"tier_power": [0.90, 0.95, 1.01, 1.08, 1.16], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "every", "secs": 5.0, "do": "scare"}, {"on": "foe_wall", "do": "scare_wall"}],
	"params": {
		"scare_secs": 1.0,
		"scare_vuln": 0.25,
		"scare_stun": 0.0, ## T5: a fleeing foe that hits a wall is stunned this long.
	},
	"tiers": [
		{"text": "Every 5s scares foe: flees, +25% dmg taken 1s", "card": "Every few seconds it flashes a scary face: the foe turns tail and takes extra damage.", "now": "Every 5s scares foe: flees, +{scare_vuln%}% dmg taken {scare_secs}s"},
		{"text": "Scare {^scare_secs} → {scare_secs}s", "scare_secs": 1.2},
		{"text": "Scared foes take {^scare_vuln%} → {scare_vuln%}% more", "scare_vuln": 0.3},
		{"text": "Scare {^scare_secs} → {scare_secs}s", "scare_secs": 1.4},
		{"text": "+ Fleeing into a wall: scared stiff 0.4s", "special": "Fright Night", "card": "Every few seconds it scares the foe into fleeing; if it runs into a wall it's scared stiff.", "now": "Every 5s scares foe {scare_secs}s (+{scare_vuln%}% taken); into wall: stun", "scare_secs": 1.6, "scare_stun": 0.4},
	],
	"art": {"eyes": {"none": true, "mouth": "none"}, "back": ["pumpkinstem"], "front": ["pumpkinface"]},
	"sound": {"ouch": "ouch_spooky", "pitch": 0.95},
}
