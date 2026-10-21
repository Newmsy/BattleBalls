## Wisp, the Ghost (Epic Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 10,
	"name": "Wisp",
	"type": "Ghost",
	"rarity": "epic",
	"role": "Skirmisher",
	"status": "live",
	"color": "e3d6ff",
	"vibe": "Shy and spooky, giggles when you miss it.",
	"description": "Ghost. Every 5s it phases out for 1.2s (-80% dmg taken), and its next hit after deals x2.",
	"stats": {"hp": 102.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.0},
	"ability": [{"on": "every", "secs": "phase_every", "do": "phase"}, {"on": "guard", "do": "phased"}, {"on": "strike", "do": "ambush"}],
	"params": {
		"phase_every": 5.0,
		"phase_secs": 1.2,
		"phase_guard": 0.2, ## Damage taken while phased.
		"ambush_mult": 2.0,
		"trail_every": 0.1, ## T5 wisp trail.
		"trail_width": 30.0,
		"trail_life": 1.5,
		"trail_slow": 0.3,
		"trail_dps": 0.0,
	},
	"tiers": [
		{"text": "Phases out 1.2s every 5s; next hit x2", "now": "Phases out {phase_secs}s every {phase_every}s; next hit x{ambush_mult}"},
		{"text": "Phase 1.2 → 1.5s", "phase_secs": 1.5},
		{"text": "+ Dashes at the foe as it reappears", "now": "Phases out {phase_secs}s every {phase_every}s, dashes back; hit x{ambush_mult}", "ability": [{"on": "always", "do": "phase_dash"}]},
		{"text": "Phase every 5 → 4s", "phase_every": 4.0},
		{"text": "+ Slowing trail while phased (slow 30%)", "now": "Phases {phase_secs}s every {phase_every}s, slow trail, dash; hit x{ambush_mult}", "ability": [{"on": "always", "do": "phase_trail"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .15, "h": .24, "hollow": true, "mouth": "o"}, "body": "ghost", "back": ["wisp_tail"]},
	"sound": {"ouch": "ouch_laser", "pitch": 1.45},
}
