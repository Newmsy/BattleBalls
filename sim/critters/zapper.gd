## Zapper, the Coil bot (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 57,
	"name": "Zapper",
	"type": "Coil bot",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "live",
	"color": "c47a2c",
	"vibe": "A buzzing coil bot that loves to share its electricity.",
	"description": "Coil bot. Every 5 seconds it zaps the foe with an arc that stuns it for a moment.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.5},
	"ability": [{"on": "every", "secs": "zap_every", "do": "zap"}, {"on": "always", "do": "zap_tick"}],
	"params": {
		"zap_every": 4.5, ## Seconds between zaps (off Wisp's 5s phase beat).
		"zap_damage": 4.0,
		"zap_stun": 0.2,
		"zap_linger_dps": 0.0, ## T3: the arc stays 1s as a beam.
		"zap_storm_every": 0, ## T5: every Nth zap is a storm of 3 arcs.
	},
	"tiers": [
		{"text": "Every 4.5s an arc zaps the foe for 4 and stuns it 0.2s"},
		{"text": "Zap damage 5.5", "zap_damage": 5.5},
		{"text": "The arc lingers as a beam for 1s (6 damage a second)", "zap_linger_dps": 6.0},
		{"text": "Zaps every 3.5s", "zap_every": 3.5},
		{"text": "Every third zap is a storm of 3 arcs over 1s", "zap_storm_every": 3},
	],
	"art": {"eyes": {"sep": .3, "w": .24, "h": .28, "p": .1, "mouth": "flat"}, "back": ["rodball"], "front": ["coil"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.05},
}
