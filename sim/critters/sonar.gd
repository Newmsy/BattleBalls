## Sonar, the Bat (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 51,
	"name": "Sonar",
	"type": "Bat",
	"rarity": "rare",
	"rarity_power": 1.075, ## Per rarity step: its kit gains less than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "3c096c",
	"vibe": "A nocturnal bat that always knows exactly where you are.",
	"description": "Bat. Every wall bounce it pings, swerving toward the foe and sending out a ring that slows 20% for 1s.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "wall", "do": "ping"}],
	"params": {
		"ping_mark": 0.0, ## T5: seconds a pinged foe stays heard (its next hit on it crits).
		"ping_gap": 1.0, ## Seconds between pings (pillar maps bounce a lot).
		"ping_turn": 45.0, ## Most it turns toward the foe, in degrees.
		"ping_dash_mult": 1.4, ## Swerve speed toward the foe, x its own.
		"ping_dash_secs": 0.3,
		"ping_radius": 180.0,
		"ping_damage": 0.0, ## T3.
		"ping_slow": 0.2,
		"ping_slow_secs": 1.0,
		"ping_hit_mult": 2.0, ## T5: a hit while still swerving.
	},
	"tiers": [
		{"text": "Bounces ping: swerve at foe, slow 20%", "now": "Bounces ping: swerve at foe, slow {ping_slow%}%"},
		{"text": "Swerve speed x1.4 → 1.5", "ping_dash_mult": 1.5},
		{"text": "+ The ping deals 4", "now": "Bounces ping: swerve at foe, {ping_damage} dmg, slow {ping_slow%}%", "ping_damage": 4.0},
		{"text": "Ping size +22%", "ping_radius": 220.0},
		{"text": "+ Pings find the foe · next hit in 3s x2.5", "now": "Bounces ping: swerve, {ping_damage} dmg, slow {ping_slow%}% · hit in {ping_mark}s x{ping_hit_mult}", "special": "Echolocation", "ping_hit_mult": 2.5, "ping_mark": 3.0, "ability": [{"on": "strike", "do": "ping_crit"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "fangs"}, "back": ["batwings", "ears"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
