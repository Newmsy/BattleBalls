## Beacon, the Lighthouse (Epic Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 67,
	"name": "Beacon",
	"type": "Lighthouse",
	"rarity": "epic",
	"role": "Zoner",
	"status": "live",
	"color": "06d6a0",
	"vibe": "A steady old lighthouse keeper who keeps an eye on everything.",
	"description": "Lighthouse. Every 4 seconds it shines a beam straight ahead to the far wall, and foes caught in the light take 20% more damage for 2 seconds.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 19.5},
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
		{"text": "Every 4s a beam shines ahead to the wall (6 damage a second); lit foes take 20% more damage for 2s"},
		{"text": "Beam 8 damage a second", "lamp_dps": 8.0},
		{"text": "The beam sweeps 45 degrees as it shines", "lamp_sweep": 45.0, "ability": [{"on": "always", "do": "lamp_sweep"}]},
		{"text": "Shines every 3.5s", "lamp_every": 3.5},
		{"text": "Two beams, one forward and one back", "lamp_back": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smile"}, "back": ["lamp"], "front": ["stripes"]},
	"sound": {"ouch": "ouch_laser", "pitch": 0.9},
}
