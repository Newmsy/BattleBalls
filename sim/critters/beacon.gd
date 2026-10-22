## Beacon, the Lighthouse (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 67,
	"name": "Beacon",
	"type": "Lighthouse",
	"rarity": "epic",
	"rarity_power": 1.04, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "06d6a0",
	"vibe": "A steady old lighthouse keeper who keeps an eye on everything.",
	"description": "Lighthouse. Every 4s it shines a beam straight ahead to the far wall (6/s), and foes caught in the light take +20% dmg for 2s.",
	"stats": {"hp": 116.0, "radius": 64.0, "speed": 400.0, "contact_damage": 20.0},
	"ability": [{"on": "every", "secs": "lamp_every", "do": "lamp"}],
	"params": {
		"lamp_every": 4.0, ## Seconds between beams.
		"lamp_life": 1.2,
		"lamp_dps": 6.0, ## Damage a second in the light.
		"lamp_vuln": 0.2, ## Extra damage share after being lit.
		"lamp_vuln_secs": 2.0,
		"lamp_sweep": 0.0, ## T3: degrees the beam swings.
		"lamp_back": 0, ## T5: also shine backwards.
	},
	"tiers": [
		{"text": "Beam every 4s: 6/s, lit foes +20% dmg taken", "now": "Beam every {lamp_every}s: {lamp_dps}/s, lit foes +{lamp_vuln%}% dmg taken"},
		{"text": "Beam 6 → 8/s", "lamp_dps": 8.0},
		{"text": "+ Beam sweeps 45°", "now": "Sweeping beam every {lamp_every}s: {lamp_dps}/s, lit +{lamp_vuln%}% dmg taken", "lamp_sweep": 45.0, "ability": [{"on": "always", "do": "lamp_sweep"}]},
		{"text": "Beam every 4 → 3.5s", "lamp_every": 3.5},
		{"text": "+ A 2nd beam shines backwards", "now": "2 sweeping beams every {lamp_every}s: {lamp_dps}/s, +{lamp_vuln%}% dmg taken", "lamp_back": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smile"}, "back": ["lamp"], "front": ["stripes"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.9},
}
