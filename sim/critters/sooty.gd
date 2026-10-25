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
	"description": "Coal. Every 4s it drops a hot patch ({patch_dps}/sec for 4s) that burns foes standing in it.",
	"stats": {"hp": 125.0, "radius": 64.0, "speed": 400.0, "contact_damage": 18.0},
	"ability": [{"on": "every", "secs": "patch_every", "do": "patch"}],
	"params": {
		"patch_every": 4.0, ## Seconds between hot patches.
		"patch_radius": 60.0,
		"patch_life": 4.0,
		"patch_dps": 3.0,
		"linger_dps": 2.0, ## T3: a foe that was in a patch keeps burning this much...
		"linger_slow": 0.0,
		"linger_secs": 2.0, ## ...for this long.
		"patch_flare_radius": 80.0, ## T5: each patch flares once when Sooty is hurt.
		"patch_flare_damage": 6.0,
	},
	"tiers": [
		{"text": "Hot patch every 4s: 3/sec", "card": "Drops hot patches that burn foes standing in them.", "now": "Hot patch every {patch_every}s: {patch_dps}/sec"},
		{"text": "Patch {^patch_dps} → {patch_dps}/sec", "patch_dps": 4.0},
		{"text": "+ Leaving keeps burning {linger_dps}/sec for 2s", "card": "Drops hot patches that burn foes, and the burn lingers after they leave.", "now": "Hot patch every {patch_every}s: {patch_dps}/sec, burns after", "ability": [{"on": "always", "do": "linger"}]},
		{"text": "Patch every 4 → 3s", "patch_every": 3.0},
		{"text": "+ Hurt: every patch flares once ({patch_flare_damage} dmg)", "card": "Drops hot patches with a lingering burn. When it's hurt, every patch flares up.", "now": "Hot patch every {patch_every}s: {patch_dps}/sec, burns after; flares when hurt", "ability": [{"on": "hurt", "do": "patch_flare"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "brow": .14, "mouth": "frown"}, "back": ["smoke"], "front": ["embers"]},
	"sound": {"ouch": "ouch_fire", "pitch": 0.8},
}
