## Sonar, the Bat (Rare Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 51,
	"name": "Sonar",
	"type": "Bat",
	"rarity": "rare",
	"role": "Skirmisher",
	"status": "live",
	"color": "3c096c",
	"vibe": "A nocturnal bat that always knows exactly where you are.",
	"description": "Bat. Every wall bounce it pings, swerving toward the foe and sending out a ring that slows.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.0},
	"ability": [{"on": "wall", "do": "ping"}],
	"params": {
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
		{"text": "Pings on every bounce, slowing 20%"},
		{"text": "Swerves harder", "ping_dash_mult": 1.5},
		{"text": "The ping deals 4", "ping_damage": 4.0},
		{"text": "Bigger ping", "ping_radius": 220.0},
		{"text": "A hit right after a ping deals x2", "ability": [{"on": "strike", "do": "ping_crit"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "fangs"}, "back": ["batwings", "ears"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.3},
}
