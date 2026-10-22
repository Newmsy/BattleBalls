## Glowbug, the Firefly (Uncommon Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 31,
	"name": "Glowbug",
	"type": "Firefly",
	"rarity": "uncommon",
	"role": "Zoner",
	"status": "live",
	"color": "d4ff3a",
	"vibe": "A dreamy firefly that brings its own little lights to every fight.",
	"description": "Firefly. A tiny light-bug circles it and stings foes it touches for 4.",
	"stats": {"hp": 130.0, "radius": 64.0, "speed": 400.0, "contact_damage": 17.5},
	"ability": [{"on": "always", "do": "moons"}],
	"params": {
		"moon_count": 1,
		"moon_orbit": 40.0, ## Distance beyond its edge.
		"moon_size": 12.0,
		"moon_damage": 4.0,
		"moon_spin": 3.5, ## Radians a second.
		"moon_cooldown": 0.5,
		"moon_look": "bug",
		"moon_burn": 0.0,
		"orb_flare_radius": 120.0, ## T5 flare round each bug.
		"orb_flare_damage": 6.0,
	},
	"tiers": [
		{"text": "A light-bug circles it and stings for 4", "now": "A light-bug circles it and stings for {moon_damage}"},
		{"text": "Sting 4 → 5", "moon_damage": 5.0},
		{"text": "Bugs 1 → 2", "now": "{moon_count} light-bugs circle it and sting for {moon_damage}", "moon_count": 2},
		{"text": "Bug orbit +50%", "moon_orbit": 60.0},
		{"text": "+ Every 6s the bugs flare for 6", "now": "{moon_count} light-bugs sting for {moon_damage} · flare every 6s", "ability": [{"on": "every", "secs": 6.0, "do": "orb_flare"}]},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["antenna2"], "front": ["glowbelly"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.4},
}
