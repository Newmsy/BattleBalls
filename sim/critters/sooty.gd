## Sooty, the Coal (Common Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 19,
	"name": "Sooty",
	"type": "Coal",
	"rarity": "common",
	"role": "Zoner",
	"status": "live",
	"color": "4a3b36",
	"vibe": "A grumpy little lump of coal that leaves hot spots wherever it sulks.",
	"description": "Coal. Every 4 seconds it drops a hot patch that burns foes standing in it.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "every", "secs": "patch_every", "do": "patch"}],
	"params": {
		"patch_every": 4.0, ## Seconds between hot patches.
		"patch_radius": 60.0,
		"patch_life": 4.0,
		"patch_dps": 4.0,
		"linger_dps": 2.0, ## T3: a foe that was in a patch keeps burning this much...
		"linger_slow": 0.0,
		"linger_secs": 2.0, ## ...for this long.
		"patch_flare_radius": 80.0, ## T5: each patch flares once when Sooty is hurt.
		"patch_flare_damage": 6.0,
	},
	"tiers": [
		{"text": "Hot patch every 4s: 4 damage/s"},
		{"text": "Patches burn for 5/s", "patch_dps": 5.0},
		{"text": "Leaving a patch keeps the foe burning (2/s for 2s)", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "A patch every 3s", "patch_every": 3.0},
		{"text": "Hurt Sooty and every patch flares once (6 damage)", "ability": [{"on": "hurt", "do": "patch_flare"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "frown"}, "back": ["smoke"], "front": ["embers"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 0.8},
}
