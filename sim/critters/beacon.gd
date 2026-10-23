## Beacon, the Lighthouse (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 67,
	"name": "Beacon",
	"type": "Lighthouse",
	"rarity": "epic",
	"rarity_power": 1.04, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.85, 0.81, 1.00, 1.00, 1.00], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Zoner",
	"status": "live",
	"color": "06d6a0",
	"vibe": "A steady old lighthouse keeper who keeps an eye on everything.",
	"description": "Lighthouse. Every {lamp_every}s it turns to the foe and shines a beam to the far wall ({lamp_dps}/sec), and foes caught in the light take +{lamp_vuln%}% dmg for {lamp_vuln_secs}s.",
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 400.0, "contact_damage": 20.0},
	"ability": [{"on": "every", "secs": "lamp_every", "do": "lamp"}],
	"params": {
		"lamp_every": 4.0, ## Seconds between beams.
		"lamp_life": 1.2,
		"lamp_dps": 3.5, ## Damage a second in the light.
		"lamp_vuln": 0.2, ## Extra damage share after being lit.
		"lamp_vuln_secs": 2.0,
		"lamp_sweep": 0.0, ## T3: degrees the beam swings.
		"lamp_back": 0, ## T5: also shine backwards.
		"lamp_aim": 1, ## Turns to the foe before shining.
		"lamp_spin_every": 0, ## T5: every this-many shines turn a full circle.
	},
	"tiers": [
		{"text": "Aimed beam every 4s: 3.5/sec, lit foes +20% dmg taken", "now": "Aimed beam every {lamp_every}s: {lamp_dps}/sec, lit foes +{lamp_vuln%}% dmg taken"},
		{"text": "Beam {^lamp_dps} → {lamp_dps}/sec", "lamp_dps": 5.0},
		{"text": "+ Beam sweeps 45°", "now": "Sweeping beam every {lamp_every}s: {lamp_dps}/sec, lit +{lamp_vuln%}% dmg taken", "lamp_sweep": 45.0, "ability": [{"on": "always", "do": "lamp_sweep"}]},
		{"text": "Beam every 4 → 3.5s", "lamp_every": 3.5},
		{"text": "+ A 2nd beam backwards; every 3rd: full spin", "now": "2 sweeping beams every {lamp_every}s (3rd spins): {lamp_dps}/sec, lit +{lamp_vuln%}%", "lamp_back": 1, "lamp_spin_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smile"}, "back": ["lamp"], "front": ["stripes"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.9},
}
